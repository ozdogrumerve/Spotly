import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'places_screen.dart';
import 'fav_places_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ana Ekran',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Haritaya Geç
                _HomeNavButton(
                  icon: Icons.location_on,
                  text: 'Haritaya Geç',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Mekanlarım
                _HomeNavButton(
                  icon: Icons.menu,
                  text: 'Mekanlarım',
                  //borderColor: border,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlacesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Favori Mekanlarım
                _HomeNavButton(
                  icon: Icons.favorite_border,
                  text: 'Favori Mekanlarım',
                  //borderColor: border,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FavPlacesScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
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
    //this.borderColor,
  });

  final IconData icon;
  final String text;
  //final Color? borderColor;
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          //border: borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,),
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
    );
  }
}
