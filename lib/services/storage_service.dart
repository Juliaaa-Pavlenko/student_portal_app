import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadUserAvatar(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('avatars').child('$userId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
