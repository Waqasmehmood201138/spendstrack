import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_providers.dart';
import 'avatar_upload_service.dart';

final avatarUploadServiceProvider = Provider<AvatarUploadService>((ref) {
  return AvatarUploadService(ref.watch(supabaseClientProvider));
});
