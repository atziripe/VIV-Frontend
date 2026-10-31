import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import 'auth_repository.dart';

/// Which provider is currently signing in, so only that button spins.
enum AuthMethod { apple, google, email }

/// Shared "Continue with Apple / Google — or use email" block used by both
/// Sign up and Log in.
class SocialSignIn extends ConsumerWidget {
  const SocialSignIn({super.key, required this.busy, required this.run});

  final AuthMethod? busy;
  final Future<void> Function(AuthMethod method, Future<bool> Function() action) run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(authRepositoryProvider);
    final disabled = busy != null;
    // Sign in with Apple is native on iOS; on Android it needs a web
    // service ID, so it's only offered on iOS for now.
    final showApple = Platform.isIOS;
    return Column(
      children: [
        if (showApple) ...[
          PillButton(
            label: 'Continue with Apple',
            variant: PillVariant.outline,
            size: PillSize.control,
            icon: const Icon(Icons.apple),
            busy: busy == AuthMethod.apple,
            onPressed: disabled ? null : () => run(AuthMethod.apple, repo.signInWithApple),
          ),
          const SizedBox(height: 11),
        ],
        PillButton(
          label: 'Continue with Google',
          variant: PillVariant.outline,
          size: PillSize.control,
          busy: busy == AuthMethod.google,
          onPressed: disabled ? null : () => run(AuthMethod.google, repo.signInWithGoogle),
        ),
        const SizedBox(height: 15),
        const _OrDivider(),
        const SizedBox(height: 15),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VivSpace.sm),
          child: Text('or email', style: VivType.meta.copyWith(color: c.subtle)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Runs an auth action with shared busy/error handling and analytics.
mixin AuthActionRunner<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  AuthMethod? busy;

  /// `sign_up` or `log_in`, for analytics.
  String get authScreen;

  /// [action] returns whether it created a new account.
  Future<void> runAuth(AuthMethod method, Future<bool> Function() action) async {
    final analytics = ref.read(analyticsProvider);
    setState(() => busy = method);
    analytics.authStarted(method: method.name, screen: authScreen);
    try {
      final isNewUser = await action();
      isNewUser
          ? analytics.signUpCompleted(method: method.name)
          : analytics.logInCompleted(method: method.name);
      // Success: the router redirects on the auth state change.
    } on SignInCancelled {
      // User closed the native sheet — nothing to report.
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }
}

String? validateEmail(String? v) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
    return 'That email doesn\'t look right';
  }
  return null;
}

/// "Already have an account? Log in" footer link.
class SwitchLink extends StatelessWidget {
  const SwitchLink({super.key, required this.text, required this.action, required this.onTap});

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VivRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: VivSpace.sm),
        child: Text.rich(
          TextSpan(
            style: VivType.body.copyWith(color: c.muted),
            children: [
              TextSpan(text: '$text '),
              TextSpan(
                text: action,
                style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
