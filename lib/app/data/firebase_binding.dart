import 'package:get/get.dart';

import '../modules/home/controllers/home_controller.dart';

import 'firebase_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController(), permanent: true);

    Get.lazyPut(() => FirebaseService(), fenix: true);
  }
}
