import 'package:flutter/material.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../widgets/restaurant_ui_helpers.dart';

import 'package:splash_screen/core/widgets/custom_loader.dart';
void showAddCategorySheet({
  required BuildContext context,
  required String restaurantId,
  required Color brandColor,
  required VoidCallback onAdded,
}) {
  final controller = TextEditingController();
  bool isLoading = false;

  showCustomBottomSheet(
    context: context,
    title: 'Add New Category',
    child: StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildInput(
            controller: controller,
            hint: 'Category Name',
            icon: Icons.category,
          ),
          const SizedBox(height: 20),
          isLoading
              ? CustomLoader()
              : buildPrimaryButton(
                  text: 'Create Category',
                  color: brandColor,
                  onPressed: () async {
                    if (controller.text.trim().isEmpty) return;
                    setState(() => isLoading = true);
                    
                    try {
                      await SupabaseRepository().addCategory(
                        restaurantId,
                        controller.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        onAdded();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                      setState(() => isLoading = false);
                    }
                  },
                ),
        ],
      );
    }),
  );
}
