import 'package:flutter/material.dart';


Widget buildInput({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  bool isNumber = false,
  Color? titleColor,
}) {
  Color textColor = titleColor ?? Colors.white;
  Color bgColor = titleColor == Colors.black ? Colors.white54 : Colors.black54;

  return TextField(
    controller: controller,
    style: TextStyle(color: textColor, fontSize: 16),
    keyboardType: isNumber
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
      filled: true,
      fillColor: bgColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: textColor.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: textColor),
      ),
    ),
  );
}

Widget buildPrimaryButton({
  required String text,
  required VoidCallback onPressed,
  Color? color,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
