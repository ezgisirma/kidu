import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child_profiles/presentation/create_child_profile_screen.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _isSignIn = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authControllerProvider.notifier);
    if (_isSignIn) {
      await notifier.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      await notifier.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (!mounted) return;

    final state = ref.read(authControllerProvider);
    state.whenOrNull(
      error: (error, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İşlem başarısız: $error')));
      },
      data: (_) {
        final hasSession = ref.read(currentSessionProvider) != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSignIn
                  ? 'Giriş başarılı.'
                  : 'Kayıt başarılı. E-posta doğrulaması gerekebilir.',
            ),
          ),
        );

        if (!_isSignIn && hasSession) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const CreateChildProfileScreen(),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSignIn
                              ? 'Kidu\'ya Hoş Geldin'
                              : 'Yeni Hesap Oluştur',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Çocuk sağlığı takibini güvenle başlat.'),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-posta',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'E-posta zorunludur.';
                            }
                            if (!value.contains('@')) {
                              return 'Geçerli bir e-posta gir.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Şifre'),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Şifre en az 6 karakter olmalı.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          child: Text(
                            isLoading
                                ? 'Lütfen bekleyin...'
                                : _isSignIn
                                ? 'Giriş Yap'
                                : 'Kayıt Ol',
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => setState(() => _isSignIn = !_isSignIn),
                          child: Text(
                            _isSignIn
                                ? 'Hesabın yok mu? Kayıt Ol'
                                : 'Zaten hesabın var mı? Giriş Yap',
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
