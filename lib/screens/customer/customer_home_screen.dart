import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splash_screen/core/widgets/custom_loader.dart';

import '../../data/repositories/supabase_repository.dart';
import '../../core/widgets/curved_dashboard_scaffold.dart';
import 'widgets/profile_tab_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_dashboard_screen.dart';
import '../restaurant/restaurant_dashboard_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final Map<String, dynamic> restaurantData;

  const CustomerHomeScreen({super.key, this.restaurantData = const {}});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final List<String> _tabs = ['Home', 'Search', 'Cart', 'Profile'];

  Map<String, List<Map<String, String>>> _menuData = {};
  bool _isMenuLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStrictRouting();
    _loadMenu();
  }

  void _checkStrictRouting() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      if (session != null && mounted) {
        final role = await SupabaseRepository().getUserRole(session.user.id);
        if (role == 'admin') {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              (route) => false,
            );
          }
        } else if (role == 'restaurant') {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const RestaurantDashboardScreen(),
              ),
              (route) => false,
            );
          }
        }
      }
    });
  }

  Future<void> _loadMenu() async {
    final data = await SupabaseRepository().getRestaurantMenu(
      widget.restaurantData['id'],
    );
    if (mounted) {
      setState(() {
        _menuData = data;
        _isMenuLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String restaurantName = widget.restaurantData['text'] ?? 'Restaurant';
    final List<Color> brandColors = widget.restaurantData['colors'] ?? [Colors.blue, Colors.blueAccent];
    final Color primaryColor = brandColors[0];

    return CurvedDashboardScaffold(
      tabs: _tabs,
      brandColors: brandColors,
      tabBackgroundColorsOverrides: const {
        3: Color(0xFFF5F5F5), // Static background for Profile
      },
      appBarTitle: restaurantName,
      drawerBackgroundColor: Colors.white,
      drawerContent: SafeArea(
        child: Container(
          width: 240,
          padding: const EdgeInsets.only(left: 20.0, top: 40.0, right: 10.0),
          child: _isMenuLoading
              ? Center(child: CustomLoader())
              : _menuData.isEmpty
                  ? Center(
                      child: Text(
                        "No menu available.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _menuData.keys.length,
                      itemBuilder: (context, index) {
                        String category = _menuData.keys.elementAt(index);
                        List<Map<String, String>> items = _menuData[category]!;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 25.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...items.map((item) {
                                List<String> images = [];
                                if (item['image_url'] != null && item['image_url']!.isNotEmpty) {
                                  try {
                                    images = List<String>.from(jsonDecode(item['image_url']!));
                                  } catch (e) {
                                    debugPrint('Error parsing images: $e');
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 15.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (images.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(right: 12.0),
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            image: DecorationImage(
                                              image: NetworkImage(images.first),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          item['name']!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '\$${item['price']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
      pageBuilder: (context, index, titleColor) {
        if (_tabs[index] == 'Profile') {
          return ProfileTabView(titleColor: titleColor, buttonColor: primaryColor);
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _tabs[index],
                  style: GoogleFonts.originalSurfer(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
