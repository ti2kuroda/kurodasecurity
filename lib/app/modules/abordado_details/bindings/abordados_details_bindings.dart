import 'package:get/get.dart';

import '../controller/abordados_details_controller.dart';

class AbordadosDetailsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AbordadosDetailsController>(() => AbordadosDetailsController());
  }
}
