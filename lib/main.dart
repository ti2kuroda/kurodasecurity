import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'app/data/firebase_binding.dart';
import 'app/data/firebase_service.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialize o Firebase Core (OBRIGATÓRIO)
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['API_KEY']!,
      appId: dotenv.env['APP_ID']!,
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['PROJECT_ID']!,
      storageBucket: dotenv.env['STORAGE_BUCKET']!,
    ),
  );

  await Get.putAsync(() => FirebaseService().init());
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider()
          : AndroidProvider.playIntegrity as AndroidAppCheckProvider,
      providerApple: kDebugMode
          ? AppleDebugProvider()
          : AppleProvider.deviceCheck as AppleAppCheckProvider,
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } catch (e) {
    print('\n ${e.toString()} \n ');
  }

  runApp(
    GetMaterialApp(
      title: "Application",
      initialRoute: AppPages.initial,
      initialBinding: InitialBinding(),
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
      ),

      // 2. TEMA ESCURO (darkTheme)
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red.shade900.withValues(alpha: 0.6),
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
      ),

      // Tela inicial (onde o tema será aplicado)
    ),
  );
}
