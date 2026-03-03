import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/child_profiles/presentation/child_profile_controller.dart';
import 'features/child_profiles/presentation/create_child_profile_screen.dart';

Future<void> main() async {
  await initializeDateFormatting('tr_TR');
  await initializeSupabase();
  runApp(const ProviderScope(child: KiduApp()));
}

class KiduApp extends StatelessWidget {
  const KiduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authChanges = ref.watch(authStateProvider);

    return authChanges.when(
      loading: () =>
          const _LoadingScaffold(message: 'Oturum kontrol ediliyor...'),
      error: (error, _) => _ErrorScaffold(message: 'Oturum hatası: $error'),
      data: (_) {
        final session = ref.watch(currentSessionProvider);
        if (session == null) {
          return const AuthScreen();
        }

        final hasProfile = ref.watch(hasChildProfileProvider);
        return hasProfile.when(
          loading: () =>
              const _LoadingScaffold(message: 'Profil kontrol ediliyor...'),
          error: (error, _) =>
              _ErrorScaffold(message: 'Profil okunamadı: $error'),
          data: (exists) {
            if (!exists) {
              return const CreateChildProfileScreen();
            }
            return const DashboardPlaceholder();
          },
        );
      },
    );
  }
}

class DashboardPlaceholder extends ConsumerWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kidu'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Çocuk profili hazır. Sıradaki adımda hastalık ve semptom takibi ekranlarını ekleyeceğiz.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
