import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place_model.dart';

class FirestoreService {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _firestore = FirebaseFirestore.instance;

  Stream<List<PlaceModel>> getUserPlacesStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('places')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PlaceModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<PlaceModel>> getUserFavoritePlacesStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('places')
        .where('favori', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PlaceModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> addPlace(PlaceModel place) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('places')
        .add(place.toMap());
  }

  Future<void> deletePlace(String placeId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('places')
        .doc(placeId)
        .delete();
  }

  Future<void> updatePlace(PlaceModel place) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('places')
        .doc(place.id)
        .update(place.toMap());
  }

  Future<void> toggleFavorite(String placeId, bool isFav) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('places')
        .doc(placeId)
        .update({'favori': isFav});
  }
}
