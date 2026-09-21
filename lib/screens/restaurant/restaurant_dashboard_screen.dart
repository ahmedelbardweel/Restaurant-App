import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_repository.dart';
import '../customer/widgets/restaurant_list_view.dart';
import 'dialogs/add_category_sheet.dart';
import 'dialogs/add_item_sheet.dart';
import 'dialogs/confirm_delete_sheet.dart';
import 'widgets/restaurant_profile_tab.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _restaurantId;
  String _restaurantName = '';
  String? _logoUrl;
  List<Color> _brandColors = [Colors.black, Colors.grey];

  List<Map<String, dynamic>> _categories = [];

  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Drag? _drag;
  late final AnimationController _drawerController;
  final List<String> _tabs = ['Menu', 'Orders', 'Profile'];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        int newIndex = _pageController.page!.round();
        if (newIndex != _currentIndex) {
          _currentIndex = newIndex;
          // You can optionally add haptic feedback here if needed
        }
      }
    });
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _pageController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.only(left: 16, right: 16, top: 160, bottom: 160), // Space for AppBar and BottomBar
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final List items = category['menu_items'] ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Menu Items
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No items in this category.', style: TextStyle(color: Colors.white38)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, i) {
                            final item = items[i];
                            List<String> images = [];
                            if (item['image_url'] != null && item['image_url'].toString().isNotEmpty) {
                              try {
                                images = List<String>.from(jsonDecode(item['image_url']));
                              } catch (e) {
                                print('Error parsing images: $e');
                              }
                            }

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: images.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        images.first,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          width: 50, height: 50, color: Colors.white10,
                                          child: const Icon(Icons.broken_image, color: Colors.white38),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 50, height: 50,
                                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                                      child: const Icon(Icons.fastfood, color: Colors.white38),
                                    ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name'], 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('\$${item['price']}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              subtitle: item['description'] != null && item['description'].toString().isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        item['description'], 
                                        style: const TextStyle(color: Colors.white38),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : null,
                              trailing: IconButton(
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
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final menuWidget = _buildMenuWidget();

    final size = MediaQuery.of(context).size;
    final double itemWidth = size.width / 3.5;
    final Color primaryColor = _brandColors[0];
    final Color menuBgColor = Colors.white;

    return Scaffold(
      backgroundColor: menuBgColor,
      body: Stack(
        children: [
          // 1. The Drawer Menu (Bottom Layer)
          SafeArea(
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
                                color: primaryColor.withOpacity(0.2),
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
                        const Center(child: CircularProgressIndicator(color: Colors.black87))
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
                          _drawerController.reverse();
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

          // 2. The Main Application Layer (Top Layer)
          AnimatedBuilder(
            animation: _drawerController,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  // 1. The Main Content (PageView)
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      // Dynamically calculate background color and app bar color based on brandColors
                      Color bgColor = _brandColors[index % _brandColors.length];
                      Color appBarColor = _brandColors[(index + 1) % _brandColors.length];

                      bool isLightBg = bgColor.computeLuminance() > 0.5;
                      Color titleColor = isLightBg ? Colors.black : Colors.white;

                      bool isLightAppBar = appBarColor.computeLuminance() > 0.5;
                      Color appBarTextColor = isLightAppBar ? Colors.black : Colors.white;

                      Widget pageContent;
                      if (index == 0) {
                        pageContent = menuWidget;
                      } else if (_tabs[index] == 'Profile') {
                        pageContent = RestaurantProfileTab(titleColor: titleColor);
                      } else {
                        pageContent = Center(
                          child: Text(
                            '${_tabs[index]} (Coming Soon)',
                            style: GoogleFonts.originalSurfer(fontSize: 24, fontWeight: FontWeight.bold, color: titleColor),
                          ),
                        );
                      }

                      return Container(
                        color: bgColor,
                        child: Stack(
                          children: [
                            // Main Page Content
                            pageContent,

                            // Semi-circle App Bar
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: size.width,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: appBarColor,
                                  borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(size.width, 80)),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
                                ),
                                child: SafeArea(
                                  bottom: false,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                    child: Stack(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: () {
                                              if (_drawerController.isDismissed) {
                                                _drawerController.forward();
                                              } else {
                                                _drawerController.reverse();
                                              }
                                            },
                                            child: Text(
                                              'Menu',
                                              style: GoogleFonts.originalSurfer(fontSize: 16, fontWeight: FontWeight.w500, color: appBarTextColor.withOpacity(0.7), letterSpacing: 1.0),
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            _restaurantName,
                                            style: GoogleFonts.pacifico(fontSize: 34, fontWeight: FontWeight.normal, color: appBarTextColor, letterSpacing: 0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // 2. The Custom Interactive Bottom Bar
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (DragStartDetails details) {
                        if (_pageController.hasClients) {
                          _drag = _pageController.position.drag(details, () { _drag = null; });
                        }
                      },
                      onHorizontalDragUpdate: (DragUpdateDetails details) { _drag?.update(details); },
                      onHorizontalDragEnd: (DragEndDetails details) { _drag?.end(details); },
                      onHorizontalDragCancel: () { _drag?.cancel(); },
                      child: SizedBox(
                        height: 140,
                        width: size.width,
                        child: AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double progress = 0.0;
                            if (_pageController.hasClients) {
                              progress = _pageController.page ?? 0.0;
                            }

                            int lowerIndex = progress.floor().clamp(0, _tabs.length - 1);
                            int upperIndex = progress.ceil().clamp(0, _tabs.length - 1);
                            double t = progress - lowerIndex;
                            Color currentBgColor = Color.lerp(
                              _brandColors[lowerIndex % _brandColors.length], 
                              _brandColors[upperIndex % _brandColors.length], 
                              t
                            ) ?? _brandColors[lowerIndex % _brandColors.length];

                            bool isLight = currentBgColor.computeLuminance() > 0.5;
                            Color activeColor = isLight ? Colors.black : Colors.white;
                            Color inactiveColor = isLight ? Colors.black54 : Colors.white54;

                            final double centerX = size.width / 2;
                            final double Rx = size.width * 0.8; 
                            const double Ry = 45.0; 

                            return RepaintBoundary(
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.elliptical(size.width, 80)),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.vertical(top: Radius.elliptical(size.width, 80)),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // The stationary dot in the center of the bar
                                        Positioned(
                                          bottom: 55,
                                          child: Container(
                                            width: 8, height: 8,
                                            decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                                          ),
                                        ),

                                  // The scrolling tabs
                                  for (int i = 0; i < _tabs.length; i++)
                                    Builder(
                                      builder: (context) {
                                        double dx = (i - progress) * itemWidth;
                                        double distance = dx.abs();
                                        double dy = 0;
                                        if (distance < Rx) {
                                          dy = Ry * math.sqrt(1 - (distance * distance) / (Rx * Rx));
                                        }

                                        double distanceRatio = (distance / itemWidth).clamp(0.0, 1.0);
                                        double curveRatio = Curves.easeOut.transform(1.0 - distanceRatio);
                                        double currentFontSize = 16.0 + (12.0 * curveRatio);
                                        Color currentColor = Color.lerp(inactiveColor, activeColor, curveRatio)!;

                                        double wordLeft = centerX + dx - (itemWidth / 2);
                                        double wordBottom = 25.0 + dy;

                                        return Positioned(
                                          left: 0, bottom: 0,
                                          child: Transform.translate(
                                            offset: Offset(wordLeft, -wordBottom),
                                            child: SizedBox(
                                              width: itemWidth,
                                              child: GestureDetector(
                                                onTap: () {
                                                  _pageController.animateToPage(i, duration: const Duration(milliseconds: 500), curve: Curves.easeOutExpo);
                                                },
                                                child: Container(
                                                  color: Colors.transparent,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    _tabs[i],
                                                    style: GoogleFonts.originalSurfer(fontWeight: FontWeight.bold, fontSize: currentFontSize, color: currentColor),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            builder: (context, child) {
              double slide = 250.0 * _drawerController.value;
              double scale = 1.0 - (0.2 * _drawerController.value); 

              return Transform(
                transform: Matrix4.identity()..translate(slide)..scale(scale),
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_drawerController.value * 30),
                  child: Stack(
                    children: [
                      child!, 
                      if (_drawerController.value > 0)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () { _drawerController.reverse(); },
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
