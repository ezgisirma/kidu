import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  Future<void> initCheck() async {
    try {
      await _client
          .from('illness_templates')
          .select('id')
          .eq('is_system', true)
          .limit(1);
      debugPrint('[SupabaseService] initCheck: Supabase bağlantısı başarılı.');
    } catch (error) {
      debugPrint(
        '[SupabaseService] initCheck HATA: Supabase bağlantısı kurulamadı. '
        'URL/Key/.env ve ağ izinlerini kontrol et. Detay: $error',
      );
      rethrow;
    }
  }
}
