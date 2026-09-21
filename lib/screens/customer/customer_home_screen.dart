import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/repositories/supabase_repository.dart';
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

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Drag? _drag;

  late final AnimationController _drawerController;

  final List<String> _tabs = ['Home', 'Search', 'Cart', 'Profile'];

  Map<String, List<Map<String, String>>> _menuData = {};
  bool _isMenuLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStrictRouting();
    _loadMenu();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        int newIndex = _pageController.page!.round();
        if (newIndex != _currentIndex) {
          _currentIndex = newIndex;
          HapticFeedback.selectionClick();
        }
      }
    });
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
  void dispose() {
    _drawerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double itemWidth = size.width / 3.5;

    final String restaurantName = widget.restaurantData['text'];
    final List<Color> brandColors = widget.restaurantData['colors'];
    final Color primaryColor = brandColors[0];
    final Color menuBgColor = Colors.white;

    return Scaffold(
      backgroundColor: menuBgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              width: 240,
              padding: const EdgeInsets.only(
                left: 20.0,
                top: 40.0,
                right: 10.0,
              ),
              child: _isMenuLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
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
                                if (item['image_url'] != null &&
                                    item['image_url']!.isNotEmpty) {
                                  try {
                                    images = List<String>.from(
                                      jsonDecode(item['image_url']!),
                                    );
                                  } catch (e) {
                                    print('Error parsing images: $e');
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 15.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (images.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 12.0,
                                          ),
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                                        item['price']!,
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
          AnimatedBuilder(
            animation: _drawerController,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      Color bgColor = brandColors[index];
                      Color appBarColor =
                          brandColors[(index + 1) % brandColors.length];

                      bool isLightBg = bgColor.computeLuminance() > 0.5;
                      Color titleColor = isLightBg
                          ? Colors.black
                          : Colors.white;

                      bool isLightAppBar = appBarColor.computeLuminance() > 0.5;
                      Color appBarTextColor = isLightAppBar
                          ? Colors.black
                          : Colors.white;

                      return Container(
                        color: bgColor,
                        child: Stack(
                          children: [
                            Center(
                              child: _tabs[index] == 'Profile'
                                  ? ProfileTabView(titleColor: titleColor)
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: size.width,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: appBarColor,
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.elliptical(size.width, 80),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: SafeArea(
                                  bottom: false,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                    ),
                                    child: Stack(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: () {
                                              if (_drawerController
                                                  .isDismissed) {
                                                _drawerController.forward();
                                              } else {
                                                _drawerController.reverse();
                                              }
                                            },
                                            child: Text(
                                              'Menu',
                                              style: GoogleFonts.originalSurfer(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: appBarTextColor
                                                    .withOpacity(0.7),
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            restaurantName,
                                            style: GoogleFonts.pacifico(
                                              fontSize: 34,
                                              fontWeight: FontWeight.normal,
                                              color: appBarTextColor,
                                              letterSpacing: 0,
                                            ),
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
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (DragStartDetails details) {
                        if (_pageController.hasClients) {
                          _drag = _pageController.position.drag(details, () {
                            _drag = null;
                          });
                        }
                      },
                      onHorizontalDragUpdate: (DragUpdateDetails details) {
                        _drag?.update(details);
                      },
                      onHorizontalDragEnd: (DragEndDetails details) {
                        _drag?.end(details);
                      },
                      onHorizontalDragCancel: () {
                        _drag?.cancel();
                      },
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

                            int lowerIndex = progress.floor().clamp(
                              0,
                              _tabs.length - 1,
                            );
                            int upperIndex = progress.ceil().clamp(
                              0,
                              _tabs.length - 1,
                            );
                            double t = progress - lowerIndex;
                            Color currentBgColor =
                                Color.lerp(
                                  brandColors[lowerIndex],
                                  brandColors[upperIndex],
                                  t,
                                ) ??
                                brandColors[lowerIndex];

                            bool isLight =
                                currentBgColor.computeLuminance() > 0.5;
                            Color activeColor = isLight
                                ? Colors.black
                                : Colors.white;
                            Color inactiveColor = isLight
                                ? Colors.black54
                                : Colors.white54;

                            final double centerX = size.width / 2;
                            final double Rx = size.width * 0.8;
                            const double Ry = 45.0;

                            return RepaintBoundary(
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.elliptical(size.width, 80),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10.0,
                                    sigmaY: 10.0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.elliptical(size.width, 80),
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned(
                                          bottom: 55,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: activeColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        for (int i = 0; i < _tabs.length; i++)
                                          Builder(
                                            builder: (context) {
                                              double dx =
                                                  (i - progress) * itemWidth;
                                              double distance = dx.abs();
                                              double dy = 0;
                                              if (distance < Rx) {
                                                dy =
                                                    Ry *
                                                    math.sqrt(
                                                      1 -
                                                          (distance *
                                                                  distance) /
                                                              (Rx * Rx),
                                                    );
                                              }

                                              double distanceRatio =
                                                  (distance / itemWidth).clamp(
                                                    0.0,
                                                    1.0,
                                                  );
                                              double curveRatio = Curves.easeOut
                                                  .transform(
                                                    1.0 - distanceRatio,
                                                  );
                                              double currentFontSize =
                                                  16.0 + (12.0 * curveRatio);
                                              Color currentColor = Color.lerp(
                                                inactiveColor,
                                                activeColor,
                                                curveRatio,
                                              )!;

                                              double wordLeft =
                                                  centerX +
                                                  dx -
                                                  (itemWidth / 2);
                                              double wordBottom = 25.0 + dy;

                                              return Positioned(
                                                left: 0,
                                                bottom: 0,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                    wordLeft,
                                                    -wordBottom,
                                                  ),
                                                  child: SizedBox(
                                                    width: itemWidth,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _pageController
                                                            .animateToPage(
                                                              i,
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        500,
                                                                  ),
                                                              curve: Curves
                                                                  .easeOutExpo,
                                                            );
                                                      },
                                                      child: Container(
                                                        color:
                                                            Colors.transparent,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          _tabs[i],
                                                          style: GoogleFonts.originalSurfer(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize:
                                                                currentFontSize,
                                                            color: currentColor,
                                                          ),
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
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale),
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    _drawerController.value * 30,
                  ),
                  child: Stack(
                    children: [
                      child!,
                      if (_drawerController.value > 0)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              _drawerController.reverse();
                            },
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
