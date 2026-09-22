import 'package:flutter/material.dart';
import 'package:splash_screen/l10n/app_localizations.dart';
import '../../../data/repositories/supabase_repository.dart';
import 'restaurant_ui_helpers.dart';
import 'package:splash_screen/core/widgets/custom_loader.dart';

class AddCategoryTab extends StatefulWidget {
  final String restaurantId;
  final Color primaryColor;
  final Color titleColor;
  final VoidCallback onAdded;

  const AddCategoryTab({
    super.key,
    required this.restaurantId,
    required this.primaryColor,
    required this.titleColor,
    required this.onAdded,
  });

  @override
  State<AddCategoryTab> createState() => _AddCategoryTabState();
}

class _AddCategoryTabState extends State<AddCategoryTab> {
  final controllerAr = TextEditingController();
  final controllerEn = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    controllerAr.dispose();
    controllerEn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: 120,
          bottom: 120,
          right: 20,
          left: 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addCategory,
              style: TextStyle(
                color: widget.titleColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            buildInput(
              controller: controllerAr,
              hint: l10n.categoryNameAr,
              icon: Icons.category,
              titleColor: widget.titleColor,
            ),
            const SizedBox(height: 15),
            buildInput(
              controller: controllerEn,
              hint: l10n.categoryNameEn,
              icon: Icons.category,
              titleColor: widget.titleColor,
            ),
            const SizedBox(height: 30),
            Center(
              child: isLoading
                  ? const CustomLoader()
                  : buildPrimaryButton(
                      text: l10n.createCategory,
                      color: widget.primaryColor,
                      onPressed: () async {
                        if (controllerAr.text.trim().isEmpty ||
                            controllerEn.text.trim().isEmpty)
                          return;
                        setState(() => isLoading = true);

                        try {
                          await SupabaseRepository().addCategory(
                            widget.restaurantId,
                            controllerAr.text.trim(),
                            controllerEn.text.trim(),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.categoryAddedSuccessfully),
                              ),
                            );
                            controllerAr.clear();
                            controllerEn.clear();
                            widget.onAdded();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
