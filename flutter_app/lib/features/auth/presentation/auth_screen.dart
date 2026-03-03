import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  var _obscurePassword = true;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authControllerProvider.notifier);
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final result = _isSignIn
          ? await notifier.signIn(
              email: _emailController.text,
              password: _passwordController.text,
            )
          : await notifier.signUp(
              email: _emailController.text,
              password: _passwordController.text,
            );

      if (!mounted) return;

      switch (result) {
        case AuthActionResult.signedIn:
          setState(() {
            _infoMessage =
                'Giriş başarılı. Çocuk profili ekranına yönlendiriliyorsun.';
          });
          _goToCreateProfile();
        case AuthActionResult.signedUpAndSignedIn:
          setState(() {
            _infoMessage =
                'Kayıt başarılı. Hesabın açıldı, çocuk profili oluşturma adımına geçiliyor.';
          });
          _goToCreateProfile();
        case AuthActionResult.signedUpNeedsEmailVerification:
          setState(() {
            _infoMessage =
                'Kayıt başarılı. E-postana gelen doğrulama bağlantısını onayladıktan sonra giriş yapabilirsin.';
          });
      }
    } catch (error) {
      setState(() {
        _errorMessage = _translateAuthError(error);
      });
    }
  }

  void _goToCreateProfile() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const CreateChildProfileScreen()),
    );
  }

  String _translateAuthError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('invalid login credentials')) {
        return 'E-posta veya şifre hatalı. Bilgilerini kontrol edip tekrar dene.';
      }
      if (message.contains('email not confirmed')) {
        return 'E-posta adresin doğrulanmamış. Gelen kutunu kontrol et.';
      }
      if (message.contains('user already registered')) {
        return 'Bu e-posta adresi zaten kayıtlı. Giriş yapmayı dene.';
      }
      if (message.contains('password should be at least')) {
        return 'Şifre en az 6 karakter olmalı.';
      }
      if (message.contains('invalid email')) {
        return 'Geçerli bir e-posta adresi gir.';
      }
      if (message.contains('rate limit') || message.contains('too many')) {
        return 'Kısa sürede çok fazla deneme yapıldı. Birkaç dakika sonra tekrar dene.';
      }

      return 'İşlem başarısız: ${error.message}';
    }

    final raw = error.toString().toLowerCase();
    if (raw.contains('socket') || raw.contains('network')) {
      return 'İnternet bağlantısı sorunu görünüyor. Bağlantını kontrol edip tekrar dene.';
    }

    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar dene.';
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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        const Text(
                          'Çocuk sağlığı takibini güvenle başlat. Hata durumlarında net yönlendirme göreceksin.',
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _MessageBox(
                            message: _errorMessage!,
                            backgroundColor: const Color(0xFFFFEBEE),
                            textColor: const Color(0xFFB71C1C),
                            icon: Icons.error_outline,
                          ),
                        ],
                        if (_infoMessage != null) ...[
                          const SizedBox(height: 14),
                          _MessageBox(
                            message: _infoMessage!,
                            backgroundColor: const Color(0xFFE8F5E9),
                            textColor: const Color(0xFF1B5E20),
                            icon: Icons.info_outline,
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-posta',
                            hintText: 'ornek@domain.com',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'E-posta zorunludur.';
                            }
                            final emailPattern = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );
                            if (!emailPattern.hasMatch(value.trim())) {
                              return 'Geçerli bir e-posta gir.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
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
                              : () => setState(() {
                                  _isSignIn = !_isSignIn;
                                  _errorMessage = null;
                                  _infoMessage = null;
                                }),
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

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
