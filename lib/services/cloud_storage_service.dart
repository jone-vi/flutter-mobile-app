import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database.dart';
import 'dart:io';

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Database db;

  CloudStorageService({required this.db});

  Future<void> uploadItemImage(Item item) async {
    if (_auth.currentUser == null) {
      return;
    }

    if (item.imagePath == null) {
      return;
    }

    File image = File(item.imagePath!);
    int locationId = item.locationId;
    Location location = await db.getLocationById(locationId);
    int roomId = location.roomId;
    Room room = await db.getRoomById(roomId);
    int houseId = room.houseId;

    String path =
        '${_auth.currentUser!.uid}/$houseId/$roomId/$locationId/${item.id}';

    try {
      await _storage.ref(path).putFile(image);
    } catch (e) {
      throw Exception("Failed to upload the picture: $e");
    }
  }

  Future<String> downloadImage(String path) async {
    return await _storage.ref(path).getDownloadURL();
  }

  Future<void> deleteImage(String path) async {
    await _storage.ref(path).delete();
  }
}
