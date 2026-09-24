import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';
import 'viv_page.dart';

/// Labelled text field. Pass [obscurable] for passwords to get the
/// "Show / Hide" trailing toggle from the sign-up design.
class VivTextField extends StatefulWidget {
  const VivTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.labelTrailing,
    this.obscurable = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final Widget? labelTrailing;
  final bool obscurable;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  @override
  State<VivTextField> createState() => _VivTextFieldState();
}

class _VivTextFieldState extends State<VivTextField> {
  late bool _obscured = widget.obscurable;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(widget.label, trailing: widget.labelTrailing),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          textCapitalization: widget.textCapitalization,
          autocorrect: !widget.obscurable,
          enableSuggestions: !widget.obscurable,
          style: VivType.body.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            helperStyle: VivType.caption.copyWith(color: c.textTertiary),
            suffixIcon: widget.obscurable
                ? TextButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    child: Text(
                      _obscured ? 'Show' : 'Hide',
                      style: VivType.caption.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
