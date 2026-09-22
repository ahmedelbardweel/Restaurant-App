import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../core/widgets/curved_dashboard_scaffold.dart';
import '../customer/widgets/restaurant_list_view.dart';
import 'dialogs/add_category_sheet.dart';
import 'dialogs/add_item_sheet.dart';
import 'dialogs/confirm_delete_sheet.dart';
import 'widgets/restaurant_profile_tab.dart';

import 'package:splash_screen/core/widgets/custom_loader.dart';
class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  bool _isLoading = true;
  String? _restaurantId;
  String _restaurantName = '';
  String? _logoUrl;
  List<Color> _brandColors = [Colors.black, Colors.grey];

  List<Map<String, dynamic>> _categories = [];
  final List<String> _tabs = ['Menu', 'Orders', 'Profile'];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await SupabaseRepository().getRestaurantProfile(user.id);
    if (profile != null) {
      _restaurantId = profile['id'];
      _restaurantName = profile['name'] ?? 'My Restaurant';
      _logoUrl = profile['logo_url'];

      List<dynamic> rawColors = profile['colors'] ?? [];
      List<Color> parsedColors = rawColors
          .map((c) => Color(int.tryParse(c.toString()) ?? 0xFF000000))
          .toList();
      if (parsedColors.isNotEmpty) {
        _brandColors = parsedColors;
      }

      await _fetchCategories();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCategories() async {
    if (_restaurantId == null) return;
    final cats = await SupabaseRepository().getRawCategories(_restaurantId!);
    if (mounted) {
      setState(() {
        _categories = cats;
      });
    }
  }

  Widget _buildMenuWidget() {
    return _categories.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu, size: 80, color: Colors.white24),
                  const SizedBox(height: 20),
                  const Text('Your menu is empty.', style: TextStyle(color: Colors.white54, fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _brandColors[0]),
                    onPressed: () => showAddCategorySheet(context: context, restaurantId: _restaurantId!, brandColor: _brandColors[0], onAdded: _fetchCategories),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Category', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 160, bottom: 160), 
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final List items = category['menu_items'] ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category['name'],
                              style: TextStyle(color: _brandColors[0], fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white70),
                                  onPressed: () => showAddItemSheet(context: context, categoryId: category['id'], brandColor: _brandColors[0], onAdded: _fetchCategories),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    showConfirmDeleteSheet(
                                      context: context,
                                      title: 'Delete Category',
                                      subtitle: 'Are you sure you want to delete "${category['name']}"? This will delete all items inside it.',
                                      onConfirm: () async {
                                        setState(() => _isLoading = true);
                                        await SupabaseRepository().deleteCategory(category['id']);
                                        await _fetchCategories();
                                        setState(() => _isLoading = false);
                                      }
                                    );
                                  },
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      // Category Items
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No items yet. Add one!', style: TextStyle(color: Colors.white38)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, idx) {
                            final item = items[idx];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              title: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              subtitle: Text(item['description'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('\$${item['price']}', style: TextStyle(color: _brandColors[0], fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
                                    onPressed: () {
                                      showConfirmDeleteSheet(
                                        context: context,
                                        title: 'Delete Item',
                                        subtitle: 'Are you sure you want to delete "${item['name']}"?',
                                        onConfirm: () async {
                                          setState(() => _isLoading = true);
                                          await SupabaseRepository().deleteMenuItem(item['id']);
                                          await _fetchCategories();
                                          setState(() => _isLoading = false);
                                        }
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                    ],
                  ),
                );
              },
            );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CustomLoader()),
      );
    }

    final menuWidget = _buildMenuWidget();
    final Color primaryColor = _brandColors[0];

    return CurvedDashboardScaffold(
      tabs: _tabs,
      brandColors: _brandColors,
      tabBackgroundColorsOverrides: const {
        2: Color(0xFFF5F5F5), // Static background for Profile
      },
      appBarTitle: 'Menu',
      drawerBackgroundColor: Colors.white,
      drawerContent: SafeArea(
        child: Container(
          width: 240, 
          padding: const EdgeInsets.only(left: 20.0, top: 40.0, right: 10.0),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_logoUrl != null && _logoUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _logoUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.restaurant, color: primaryColor, size: 30),
                        ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          _restaurantName,
                          style: GoogleFonts.originalSurfer(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  const Divider(color: Colors.black12, thickness: 1),
                  const SizedBox(height: 10),
                  Text(
                    'Menu Categories',
                    style: GoogleFonts.originalSurfer(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    const Center(child: CustomLoader())
                  else if (_categories.isEmpty)
                    const Text("No categories available.", style: TextStyle(color: Colors.black54, fontSize: 16))
                  else
                    ..._categories.map((cat) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        cat['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    )),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.black12, thickness: 1),
                  
                  GestureDetector(
                    onTap: () {
                      showAddCategorySheet(context: context, restaurantId: _restaurantId!, brandColor: _brandColors[0], onAdded: _fetchCategories);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, color: Colors.black87, size: 28),
                          SizedBox(width: 20),
                          Text('Add Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  
                  GestureDetector(
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const RestaurantListScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.black87, size: 28),
                          SizedBox(width: 20),
                          Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      pageBuilder: (context, index, titleColor) {
        if (index == 0) {
          return menuWidget;
        } else if (_tabs[index] == 'Profile') {
          return RestaurantProfileTab(titleColor: titleColor);
        } else {
          return Center(
            child: Text(
              '${_tabs[index]} (Coming Soon)',
              style: GoogleFonts.originalSurfer(fontSize: 24, fontWeight: FontWeight.bold, color: titleColor),
            ),
          );
        }
      },
    );
  }
}
