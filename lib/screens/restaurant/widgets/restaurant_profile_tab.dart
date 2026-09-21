import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splash_screen/screens/splash_loader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../data/repositories/supabase_repository.dart';

class RestaurantProfileTab extends StatefulWidget {
  final Color titleColor;
  const RestaurantProfileTab({super.key, required this.titleColor});

  @override
  State<RestaurantProfileTab> createState() => _RestaurantProfileTabState();
}

class _RestaurantProfileTabState extends State<RestaurantProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _color1Controller = TextEditingController();
  final TextEditingController _color2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await SupabaseRepository().getRestaurantProfile(user.id);
    if (profile != null) {
      _nameController.text = profile['name'] ?? '';
      _descriptionController.text = profile['description'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _addressController.text = profile['address'] ?? '';

      List<dynamic> rawColors = profile['colors'] ?? [];
      if (rawColors.isNotEmpty) {
        _color1Controller.text = Color(
          int.tryParse(rawColors[0].toString()) ?? 0xFF000000,
        ).value.toRadixString(16).toUpperCase();
        if (rawColors.length > 1) {
          _color2Controller.text = Color(
            int.tryParse(rawColors[1].toString()) ?? 0xFF000000,
          ).value.toRadixString(16).toUpperCase();
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final String name = _nameController.text.trim();
    final String desc = _descriptionController.text.trim();
    final String phone = _phoneController.text.trim();
    final String address = _addressController.text.trim();

    // Parse colors
    final String c1 = _color1Controller.text.trim().replaceAll('#', '');
    final String c2 = _color2Controller.text.trim().replaceAll('#', '');

    final int color1 = int.tryParse(c1, radix: 16) ?? 0xFF000000;
    final int color2 = int.tryParse(c2, radix: 16) ?? 0xFF555555;

    final List<int> colors = [color1, color2];

    final data = {
      'name': name,
      'description': desc,
      'phone': phone,
      'address': address,
      'colors': colors,
    };

    try {
      await SupabaseRepository().updateRestaurantInfo(user.id, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _color1Controller.dispose();
    _color2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: widget.titleColor));
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 120), // Padding from app bar
            Center(
              child: Text(
                'Restaurant Profile',
                style: GoogleFonts.originalSurfer(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: widget.titleColor,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Restaurant Name',
                    prefixIcon: Icons.restaurant,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _descriptionController,
                    hintText: 'Description',
                    prefixIcon: Icons.description,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _addressController,
                    hintText: 'Address',
                    prefixIcon: Icons.location_on,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _color1Controller,
                          hintText: 'Primary Color',
                          prefixIcon: Icons.color_lens,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: _color2Controller,
                          hintText: 'Secondary Color',
                          prefixIcon: Icons.format_paint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: _isSaving ? 'Saving...' : 'Save Changes',
                    onPressed: _isSaving ? null : _saveProfileData,
                    isLoading: _isSaving,
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const SplashLoaderScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
