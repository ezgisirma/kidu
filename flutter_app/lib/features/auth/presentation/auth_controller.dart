import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(supabaseClientProvider));
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return ref.read(supabaseClientProvider).auth.currentSession;
});

enum AuthActionResult {
  signedIn,
  signedUpAndSignedIn,
  signedUpNeedsEmailVerification,
}

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .signIn(email: email.trim(), password: password);
      debugPrint(
        '[AUTH][SIGNIN] userId=${response.user?.id} session=${response.session != null}',
      );

      if (response.session == null) {
        throw const AuthException('Giriş oturumu oluşturulamadı.');
      }

      state = const AsyncData(null);
      return AuthActionResult.signedIn;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .signUp(email: email.trim(), password: password);
      debugPrint(
        '[AUTH][SIGNUP] userId=${response.user?.id} session=${response.session != null}',
      );

      state = const AsyncData(null);
      if (response.session != null) {
        return AuthActionResult.signedUpAndSignedIn;
      }
      return AuthActionResult.signedUpNeedsEmailVerification;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}
