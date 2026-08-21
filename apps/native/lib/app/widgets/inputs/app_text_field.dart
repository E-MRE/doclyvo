import 'package:flutter/material.dart';

final class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
    this.keyboardType,
    super.key,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
