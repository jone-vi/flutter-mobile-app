import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirestoreService();

  Future<void> addData(String collection, Map<String, dynamic> data) async {
    await _db.collection(collection).add(data);
  }

  Future<void> addUser(String? id, Map<String, dynamic> data) async {
    await _db.collection("users").doc(id).set(data);
  }

  Future<void> updateData(
      String collection, String id, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(id).update(data);
  }

  Future<void> deleteData(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  Future<DocumentSnapshot> getData(String collection, String id) async {
    return await _db.collection(collection).doc(id).get();
  }

  Future<void> updateLastEmailSent() async {
    if (_auth.currentUser == null) {
      return;
    }
    await _db
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .update({'lastEmailSent': FieldValue.serverTimestamp()});
  }

  // Get full name of user
  Future<String> getFullName() async {
    String id = _auth.currentUser!.uid;
    DocumentSnapshot doc = await getData('users', id);
    String fullName = await doc.get('fullName');
    return fullName;
  }

  Future<void> addHouseToFire(int houseId, String houseName) async {
    String userId = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .set({
      'name': houseName,
    });
  }

  Future<void> addRoomToFire(int roomId, String roomName, int houseId) async {
    String userId = _auth.currentUser!.uid;

    await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .collection('rooms')
        .doc(roomId.toString())
        .set({
      'name': roomName,
    });
  }

  Future<void> addLocationToFire(
      int locationId, String locationName, int roomId, int houseId) async {
    String userId = _auth.currentUser!.uid;

    await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .collection('rooms')
        .doc(roomId.toString())
        .collection('locations')
        .doc(locationId.toString())
        .set({
      'name': locationName,
    });
  }

  Future<void> addItemToFire(int itemId, String itemName, int locationId,
      int roomId, int houseId) async {
    String userId = _auth.currentUser!.uid;

    await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .collection('rooms')
        .doc(roomId.toString())
        .collection('locations')
        .doc(locationId.toString())
        .collection('items')
        .doc(itemId.toString())
        .set({
      'name': itemName,
    });
  }

  Future<void> deleteHouseFromFire(int houseId) async {
    String userId = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .delete();
  }

  Future<void> deleteRoomFromFire(int roomId, int houseId) async {
    String userId = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .collection('rooms')
        .doc(roomId.toString())
        .delete();
  }

  Future<void> deleteLocationFromFire(int locationId, int roomId, int houseId) async {
    String userId = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .collection('rooms')
        .doc(roomId.toString())
        .collection('locations')
        .doc(locationId.toString())
        .delete();
  }

  Future<void> deleteItemFromFire(int itemId, int locationId, int roomId, int houseId) async {
    String userId = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .collection('rooms')
        .doc(roomId.toString())
        .collection('locations')
        .doc(locationId.toString())
        .collection('items')
        .doc(itemId.toString())
        .delete();
  }

  Future<List<Map<String, dynamic>>> getHouses() async {
    String userId = _auth.currentUser!.uid;
    QuerySnapshot query =
        await _db.collection('users').doc(userId).collection('houses').get();
    List<Map<String, dynamic>> houses = [];
    for (var doc in query.docs) {
      houses.add({
        'id': doc.id,
        'name': doc.get('name'),
      });
    }
    return houses;
  }

  Future<List<Map<String, dynamic>>> getRooms(int houseId) async {
    String userId = _auth.currentUser!.uid;
    QuerySnapshot query = await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .collection('rooms')
        .get();
    List<Map<String, dynamic>> rooms = [];
    for (var doc in query.docs) {
      rooms.add({
        'id': doc.id,
        'name': doc.get('name'),
      });
    }
    return rooms;
  }

  Future<List<Map<String, dynamic>>> getLocations(
      int roomId, int houseId) async {
    String userId = _auth.currentUser!.uid;
    QuerySnapshot query = await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .collection('rooms')
        .doc(roomId.toString())
        .collection('locations')
        .get();
    List<Map<String, dynamic>> locations = [];
    for (var doc in query.docs) {
      locations.add({
        'id': doc.id,
        'name': doc.get('name'),
      });
    }
    return locations;
  }

  Future<List<Map<String, dynamic>>> getItems(
      int locationId, int roomId, int houseId) async {
    String userId = _auth.currentUser!.uid;
    QuerySnapshot query = await _db
        .collection('users')
        .doc(userId)
        .collection('houses')
        .doc(houseId.toString())
        .collection('rooms')
        .doc(roomId.toString())
        .collection('locations')
        .doc(locationId.toString())
        .collection('items')
        .get();
    List<Map<String, dynamic>> items = [];
    for (var doc in query.docs) {
      items.add({
        'id': doc.id,
        'name': doc.get('name'),
      });
    }
    return items;
  }
}
