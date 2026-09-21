import 'package:flutter/material.dart';
import '../widgets/restaurant_ui_helpers.dart';

void showConfirmDeleteSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required VoidCallback onConfirm,
}) {
  showCustomBottomSheet(
    context: context,
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: buildPrimaryButton(
                text: 'Delete',
                color: Colors.redAccent,
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
