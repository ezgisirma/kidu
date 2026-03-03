import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';

Future<void> initializeSupabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: AppConstants.envFileName);

  final url = dotenv.env[AppConstants.supabaseUrlKey];
  final anonKey = dotenv.env[AppConstants.supabaseAnonKey];

  if (url == null || url.isEmpty) {
    throw StateError('SUPABASE_URL .env dosyasında tanımlı değil.');
  }

  if (anonKey == null || anonKey.isEmpty) {
    throw StateError('SUPABASE_ANON_KEY .env dosyasında tanımlı değil.');
  }

  await Supabase.initialize(url: url, anonKey: anonKey);
}

SupabaseClient get supabaseClient => Supabase.instance.client;

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return supabaseClient;
});
