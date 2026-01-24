import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'places_screen.dart';
import 'fav_places_screen.dart';
import '/widgets/discovery_wheel.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ana Ekran',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),

                  // Haritaya Geç
                  _HomeNavButton(
                    icon: Icons.location_on,
                    heroTag: 'home-map',
                    text: 'Haritaya Geç',
                    onTap: () {
                      Navigator.push(
                        context,
                        _fadeRoute(const MapScreen())
                      );

                    },
                  ),
                  const SizedBox(height: 16),

                  // Mekanlarım
                  _HomeNavButton(
                    icon: Icons.menu,
                    heroTag: 'home-places',
                    text: 'Mekanlarım',
                    //borderColor: border,
                    onTap: () {
                      Navigator.push(
                        context,
                        _fadeRoute(const PlacesScreen())
                      );

                    },
                  ),
                  const SizedBox(height: 16),

                  // Favori Mekanlarım
                  _HomeNavButton(
                    icon: Icons.favorite_border,
                    heroTag: 'home-favs',
                    text: 'Favori Mekanlarım',
                    //borderColor: border,
                    onTap: () {
                      Navigator.push(
                        context,
                        _fadeRoute(const FavPlacesScreen())
                      );

                    },
                  ),              
                ],
              ),
            ),
            //🔹 ÇARK
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: SizedBox(
                    height: 140, 
                    width: 140,
                    child: DiscoveryWheel(),
                  ),
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }
}

class _HomeNavButton extends StatelessWidget {
  const _HomeNavButton({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.heroTag,
  });

  final IconData icon;
  final String text;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? theme.colorScheme.surface
        : theme.colorScheme.primary;

    final fgColor = isDark
        ? theme.colorScheme.onSurface
        : Colors.white;

    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fgColor),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

PageRouteBuilder _fadeRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 700),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.98, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
