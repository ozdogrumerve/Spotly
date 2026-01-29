import 'package:flutter/services.dart';
import 'package:spotly/models/place_model.dart';
import 'package:spotly/services/firestore_service.dart';
import 'package:spotly/services/theme_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RouteScreen extends StatefulWidget {
  final LatLng destination;
  final PlaceModel place;

  const RouteScreen(
      {super.key, required this.destination, required this.place});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  final Set<Polyline> _polylines = {};
  List<LatLng> _routeCoords = [];
  String? _mapStyle;

  Future<void> openGoogleMapsNavigation(LatLng destination) async {
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1'
        '&destination=${destination.latitude},${destination.longitude}'
        '&travelmode=driving');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Google Maps açılamadı: $url';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _prepareRoute();
  }

  Future<void> _loadMapStyle() async {
    final isDark = ThemeController.instance.isDark;
    if (isDark) {
      _mapStyle =
          await rootBundle.loadString('assets/map_styles/dark_map.json');
    } else {
      _mapStyle = null;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _prepareRoute() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = LatLng(pos.latitude, pos.longitude);

      await _drawRoute(_currentLocation!, widget.destination);
    } catch (e) {
      debugPrint("Location or route error: $e");
    }
  }

  Future<void> _drawRoute(LatLng start, LatLng end) async {
    print("ROUTE FUNCTION CALLED");

    final polylinePoints = PolylinePoints(
      apiKey: dotenv.env['GOOGLE_DIRECTIONS_API_KEY']!,
      preferRoutesApi: false,
    );

    final PolylineResult result =
        await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(end.latitude, end.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      _routeCoords =
          result.points.map((pt) => LatLng(pt.latitude, pt.longitude)).toList();

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: _routeCoords,
          ),
        );
      });

      // Haritayı rota boyunca göster
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromLatLngList(_routeCoords), 50),
      );
    } else {
      debugPrint("No route found");
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double south = list.first.latitude,
        north = list.first.latitude,
        east = list.first.longitude,
        west = list.first.longitude;

    for (var pt in list) {
      if (pt.latitude < south) south = pt.latitude;
      if (pt.latitude > north) north = pt.latitude;
      if (pt.longitude < west) west = pt.longitude;
      if (pt.longitude > east) east = pt.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rota Önizleme")),
      body: Column(
        children: [
          Expanded(
            child: _currentLocation == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 13,
                    ),
                    polylines: _polylines,
                    markers: {
                      Marker(
                        markerId: const MarkerId('start'),
                        position: _currentLocation!,
                      ),
                      Marker(
                        markerId: const MarkerId('end'),
                        position: widget.destination,
                      ),
                    },
                    onMapCreated: (controller) async {
                      _mapController = controller;
                      await _loadMapStyle();
                    },
                    style: _mapStyle,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirestoreService().setLastVisitedPlace(widget.place.id);

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set(
                    {
                      'lastVisitedPlaceId': widget.place.id,
                      'lastVisitedAt': FieldValue.serverTimestamp(),
                    },
                    SetOptions(merge: true),
                  );

                  openGoogleMapsNavigation(widget.destination);
                },
                icon: const Icon(Icons.navigation),
                label: const Text("Başlat"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
