import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotly/models/place_model.dart';
import 'package:spotly/screens/note_detail_screen.dart'; 
import 'package:spotly/screens/route_screen.dart';
import 'package:spotly/services/location_service.dart';
import 'package:spotly/services/theme_controller.dart';
import '../models/location_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LocationModel? _userLocation;
  String? _mapStyle;
  Set<Marker> _markers = {};
  List<PlaceModel> _allPlaces = [];
  List<PlaceModel> _filteredPlaces = [];
  bool _isSearching = false;
  bool _isAnimating = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedMarkerId;

  // Kartları yönetmek için PageController
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadMapStyle();
    _loadUserMarkers();

    // Uygulama başlatıldığında ilk marker'ı seçili yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_allPlaces.isNotEmpty) {
        _selectedMarkerId = _allPlaces.first.id;
        _loadUserMarkers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose(); // Controller'ı temizle
    super.dispose();
  }


  // Yanıp Sönme Animasyonu Metodu
  Future<void> _animateSelectedMarker(
      MarkerId markerId, LatLng originalPosition) async {
    _isAnimating = true;

    await Future.delayed(const Duration(milliseconds: 100));

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
          originalPosition, 19), // Zoom seviyesini 19
    );

    final defaultIcon = BitmapDescriptor.defaultMarker;
    final blueIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

    for (int i = 0; i < 5; i++) {
      _updateSingleMarkerIcon(markerId, defaultIcon);
      await Future.delayed(const Duration(milliseconds: 150));

      _updateSingleMarkerIcon(markerId, blueIcon);
      await Future.delayed(const Duration(milliseconds: 150));
    }

    _updateSingleMarkerIcon(markerId, blueIcon);

    _isAnimating = false;
  }

  void _updateSingleMarkerIcon(MarkerId id, BitmapDescriptor icon) {
    final updated = Set<Marker>.of(_markers);
    final marker = updated.firstWhere(
      (m) => m.markerId == id,
      orElse: () => Marker(markerId: const MarkerId("none")),
    );

    if (marker.markerId.value == "none") return;

    updated.remove(marker);
    updated.add(marker.copyWith(iconParam: icon));

    setState(() => _markers = updated);
  }

  // ARAMA VE FİLTRELEME

  void _onSearchChanged(String query) {
    final cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredPlaces = _allPlaces;
      });
    } else {
      setState(() {
        _isSearching = true;
        _filteredPlaces = _allPlaces.where((place) {
          final isim = place.isim;
          if (isim.isEmpty) {
            return false;
          }
          return isim.toLowerCase().contains(cleanedQuery.toLowerCase());
        }).toList();
      });
    }
  }

  // MARKER YÜKLEME VE RENK KONTROLÜ

  Future<void> _loadUserMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('places')
        .get();

    final places = snapshot.docs.map((doc) {
      final data = doc.data();
      return PlaceModel.fromMap(doc.id, data);
    }).toList();

    final markers = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final markerId = MarkerId(doc.id);
          final isSelected = markerId.value == _selectedMarkerId;

          final markerColor = isSelected
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue) // Seçiliyse Mavi
              : BitmapDescriptor
                  .defaultMarker; // Seçili değilse Kırmızı/Varsayılan

          if (data.containsKey('lat') && data.containsKey('lng')) {
            return Marker(
              markerId: markerId,
              position: LatLng(
                (data['lat'] as num).toDouble(),
                (data['lng'] as num).toDouble(),
              ),
              icon: markerColor,
              infoWindow: InfoWindow(
                title: data['isim'] ?? '',
                snippet: data['kategori'] ?? '',
              ),
              // Marker'a tıklama işlevi 
              onTap: () {
                final index = places.indexWhere((p) => p.id == doc.id);
                if (index != -1) {
                  // Tıklanan marker'ın kartına kaydır
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  // Marker'ı seçili hale getir, haritayı taşı
                  _onPageChanged(index);
                }
              },
            );
          } else {
            return null;
          }
        })
        .whereType<Marker>()
        .toSet();

    if (mounted) {
      setState(() {
        _markers = markers;
        _allPlaces = places;
        _filteredPlaces = places;
      });
    }
  }

  // SAYFA DEĞİŞİMİ VE MARKER SENKRONİZASYONU 

  void _onPageChanged(int index) {
    if (_isAnimating) return;

    if (index >= 0 && index < _allPlaces.length) {
      final selectedPlace = _allPlaces[index];
      final targetPosition = LatLng(selectedPlace.lat!, selectedPlace.lng!);

      // 1. Marker rengini güncelle (SADECE MAVİYE DÖNME)
      setState(() {
        _selectedMarkerId = selectedPlace.id;
        _loadUserMarkers(); // Marker'ları yeniden yükleyerek rengi güncelle
      });

      // 2. Harita kamerasını yeni konuma taşı
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
            targetPosition, 16), // Zoom seviyesini 16 olarak belirledik
      );
    }
  }

  // Mekan seçimi (Arama listesinden seçim için)

  Future<void> _onPlaceSelected(PlaceModel place) async {
    final index = _allPlaces.indexWhere((p) => p.id == place.id);
    if (index != -1) {
      final markerId = MarkerId(place.id);
      final targetPosition = LatLng(place.lat!, place.lng!);
      _animateSelectedMarker(markerId, targetPosition);
      // Arama durumunu sıfırla ve klavyeyi kapat
      _searchController.clear();
      setState(() {
        _isSearching = false;
        _filteredPlaces = _allPlaces;
      });
      FocusManager.instance.primaryFocus?.unfocus();
      _onPageChanged(index);

      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
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

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_userLocation!.toLatLng(), 15),
    );
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

  // KART OLUŞTURMA YARDIMCI METODU (Yıldız derecelendirmesi ve buton stilleri)
  Widget _buildPlaceCard(PlaceModel place) {
    // Derecelendirme puanını güvenli bir şekilde al ve double'a dönüştür.
    final dynamic rawRating = place.puan;
    double rating = 0.0;

    if (rawRating is num) {
      rating = rawRating.toDouble();
    } else if (rawRating is String) {
      rating = double.tryParse(rawRating) ?? 0.0;
    }

    if (rating > 5.0) rating = 5.0;

    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;
    final int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mekan Adı
            Text(
              place.isim,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // Yıldızları dinamik olarak oluştur
            Row(
              children: [
                // Tam Yıldızlar
                ...List.generate(
                    fullStars,
                    (index) =>
                        const Icon(Icons.star, color: Colors.amber, size: 18)),
                // Yarım Yıldız
                if (hasHalfStar)
                  const Icon(Icons.star_half, color: Colors.amber, size: 18),
                // Boş Yıldızlar
                ...List.generate(
                    emptyStars,
                    (index) => const Icon(Icons.star_border,
                        color: Colors.amber, size: 18)),
                SizedBox(width: 21),
                if (place.favori)
                  Icon(Icons.favorite, color: Colors.red, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            // Butonlar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Detay sayfasına gitme işlevi
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => NoteDetailScreen(
                            place: place,
                          ),
                        ),
                      );
                    },
                    child: const Text('Detay'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Rota açma işlevi
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RouteScreen(
                            destination: LatLng(place.lat!, place.lng!),
                          ),
                        ),
                      );
                    },
                    child: const Text('Rota Aç'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Harita'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
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
                    await _loadMapStyle();
                    if (_userLocation != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                            _userLocation!.toLatLng(), 15),
                      );
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: _markers,
                  style: _mapStyle,
                ),

          // Arama çubuğu ve sonuç listesi
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Tıklama alanını sınırlamak için
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Arama çubuğu
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Mekan ara...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  // Arama Sonuçları Listesi
                  if (_isSearching)
                    Container(
                      padding: const EdgeInsets.only(top: 8.0),
                      // Taşmayı engellemek için maksimum yükseklik kısıtlaması
                      constraints: BoxConstraints(
                        maxHeight: mediaQuery.size.height * 0.35,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredPlaces.length,
                          itemBuilder: (ctx, index) {
                            final place = _filteredPlaces[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on),
                              title: Text(place.isim),
                              subtitle: Text(place.kategori),
                              onTap: () {
                                _onPlaceSelected(place);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Alt kısımda kaydırılabilir kartlar
          if (_allPlaces.isNotEmpty && !_isSearching)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  height: 180, // Kartın yüksekliğini belirle
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _allPlaces.length,
                    onPageChanged:
                        _onPageChanged, // Sayfa değişiminde marker'ı güncelle
                    itemBuilder: (context, index) {
                      final place = _allPlaces[index];
                      final isSelected = place.id == _selectedMarkerId;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        // Seçili kartı diğerlerinden biraz yukarıda göstermek için
                        margin: EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: isSelected ? 0 : 10,
                        ),
                        child: _buildPlaceCard(place),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
