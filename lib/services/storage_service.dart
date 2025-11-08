import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Pick an image from the gallery
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Pick an image from the camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Upload an image to Firebase Storage and return the download URL
  Future<String> uploadImage(String tripId, File image) async {
    try {
      // Generate a unique filename
      String fileName = _uuid.v4();
      
      // Create the storage path
      String path = 'journal_images/$tripId/$fileName.jpg';
      
      // Create a reference to the file location
      final ref = _storage.ref(path);
      
      // Set metadata for the image
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Upload the file
      final uploadTask = ref.putFile(image, metadata);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload a profile image to Firebase Storage and return the download URL
  Future<String> uploadProfileImage(String uid, File image) async {
    try {
      // Fixed path for profile image - overwrites existing
      String path = 'profile_images/$uid/profile.jpg';
      
      // Create a reference to the file location
      final ref = _storage.ref(path);
      
      // Set metadata for the image
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Upload the file
      final uploadTask = ref.putFile(image, metadata);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      // File might not exist or user might not have permission
      print('Error deleting image: $e');
      // Don't throw exception as this is not critical
    }
  }

  /// Get the file size of an image in the storage
  Future<int?> getImageSize(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        final metadata = await ref.getMetadata();
        return metadata.size;
      }
      return null;
    } catch (e) {
      print('Error getting image size: $e');
      return null;
    }
  }

  /// Get metadata of an image in the storage
  Future<FullMetadata?> getImageMetadata(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        return await ref.getMetadata();
      }
      return null;
    } catch (e) {
      print('Error getting image metadata: $e');
      return null;
    }
  }

  /// Show a dialog to choose between camera and gallery
  static Future<ImageSource?> showImageSourceDialog() async {
    // This would typically be implemented in the UI layer
    // For now, we'll default to gallery
    return ImageSource.gallery;
  }
}