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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PlaceModel? _lastVisitedPlace;
  bool _loadingLastVisited = true;

  @override
  void initState() {
    super.initState();
    _loadLastVisitedPlace();
  }

  Future<void> _loadLastVisitedPlace() async {
    final place = await FirestoreService().getLastVisitedPlace();

    if (!mounted) return;

    setState(() {
      _lastVisitedPlace = place;
      _loadingLastVisited = false;
    });
  }

  void _showPlacePreview(
    BuildContext context,
    PlaceModel place,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 🔹 Mekan adı
              Text(
                place.isim,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 6),

              // 🔹 Kategori
              Text(
                place.kategori,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 20),

              // 🔹 Rota butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.directions),
                  label: const Text('Rotaya Geç'),
                  onPressed: () async {
                    // 🔹 Yeni last visited place'i anında yükle
                    final updated =
                        await FirestoreService().getLastVisitedPlace();

                    if (!mounted) return;

                    setState(() {
                      _lastVisitedPlace = updated;
                      _loadingLastVisited = false;
                    });

                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      _fadeRoute(
                        RouteScreen(
                          destination: LatLng(place.lat!, place.lng!),
                          place: place,
                        ),
                      ),
                    ).then((_) async {
                      final updated = await FirestoreService().getLastVisitedPlace();
                      if (!mounted) return;
                      setState(() {
                        _lastVisitedPlace = updated;
                        _loadingLastVisited = false;
                      });
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
      _showPlacePreview(context, randomPlace);
    }

    // Last visited card'da date gösteren fonksiyon
    String _formatDate(DateTime date) {
      return '${date.day}.${date.month}.${date.year} – ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const Text(
                  'Ana Ekran',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Haritaya Geç
                _HomeNavButton(
                  icon: Icons.location_on,
                  heroTag: 'home-map',
                  text: 'Haritaya Geç',
                  onTap: () {
                    Navigator.push(context, _fadeRoute(const MapScreen())).then((_) {
                      FirestoreService().getLastVisitedPlace().then((updatedPlace) {
                        if (!mounted) return;
                        setState(() {
                          _lastVisitedPlace = updatedPlace;
                          _loadingLastVisited = false;
                        });
                      });
                    });
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

          SizedBox(
            height: 50,
          ),

          if (!_loadingLastVisited && _lastVisitedPlace != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Son Ziyaret Edilen Mekan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                      ),
                      const SizedBox(height: 50),
                      Text(
                        _lastVisitedPlace!.isim,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _lastVisitedPlace!.kategori,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                            ),
                      ),
                      const SizedBox(height: 24),
                      if (_lastVisitedPlace!.visitedAt != null)
                        Text(
                          _formatDate(_lastVisitedPlace!.visitedAt!),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(),
                        ),
                    ],
                  ),
                ),
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
