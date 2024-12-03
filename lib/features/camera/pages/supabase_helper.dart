import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHelper {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads an image to the 'images' bucket in Supabase storage.
  ///
  /// [filePath]: The local file path of the image to be uploaded.
  /// [fileName]: The name to save the file as in Supabase storage.
  Future<void> uploadImage(String filePath, String fileName) async {
    try {
      final file = File(filePath);

      // Log details for debugging
      print("Uploading to bucket: images");
      print("File path: $filePath");
      print("File name: $fileName");

      // Upload file to Supabase storage
      final String filePathInBucket = await _supabase.storage
          .from('images') // Your bucket name
          .upload(fileName, file);

      // Log success
      print("Image uploaded successfully: $filePathInBucket");
    } on StorageException catch (e) {
      // Handle Supabase-specific errors
      print("StorageException: ${e.message}");
      rethrow;
    } catch (e) {
      // Handle other types of exceptions
      print("Exception while uploading: $e");
      rethrow;
    }
  }
}
