import 'package:flutter/material.dart';
import 'package:spotly/models/place_model.dart';
import 'package:spotly/screens/note_detail_screen.dart';
import 'package:spotly/services/firestore_service.dart';

class FavPlacesScreen extends StatelessWidget {
  const FavPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favori Mekanlar')),
      body: StreamBuilder<List<PlaceModel>>(
        stream: FirestoreService().getUserFavoritePlacesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Favori mekan yok.'));
          }

          final favoritePlaces = snapshot.data!;

          // 1. Kategorilere göre grupla
          final grouped = <String, List<PlaceModel>>{};
          for (var place in favoritePlaces) {
            grouped.putIfAbsent(place.kategori, () => []).add(place);
          }

          // 2. Görüntüle
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Favori Mekanların',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Favoriye eklediğin mekanlar burada listelenir',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // 🔹 KATEGORİLER
              ...grouped.entries.map((entry) {
                final kategori = entry.key;
                final places = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kategori,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...places.map((place) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.favorite, color: Colors.red),
                          title: Text(place.isim),
                          subtitle: Text(place.kategori),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NoteDetailScreen(
                                  place: place,
                                  isFavorite: true,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20), // Kategori arası boşluk
                  ],
                );
              })
            ]
          );
        },
      ),
    );
  }
}
