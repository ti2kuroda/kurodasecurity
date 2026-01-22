import 'package:get/get.dart';
import 'package:kurodasecurity/app/modules/abordado_details/bindings/abordados_details_bindings.dart';
import 'package:kurodasecurity/app/modules/abordado_details/views/abordado_details_view.dart';
import '../modules/config/bindings/config_binding.dart';
import '../modules/config/views/config_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/retrato_details/binding/retrato_details_binding.dart';
import '../modules/retrato_details/views/retrato_details_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: _Paths.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.config,
      page: () => const ConfigView(),
      binding: ConfigBinding(),
    ),
    GetPage(
      name: _Paths.retratoDetails,
      page: () => RetratoDetailsView(),
      binding: RetratoDetailsBinding(),
    ),
    GetPage(
      name: _Paths.abordadosDetails,
      page: () => AbordadoDetailsView(),
      binding: AbordadosDetailsBindings(),
    ),
  ];
}
