import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kurodasecurity/app/modules/home/widgets/textformfield.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../../models/retrato_model.dart';
import '../../home/controllers/home_controller.dart';
import '../controller/retrato_details_controller.dart';

class RetratoDetailsView extends GetView<RetratoDetailsController> {
  RetratoDetailsView({super.key});

  final _homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final RetratoModel retrato = controller.retrato;

    return OrientationBuilder(
      builder: (context, orientation) {
        bool isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: Colors.black,
          // Esconde a AppBar no modo paisagem para ganhar espaço
          appBar: isLandscape
              ? null
              : AppBar(title: Text(retrato.title), centerTitle: true),
          body: SingleChildScrollView(
            // Se estiver em paisagem, desabilita o scroll para focar no vídeo
            physics: BouncingScrollPhysics(),
            child: // ... dentro do SingleChildScrollView
            Obx(() {
              // Se não estiver autenticado, mostra o Skeleton
              if (!_homeController.isAuthenticated.value) {
                return buildSkeletonCard();
              }

              // Se estiver autenticado, retorna a Column principal
              return Column(
                children: [
                  if (!isLandscape) ...[
                    _buildImageHeader(),
                    _buildInfoSection(retrato, context, height, width),
                    const Divider(color: Colors.white24),
                  ],

                  if (controller.isLoading.value &&
                      controller.videoControllers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(50.0),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: retrato.videos.length,
                      itemBuilder: (context, index) {
                        if (!controller.initializedFlags[index]) {
                          return const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final vController = controller.videoControllers[index]!;

                        return Container(
                          height: isLandscape
                              ? MediaQuery.of(context).size.height
                              : null,
                          margin: isLandscape
                              ? EdgeInsets.zero
                              : EdgeInsets.symmetric(vertical: height / 100),
                          child: Column(
                            children: [
                              if (!isLandscape)
                                Text(
                                  "Vídeo ${index + 1}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: width / 20,
                                  ),
                                ),
                              Expanded(
                                flex: isLandscape ? 2 : 0,
                                child: InteractiveViewer(
                                  child: SizedBox(
                                    height: isLandscape ? height : height / 2.2,
                                    width: isLandscape ? width : null,
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: SizedBox(
                                        width: vController.value.size.width,
                                        height: vController.value.size.height,
                                        child: VideoPlayer(vController),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              VideoProgressIndicator(
                                vController,
                                allowScrubbing: true,
                                padding: EdgeInsets.zero,
                                colors: const VideoProgressColors(
                                  playedColor: Colors.red,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              _buildControlsByIndex(index),
                              const Divider(color: Colors.white24),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget buildSkeletonCard() {
    return Shimmer.fromColors(
      period: const Duration(
        milliseconds: 1500,
      ), // Movimento mais lento = mais suave
      baseColor: Colors.grey[800]!, // Cinza claro de fundo
      highlightColor: Colors.grey[700]!, // Brilho quase branco, mas sutil
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Cor base para o Shimmer aplicar o efeito
          borderRadius: BorderRadius.circular(16), // Bordas mais suaves
        ),
      ),
    );
  }

  // Widget de controles com GetBuilder para atualização de ícone
  Widget _buildControlsByIndex(int index) {
    return GetBuilder<RetratoDetailsController>(
      builder: (controller) {
        final v = controller.videoControllers[index];
        bool isPlaying = v?.value.isPlaying ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 50,
                color: Colors.white,
              ),
              onPressed: () => controller.togglePlayPause(index),
            ),
            IconButton(
              icon: const Icon(Icons.stop, size: 50, color: Colors.white),
              onPressed: () => controller.stopAndReset(index),
            ),
          ],
        );
      },
    );
  }

  // Widget de Imagem de Capa
  Widget _buildImageHeader() {
    return Obx(() {
      if (controller.isImagesLoading.value) {
        return const SizedBox(
          height: 250,
          child: Center(child: CircularProgressIndicator(color: Colors.red)),
        );
      }

      if (controller.loadedImages.isEmpty) {
        return const SizedBox(
          height: 100,
          child: Center(
            child: Text(
              "Nenhuma imagem disponível",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        );
      }
      final sortedFiles = controller.loadedImages;
      // Criamos um carrossel de imagens
      return Column(
        children: [
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: controller.pageController,
              itemCount: sortedFiles.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () =>
                      _showFullScreenImage(context, sortedFiles[index]),
                  child: Image.file(sortedFiles[index], fit: BoxFit.contain),
                );
              },
            ),
          ),

          SmoothPageIndicator(
            controller: controller.pageController,
            count: sortedFiles.length,
            effect: const WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: Colors.red,
              dotColor: Colors.grey,
            ),
          ),
        ],
      );
    });
  }

  //Função para abrir a Imagem em tela cheia.
  void _showFullScreenImage(BuildContext context, File imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black, // Fundo preto para destacar a foto
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true, // Permite mover a imagem
            minScale: 1.0,
            maxScale: 5.0,
            child: Image.file(
              imageBytes,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  // Seção de Informações com botão de Deletar validado
  Widget _buildInfoSection(
    RetratoModel retrato,
    BuildContext context,
    double height,
    double width,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.person_rounded, color: Colors.red),
              SizedBox(width: width / 30),
              Expanded(
                child: Text(
                  retrato.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width / 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  _homeController.isAuthenticated.value = false;
                  _homeController.showDialog(() {
                    _homeController.deleteRetrato(retrato.id!, 'retratos');
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          _infoRow(Icons.calendar_today, "Data: ${retrato.date}", width),
          _infoRow(Icons.article, "EANs: ${retrato.eans}", width),
          _infoRow(
            Icons.report_problem,
            "Ocorrência: ${retrato.caseOcurrent}",
            width,
          ),
          Text(
            "Descrição:",
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: width / 24,
            ),
          ),
          Text(
            retrato.description,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Row(
            children: [
              Text(
                "Salvo por: ",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width / 24,
                ),
              ),
              Text(
                retrato.portraitMadeBy,
                style: TextStyle(color: Colors.white70, fontSize: width / 23),
              ),
            ],
          ),
          SizedBox(height: height / 20),
          SizedBox(
            width: width,
            height: height / 15,
            child: ElevatedButton(
              onPressed: () async {
                Get.defaultDialog(
                  title: "Mover para Abordados?",
                  backgroundColor: Colors.transparent,
                  buttonColor: Colors.red,
                  titleStyle: const TextStyle(color: Colors.white),
                  content: Column(
                    spacing: 10,
                    children: [
                      HomeTextFormField(
                        controller: _homeController.userController,
                        hintText: "Usuário",
                        iconData: Icons.person,
                      ),
                      HomeTextFormField(
                        controller: _homeController.passwordController,
                        hintText: "Senha",
                        obscureText: true,
                        iconData: Icons.password,
                        textInputType: TextInputType.number,
                      ),
                      HomeTextFormField(
                        controller: controller.dataAbordagemController,
                        hintText: "Data da Abordagem",
                        iconData: Icons.date_range,
                        textInputType: TextInputType.datetime,
                        textFormatter: MaskTextInputFormatter(
                          mask: '##/##/####',
                          type: MaskAutoCompletionType.lazy,
                        ),
                      ),
                      Obx(
                        () => Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: controller.usuarioSelecionado.value,
                              borderRadius: BorderRadius.circular(20),
                              dropdownColor: Colors.white,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: width / 25,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                labelText: 'Abordado por',
                                labelStyle: TextStyle(color: Colors.grey[800]),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                prefixIcon: Icon(
                                  Icons.arrow_drop_down_circle,
                                  color: Theme.of(context).primaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                              ),
                              isExpanded:
                                  true, // Faz o dropdown ocupar a largura disponível
                              items: controller.listaUsuarios.map((
                                String nome,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: nome,
                                  child: Text(nome),
                                );
                              }).toList(),
                              onChanged: (value) {
                                controller.usuarioSelecionado.value = value
                                    .toString();
                              },
                            ),
                            SizedBox(height: height / 80),
                            DropdownMenu<String>(
                              width: width,
                              controller: controller.testemunhaController,
                              initialSelection: controller
                                  .usuarioSelecionado2
                                  .value, // Mantém a seleção inicial
                              requestFocusOnTap: true,
                              enableFilter: true,
                              textStyle: TextStyle(
                                color: Colors.grey[800],
                                fontSize: width / 25,
                              ),
                              hintText: 'Selecione a Testemunha',

                              trailingIcon: const SizedBox.shrink(),
                              inputDecorationTheme: InputDecorationTheme(
                                hintStyle: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: width / 25,
                                ),
                                labelStyle: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: width / 25,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 18,
                                ),
                              ),
                              leadingIcon: Icon(
                                Icons.arrow_drop_down_circle,
                                color: Theme.of(context).primaryColor,
                              ),
                              label: const Text('Selecione a Testemunha'),
                              dropdownMenuEntries: controller.listaUsuarios.map(
                                (String nome) {
                                  return DropdownMenuEntry<String>(
                                    value: nome,
                                    label: nome,
                                  );
                                },
                              ).toList(),
                              onSelected: (String? value) {
                                // Atualiza o valor na sua controller GetX
                                if (value != null) {
                                  controller.usuarioSelecionado2.value = value;
                                  controller.testemunhaController.text = value;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  textConfirm: 'Mover',
                  confirmTextColor: Colors.white,
                  onConfirm: () async {
                    //Validação se o usuário tem permissão
                    var authenticated = await _homeController.validateUser(
                      _homeController.userController.text,
                      _homeController.passwordController.text,
                    );

                    if (authenticated) {
                      await controller.moverParaAbordados(
                        retrato.id ?? '',
                        controller.dataAbordagemController.text,
                        controller.usuarioSelecionado.value ?? "",
                        controller.usuarioSelecionado2.value ??
                            controller.testemunhaController.text,
                        _homeController.userController.text,
                      );
                      _homeController.userController.clear();
                      _homeController.passwordController.clear();
                      controller.abordadoPorController.clear();
                      controller.dataAbordagemController.clear();
                      controller.testemunhaController.clear();
                      controller.usuarioSelecionado.value = null;
                      controller.usuarioSelecionado2.value = null;
                    }
                  },
                  textCancel: 'Cancelar',
                  onCancel: () {
                    _homeController.userController.clear();
                    _homeController.passwordController.clear();
                    controller.abordadoPorController.clear();
                    controller.dataAbordagemController.clear();
                    controller.usuarioSelecionado.value = null;
                    controller.usuarioSelecionado2.value = null;
                  },
                );
              },
              child: controller.isLoadingMoveAbordados.value
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.arrow_back_ios),
                        Text('Mover para Abordados'),
                        Icon(Icons.person_off),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: width / 22),
          SizedBox(width: width / 30),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: width / 22),
            ),
          ),
        ],
      ),
    );
  }
}
