import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Picks an image and uploads it to the `avatars` Storage bucket, returning
/// its public URL. Shared by profile pictures and group logos — see
/// docs/database-schema.md for the bucket's path convention and RLS.
class AvatarUploadService {
  final SupabaseClient _client;
  const AvatarUploadService(this._client);

  Future<String?> pickAndUploadProfilePicture(String userId) {
    return _pickAndUpload(storagePath: 'profile/$userId.jpg');
  }

  Future<String?> pickAndUploadGroupLogo(String groupId) {
    return _pickAndUpload(storagePath: 'group/$groupId.jpg');
  }

  Future<String?> _pickAndUpload({required String storagePath}) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final bytes = await File(picked.path).readAsBytes();
    await _client.storage.from('avatars').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    // Cache-bust: the path is stable (upsert overwrites it), so without a
    // query param every viewer's <Image> would keep showing the previously
    // cached bytes at the same URL after a re-upload.
    final publicUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}
