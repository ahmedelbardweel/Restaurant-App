import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splash_screen/l10n/app_localizations.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../widgets/restaurant_ui_helpers.dart';
import '../../../core/widgets/sheets/app_bottom_sheets.dart';
import 'package:splash_screen/core/widgets/custom_loader.dart';

void showAddItemSheet({
  required BuildContext context,
  required String categoryId,
  required Color brandColor,
  required VoidCallback onAdded,
}) {
  final nameArController = TextEditingController();
  final nameEnController = TextEditingController();
  final descArController = TextEditingController();
  final descEnController = TextEditingController();
  final priceController = TextEditingController();
  List<XFile> selectedImages = [];
  bool isUploading = false;

  AppBottomSheets.showCustomBottomSheet(
    context: context,
    title: AppLocalizations.of(context)!.addMenuItem,
    child: StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildInput(
              controller: nameArController,
              hint: AppLocalizations.of(context)!.itemNameAr,
              icon: Icons.fastfood,
            ),
            const SizedBox(height: 10),
            buildInput(
              controller: nameEnController,
              hint: AppLocalizations.of(context)!.itemNameEn,
              icon: Icons.fastfood,
            ),
            const SizedBox(height: 15),
            buildInput(
              controller: descArController,
              hint: AppLocalizations.of(context)!.descAr,
              icon: Icons.description,
            ),
            const SizedBox(height: 10),
            buildInput(
              controller: descEnController,
              hint: AppLocalizations.of(context)!.descEn,
              icon: Icons.description,
            ),
            const SizedBox(height: 15),
            buildInput(
              controller: priceController,
              hint: AppLocalizations.of(context)!.price,
              icon: Icons.attach_money,
              isNumber: true,
            ),
            const SizedBox(height: 15),

            InkWell(
              onTap: () async {
                final ImagePicker picker = ImagePicker();
                final List<XFile> images = await picker.pickMultiImage();
                if (images.isNotEmpty) {
                  setModalState(() {
                    selectedImages.addAll(images);
                  });
                }
              },
              borderRadius: BorderRadius.circular(5),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.white54,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.addImages,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selectedImages.isNotEmpty)
              Container(
                height: 80,
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(
                                File(selectedImages[index].path),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),
            isUploading
                ? Center(child: CustomLoader())
                : buildPrimaryButton(
                    text: AppLocalizations.of(context)!.addMenuItem,
                    color: brandColor,
                    onPressed: () async {
                      if (nameArController.text.trim().isEmpty ||
                          nameEnController.text.trim().isEmpty ||
                          priceController.text.trim().isEmpty) {
                        return;
                      }
                      final price = double.tryParse(
                        priceController.text.trim(),
                      );
                      if (price == null) return;

                      setModalState(() => isUploading = true);

                      try {
                        // Upload images if any
                        List<String> imageUrls = [];
                        if (selectedImages.isNotEmpty) {
                          imageUrls = await SupabaseRepository()
                              .uploadMenuItemImages(selectedImages);
                        }

                        await SupabaseRepository().addMenuItem(
                          categoryId,
                          nameArController.text.trim(),
                          nameEnController.text.trim(),
                          descArController.text.trim(),
                          descEnController.text.trim(),
                          price,
                          imageUrls,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.itemAddedSuccessfully,
                              ),
                            ),
                          );
                          Navigator.pop(context);
                          onAdded();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                      setModalState(() => isUploading = false);
                    },
                  ),
          ],
        );
      },
    ),
  );
}
