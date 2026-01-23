import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotly/models/location_model.dart';
import 'package:spotly/services/location_service.dart';
import 'package:spotly/services/theme_controller.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  LocationModel? _userLocation;
  String? _selectedPlaceName;
  String? _selectedPlaceCategory;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _moveToUserLocation();
    _loadUserLocation();
    _loadExistingPlaces();
  }

  // Marker seti
  Set<Marker> _markers = {};

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

  // Load existing places fonksiyonu
  Future<void> _loadExistingPlaces() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('places')
        .get();
    final existingMarkers = snapshot.docs
        .map((doc) {
          final data = doc.data();
          if (data['lat'] != null && data['lng'] != null) {
            return Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(data['lat'], data['lng']),
              infoWindow: InfoWindow(title: data['isim']),
            );
          }
          return null;
        })
        .whereType<Marker>()
        .toSet();
    setState(() {
      _markers.addAll(existingMarkers);
    });
  }

  Future<void> _moveToUserLocation() async {
    final location = await LocationService.getCurrentPositionIfPossible();
    if (location != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          15,
        ),
      );
    }
  }

  void _onMapTap(LatLng tappedPoint) async {
    setState(() {
      _selectedLocation = tappedPoint;
      _selectedPlaceName = null;
      _selectedPlaceCategory = null;
    });

    //öncekini kaldır
    _markers.removeWhere((marker) => marker.markerId == const MarkerId("selected-location"));

    _markers.add(Marker(
      markerId: const MarkerId("selected-location"),
      position: tappedPoint,
    ));

    if (!mounted) return;
  }

  Future<void> _loadUserLocation() async {
    final position = await LocationService.getCurrentPositionIfPossible();

    if (!mounted) return;

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Konum alınamadı. Lütfen izinleri kontrol edin.")),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
      return;
    }

    setState(() {
      _userLocation = LocationModel.fromPosition(position);
    });
  }

  Future<void> _loadUserMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('places')
      .get();

    final newMarkers = snapshot.docs.map((doc) {
      final data = doc.data();
      if (data.containsKey('lat') && data.containsKey('lng')) {
        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(
            (data['lat'] as num).toDouble(),
            (data['lng'] as num).toDouble(),
          ),
          infoWindow: InfoWindow(title: data['isim'] ?? ''),
        );
      }
      return null;
    }).whereType<Marker>().toSet();

    setState(() {
      _markers = newMarkers.union({
        if (_selectedLocation != null)
          Marker(
            markerId: const MarkerId("selected-location"),
            position: _selectedLocation!,
          )
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mekan Ekle"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _userLocation == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _userLocation!.toLatLng(),
                          zoom: 14,
                        ),
                        onMapCreated: (controller) async {
                          _mapController = controller;
                          _moveToUserLocation();
                          await _loadMapStyle();
                        },
                        onTap: _onMapTap,
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        style: _mapStyle,
                      ),
                // Harita üstü arama kutusu vs. eklenebilir
              ],
            ),
          ),
          if (_selectedLocation != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.place, color: Colors.blue),
                  title: Text(
                    _selectedPlaceName ?? "Mekan adı yükleniyor...",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _selectedPlaceCategory ?? "Kategori belirleniyor...",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedLocation != null
                    ? () async {
                        // Detay ekranına yönlendir
                        final result = await Navigator.pushNamed(
                          context,
                          "/addOrUpdatePlace",
                          arguments: {
                            'location': _selectedLocation,
                            'name': _selectedPlaceName,
                            'category': _selectedPlaceCategory,
                          },                          
                        );

                        // Eğer veri geri dönerse marker'ı güncelle
                        if (result == true) {
                          _loadUserMarkers(); // markerları yeniden yükle
                        }
                      }
                    : null,
                child: const Text("Seçili mekanı ekle"),
              ),
            ),
          )
        ],
      ),
    );
  }
}

