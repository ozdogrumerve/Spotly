import 'package:flutter/material.dart';
import 'package:spotly/screens/add_update_screen.dart';
import 'package:spotly/screens/first_screen.dart';
import 'package:spotly/services/theme_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.signInAnonymously();
  await dotenv.load(fileName: ".env");

  // Daha önce kayıtlı tema ayarını yükle
  await ThemeController.instance.loadTheme();

  runApp(const SpotlyApp());
}

class SpotlyApp extends StatelessWidget {
  const SpotlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema değişimlerini dinliyoruz
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode, // aktif tema buradan kontrol edilir
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),

          routes: {
            '/addOrUpdatePlace': (context) => const AddUpdateScreen(),
          },

          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Yukarıdan (y = -0.40) merkeze kayma
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.40),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ac, curve: Curves.easeOutBack),
    );

    _ac.forward(); // animasyonu başlat

    // 2 saniye sonra FirstScreen'e geç
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FirstScreen()),
      );
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: _LogoSlide(),
      ),
    );
  }
}

class _LogoSlide extends StatelessWidget {
  const _LogoSlide();

  @override
  Widget build(BuildContext context) {
    // üstteki State içindeki controller'a erişmek için InheritedElement yerine
    // basit bir Builder ile parent State'e ulaşıyoruz
    final state = context.findAncestorStateOfType<_SplashScreenState>()!;
    return Center(
      child: SlideTransition(
        position: state._slide,
        child: Image.asset(
          'assets/images/logo.png',
          width: 140,
          height: 140,
        ),
      ),
    );
  }
}
