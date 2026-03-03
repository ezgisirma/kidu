import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client.dart';
import '../data/child_profile_repository.dart';

final childProfileRepositoryProvider = Provider<ChildProfileRepository>((ref) {
  return ChildProfileRepository(ref.read(supabaseClientProvider));
});

final hasChildProfileProvider = FutureProvider<bool>((ref) {
  return ref.read(childProfileRepositoryProvider).hasAnyProfile();
});

final childProfileControllerProvider =
    AsyncNotifierProvider<ChildProfileController, void>(
      ChildProfileController.new,
    );

class ChildProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createProfile({
    required String firstName,
    required String? lastName,
    required DateTime birthDate,
    required String? bloodType,
    required String? gender,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(childProfileRepositoryProvider)
          .createProfile(
            firstName: firstName,
            lastName: lastName,
            birthDate: birthDate,
            bloodType: bloodType,
            gender: gender,
          ),
    );

    if (!state.hasError) {
      ref.invalidate(hasChildProfileProvider);
    }
  }
}
