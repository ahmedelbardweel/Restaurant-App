import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../widgets/restaurant_ui_helpers.dart';

void showAddItemSheet({
  required BuildContext context,
  required String categoryId,
  required Color brandColor,
  required VoidCallback onAdded,
}) {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  List<XFile> selectedImages = [];
  bool isUploading = false;

  showCustomBottomSheet(
    context: context,
    title: 'Add Menu Item',
    child: StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildInput(
              controller: nameController,
              hint: 'Item Name',
              icon: Icons.fastfood,
            ),
            const SizedBox(height: 15),
            buildInput(
              controller: descController,
              hint: 'Description',
              icon: Icons.description,
            ),
            const SizedBox(height: 15),
            buildInput(
              controller: priceController,
              hint: 'Price (e.g. 10.99)',
              icon: Icons.attach_money,
              isNumber: true,
            ),
            const SizedBox(height: 15),

            // Image Picker Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Images',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.add_photo_alternate,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Add Images',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final List<XFile> images = await picker.pickMultiImage();
                    if (images.isNotEmpty) {
                      setModalState(() {
                        selectedImages.addAll(images);
                      });
                    }
                  },
                ),
              ],
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
                ? Center(
                    child: CircularProgressIndicator(color: brandColor),
                  )
                : buildPrimaryButton(
                    text: 'Add Item',
                    color: brandColor,
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty ||
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
                          nameController.text.trim(),
                          descController.text.trim(),
                          price,
                          imageUrls,
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
                        setModalState(() => isUploading = false);
                      }
                    },
                  ),
          ],
        );
      },
    ),
  );
}
