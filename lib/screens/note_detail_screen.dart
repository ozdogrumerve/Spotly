import 'package:flutter/material.dart';
import 'package:spotly/models/place_model.dart';

class NoteDetailScreen extends StatelessWidget {
  final PlaceModel place;
  final bool isFavorite; 

  const NoteDetailScreen({
    super.key,
    required this.place,
    this.isFavorite = false, 
  });

  // Derecelendirme yıldızlarını oluşturan yardımcı metot
  Widget _buildRatingStars(double rating) {
    if (rating < 0) rating = 0.0;
    if (rating > 5.0) rating = 5.0;

    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;
    final int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      children: [
        // Tam Yıldızlar
        ...List.generate(fullStars, (index) => 
          const Icon(Icons.star, color: Colors.amber, size: 24)
        ),
        // Yarım Yıldız
        if (hasHalfStar) 
          const Icon(Icons.star_half, color: Colors.amber, size: 24),
        // Boş Yıldızlar
        ...List.generate(emptyStars, (index) => 
          const Icon(Icons.star_border, color: Colors.amber, size: 24)
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rating'i güvenli bir şekilde al ve double'a dönüştür
    final dynamic rawRating = place.puan;
    double rating = 0.0;
    if (rawRating is num) {
      rating = rawRating.toDouble();
    } else if (rawRating is String) {
      rating = double.tryParse(rawRating) ?? 0.0;
    }
    
    final String mekanAdi = place.isim;
    final String kategori = place.kategori;
    // Dinamik not içeriği
    final String mekanNotu = place.note;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detay'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TEK BÜYÜK DETAY KARTI
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst Kısım: Başlık ve Harita Görseli
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mekan Adı, Favori ve Kategori
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mekan Adı ve Kalp
                              Row(
                                children: [
                                  Text(
                                    mekanAdi,
                                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 21,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),

                                  const SizedBox(width: 8),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Kategori
                              Text(
                                kategori,
                                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                              // favori simgesi
                              if (isFavorite)
                                    const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                            ],
                          ),
                        ),
                        
                        // Sağ Üst Harita Görseli
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200, 
                            child: place.lat != null && place.lng != null
                                ? const Center(
                                    child: Icon(Icons.location_on, size: 40, color: Colors.blue),
                                  )
                                : const Center(
                                    child: Text('Harita Yok', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32), // Ayırıcı çizgi
                    
                    // Yıldız Derecelendirmesi
                    _buildRatingStars(rating),
                    const SizedBox(height: 16),
                    
                    // Not Başlığı
                    Text(
                      "Mekan Notu:",
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Dinamik Not İçeriği
                    Text(
                      mekanNotu,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}