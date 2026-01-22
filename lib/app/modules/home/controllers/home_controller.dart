import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kurodasecurity/app/data/firebase_service.dart';
import 'package:kurodasecurity/app/models/retrato_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smb_connect/smb_connect.dart';

import '../widgets/textformfield.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin, WidgetsBindingObserver {
  //TabController
  late TabController tabController;
  RxInt currentIndex = 0.obs;
  RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    _clearSambaCache();
    //Observador do sistema
    WidgetsBinding.instance.addObserver(this);

    //Pede login do usuário assim que abre o sistema
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(() {});
    });
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      currentIndex.value = tabController.index;
    });
  }

  @override
  void dispose() {
    tabController.removeListener(() {});
    tabController.dispose();
    super.dispose();
  }

  //Key para validar o formulário
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  //Controladores dos Campos de Texto do Formulário
  var titleController = TextEditingController();
  var dateController = TextEditingController();
  RxnString selectedDropDownItem = RxnString(null);
  var othersSelectedDrpDownItemController = TextEditingController();
  var eansController = TextEditingController();
  var listVideosController = TextEditingController();
  var descriptionController = TextEditingController();

  @override
  void onClose() {
    _clearSambaCache();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> _clearSambaCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final sambaDir = Directory('${tempDir.path}/samba_cache');

      if (await sambaDir.exists()) {
        // Apaga a pasta e tudo o que está dentro de forma recursiva
        await sambaDir.delete(recursive: true);
        print("Cache do Samba limpo com sucesso.");
      }
    } catch (e) {
      print("Erro ao limpar cache: $e");
    }
  }

  var files = <SmbFile>[].obs;
  var isLoadingSmb = false.obs;
  final searchController = TextEditingController();

  Future<void> searchFile(BuildContext context) async {
    String caminhoDigitado = searchController.text.trim();
    if (caminhoDigitado.startsWith('/')) {
      caminhoDigitado = caminhoDigitado.substring(1);
    }
    String caminhoFinal = "${dotenv.env["SAMBA_FILE_PATH"]}$caminhoDigitado";
    if (!caminhoFinal.endsWith('/')) {
      caminhoFinal = '$caminhoFinal/';
    }
    isLoadingSmb.value = true;
    try {
      final connect = await SmbConnect.connectAuth(
        host: dotenv.env["SAMBA_HOST"]!,
        domain: "",
        username: dotenv.env["SAMBA_USER"]!,
        password: dotenv.env["SAMBA_PASS"]!,
      );

      SmbFile folder = await connect.file(caminhoFinal);
      List<SmbFile> result = await connect.listFiles(folder);
      files.assignAll(result);
      FocusScope.of(context).unfocus();
      Get.snackbar(
        'Pasta Encontrada!',
        'Selecione os arquivos desejados.',
        backgroundColor: Colors.white12,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Erro na busca",
        "Digite uma pasta existente ou verifique o Wifi.\n Erro:$e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoadingSmb.value = false;
    }
  }

  // Mude para uma lista de Strings (caminhos)
  var selectedFilesPaths = <String>[].obs;

  void toggleSelection(SmbFile file) {
    if (selectedFilesPaths.contains(file.path)) {
      selectedFilesPaths.remove(file.path);
    } else {
      selectedFilesPaths.add(file.path);
    }
  }

  //Injeta dados dentro do Firebase passando os caminhos dos arquivos selecionados que estão dentro da lista selectedFilesPaths.

  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  //Variavel para manipular se esta carregando a resposta para o banco de dados ou não.
  RxBool isLoadingFirebase = false.obs;

  Future<void> addRetrato(RetratoModel retrato) async {
    try {
      isLoadingFirebase.value = true;
      final String pathReferencia = retrato.photos.first;

      // 1. Verificação na coleção de RETratos
      final queryRetratos = await _firebaseService.db
          .collection('retratos')
          .where('photos', arrayContains: pathReferencia)
          .limit(1)
          .get();

      // 2. Verificação na coleção de ABORDADOS
      final queryAbordados = await _firebaseService.db
          .collection('abordados')
          .where('photos', arrayContains: pathReferencia)
          .limit(1)
          .get();

      // --- LÓGICA DE VALIDAÇÃO ---

      // Checa se existe como ATIVO em Abordados
      if (queryAbordados.docs.isNotEmpty &&
          (queryAbordados.docs.first['isActive'] ?? false)) {
        Get.back(closeOverlays: true);
        _avisoJaExiste("Este retrato já está na lista de Abordados.");
        titleController.clear();
        dateController.clear();
        selectedDropDownItem.value = null;
        eansController.clear();
        searchController.clear();
        descriptionController.clear();
        return;
      }

      // Checa se existe como ATIVO em Retratos
      if (queryRetratos.docs.isNotEmpty) {
        final docRetrato = queryRetratos.docs.first;
        final bool isActive = docRetrato['isActive'] ?? false;

        if (isActive) {
          Get.back(closeOverlays: true);
          _avisoJaExiste("Este retrato já está nos Retratos.");
          titleController.clear();
          dateController.clear();
          selectedDropDownItem.value = null;
          eansController.clear();
          searchController.clear();
          descriptionController.clear();
          return;
        }
        // CASO B: Existe em Retratos mas está desativado -> Reativa
        else {
          await _firebaseService.db
              .collection('retratos')
              .doc(docRetrato.id)
              .update({
                ...retrato.toMap(),
                'isActive': true,
                'updatedAt': DateFormat(
                  'dd/MM/yyyy HH:mm:ss',
                ).format(DateTime.now()),
              });
          _limparCamposESucesso("Retrato salvo com sucesso!");
          return;
        }
      }

      // CASO C: Não existe em lugar nenhum ou apenas inativo em coleções que não bloqueiam
      await _firebaseService.db.collection('retratos').add(retrato.toMap());
      Get.back();
      _limparCamposESucesso("Novo Retrato registrado com sucesso!");
    } catch (e) {
      Get.snackbar(
        'Erro ao Salvar',
        "Erro: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingFirebase.value = false;
    }
  }

  // Helper para mensagens de erro/duplicidade
  void _avisoJaExiste(String mensagem) {
    isLoadingFirebase.value = false;
    Get.back(closeOverlays: true);
    Get.snackbar(
      'Registro já existente!',
      mensagem,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  // Função auxiliar para evitar repetição de código
  void _limparCamposESucesso(String mensagem) {
    Get.back(closeOverlays: true);

    // Limpa campos
    titleController.clear();
    dateController.clear();
    selectedDropDownItem.value = null;
    othersSelectedDrpDownItemController.clear();
    eansController.clear();
    searchController.clear();
    listVideosController.clear();
    descriptionController.clear();
    files.clear();
    selectedFilesPaths.clear();

    Get.snackbar(
      'Sucesso!',
      mensagem,
      backgroundColor: Colors.transparent,
      colorText: Colors.white,
    );
  }

  //Função para deletar o Retrato
  Future<void> deleteRetrato(String docId, String collectionName) async {
    try {
      isLoadingFirebase.value = true;
      // Deleta o documento específico pelo ID
      await _firebaseService.db.collection(collectionName).doc(docId).update({
        'isActive': false,
        'deletedAt': DateFormat(
          'dd/MM/yyyy HH:mm:ss',
        ).format(DateTime.now()), // Opcional: salva quando foi desativado
        'deletedFor': userController.text,
      });
      Get.back(closeOverlays: true);

      Get.snackbar(
        'Sucesso',
        collectionName == 'retratos'
            ? 'O Retrato removido do APP com sucesso!'
            : 'O Abordado foi removido do APP com sucesso!',
        backgroundColor: Colors.white12,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Erro ao Remover.',
        'Erro: $e \n Fale com o TI para solucionar o problema.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoadingFirebase.value = false;
    }
  }

  //Função que comunica com Samba
  final smb = SmbConnect;

  // Crie uma variável para manter a conexão ativa no Controller
  SmbConnect? _activeConnection;

  Future<SmbConnect> _getConn() async {
    if (_activeConnection != null) return _activeConnection!;

    _activeConnection = await SmbConnect.connectAuth(
      host: dotenv.env["SAMBA_HOST"]!,
      domain: "",
      username: dotenv.env["SAMBA_USER"]!,
      password: dotenv.env["SAMBA_PASS"]!,
    );
    return _activeConnection!;
  }

  final Map<String, String> _localFileCache = {};

  Future<List<File>> getImagesSambaAsFiles(List<dynamic> paths) async {
    List<File> files = [];
    final tempDir = await getTemporaryDirectory();
    final sambaDir = await Directory(
      '${tempDir.path}/samba_cache',
    ).create(recursive: true);
    final connect = await _getConn();

    for (String remotePath in paths) {
      // CORREÇÃO: Criar um nome único substituindo caracteres especiais do path original
      // Isso garante que 'pasta1/foto.jpg' seja diferente de 'pasta2/foto.jpg'
      String uniqueName = remotePath.replaceAll(RegExp(r'[\\/ :.]'), '_');
      File localFile = File('${sambaDir.path}/$uniqueName');

      if (await localFile.exists()) {
        files.add(localFile);
      } else {
        try {
          SmbFile smbFile = await connect.file(
            remotePath.replaceAll('\\', '/'),
          );
          var stream = await connect.openRead(smbFile);

          final IOSink sink = localFile.openWrite();
          await for (var chunk in stream) {
            sink.add(chunk);
          }
          await sink.close();
          files.add(localFile);
        } catch (e) {
          print("Erro ao baixar $remotePath: $e");
        }
      }
    }
    return files;
  }

  // Verifica se o path do arquivo está na lista
  RxBool isSelected(SmbFile file) => selectedFilesPaths.contains(file.path).obs;

  IconData getIconForFile(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.mp4') ||
        name.endsWith('.mkv') ||
        name.endsWith('.mov')) {
      return Icons.videocam;
    }
    if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  Future<void> listDocsSamba() async {
    try {
      final connect = await SmbConnect.connectAuth(
        host: dotenv.env["SAMBA_HOST"]!,
        domain: "",
        username: dotenv.env["SAMBA_USER"]!,
        password: dotenv.env["SAMBA_PASS"]!,
      );
      SmbFile folder = await connect.file("Retratos/");
      List<SmbFile> files = await connect.listFiles(folder);
      if (files.isEmpty) {
        print("A pasta está vazia ou o compartilhamento não foi encontrado.");
      } else {
        print(files.map((e) => e.path).toList());
      }
    } catch (e) {
      print('Erro ao acessar o Samba: $e');
    }
  }

  //Função para validar qualquer usuário que tentar realizar alguma operação.
  var userController = TextEditingController();
  var passwordController = TextEditingController();
  RxBool validateUserIsLoading = false.obs;

  Future<bool> validateUser(
    String userController,
    String passwordController,
  ) async {
    try {
      validateUserIsLoading.value = true;
      // Busca na coleção "users" onde o campo "user" (ou o nome que você deu)
      // seja igual ao que o humano digitou
      final snapshot = await _firebaseService.db
          .collection('users')
          .where('username', isEqualTo: userController)
          .where('password', isEqualTo: passwordController)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var dadosUsuario = snapshot.docs.first.data();
        String role = dadosUsuario['role'] ?? '';

        if (role == 'Fiscal de Loja' || role == 'admin') {
          return true;
        } else {
          Get.snackbar(
            "Acesso Negado",
            "Você não tem permissão para executar essa operação.",
            colorText: Colors.white,
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.TOP,
          );
          return false;
        }
      } else {
        Get.snackbar(
          "Erro ao Autenticar",
          "Usuário e/ou Senha incorretos.",
          colorText: Colors.white,
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        "Erro ao Autenticar",
        "Falha na Conexão com Banco de Dados. \n Verifique a conexão e tente novamente. ",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      validateUserIsLoading.value = false;
    }
  }

  Future<bool> validateUserCreateAccount(
    String userController,
    String passwordController,
  ) async {
    try {
      // Busca na coleção "users" onde o campo "user" (ou o nome que você deu)
      // seja igual ao que o humano digitou
      final snapshot = await _firebaseService.db
          .collection('users')
          .where('username', isEqualTo: userController)
          .where('password', isEqualTo: passwordController)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var dadosUsuario = snapshot.docs.first.data();
        String role = dadosUsuario['role'] ?? '';

        if (role.toLowerCase() == 'admin') {
          return true;
        } else {
          Get.snackbar(
            "Acesso Negado",
            "Você não tem permissão para executar essa operação.",
            colorText: Colors.white,
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.TOP,
          );
          return false;
        }
      } else {
        Get.snackbar(
          "Erro ao Autenticar",
          "Usuário e/ou Senha incorretos.",
          colorText: Colors.white,
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        "Erro ao Autenticar",
        "Falha na Conexão com Banco de Dados. \n Verifique a conexão e tente novamente. ",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  @override
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 1. Quando o app sai de cena (Usuário minimizou ou bloqueou a tela)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Resetamos o estado de autenticação IMEDIATAMENTE por segurança
      isAuthenticated.value = false;
      userController.clear();
      passwordController.clear();

      // Fechamos qualquer diálogo que tenha ficado aberto (evita duplicidade ao voltar)
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }

    // 2. Quando o app volta para o primeiro plano
    if (state == AppLifecycleState.resumed) {
      // Verificamos se NÃO está autenticado E se NÃO há diálogo aberto
      if (!isAuthenticated.value && Get.isDialogOpen == false) {
        Get.snackbar(
          "Bem Vindo, Fiscal de Loja!",
          "Faça Login com seu usuário e senha para continuar.",
        );

        // Removemos o snackbar daqui de dentro, pois ele pode "travar" a UI
        // ou ser confundido com um diálogo pelo GetX
        showDialog(() {});
      }
    }
  }

  Future<Null> showDialog(Function function) async {
    return Get.defaultDialog(
      barrierDismissible: true,
      backgroundColor: Colors.transparent,
      title: "Por favor, insira suas credenciais para continuar.",
      titleStyle: TextStyle(color: Colors.white),
      content: Obx(() {
        return validateUserIsLoading.value
            ? const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : Column(
                children: [
                  HomeTextFormField(
                    controller: userController,
                    hintText: "Usuário",
                    iconData: Icons.person,
                  ),
                  const SizedBox(height: 10),
                  HomeTextFormField(
                    controller: passwordController,
                    hintText: "Senha",
                    obscureText: true,
                    iconData: Icons.password,
                    textInputType: TextInputType.number,
                  ),
                ],
              );
      }),
      confirm: Obx(() {
        if (validateUserIsLoading.value) return const SizedBox.shrink();

        return ElevatedButton.icon(
          onPressed: () async {
            var authenticated = await validateUser(
              userController.text,
              passwordController.text,
            );
            if (authenticated == true) {
              isAuthenticated.value = true;
              await function();
              Get.back();
              userController.clear();
              passwordController.clear();
            }
          },
          label: const Icon(Icons.check_circle, color: Colors.white),
          icon: const Text("Confirmar", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
        );
      }),
      cancel: Obx(() {
        if (validateUserIsLoading.value) return const SizedBox.shrink();
        return ElevatedButton.icon(
          onPressed: () {
            isAuthenticated.value = false;
            userController.clear();
            passwordController.clear();
            Get.back();
          },
          label: const Icon(Icons.cancel),
          icon: const Text('Cancelar', style: TextStyle(color: Colors.white)),
        );
      }),
    ).then((_) {
      if (userController.text.isNotEmpty &&
          passwordController.text.isNotEmpty) {
        userController.clear();
        passwordController.clear();
        validateUserIsLoading.value = false;
      }
    });
  }
}
