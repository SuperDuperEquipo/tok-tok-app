import 'package:flutter/material.dart';
import 'package:toktok/config/theme/app_colors.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon, color: AppColors.textMuted),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}
