import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload image file and return URL
  Future<String?> uploadImage(File imageFile, String path) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      // Create reference
      final storageRef = _storage.ref().child('$path/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Handle upload based on platform
      UploadTask uploadTask;
      if (kIsWeb) {
        // For web platform
        uploadTask = storageRef.putData(
          await imageFile.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // For mobile platforms
        uploadTask = storageRef.putFile(imageFile);
      }

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Delete image by URL
  Future<bool> deleteImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}

final storageService = StorageService(); 