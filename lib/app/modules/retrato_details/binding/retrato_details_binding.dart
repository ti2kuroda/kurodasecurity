import 'package:get/get.dart';

import '../controller/retrato_details_controller.dart';

class RetratoDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RetratoDetailsController>(() => RetratoDetailsController());
  }
}
