import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../router/app_router.dart';
import 'auth_form.dart';
import 'auth_repository.dart';

/// 03 · Log in
class LogInScreen extends ConsumerStatefulWidget {
  const LogInScreen({super.key});

  @override
  ConsumerState<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends ConsumerState<LogInScreen> with AuthActionRunner {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    runAuth(
      AuthMethod.email,
      () => ref.read(authRepositoryProvider).signInWithEmail(_email.text, _password.text),
    );
  }

  Future<void> _forgot() async {
    final error = validateEmail(_email.text);
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter your email above, then tap Forgot again.')),
      );
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      messenger.showSnackBar(SnackBar(content: Text('Reset link sent to ${_email.text.trim()}.')));
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return VivPage(
      showBack: true,
      topCenter: const VivWordmark(),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VivButton(
            label: 'Log in',
            loading: busy == AuthMethod.email,
            onPressed: busy == null ? _submit : null,
          ),
          const SizedBox(height: VivSpace.xs),
          SwitchLink(
            text: 'New to VIV?',
            action: 'Create an account',
            onTap: () => context.pushReplacement(Routes.signUp),
          ),
        ],
      ),
      children: [
        const PageHeader(title: 'Welcome back', subtitle: 'Your week is where you left it.'),
        SocialSignIn(busy: busy, run: runAuth),
        AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              children: [
                VivTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: validateEmail,
                ),
                const SizedBox(height: VivSpace.md),
                VivTextField(
                  label: 'Password',
                  controller: _password,
                  hint: 'Password',
                  obscurable: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
                  labelTrailing: GestureDetector(
                    onTap: _forgot,
                    child: Text(
                      'Forgot?',
                      style: VivType.caption.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
