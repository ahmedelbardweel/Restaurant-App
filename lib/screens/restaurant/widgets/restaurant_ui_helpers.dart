import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showCustomBottomSheet({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.originalSurfer(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              child,
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildInput({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  bool isNumber = false,
}) {
  return TextField(
    controller: controller,
    style: const TextStyle(color: Colors.white, fontSize: 16),
    keyboardType: isNumber
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: Colors.black54,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.white),
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
