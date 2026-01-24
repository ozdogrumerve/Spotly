import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotly/screens/route_screen.dart';
import 'package:spotly/services/firestore_service.dart';
import 'package:spotly/services/location_service.dart';
import 'package:spotly/models/place_model.dart';
import 'map_screen.dart';
import 'places_screen.dart';
import 'fav_places_screen.dart';
import '/widgets/discovery_wheel.dart';
import 'dart:math';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    double distanceInMeters(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
    ) {
      const earthRadius = 6371000; // metre

      final dLat = (lat2 - lat1) * pi / 180;
      final dLon = (lon2 - lon1) * pi / 180;

      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1 * pi / 180) *
              cos(lat2 * pi / 180) *
              sin(dLon / 2) *
              sin(dLon / 2);

      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return earthRadius * c;
    }

    void onDiscoverySpin() async {
      final position = await LocationService.getCurrentPositionIfPossible();
      if (position == null) return;

      final userLat = position.latitude;
      final userLng = position.longitude;

      final List<PlaceModel> places =
          await FirestoreService().getUserPlacesOnce();

      if (places.isEmpty) return;

      final nearby = places.where((place) {
        return distanceInMeters(
              userLat,
              userLng,
              place.lat!,
              place.lng!,
            ) <
            3000; // 3 km
      }).toList();

      final sourceList = nearby.isNotEmpty ? nearby : places;

      final randomPlace = sourceList[Random().nextInt(sourceList.length)];

      Navigator.push(
        context,
        _fadeRoute(
          RouteScreen(
            destination: LatLng(
              randomPlace.lat!,
              randomPlace.lng!,
            ),
            place: randomPlace,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
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
                    Navigator.push(context, _fadeRoute(const MapScreen()));
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
                    Navigator.push(context, _fadeRoute(const PlacesScreen()));
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
                        context, _fadeRoute(const FavPlacesScreen()));
                  },
                ),
              ],
            ),
          ),
          // 🔹 ÇARK + YAZI
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Mekan önerisi almak için pusulayı döndür',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    height: 120, // ← biraz büyüttük
                    child: DiscoveryWheel(
                      onSpin: onDiscoverySpin,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
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

    final bgColor =
        isDark ? theme.colorScheme.surface : theme.colorScheme.primary;

    final fgColor = isDark ? theme.colorScheme.onSurface : Colors.white;

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
