import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/viv_theme.dart';

/// "By continuing you agree to VIV's Terms and Privacy Policy."
class LegalFooter extends StatefulWidget {
  const LegalFooter({super.key, required this.prefix});

  final String prefix;

  @override
  State<LegalFooter> createState() => _LegalFooterState();
}

class _LegalFooterState extends State<LegalFooter> {
  // TODO(product): point these at the real Terms / Privacy URLs.
  late final _terms = TapGestureRecognizer()..onTap = () {};
  late final _privacy = TapGestureRecognizer()..onTap = () {};

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final base = VivType.caption.copyWith(color: c.textTertiary);
    final link = base.copyWith(
      color: c.textSecondary,
      decoration: TextDecoration.underline,
      decorationColor: c.textSecondary,
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
      textAlign: TextAlign.center,
    );
  }
}
