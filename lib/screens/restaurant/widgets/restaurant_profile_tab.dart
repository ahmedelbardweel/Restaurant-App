import 'package:flutter/material.dart';
import 'package:splash_screen/screens/splash_loader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../data/repositories/supabase_repository.dart';
import '../../../../core/utils/validators.dart';

import 'package:splash_screen/core/widgets/custom_loader.dart';
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
  bool _isGettingLocation = false;
  
  LatLng? _currentLocation;
  final MapController _mapController = MapController();

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

      if (profile['latitude'] != null && profile['longitude'] != null) {
        _currentLocation = LatLng(
          (profile['latitude'] as num).toDouble(),
          (profile['longitude'] as num).toDouble(),
        );
      } else if (_addressController.text.isNotEmpty) {
        try {
          List<Location> locations = await Geocoding().locationFromAddress(_addressController.text);
          if (locations.isNotEmpty) {
            _currentLocation = LatLng(locations[0].latitude, locations[0].longitude);
          }
        } catch (e) {
          debugPrint('Could not geocode address: $e');
        }
      }

      List<dynamic> rawColors = profile['colors'] ?? [];
      if (rawColors.isNotEmpty) {
        _color1Controller.text = Color(
          int.tryParse(rawColors[0].toString()) ?? 0xFF000000,
        ).toARGB32().toRadixString(16).toUpperCase();
        if (rawColors.length > 1) {
          _color2Controller.text = Color(
            int.tryParse(rawColors[1].toString()) ?? 0xFF000000,
          ).toARGB32().toRadixString(16).toUpperCase();
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
          
      final latLng = LatLng(position.latitude, position.longitude);
          
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude, position.longitude);
          
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.locality}, ${place.country}';
        setState(() {
          _addressController.text = address;
          _currentLocation = latLng;
        });
        _mapController.move(latLng, 15.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
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

    if (_currentLocation != null) {
      data['latitude'] = _currentLocation!.latitude;
      data['longitude'] = _currentLocation!.longitude;
    }

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

  Widget _buildColorPickerField(String label, TextEditingController controller) {
    Color currentColor = Colors.white;
    if (controller.text.isNotEmpty && controller.text.length == 8) {
      try {
        currentColor = Color(int.parse('0x${controller.text}'));
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            Color tempColor = currentColor;
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select $label Color', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ColorPicker(
                    pickerColor: currentColor,
                    onColorChanged: (color) {
                      tempColor = color;
                    },
                    enableAlpha: false,
                    displayThumbColor: true,
                    showLabel: true,
                    paletteType: PaletteType.hsv,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            controller.text = tempColor.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0');
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(25), // match text field style
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.text.isNotEmpty ? controller.text : label,
                style: TextStyle(
                  color: controller.text.isNotEmpty ? Colors.black87 : Colors.grey,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CustomLoader());
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              top: 120,
              left: 10,
              right: 10,
              bottom: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: double.infinity),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Restaurant Name',
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _descriptionController,
                    hintText: 'Description',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _addressController,
                    hintText: 'Address',
                    maxLines: 2,
                    suffixIcon: _isGettingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CustomLoader(size: 8),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location, size: 20, color: Colors.blueAccent),
                            onPressed: _getCurrentLocation,
                          ),
                  ),
                  if (_currentLocation != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: RepaintBoundary(
                          child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentLocation!,
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.splash_screen',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildColorPickerField('Primary', _color1Controller),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildColorPickerField('Secondary', _color2Controller),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            bottom: 110,
            left: 10,
            right: 10,
          ),
          child: Column(
            children: [
              CustomButton(
                text: _isSaving ? 'Saving...' : 'Save Changes',
                onPressed: _isSaving ? null : _saveProfileData,
                isLoading: _isSaving,
              ),
              const SizedBox(height: 5),
              CustomButton(
                text: 'Sign Out',
                backgroundColor: const Color.fromARGB(255, 59, 1, 1),
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
