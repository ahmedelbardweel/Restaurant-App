import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _isObscured : false,
      keyboardType: widget.keyboardType,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      validator: widget.validator,
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: Colors.grey.shade100,
        hintStyle: const TextStyle(
          color: Colors.black38,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          widget.prefixIcon,
          color: Colors.black45,
          size: 20,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black45,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        isDense: true,
      ),
    );
  }
}
