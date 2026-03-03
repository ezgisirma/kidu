import 'package:supabase_flutter/supabase_flutter.dart';

class ChildProfileRepository {
  ChildProfileRepository(this._client);

  final SupabaseClient _client;

  Future<void> createProfile({
    required String firstName,
    required String? lastName,
    required DateTime birthDate,
    required String? bloodType,
    required String? gender,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Oturum bulunamadı.');
    }

    final profilePayload = {
      'owner_user_id': user.id,
      'first_name': firstName.trim(),
      'last_name': _nullable(lastName),
      'birth_date': birthDate.toIso8601String().split('T').first,
      'blood_type': _nullable(bloodType),
      'gender': _nullable(gender),
    };

    final inserted = await _client
        .from('profiles')
        .insert(profilePayload)
        .select('id')
        .single();

    final profileId = inserted['id'] as String?;
    if (profileId == null) {
      throw StateError('Profil kaydı oluşturuldu ancak profil ID alınamadı.');
    }

    await _insertChildIfTableExists(
      profileId: profileId,
      ownerUserId: user.id,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      bloodType: bloodType,
      gender: gender,
    );
  }

  Future<bool> hasAnyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final result = await _client
        .from('profiles')
        .select('id')
        .eq('owner_user_id', user.id)
        .limit(1);

    return (result as List).isNotEmpty;
  }

  String? _nullable(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    return cleaned;
  }

  Future<void> _insertChildIfTableExists({
    required String profileId,
    required String ownerUserId,
    required String firstName,
    required String? lastName,
    required DateTime birthDate,
    required String? bloodType,
    required String? gender,
  }) async {
    try {
      await _client.from('children').insert({
        'profile_id': profileId,
        'owner_user_id': ownerUserId,
        'first_name': firstName.trim(),
        'last_name': _nullable(lastName),
        'birth_date': birthDate.toIso8601String().split('T').first,
        'blood_type': _nullable(bloodType),
        'gender': _nullable(gender),
      });
    } on PostgrestException catch (error) {
      final message = (error.message).toLowerCase();
      final isMissingTable =
          message.contains('relation "children" does not exist') ||
          message.contains('could not find the table') ||
          message.contains('children');

      if (!isMissingTable) rethrow;
    }
  }
}
