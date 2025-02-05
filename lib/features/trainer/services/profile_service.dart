import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage({bool fromCamera = false}) async {
    final XFile? image = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    return image?.path;
  }

  Future<String> uploadProfilePicture(String imagePath, String userId) async {
    try {
      final ref = _storage.ref().child('profile_pictures').child('$userId.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );

      await ref.putFile(File(imagePath), metadata);
      final downloadUrl = await ref.getDownloadURL();
      
      // Update profile picture URL in Firestore
      await _firestore.collection('trainers').doc(userId).update({
        'profilePictureUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload profile picture: $e';
    }
  }

  Future<void> updateProfile(String userId, {String? bio, String? name}) async {
    try {
      final data = <String, dynamic>{};
      if (bio != null) data['bio'] = bio;
      if (name != null) data['name'] = name;

      await _firestore.collection('trainers').doc(userId).update(data);
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }
} 