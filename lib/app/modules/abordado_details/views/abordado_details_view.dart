import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kurodasecurity/app/models/abordados_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../home/controllers/home_controller.dart';
import '../controller/abordados_details_controller.dart';

class AbordadoDetailsView extends GetView<AbordadosDetailsController> {
  AbordadoDetailsView({super.key});

  final _homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final AbordadosModel abordado = controller.abordado;

    return OrientationBuilder(
      builder: (context, orientation) {
        bool isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: Colors.black,
          // Esconde a AppBar no modo paisagem para ganhar espaço
          appBar: isLandscape
              ? null
              : AppBar(title: Text(abordado.title), centerTitle: true),
          body: Obx(() {
            return _homeController.isAuthenticated.value == true
                ? SingleChildScrollView(
                    // Se estiver em paisagem, desabilita o scroll para focar no vídeo
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        if (!isLandscape) ...[
                          _buildImageHeader(),
                          _buildInfoSection(abordado, context, height, width),
                          Divider(color: Colors.white24),
                        ],

                        Obx(() {
                          if (controller.isLoading.value &&
                              controller.videoControllers.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.all(50.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: abordado.videos.length,
                            itemBuilder: (context, index) {
                              if (!controller.initializedFlags[index]) {
                                return SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final vController =
                                  controller.videoControllers[index]!;

                              // CORREÇÃO: Verificamos se houve erro de fato ou se ainda não inicializou
                              if (vController.value.hasError) {
                                return ListTile(
                                  leading: Icon(Icons.error, color: Colors.red),
                                  title: Text(
                                    "Erro: ${vController.value.errorDescription}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }
                              return Container(
                                // No modo paisagem, o container ocupa a altura total da tela
                                height: isLandscape
                                    ? MediaQuery.of(context).size.height
                                    : null,
                                margin: isLandscape
                                    ? EdgeInsets.zero
                                    : EdgeInsets.symmetric(
                                        vertical: height / 100,
                                      ),
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
                                      // <--- Troque o SizedBox.expand por Expanded se estiver dentro de uma Column com altura definida
                                      flex: isLandscape ? 2 : 0,
                                      child: InteractiveViewer(
                                        child: SizedBox(
                                          // No modo abordado, defina uma altura fixa (ex: 300) para não quebrar a Column
                                          height: isLandscape
                                              ? height
                                              : height / 2.2,
                                          width: isLandscape ? width : null,
                                          child: FittedBox(
                                            fit: isLandscape
                                                ? BoxFit.contain
                                                : BoxFit.contain,
                                            child: SizedBox(
                                              width:
                                                  vController.value.size.width,
                                              height:
                                                  vController.value.size.height,
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
                                      colors: VideoProgressColors(
                                        playedColor: Colors.red,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    // Mostra controles apenas no modo abordado ou se você quiser implementar um overlay
                                    _buildControlsByIndex(index),
                                    Divider(color: Colors.white24),
                                  ],
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  )
                : buildSkeletonCard();
            // Fazer um Skeleton aqui ou antes
          }),
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
    return GetBuilder<AbordadosDetailsController>(
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
              icon: Icon(Icons.stop, size: 50, color: Colors.white),
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
        return SizedBox(
          height: 250,
          child: Center(child: CircularProgressIndicator(color: Colors.red)),
        );
      }

      if (controller.loadedImages.isEmpty) {
        return SizedBox(
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
            effect: WormEffect(
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

  void _showFullScreenImage(BuildContext context, File imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black, // Fundo preto para destacar a foto
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 30),
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
    AbordadosModel abordado,
    BuildContext context,
    double height,
    double width,
  ) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.person_rounded, color: Colors.red),
              Text(
                abordado.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width / 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () async {
                  _homeController.isAuthenticated.value = false;
                  _homeController.showDialog(() {
                    _homeController.deleteRetrato(abordado.id!, 'abordados');
                  });
                },
                icon: Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          _infoRow(Icons.calendar_today, "Data: ${abordado.date}", width),
          _infoRow(Icons.article, "EANs: ${abordado.eans}", width),
          _infoRow(
            Icons.report_problem,
            "Ocorrência: ${abordado.caseOcurrent}",
            width,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Descrição:",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width / 22,
                ),
              ),
              Expanded(
                child: Text(
                  abordado.description,
                  style: TextStyle(color: Colors.white70, fontSize: width / 22),
                ),
              ),
              SizedBox(height: height / 30),
            ],
          ),
          Row(
            children: [
              Text(
                "Abordado por: ",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width / 22,
                ),
              ),
              Text(
                abordado.abordadoPor,
                style: TextStyle(color: Colors.white70, fontSize: width / 22),
              ),
              SizedBox(height: height / 30),
            ],
          ),
          Row(
            children: [
              Text(
                "Testemunha: ",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width / 22,
                ),
              ),
              Text(
                abordado.testemunha,
                style: TextStyle(color: Colors.white70, fontSize: width / 22),
              ),
              SizedBox(height: height / 30),
            ],
          ),
          Row(
            children: [
              Text(
                "Data da Abordagem: ",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width / 22,
                ),
              ),
              Text(
                abordado.dataAbordagem,
                style: TextStyle(color: Colors.white70, fontSize: width / 22),
              ),
              SizedBox(height: height / 30),
            ],
          ),
          Row(
            children: [
              Text(
                "Movido por: ",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: width / 22,
                ),
              ),
              Text(
                "${abordado.movidoPor} em ${abordado.movidoEm}",
                style: TextStyle(color: Colors.white70, fontSize: width / 22),
              ),
              SizedBox(height: height / 30),
            ],
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
