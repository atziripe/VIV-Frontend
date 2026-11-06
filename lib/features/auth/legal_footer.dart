import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/legal_links.dart';

/// "By continuing you agree to VIV's Terms and Privacy Policy."
class LegalFooter extends StatefulWidget {
  const LegalFooter({super.key, required this.prefix});

  final String prefix;

  @override
  State<LegalFooter> createState() => _LegalFooterState();
}

class _LegalFooterState extends State<LegalFooter> {
  late final _terms = TapGestureRecognizer()..onTap = () => openLegalPage(context, LegalPage.terms);
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => openLegalPage(context, LegalPage.privacy);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final base = VivType.legal.copyWith(color: c.subtle);
    final link = base.copyWith(
      color: c.muted,
      decoration: TextDecoration.underline,
      decorationColor: c.muted,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: '${widget.prefix} '),
          TextSpan(text: 'Terms', style: link, recognizer: _terms),
          const TextSpan(text: ' and '),
          TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacy),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
