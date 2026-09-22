import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splash_screen/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/localization_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/curved_dashboard_scaffold.dart';
import '../../data/repositories/supabase_repository.dart';
import '../customer/widgets/restaurant_list_view.dart';
import 'dialogs/add_category_sheet.dart';
import 'dialogs/add_item_sheet.dart';
import 'dialogs/confirm_delete_sheet.dart';
import 'widgets/restaurant_profile_tab.dart';
import 'widgets/add_category_tab.dart';

import 'package:splash_screen/core/widgets/custom_loader.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  bool _isLoading = true;
  String? _restaurantId;
  Map<String, dynamic>? _profileData;
  String? _logoUrl;
  List<Color> _brandColors = [Colors.black, Colors.grey];

  List<Map<String, dynamic>> _categories = [];

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
      _profileData = profile;
      _restaurantId = profile['id'];
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
                const Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: Colors.white24,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your menu is empty.',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColors[0],
                  ),
                  onPressed: () => showAddCategorySheet(
                    context: context,
                    restaurantId: _restaurantId!,
                    brandColor: _brandColors[0],
                    onAdded: _fetchCategories,
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    AppLocalizations.of(context)!.addCategory,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(
              top: 120,
              bottom: 120,
              right: 10,
              left: 10,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final List items = category['menu_items'] ?? [];

              return Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.getLocalized(category, 'name'),
                            style: TextStyle(
                              color: _brandColors[0],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  padding: const EdgeInsets.all(8),
                                ),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () => showAddItemSheet(
                                  context: context,
                                  categoryId: category['id'],
                                  brandColor: _brandColors[0],
                                  onAdded: _fetchCategories,
                                ),
                                tooltip: AppLocalizations.of(context)!.add,
                              ),
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  padding: const EdgeInsets.all(8),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () {
                                  showConfirmDeleteSheet(
                                    context: context,
                                    title: AppLocalizations.of(
                                      context,
                                    )!.deleteCategory,
                                    subtitle: AppLocalizations.of(
                                      context,
                                    )!.deleteCategoryConfirm,
                                    onConfirm: () async {
                                      await SupabaseRepository().deleteCategory(
                                        category['id'],
                                      );
                                      _fetchCategories();
                                    },
                                  );
                                },
                                tooltip: AppLocalizations.of(context)!.delete,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          AppLocalizations.of(context)!.noItemsInCategory,
                          style: const TextStyle(color: Colors.white38),
                        ),
                      )
                    else
                      ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            title: Text(
                              context.getLocalized(item, 'name'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              context.getLocalized(item, 'description'),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${item['price']}',
                                  style: TextStyle(
                                    color: _brandColors[0],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white10,
                                    padding: const EdgeInsets.all(6),
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    showConfirmDeleteSheet(
                                      context: context,
                                      title: AppLocalizations.of(
                                        context,
                                      )!.deleteItem,
                                      subtitle: AppLocalizations.of(
                                        context,
                                      )!.deleteItemConfirm,
                                      onConfirm: () async {
                                        await SupabaseRepository()
                                            .deleteMenuItem(item['id']);
                                        _fetchCategories();
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RestaurantListScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> localizedTabs = [
      l10n.menu,
      l10n.add,
      l10n.orders,
      l10n.profile,
    ];

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CustomLoader()),
      );
    }

    final menuWidget = _buildMenuWidget();
    final Color primaryColor = _brandColors[0];

    return CurvedDashboardScaffold(
      tabs: localizedTabs,
      brandColors: _brandColors,
      tabBackgroundColorsOverrides: const {
        3: Color(0xFFF5F5F5), // Static background for Profile
      },
      appBarTitle: _profileData != null ? context.getLocalized(_profileData!, 'name') : l10n.menu,
      drawerBackgroundColor: Colors.white,
      drawerContent: SafeArea(
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CustomLoader())
              : Column(
                  children: [
                    Expanded(
                      child: _categories.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noItemsInCategory,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final List items = cat['menu_items'] ?? [];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 25.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.getLocalized(cat, 'name'),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...items.map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 15.0,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  context.getLocalized(
                                                    item,
                                                    'name',
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '\$${item['price']}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.black87),
                      title: Text(
                        l10n.logout,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _logout();
                      },
                    ),
                  ],
                ),
        ),
      ),
      pageBuilder: (context, index, titleColor) {
        if (_restaurantId == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Restaurant data not found.',
                  style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Logout', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        if (index == 0) {
          return menuWidget;
        } else if (index == 1) {
          return AddCategoryTab(
            restaurantId: _restaurantId!,
            primaryColor: primaryColor,
            titleColor: titleColor,
            onAdded: _fetchCategories,
          );
        } else if (index == 3) {
          return RestaurantProfileTab(titleColor: titleColor);
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localizedTabs[index],
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
