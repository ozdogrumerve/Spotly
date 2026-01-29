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
  
  Future<List<PlaceModel>> getUserPlacesOnce() async {
    final snapshot = await getUserPlacesStream().first;
    return snapshot;
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

  Future<PlaceModel?> getLastVisitedPlace() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return null;

    final data = userDoc.data();
    if (data == null || !data.containsKey('lastVisitedPlaceId')) {
      return null;
    }

    final placeId = data['lastVisitedPlaceId'];
    final visitedAtRaw = data['lastVisitedAt'];

    DateTime? visitedAt;
    if (visitedAtRaw != null && visitedAtRaw is Timestamp) {
      visitedAt = visitedAtRaw.toDate();
    }

    final placeDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('places')
        .doc(placeId)
        .get();

    if (!placeDoc.exists) return null;

    final place = PlaceModel.fromMap(placeDoc.id, placeDoc.data()!);

    // visitedAt bilgisini copyWith ile inject edelim
    return place.copyWith(
      visitedAt: visitedAt,
    );
  }

  Future<void> setLastVisitedPlace(String placeId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'lastVisitedPlaceId': placeId,
      'lastVisitedAt': Timestamp.now(),
    });
  }
}

