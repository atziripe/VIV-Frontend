import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';
import '../../router/session.dart';
import '../auth/auth_repository.dart';

/// Shown while the session resolves, and as the retry screen if `/me` fails.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    final c = context.viv;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: session == AppSession.error
              ? Padding(
                  padding: const EdgeInsets.all(VivSpace.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VivWordmark(),
                      const SizedBox(height: VivSpace.xl),
                      ErrorView(
                        error: ref.read(meProvider).error ?? 'unknown',
                        onRetry: () => ref.invalidate(meProvider),
                      ),
                      VivButton.text(
                        label: 'Sign out',
                        onPressed: () => ref.read(authRepositoryProvider).signOut(),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VivWordmark(),
                    const SizedBox(height: VivSpace.lg),
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: c.textTertiary),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
