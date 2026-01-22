import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kurodasecurity/app/data/firebase_service.dart';
import 'package:video_player/video_player.dart';
import 'package:kurodasecurity/app/models/retrato_model.dart';
import '../../home/controllers/home_controller.dart';

class RetratoDetailsController extends GetxController {
  final HomeController _homeController = Get.find<HomeController>();

  // Lista de imagens carregadas (bytes)
  final loadedImages = <File>[].obs;
  final isImagesLoading = true.obs;
  late RetratoModel retrato;
  final videoControllers = <VideoPlayerController?>[].obs;
  final testemunhaController = TextEditingController();
  final initializedFlags = <bool>[].obs; // Para saber qual vídeo já carregou
  final isLoading = true.obs;
  //Controllador da PageView que roda nas imagens.
  final PageController pageController = PageController();
  //Mostra o índice numericamente ou reagir à mudança:
  var currentPage = 0.obs;
  @override
  void onInit() {
    super.onInit();
    retrato = Get.arguments as RetratoModel;
    _prepareImages();
    _prepareAllVideos();
    buscarUsuarios();
  }

  // No RetratoDetailsController
  Future<void> _prepareImages() async {
    try {
      isImagesLoading.value = true;
      final files = await _homeController.getImagesSambaAsFiles(retrato.photos);

      // ORDENAÇÃO CORRIGIDA
      files.sort((a, b) {
        // Convertemos para minúsculas para evitar problemas com 'Retrato' vs 'retrato'
        final pathA = a.path.toLowerCase();
        final pathB = b.path.toLowerCase();

        final isARetrato = pathA.contains('retrato');
        final isBRetrato = pathB.contains('retrato');

        if (isARetrato && !isBRetrato) {
          return -1; // 'a' (retrato) sobe para o topo (primeiro)
        } else if (!isARetrato && isBRetrato) {
          return 1; // 'b' (retrato) sobe, então 'a' desce
        }

        return 0; // Se ambos forem iguais ou nenhum for retrato, mantém a ordem
      });

      loadedImages.assignAll(files);
    } finally {
      isImagesLoading.value = false;
    }
  }

  Future<void> _prepareAllVideos() async {
    isLoading.value = true;
    videoControllers.assignAll(List.filled(retrato.videos.length, null));
    initializedFlags.assignAll(List.filled(retrato.videos.length, false));

    for (int i = 0; i < retrato.videos.length; i++) {
      final remotePath = retrato.videos[i];

      // Pede o ficheiro único ao HomeController
      final List<File> downloadedFiles = await _homeController
          .getImagesSambaAsFiles([remotePath]);

      if (downloadedFiles.isNotEmpty) {
        final File videoFile = downloadedFiles.first;

        // Já não precisas de writeAsBytes aqui, o HomeController já salvou no disco!
        final vController = VideoPlayerController.file(videoFile);
        await vController.initialize();
        videoControllers[i] = vController;
        initializedFlags[i] = true;
        update();
      }
    }
    isLoading.value = false;
  }

  void togglePlayPause(int index) {
    final v = videoControllers[index];
    if (v != null && v.value.isInitialized) {
      v.value.isPlaying ? v.pause() : v.play();
      update();
    }
  }

  void stopAndReset(int index) {
    final v = videoControllers[index];
    if (v != null) {
      v.pause();
      v.seekTo(Duration.zero);
      update();
    }
  }

  @override
  void onClose() {
    // Limpeza de todos os controllers para não vazar memória
    for (var v in videoControllers) {
      v?.dispose();
    }
    super.onClose();
  }

  var listaUsuarios = <String>[].obs;
  RxnString usuarioSelecionado = RxnString(null);
  RxnString usuarioSelecionado2 = RxnString(null);

  void buscarUsuarios() async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore.db
          .collection('users')
          // .where('role', isEqualTo: 'Fiscal de Loja')
          .get();

      // Mapeia os documentos pegando apenas o campo 'username'
      List<String> nomes = snapshot.docs
          .map((doc) => doc['username'] as String)
          .toList();

      listaUsuarios.assignAll(nomes);

      if (listaUsuarios.isEmpty) {
        usuarioSelecionado.value = null;
      }
    } catch (e) {
      Get.snackbar("Erro", "Não foi possível carregar usuários: $e");
    }
  }

  final dataAbordagemController = TextEditingController();
  final abordadoPorController = TextEditingController();

  final _firebaseFirestore = Get.find<FirebaseService>();
  final RxBool isLoadingMoveAbordados = false.obs;

  // Função para mover o documento
  Future<void> moverParaAbordados(
    String docId,
    String dataAbordagemController,
    String abordadoPorController,
    String testemunhaController,
    String userController,
  ) async {
    try {
      isLoadingMoveAbordados.value = true;

      DocumentReference refOriginal = _firebaseFirestore.db
          .collection('retratos')
          .doc(docId);
      DocumentReference refDestino = _firebaseFirestore.db
          .collection('abordados')
          .doc(docId);

      DocumentSnapshot snapshot = await refOriginal.get();

      if (snapshot.exists) {
        Map<String, dynamic> dados = snapshot.data() as Map<String, dynamic>;

        // Adicionando os dados com tratativas simples
        dados['dataAbordagem'] = dataAbordagemController;
        dados['abordadoPor'] = abordadoPorController;
        dados['testemunha'] = testemunhaController;
        dados['movidoPor'] = userController;
        dados['movidoEm'] = DateFormat(
          'dd/MM/yyyy HH:mm',
        ).format(DateTime.now());

        // Operação Atômica (Batch)
        //
        WriteBatch batch = _firebaseFirestore.db.batch();
        batch.set(refDestino, dados);
        batch.delete(refOriginal);

        await batch.commit();

        // Reset de variáveis de seleção
        usuarioSelecionado.value = null;
        usuarioSelecionado2.value = null;
        Get.back(closeOverlays: true);
        Get.snackbar(
          "Sucesso!",
          "Movido para Abordados!",
          colorText: Colors.white,
          backgroundColor: Colors.green[500],
        );
      } else {
        Get.snackbar(
          "Erro",
          "O documento original não foi encontrado no banco.",
        );
      }
    } catch (e) {
      Get.snackbar("Erro Crítico", "Falha ao mover documento: $e");
    } finally {
      isLoadingMoveAbordados.value = false;
    }
  }
}
