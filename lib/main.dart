import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/supabase_service.dart';
import 'screens/splash_loader.dart';
import 'screens/login_screen.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://srawlltewvegexdjbsxy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyYXdsbHRld3ZlZ2V4ZGpic3h5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5NzE1NjAsImV4cCI6MjEwNTU0NzU2MH0.8puCn7lM2-yFBJ8J2w-QaeO5RQhLugADbr0TAVlDf0o',
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.originalSurfer().fontFamily,
        textTheme: GoogleFonts.originalSurferTextTheme(),
      ),
      home: const SplashLoaderScreen(),
    ),
  );
}

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  _RestaurantListScreenState createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  late final PageController _pageController;
  List<Map<String, dynamic>> _words = [];
  bool _isLoading = true;

  bool _showExpansion = false;
  final double _dotSize = 30.0;
  final double _itemHeight = 80.0; // Vertical distance between items
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();

    // Use a small viewportFraction so each "page" swipe requires much less physical distance,
    // making the scrolling extremely fast and responsive.
    _pageController = PageController(viewportFraction: 0.15);

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        int newIndex = _pageController.page!.round();
        if (newIndex != _currentIndex) {
          _currentIndex = newIndex;
          HapticFeedback.selectionClick(); // Physical vibration for each word
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    final restaurants = await SupabaseService().getRestaurants();
    if (mounted) {
      setState(() {
        _words = restaurants.map((res) {
          final colorsList = res['colors'] as List<int>;
          return {
            'id': res['id'],
            'text': res['text'],
            'colors': colorsList.map((c) => Color(c)).toList(),
          };
        }).toList();
        _isLoading = false;
      });
    }
  }

  void _onRestaurantSelected() {
    if (_showExpansion) return; // Prevent multiple clicks

    HapticFeedback.heavyImpact();
    setState(() {
      _showExpansion = true;
    });

    final selectedRestaurant = _words[_currentIndex];

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              HomePage(restaurantData: selectedRestaurant),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_words.isEmpty)
            const Center(
              child: Text(
                'No restaurants created yet.',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            )
          else ...[
            // 1. The custom vertical elliptical list
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double progress = 0.0;
                  if (_pageController.hasClients) {
                    progress = _pageController.page ?? 0.0;
                  }

                  // Translate the whole list so the active item is vertically centered
                  final double translateY =
                      (size.height / 2) - (progress * _itemHeight) - 28;

                  // Pre-calculated Math Constants to save CPU cycles
                  final double Ry = size.height * 0.65;
                  const double Rx = 150.0;
                  const double baseLeft = 30.0;

                  return Transform.translate(
                    offset: Offset(0, translateY),
                    child: Stack(
                      children: [
                        for (int i = 0; i < _words.length; i++)
                          Builder(
                            builder: (context) {
                              double dy = (i - progress) * _itemHeight;

                              // Ellipse math for horizontal curve
                              double dx = 0;
                              if (dy.abs() < Ry) {
                                dx = Rx * math.sqrt(1 - (dy * dy) / (Ry * Ry));
                              }

                              double wordLeft = baseLeft + dx;

                              // Physical interpolation based on distance from center
                              double distanceRatio = (dy.abs() / _itemHeight)
                                  .clamp(0.0, 1.0);
                              double curveRatio = Curves.easeOut.transform(
                                1.0 - distanceRatio,
                              );

                              double currentFontSize =
                                  20.0 + (12.0 * curveRatio);
                              Color currentColor = Color.lerp(
                                Colors.white24,
                                Colors.white,
                                curveRatio,
                              )!;

                              return Positioned(
                                top: 0,
                                // STATIC CONSTRAINT! Prevents Layout Thrashing!
                                left: 0,
                                // STATIC CONSTRAINT!
                                child: Transform.translate(
                                  offset: Offset(wordLeft, i * _itemHeight),
                                  // PAINT-ONLY MOVEMENT
                                  child: GestureDetector(
                                    onTap: _onRestaurantSelected,
                                    child: Container(
                                      color: Colors.transparent,
                                      // Expand tap target
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 20,
                                      ),
                                      child: Text(
                                        _words[i]['text'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: currentFontSize,
                                          color: currentColor,
                                          // Removed expensive text shadow for flawless 120 FPS
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
                  );
                },
              ),
            ),

            // 2. The completely stationary left blue dot
            if (!_showExpansion)
              Positioned(
                left: 30,
                top: (size.height / 2) - (_dotSize / 2),
                child: Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // 3. The expanding circle transition (triggers on tap)
            if (_showExpansion)
              Positioned(
                left: 30,
                top: (size.height / 2) - (_dotSize / 2),
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 1.0, end: 120.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInExpo,
                  builder: (context, double scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: _dotSize,
                        height: _dotSize,
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // 4. The Invisible PageView for Native Vertical Scrolling Physics
            if (!_showExpansion) // Only allow scrolling if not animating to next page
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _words.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _onRestaurantSelected,
                    child: const SizedBox.expand(),
                  );
                },
              ),
          ],

          // 5. Glassmorphism Top App Bar
          if (!_showExpansion)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.3), // Light dark tint
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        child: Center(
                          child: Text(
                            'Choose your restaurant',
                            style: GoogleFonts.originalSurfer(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 5. Login Navigation at Bottom
          if (!_showExpansion)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const LoginScreen(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Restaurant Owner? Login Here',
                      style: GoogleFonts.originalSurfer(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Destination Home Page
class HomePage extends StatefulWidget {
  final Map<String, dynamic> restaurantData;

  const HomePage({super.key, required this.restaurantData});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Drag? _drag; // Store the active drag for native forwarding

  late final AnimationController _drawerController;

  final List<String> _tabs = ['Home', 'Search', 'Profile', 'Settings'];

  Map<String, List<Map<String, String>>> _menuData = {};
  bool _isMenuLoading = true;

  @override
  void initState() {
    super.initState();
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
          HapticFeedback.selectionClick(); // Vibrate when changing tabs
        }
      }
    });
  }

  Future<void> _loadMenu() async {
    final data = await SupabaseService().getRestaurantMenu(widget.restaurantData['id']);
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
    final double itemWidth = size.width / 3.5; // Spacing between tabs

    final String restaurantName = widget.restaurantData['text'];
    final List<Color> brandColors = widget.restaurantData['colors'];
    final Color primaryColor = brandColors[0]; // For bottom bar active items
    final Color menuBgColor = Colors.white; // Fixed white background for menu

    return Scaffold(
      backgroundColor: menuBgColor,
      body: Stack(
        children: [
          // 1. The Drawer Menu (Bottom Layer)
          SafeArea(
            child: Container(
              width: 240, // Constrain width to exactly fit within the slide gap
              padding: const EdgeInsets.only(
                left: 20.0,
                top: 40.0,
                right: 10.0,
              ),
              child: _isMenuLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _menuData.isEmpty
                  ? Center(child: Text("No menu available.", style: TextStyle(color: Colors.grey, fontSize: 16)))
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
                        // Category Title
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 20, // Smaller category font
                            fontWeight: FontWeight.bold,
                            color:
                                primaryColor, // Distinguish category with restaurant's primary brand color
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Items in this category
                        ...items.map((item) {
                          List<String> images = [];
                          if (item['image_url'] != null && item['image_url']!.isNotEmpty) {
                            try {
                              images = List<String>.from(jsonDecode(item['image_url']!));
                            } catch (e) {
                              print('Error parsing images in customer menu: $e');
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
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
                                
                                // Item Name
                                Expanded(
                                  child: Text(
                                    item['name']!,
                                    style: TextStyle(
                                      fontSize: 13, // Smaller item font
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // Price
                                Text(
                                  item['price']!,
                                  style: TextStyle(
                                    fontSize: 13, // Smaller price font
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
                      Color bgColor = brandColors[index];
                      // Pick the next color in the brand palette for the AppBar to ensure contrast while staying on-brand
                      Color appBarColor =
                          brandColors[(index + 1) % brandColors.length];

                      // Responsive text colors based on luminance
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
                        // Solid color for each page
                        child: Stack(
                          children: [
                            // Main Page Content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${_tabs[index]}',
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

                            // Semi-circle App Bar
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: size.width,
                                height: 140,
                                // Height of the AppBar
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
                                        // Menu Text Button
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
                                        // Restaurant Name
                                        Center(
                                          child: Text(
                                            restaurantName,
                                            // The restaurant name
                                            style: GoogleFonts.pacifico(
                                              fontSize:
                                                  34, // Larger size for cursive font
                                              fontWeight: FontWeight
                                                  .normal, // Pacifico is already thick enough
                                              color: appBarTextColor,
                                              letterSpacing:
                                                  0, // Cursive fonts must connect
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

                  // 2. The Custom Interactive Bottom Bar
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Catch all gestures on the bottom bar
                      onHorizontalDragStart: (DragStartDetails details) {
                        if (_pageController.hasClients) {
                          // Forward drag natively to the PageView for perfectly smooth, native physics and snapping!
                          // This eliminates all lag and manual calculations.
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
                      child: Container(
                        height: 140,
                        // Height of the bottom bar area
                        width: size.width,
                        child: AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            // Handle initial state before page is attached
                            double progress = 0.0;
                            if (_pageController.hasClients) {
                              progress = _pageController.page ?? 0.0;
                            }

                            // Dynamically calculate the exact background color at this moment in the scroll
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

                            // Make the bottom bar UI completely responsive to the current background color
                            bool isLight =
                                currentBgColor.computeLuminance() > 0.5;
                            Color activeColor = isLight
                                ? Colors.black
                                : Colors.white;
                            Color inactiveColor = isLight
                                ? Colors.black54
                                : Colors.white54;

                            final double centerX = size.width / 2;

                            // Pre-calculate constants
                            final double Rx =
                                size.width * 0.8; // Horizontal spread
                            const double Ry = 45.0; // Vertical bulge height

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
                                          // Positioned exactly underneath the active text
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: activeColor,
                                              // Responsive color
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),

                                  // The scrolling tabs
                                  for (int i = 0; i < _tabs.length; i++)
                                    Builder(
                                      builder: (context) {
                                        // Calculate horizontal distance from the center
                                        double dx = (i - progress) * itemWidth;
                                        double distance = dx.abs();

                                        // Using an ellipse for the vertical curve (Bulge upwards at center)
                                        double dy = 0;
                                        if (distance < Rx) {
                                          dy =
                                              Ry *
                                              math.sqrt(
                                                1 -
                                                    (distance * distance) /
                                                        (Rx * Rx),
                                              );
                                        }

                                        // Physical interpolation for text size and color based on distance
                                        double distanceRatio =
                                            (distance / itemWidth).clamp(
                                              0.0,
                                              1.0,
                                            );
                                        double curveRatio = Curves.easeOut
                                            .transform(1.0 - distanceRatio);

                                        double currentFontSize =
                                            16.0 + (12.0 * curveRatio);
                                        Color currentColor = Color.lerp(
                                          inactiveColor,
                                          activeColor,
                                          curveRatio,
                                        )!;

                                        // Calculate final positions
                                        double wordLeft =
                                            centerX + dx - (itemWidth / 2);
                                        double wordBottom =
                                            25.0 +
                                            dy; // Base bottom padding + curve height

                                        return Positioned(
                                          left: 0, // STATIC
                                          bottom: 0, // STATIC
                                          child: Transform.translate(
                                            offset: Offset(
                                              wordLeft,
                                              -wordBottom,
                                            ),
                                            // PAINT PHASE MOVEMENT
                                            child: SizedBox(
                                              width: itemWidth,
                                              child: GestureDetector(
                                                onTap: () {
                                                  _pageController.animateToPage(
                                                    i,
                                                    duration: const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                    curve: Curves.easeOutExpo,
                                                  );
                                                },
                                                child: Container(
                                                  color: Colors.transparent,
                                                  // Expand tap target
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    _tabs[i],
                                                    style:
                                                        GoogleFonts.originalSurfer(
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
            ), // Closes Scaffold
            builder: (context, child) {
              double slide = 250.0 * _drawerController.value;
              double scale =
                  1.0 - (0.2 * _drawerController.value); // Shrink to 0.8

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
                      child!, // The cached heavy Scaffold
                      // Transparent shield to capture taps and close drawer
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

  Widget _buildMenuItem(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Clipper for the highly professional Circular Reveal effect
class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset center;

  CircularRevealClipper({required this.fraction, required this.center});

  @override
  Path getClip(Size size) {
    Path path = Path();
    // Max radius from bottom center to the top corners
    double maxRadius = math.sqrt(
      math.pow(size.width / 2, 2) + math.pow(size.height, 2),
    );

    // The radius grows from 0 to maxRadius based on swipe progress
    double radius = maxRadius * fraction;

    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }
}
