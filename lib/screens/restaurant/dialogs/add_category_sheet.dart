import 'package:flutter/material.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../widgets/restaurant_ui_helpers.dart';
import '../../../core/widgets/sheets/app_bottom_sheets.dart';

import 'package:splash_screen/core/widgets/custom_loader.dart';

void showAddCategorySheet({
  required BuildContext context,
  required String restaurantId,
  required Color brandColor,
  required VoidCallback onAdded,
}) {
  final controllerAr = TextEditingController();
  final controllerEn = TextEditingController();
  bool isLoading = false;

  AppBottomSheets.showCustomBottomSheet(
    context: context,
    title: 'Add New Category',
    child: StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildInput(
              controller: controllerAr,
              hint: 'Category Name (Arabic)',
              icon: Icons.category,
            ),
            const SizedBox(height: 10),
            buildInput(
              controller: controllerEn,
              hint: 'Category Name (English)',
              icon: Icons.category,
            ),
            const SizedBox(height: 20),
            isLoading
                ? CustomLoader()
                : buildPrimaryButton(
                    text: 'Create Category',
                    color: brandColor,
                    onPressed: () async {
                      if (controllerAr.text.trim().isEmpty ||
                          controllerEn.text.trim().isEmpty)
                        return;
                      setState(() => isLoading = true);

                      try {
                        await SupabaseRepository().addCategory(
                          restaurantId,
                          controllerAr.text.trim(),
                          controllerEn.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          onAdded();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                        setState(() => isLoading = false);
                      }
                    },
                  ),
          ],
        );
      },
    ),
  );
}
