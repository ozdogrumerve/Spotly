import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotly/services/location_service.dart';
import 'package:spotly/services/theme_controller.dart';
import 'dart:async';
import 'homepage.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> with WidgetsBindingObserver {
  bool _navigated = false;
  bool _showOverlay = true; // ekran açıldığında overlay aktif olacak

  final List<String> _loadingMessages = [
    'Konumun kontrol ediliyor...',
    'Yakın yerler aranıyor...',
    'Rotalar çiziliyor...',
    'Spotly seni konumlandırıyor...',
    'Harita hazırlanıyor...',
  ];

  int _currentMessageIndex = 0;
  Timer? _messageTimer;
  // ignore: unused_field
  bool _checkingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _checkingLocation = true;
    _startMessageCycle();

    // 5 saniye bekle sonra konumu kontrol et
    Future.delayed(const Duration(seconds: 5), () {
      _messageTimer?.cancel();
      _checkLocationAndNavigate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationAndNavigate();
    }
  }

  void _startMessageCycle() {
    _messageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % _loadingMessages.length;
      });
    });
  }

  Future<void> _checkLocationAndNavigate() async {
    final hasPermission = await LocationService.checkPermissionOnly();
    final enabled = await LocationService.isLocationServiceEnabled();

    if (!_navigated && mounted) {
      if (hasPermission && enabled) {
        // KONUM AÇIK
        _navigated = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            title: Text("Bilgilendirme"),
            content:
                Text("Konumunuz açık. Ana sayfaya yönlendiriliyorsunuz..."),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context); // dialogu kapat

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        // KONUM KAPALI
        setState(() {
          _showOverlay = false; // karartmayı kaldır
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Konum Kapalı"),
            content: const Text(
                "Konumunuz algılanamadı.\nLütfen ayarlardan konum izni verin."),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context); // dialogu kapat
      }
    }
  }

  void _goToSettings() async {
    await LocationService.openLocationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.instance.themeMode,
        builder: (context, mode, _) {
          final isDark = mode == ThemeMode.dark;

          return SafeArea(
            child: Scaffold(
              body: Stack(children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/background.jpg'),
                      fit: BoxFit.cover, // ekrana tam oturması için
                      opacity: 0.3,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 18),
                                Text(
                                  'SPOTLY',
                                  style: GoogleFonts.dancingScript(
                                    fontSize: 57,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 68, 123, 233),
                                    shadows: [
                                      Shadow(
                                          offset: Offset(1, 1),
                                          color: Colors.black,
                                          blurRadius: 1),
                                      Shadow(
                                          offset: Offset(-1, -1),
                                          color: Colors.black,
                                          blurRadius: 1),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Yakındaki yerleri keşfetmek\n için konumun gerekiyor',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        const Color.fromARGB(255, 72, 105, 171),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _goToSettings,
                            child: const Text(
                              'Ayarlar',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded),
                            const SizedBox(width: 6),
                            const Text('Tema'),
                            const SizedBox(width: 8),
                            Switch(
                              value: isDark,
                              onChanged: (v) {
                                ThemeController.instance.setTheme(
                                  v ? ThemeMode.dark : ThemeMode.light,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showOverlay)
                  Container(
                    color: Colors.black.withAlpha(180), // karanlık katman
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: Text(
                          _loadingMessages[_currentMessageIndex],
                          key: ValueKey(_currentMessageIndex),
                          style: const TextStyle(
                            fontSize: 27,
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          );
        });
  }
}
