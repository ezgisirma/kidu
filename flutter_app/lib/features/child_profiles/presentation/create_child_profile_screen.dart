import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/home_screen.dart';
import 'child_profile_controller.dart';

class CreateChildProfileScreen extends ConsumerStatefulWidget {
  const CreateChildProfileScreen({super.key});

  @override
  ConsumerState<CreateChildProfileScreen> createState() =>
      _CreateChildProfileScreenState();
}

class _CreateChildProfileScreenState
    extends ConsumerState<CreateChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _birthDate;
  String? _bloodType;
  String? _gender;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDate: DateTime(now.year - 2),
      locale: const Locale('tr', 'TR'),
    );
    if (selected == null) return;
    setState(() => _birthDate = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Doğum tarihi zorunludur.')));
      return;
    }

    await ref
        .read(childProfileControllerProvider.notifier)
        .createProfile(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          birthDate: _birthDate!,
          bloodType: _bloodType,
          gender: _gender,
        );

    if (!mounted) return;

    final state = ref.read(childProfileControllerProvider);
    state.whenOrNull(
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil oluşturulamadı: $error')),
        );
      },
      data: (_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(childProfileControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çocuk Profili Oluştur'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış yap',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İlk adım: Çocuğun temel bilgilerini ekleyelim',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'Ad'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ad zorunludur.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Soyad (opsiyonel)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: isLoading ? null : _pickBirthDate,
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Doğum Tarihi',
                            ),
                            child: Text(
                              _birthDate == null
                                  ? 'Tarih seç'
                                  : DateFormat(
                                      'd MMMM y',
                                      'tr_TR',
                                    ).format(_birthDate!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: _bloodType,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Kan grubu seç (opsiyonel)'),
                            ),
                            ...AppConstants.bloodTypes.map(
                              (type) => DropdownMenuItem<String?>(
                                value: type,
                                child: Text(type),
                              ),
                            ),
                          ],
                          onChanged: isLoading
                              ? null
                              : (value) => setState(() => _bloodType = value),
                          decoration: const InputDecoration(
                            labelText: 'Kan Grubu',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: _gender,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Cinsiyet seç (opsiyonel)'),
                            ),
                            ...AppConstants.genders.map(
                              (item) => DropdownMenuItem<String?>(
                                value: item,
                                child: Text(item),
                              ),
                            ),
                          ],
                          onChanged: isLoading
                              ? null
                              : (value) => setState(() => _gender = value),
                          decoration: const InputDecoration(
                            labelText: 'Cinsiyet',
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          child: Text(
                            isLoading ? 'Kaydediliyor...' : 'Profili Kaydet',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
