import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../router/app_router.dart';
import 'auth_form.dart';
import 'auth_repository.dart';
import 'legal_footer.dart';

/// 02 · Sign up
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> with AuthActionRunner {
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
      () => ref.read(authRepositoryProvider).signUpWithEmail(_email.text, _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VivPage(
      showBack: true,
      topCenter: const VivWordmark(),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VivButton(
            label: 'Create account',
            loading: busy == AuthMethod.email,
            onPressed: busy == null ? _submit : null,
          ),
          const SizedBox(height: VivSpace.sm),
          const LegalFooter(prefix: 'By creating an account you agree to the'),
          const SizedBox(height: VivSpace.xs),
          SwitchLink(
            text: 'Already have an account?',
            action: 'Log in',
            onTap: () => context.pushReplacement(Routes.logIn),
          ),
        ],
      ),
      children: [
        const PageHeader(
          title: 'Create your account',
          subtitle: 'Takes about a minute. We\'ll shape your first week right after.',
        ),
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
                  obscurable: true,
                  helper: 'At least 8 characters',
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                  validator: (v) => (v ?? '').length < 8 ? 'Use at least 8 characters' : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
