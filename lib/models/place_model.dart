import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceModel {
  final String id;
  final String isim;
  final String kategori;
  final int puan;
  final bool favori;
  final double? lat;
  final double? lng;
  final String note;
  final DateTime? visitedAt;


  PlaceModel({
    required this.id,
    required this.isim,
    required this.kategori,
    required this.puan,
    required this.favori,
    this.lat,
    this.lng,
    required this.note,
    this.visitedAt,
  });

  factory PlaceModel.fromMap(String id, Map<String, dynamic> data) {
    return PlaceModel(
      id: id,
      isim: data['isim'] ?? '',
      kategori: data['kategori'] ?? '',
      puan: (data['puan'] ?? 0).toInt(),
      favori: data['favori'] ?? false,
      lat: data['lat']?.toDouble(),
      lng: data['lng']?.toDouble(),
      note: data['note'] ?? '', 
      visitedAt: data['visitedAt'] != null
        ? (data['visitedAt'] as Timestamp).toDate()
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isim': isim,
      'kategori': kategori,
      'puan': puan,
      'favori': favori,
      'lat': lat,
      'lng': lng,
      'note': note,
      'visitedAt': visitedAt != null ? Timestamp.fromDate(visitedAt!) : null,
    };
  }

  PlaceModel copyWith({
    String? isim,
    String? kategori,
    int? puan,
    bool? favori,
    double? lat,
    double? lng,
    String? note, 
    DateTime? visitedAt,
  }) {
    return PlaceModel(
      id: id,
      isim: isim ?? this.isim,
      kategori: kategori ?? this.kategori,
      puan: puan ?? this.puan,
      favori: favori ?? this.favori,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      note: note ?? this.note,
      visitedAt: visitedAt ?? this.visitedAt,
    );
  }
}
