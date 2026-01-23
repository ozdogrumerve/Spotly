import 'package:flutter/material.dart';
import 'package:spotly/models/place_model.dart';
import 'package:spotly/screens/add_places_screen.dart';
import 'package:spotly/screens/note_detail_screen.dart';
import 'package:spotly/services/firestore_service.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  PlaceModel? _selectedPlace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mekanlarım'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PlaceModel>>(
              stream: FirestoreService().getUserPlacesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Hiç mekan eklenmemiş."));
                }

                final places = snapshot.data!;
                // Kategorilere göre gruplama
                final grouped = <String, List<PlaceModel>>{};
                for (var p in places) {
                  grouped.putIfAbsent(p.kategori, () => []).add(p);
                }

                // ListView yerine tek ListView + kategori blokları
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    final kategori = entry.key;
                    final kategoriPlaces = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori Başlığı
                        Text(
                          kategori,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),

                        // Bu kategori altındaki mekanlar
                        ...kategoriPlaces.map((place) {
                          final isSelected = _selectedPlace?.id == place.id;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 4,
                            color: isSelected
                                ? const Color.fromARGB(255, 255, 255, 255)
                                : null,
                            child: ListTile(
                              title: Text(place.isim),
                              subtitle: Text(place.kategori),
                              selected: isSelected,
                              selectedTileColor: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.2),
                              trailing: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => NoteDetailScreen(
                                        place: place,
                                        isFavorite: place.favori,
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.arrow_forward_ios_rounded),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedPlace = place;
                                });
                              },
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 16), // kategori arası boşluk
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _iconButton(Icons.add, "Ekle", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddPlaceScreen()),
                  );
                }),
                _iconButton(Icons.delete, "Sil", () async {
                  if (_selectedPlace == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Lütfen silinecek mekanı seçin.")),
                    );
                    return;
                  }

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Mekanı Sil"),
                      content: Text(
                          "‘${_selectedPlace!.isim}’ adlı mekanı silmek istediğinize emin misiniz?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text("İptal"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text("Sil",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  try {
                    await FirestoreService().deletePlace(_selectedPlace!.id);
                    setState(() => _selectedPlace = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mekan silindi.")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Silme hatası: $e")),
                    );
                  }
                }),
                  _iconButton(Icons.favorite,
                    "Favorile",
                    () async {
                      if (_selectedPlace == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Lütfen favori yapılacak mekanı seçin.")),
                        );
                        return;
                      }
                      final yeniDurum = !_selectedPlace!.favori;
                      try {
                        await FirestoreService().toggleFavorite(_selectedPlace!.id, yeniDurum);
                        setState(() {
                          _selectedPlace = _selectedPlace!.copyWith(favori: yeniDurum);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(yeniDurum ? "Favoriye eklendi." : "Favoriden çıkarıldı.")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Favori güncelleme hatası: $e")),
                        );
                      }
                    }
                  ),

                _iconButton(Icons.refresh, "Güncelle", () async {
                  if (_selectedPlace == null) return;

                  Navigator.pushNamed(
                    context,
                    '/addOrUpdatePlace',
                    arguments: {
                      'place': _selectedPlace,
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _iconButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon)),
        Text(label),
      ],
    );
  }
}
