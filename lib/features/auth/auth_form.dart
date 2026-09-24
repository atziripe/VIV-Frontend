import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final Future<void> Function(AuthMethod method, Future<void> Function() action) run;

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
          VivButton(
            label: 'Continue with Apple',
            variant: VivButtonVariant.inverse,
            icon: const Icon(Icons.apple, size: 20),
            loading: busy == AuthMethod.apple,
            onPressed: disabled ? null : () => run(AuthMethod.apple, repo.signInWithApple),
          ),
          const SizedBox(height: VivSpace.xs),
        ],
        VivButton(
          label: 'Continue with Google',
          variant: showApple ? VivButtonVariant.secondary : VivButtonVariant.inverse,
          loading: busy == AuthMethod.google,
          onPressed: disabled ? null : () => run(AuthMethod.google, repo.signInWithGoogle),
        ),
        const SizedBox(height: VivSpace.lg),
        const _OrDivider(),
        const SizedBox(height: VivSpace.md),
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
          child: Text('or use email', style: VivType.caption.copyWith(color: c.textTertiary)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Runs an auth action with shared busy/error handling.
mixin AuthActionRunner<T extends StatefulWidget> on State<T> {
  AuthMethod? busy;

  Future<void> runAuth(AuthMethod method, Future<void> Function() action) async {
    setState(() => busy = method);
    try {
      await action();
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
        padding: const EdgeInsets.symmetric(vertical: VivSpace.xs, horizontal: VivSpace.sm),
        child: Text.rich(
          TextSpan(
            style: VivType.caption.copyWith(color: c.textSecondary, fontSize: 13),
            children: [
              TextSpan(text: '$text '),
              TextSpan(
                text: action,
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
