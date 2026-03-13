import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app/splash_router.dart'; // ✅ NEW
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 👇 تعطيل الكاش مؤقتًا أثناء التشخيص
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Booking',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('ar'), Locale('en')],

      // 👇 نخلّي SplashRouter هو البوابة الرئيسية بدل AuthGate
      home: const SplashRouter(),

      // 👇 مساراتك المعتادة
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(role: 'patient'),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
