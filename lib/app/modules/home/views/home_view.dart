import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kurodasecurity/app/models/abordados_model.dart';
import 'package:shimmer/shimmer.dart';
import '../../../data/firebase_service.dart';
import '../../../models/retrato_model.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_modalbotomsheet.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Obx(() {
      return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton:
            controller.currentIndex.value == 0 &&
                controller.isAuthenticated.value
            ? null
            : IconButton(
                onPressed: () {
                  // Definimos a função que abre o BottomSheet
                  void openBottomSheet() {
                    Get.bottomSheet(
                      HomeModalBotomSheet(),
                      settings: const RouteSettings(
                        name: 'homeModalBotomSheet',
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryFixed,
                      isScrollControlled: true,
                    ).then((_) {
                      controller.userController.clear();
                      controller.passwordController.clear();
                    });
                  }

                  // LÓGICA CORRIGIDA:
                  if (controller.isAuthenticated.value) {
                    // Se já está logado, abre direto o BottomSheet
                    openBottomSheet();
                  } else {
                    // Se NÃO está logado, abre o dialog e passa a função de abrir o modal como callback
                    controller.showDialog(() => openBottomSheet());
                  }
                },
                icon: Icon(
                  controller.isAuthenticated.value ? Icons.add : Icons.person,
                ),
                color: Theme.of(context).colorScheme.onPrimaryFixed,
                iconSize: 50,
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.red.shade300),
                ),
              ),
        appBar: AppBar(
          title: Text(
            'Kuroda Security',
            style: TextStyle(fontSize: width / 17, color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
          centerTitle: true,
          bottom: TabBar(
            controller: controller.tabController,

            tabs: [
              Tab(
                text: 'Abordados',
                icon: Icon(Icons.person_off_sharp, color: Colors.white),
              ),
              Tab(
                text: 'Retratos',
                icon: Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black,
        body: TabBarView(
          controller: controller.tabController,
          children: [
            streamBuilder('abordados', '/abordados-details'),
            streamBuilder('retratos', '/retrato-details'),
          ],
        ),
      );
    });
  }
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

Widget streamBuilder(String collectionName, String navigationRoute) {
  final _firebaseFirestore = Get.find<FirebaseService>();
  final controller = Get.find<HomeController>();
  return Obx(() {
    if (!controller.isAuthenticated.value) {
      return GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => buildSkeletonCard(),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseFirestore.db
          .collection(collectionName)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text('Erro ao carregar'));

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => buildSkeletonCard(),
          );
        }

        final docs = snapshot.data!.docs;

        final imageDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['photo'] != null ||
              (data['photos'] != null && data['photos'].isNotEmpty);
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: imageDocs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            var doc = imageDocs[index];
            var data = doc.data() as Map<String, dynamic>;

            List<String> pathsToFetch = [];
            if (data['photos'] is List) {
              pathsToFetch = List<String>.from(data['photos']);
            } else if (data['photo'] != null) {
              pathsToFetch = [data['photo'].toString()];
            }

            // --- LÓGICA DE ORDENAÇÃO DE RETRATO ---
            // Se houver algum arquivo que contenha a palavra "retrato", ele vai para o topo da lista
            pathsToFetch.sort((a, b) {
              bool aIsRetrato = a.toLowerCase().contains('retrato.');
              bool bIsRetrato = b.toLowerCase().contains('retrato.');
              if (aIsRetrato && !bIsRetrato) return -1;
              if (!aIsRetrato && bIsRetrato) return 1;
              return 0;
            });

            return GestureDetector(
              onTap: () {
                final retrato = RetratoModel.fromJson(data, docId: doc.id);
                final abordados = AbordadosModel.fromJson(data, docId: doc.id);
                if (navigationRoute == '/retrato-details') {
                  Get.toNamed('/retrato-details', arguments: retrato);
                } else {
                  Get.toNamed('/abordados-details', arguments: abordados);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<List<File>>(
                        // Mude para List<File>
                        future: controller.getImagesSambaAsFiles(pathsToFetch),
                        builder: (context, sambaSnapshot) {
                          if (sambaSnapshot.hasData &&
                              sambaSnapshot.data!.isNotEmpty) {
                            return Image.file(
                              sambaSnapshot.data!.first,
                              fit: BoxFit.cover,
                              cacheWidth: 300,
                            );
                          }
                          return buildSkeletonCard();
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black54,
                          child: Text(
                            data['title'] ?? 'Sem nome',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  });
}
