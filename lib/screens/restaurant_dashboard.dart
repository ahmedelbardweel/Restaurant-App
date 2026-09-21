import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../main.dart';
import '../main.dart';

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

    final profile = await SupabaseService().getRestaurantProfile(user.id);
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
    final cats = await SupabaseService().getRawCategories(_restaurantId!);
    if (mounted) {
      setState(() {
        _categories = cats;
      });
    }
  }

  // Helper: Open simple bottom sheet for input
  void _showAddCategorySheet() {
    final controller = TextEditingController();
    _showCustomBottomSheet(
      title: 'Add New Category',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInput(controller, 'Category Name', Icons.category),
          const SizedBox(height: 20),
          _buildPrimaryButton('Create Category', () async {
            if (controller.text.trim().isEmpty) return;
            Navigator.pop(context);
            setState(() => _isLoading = true);
            await SupabaseService().addCategory(
              _restaurantId!,
              controller.text.trim(),
            );
            await _fetchCategories();
            setState(() => _isLoading = false);
          }),
        ],
      ),
    );
  }

  void _showAddItemSheet(String categoryId) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    List<XFile> selectedImages = [];
    bool isUploading = false;

    _showCustomBottomSheet(
      title: 'Add Menu Item',
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInput(nameController, 'Item Name', Icons.fastfood),
              const SizedBox(height: 15),
              _buildInput(descController, 'Description', Icons.description),
              const SizedBox(height: 15),
              _buildInput(
                priceController,
                'Price (e.g. 10.99)',
                Icons.attach_money,
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
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _buildPrimaryButton('Add Item', () async {
                      if (nameController.text.trim().isEmpty ||
                          priceController.text.trim().isEmpty)
                        return;
                      final price = double.tryParse(
                        priceController.text.trim(),
                      );
                      if (price == null) return;

                      setModalState(() => isUploading = true);

                      // Upload images if any
                      List<String> imageUrls = [];
                      if (selectedImages.isNotEmpty) {
                        imageUrls = await SupabaseService()
                            .uploadMenuItemImages(selectedImages);
                      }

                      await SupabaseService().addMenuItem(
                        categoryId,
                        nameController.text.trim(),
                        descController.text.trim(),
                        price,
                        imageUrls,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        await _fetchCategories();
                        setState(() => _isLoading = false);
                      }
                    }),
            ],
          );
        },
      ),
    );
  }

  void _showConfirmDeleteSheet(
    String title,
    String subtitle,
    VoidCallback onConfirm,
  ) {
    _showCustomBottomSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPrimaryButton('Delete', () {
                  Navigator.pop(context);
                  onConfirm();
                }, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomBottomSheet({required String title, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.originalSurfer(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                child,
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.black54,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    String text,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? _brandColors[0],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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
                    onPressed: _showAddCategorySheet,
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
                                  onPressed: () => _showAddItemSheet(category['id']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    _showConfirmDeleteSheet(
                                      'Delete Category',
                                      'Are you sure you want to delete "${category['name']}"? This will delete all items inside it.',
                                      () async {
                                        setState(() => _isLoading = true);
                                        await SupabaseService().deleteCategory(category['id']);
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
                          separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
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
                                  _showConfirmDeleteSheet(
                                    'Delete Item',
                                    'Are you sure you want to delete "${item['name']}"?',
                                    () async {
                                      setState(() => _isLoading = true);
                                      await SupabaseService().deleteMenuItem(item['id']);
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
                          _showAddCategorySheet();
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
