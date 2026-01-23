import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotly/models/place_model.dart';
import 'package:spotly/services/firestore_service.dart';

class AddUpdateScreen extends StatefulWidget {
  const AddUpdateScreen({super.key});

  @override
  State<AddUpdateScreen> createState() => _AddUpdateScreenState();
}

class _AddUpdateScreenState extends State<AddUpdateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _selectedCategory;
  double _rating = 0;
  LatLng? _selectedLocation;
  bool _isFavorite = false;


  bool _isUpdateMode = false;
  late String _docId;

  final List<String> _categories = [
    'Kafe',
    'Restoran',
    'Park',
    'Müze',
    'Otel',
    'Kütüphane',
    'AVM',
    'Diğer'
  ];

  bool _isInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) return; // Tek sefer çalışmasını sağlıyor
    _isInitialized = true;

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args != null && args['place'] != null && args['place'] is PlaceModel) {
      final place = args['place'];
      _isUpdateMode = true;
      _docId = place.id;

      _nameController.text = place.isim;
      _selectedCategory = place.kategori;
      _rating = place.puan.toDouble();
      _noteController.text = place.note;
      _selectedLocation = LatLng(place.lat ?? 0, place.lng ?? 0);
      _isFavorite = place.favori;
    } else if (args != null && args['location'] != null) {
      _selectedLocation = args['location'] as LatLng;
    }
  }

  Future<void> _savePlace() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı oturumu ya da konum eksik.")),
      );
      return;
    }

    final name = _nameController.text.trim();
    final category = _selectedCategory;
    final note = _noteController.text.trim();
    final rating = _rating;

    if (name.isEmpty || category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen mekan adı ve kategori girin.")),
      );
      return;
    }

    final placeData = PlaceModel(
      id: _isUpdateMode ? _docId : '', // Güncelleme ise ID kullan
      isim: name,
      kategori: category,
      puan: rating.toInt(),
      favori: _isFavorite,
      lat: _selectedLocation!.latitude,
      lng: _selectedLocation!.longitude,
      note: note,
    );

    try {
      if (_isUpdateMode) {
        await FirestoreService().updatePlace(placeData);
      } else {
        await FirestoreService().addPlace(placeData);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            _isUpdateMode ? "Mekan güncellendi." : "Mekan başarıyla eklendi."),
      ));

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
      );
    }
    print('Kayıt edilecek kategori: $category, $_isUpdateMode');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isUpdateMode ? 'Mekan Güncelle' : 'Mekan Ekle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mekan İsmi"),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Mekan ismini girin",
              ),
            ),
            const SizedBox(height: 16),
            const Text("Kategori"),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedCategory != '' ? _selectedCategory : null,
              items: _categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                  print('Seçilen kategori: $_selectedCategory');
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Kategori seçin",
              ),
            ),
            const SizedBox(height: 16),
            const Text("Puan"),
            const SizedBox(height: 6),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() => _rating = rating);
              },
            ),
            const SizedBox(height: 16),
            const Text("Not"),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Not girin",
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePlace,
                child: Text(_isUpdateMode ? "Güncelle" : "Kaydet"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
