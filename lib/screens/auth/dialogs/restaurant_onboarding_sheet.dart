import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:splash_screen/data/repositories/supabase_repository.dart';
import 'package:splash_screen/screens/restaurant/restaurant_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:splash_screen/core/widgets/custom_text_field.dart';

import 'package:splash_screen/core/widgets/custom_loader.dart';
class OnboardingSheet extends StatefulWidget {
  const OnboardingSheet({super.key});

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // State variables
  File? _logoImage;
  List<Color> _extractedColors = [];
  final List<Color> _selectedColors = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoImage = File(pickedFile.path);
        _isLoading = true;
      });
      await _extractColors();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _extractColors() async {
    if (_logoImage == null) return;
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(FileImage(_logoImage!));

    final colors = <Color>{};
    if (paletteGenerator.dominantColor != null) {
      colors.add(paletteGenerator.dominantColor!.color);
    }
    if (paletteGenerator.vibrantColor != null) {
      colors.add(paletteGenerator.vibrantColor!.color);
    }
    if (paletteGenerator.mutedColor != null) {
      colors.add(paletteGenerator.mutedColor!.color);
    }
    if (paletteGenerator.darkVibrantColor != null) {
      colors.add(paletteGenerator.darkVibrantColor!.color);
    }
    if (paletteGenerator.lightVibrantColor != null) {
      colors.add(paletteGenerator.lightVibrantColor!.color);
    }

    // Fallback if not enough colors extracted
    if (colors.length < 4) {
      colors.addAll(paletteGenerator.colors.take(4 - colors.length));
    }

    setState(() {
      _extractedColors = colors.toList();
      _selectedColors.clear();
    });
  }

  void _toggleColorSelection(Color color) {
    setState(() {
      if (_selectedColors.contains(color)) {
        _selectedColors.remove(color);
      } else {
        if (_selectedColors.length < 4) {
          _selectedColors.add(color);
        }
      }
    });
  }

  Future<void> _completeOnboarding() async {
    if (_selectedColors.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select exactly 4 colors.')),
      );
      return;
    }
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter restaurant name.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final intColors = _selectedColors.map((c) => c.toARGB32()).toList();

      await SupabaseRepository().completeOnboarding(
        userId,
        intColors,
        _nameController.text,
        _descController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close bottom sheet
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RestaurantDashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage == 0 && _logoImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a logo first.')),
      );
      return;
    }
    if (_currentPage == 1 && _selectedColors.length < 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select 4 colors.')));
      return;
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Setup Restaurant',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  // Step 1: Logo Upload
                  _buildStepLogo(),
                  // Step 2: Color Palette
                  _buildStepColors(),
                  // Step 3: Restaurant Info
                  _buildStepInfo(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomLoader(size: 8),
                      )
                    : Text(
                        _currentPage == 2 ? 'Complete Setup' : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepLogo() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Upload your restaurant logo to generate your custom theme.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(100),
                image: _logoImage != null
                    ? DecorationImage(
                        image: FileImage(_logoImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _logoImage == null
                  ? const Icon(
                      Icons.camera_alt,
                      size: 50,
                      color: Colors.black26,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepColors() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Select exactly 4 colors for your app theme.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _extractedColors.map((color) {
              final isSelected = _selectedColors.contains(color);
              return GestureDetector(
                onTap: () => _toggleColorSelection(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepInfo() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomTextField(
            controller: _nameController,
            hintText: 'Restaurant Name',
            ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _descController,
            hintText: 'Description',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
