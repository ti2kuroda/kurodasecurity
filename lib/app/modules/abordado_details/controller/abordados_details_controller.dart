import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kurodasecurity/app/models/abordados_model.dart';
import 'package:video_player/video_player.dart';
import '../../home/controllers/home_controller.dart';

class AbordadosDetailsController extends GetxController {
  final HomeController _homeController = Get.find<HomeController>();
  final PageController pageController = PageController();
  // Lista de imagens carregadas (bytes)
  final loadedImages = <File>[].obs;
  final isImagesLoading = true.obs;
  late AbordadosModel abordado;
  final videoControllers = <VideoPlayerController?>[].obs;
  final initializedFlags = <bool>[].obs; // Para saber qual vídeo já carregou
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    abordado = Get.arguments as AbordadosModel;
    _prepareImages(); // Carrega as fotos
    _prepareAllVideos(); // Carrega os vídeos (seu código atual)
  }

  Future<void> _prepareImages() async {
    try {
      isImagesLoading.value = true;
      final files = await _homeController.getImagesSambaAsFiles(
        abordado.photos,
      );

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
    videoControllers.assignAll(List.filled(abordado.videos.length, null));
    initializedFlags.assignAll(List.filled(abordado.videos.length, false));

    for (int i = 0; i < abordado.videos.length; i++) {
      final remotePath = abordado.videos[i];

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
}
