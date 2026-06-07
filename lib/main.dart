import 'package:ai/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // المكتبة الأساسية
import 'firebase_options.dart'; // الملف اللي اتعملك لما ربطت الفايربيز
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // 1. التأكد من أن جميع الـ Widgets تم تهيئتها قبل بدء أي عملية
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تشغيل اتصال الفايربيز مع الأبلكيشن
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    // طباعة الخطأ لمساعدة عملية التشخيص
    // استبدل هذا بالتعامل المناسب في التطبيق (عرض شاشة خطأ، إعادة المحاولة، الخ.)
    debugPrint('Firebase initialization error: $e');
    debugPrint('$st');
    rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ApiService.navigatorKey, // ✅ ضيف السطر ده
      debugShowCheckedModeBanner: false,
      title: 'FitAI Coach',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        // ستايل عام مريح للعين للأبلكيشن
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E8B57)),
      ),
      home: const SplashScreen(), // الشاشة اللي بتظهر أول ما التطبيق يفتح
      // initialRoute: '/',
      routes: {
        //  '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/intro': (context) => const IntroScreen(),
      },
    );
  }
}
