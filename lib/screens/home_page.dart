import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../core/utils/circular_reveal_clipper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Drag? _drag; // Store the active drag for native forwarding

  static const List<String> _tabs = ['Home', 'Search', 'Profile', 'Settings'];
  static const List<Color> _pageColors = [
    Color(0xFF0F172A), // Dark slate
    Color(0xFF2E1065), // Dark violet
    Color(0xFF450A0A), // Dark red
    Color(0xFF064E3B), // Dark emerald
  ];

  Widget _buildPage(int index) {
    return Container(
      color: _pageColors[index],
      child: Center(
        child: Text(
          _tabs[index],
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double itemWidth = size.width / 3.5; // Spacing between tabs

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. The Custom Page Transitions (Circular Reveal)
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double page = 0.0;
              if (_pageController.hasClients) {
                page = _pageController.page ?? 0.0;
              }
              // Clamp to valid range
              page = page.clamp(0.0, _tabs.length - 1.0);

              int index1 = page.floor();
              int index2 = index1 + 1;
              double fraction = page - index1;

              if (index2 >= _tabs.length) {
                return _buildPage(index1);
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Base background page
                  _buildPage(index1),
                  // Revealing top page originating from the blue dot
                  ClipPath(
                    clipper: CircularRevealClipper(
                      fraction: fraction,
                      center: Offset(size.width / 2, size.height - 55),
                    ),
                    child: _buildPage(index2),
                  ),
                ],
              );
            },
          ),

          // 2. The Invisible PageView for Native Gesture Physics on the upper screen
          PageView.builder(
            controller: _pageController,
            itemCount: _tabs.length,
            itemBuilder: (context, index) {
              return const SizedBox.expand(); // Completely transparent
            },
          ),

          // 3. The Custom Interactive Bottom Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (DragStartDetails details) {
                if (_pageController.hasClients) {
                  // Forward drag natively to the PageView for perfectly smooth, native physics and snapping
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
                height: 140, // Height of the bottom bar area
                width: size.width,
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double progress = 0.0;
                    if (_pageController.hasClients) {
                      progress = _pageController.page ?? 0.0;
                    }

                    final double centerX = size.width / 2;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // The stationary dot in the center of the bar
                        Positioned(
                          bottom: 55, // Positioned exactly underneath the active text
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        // The scrolling tabs
                        for (int i = 0; i < _tabs.length; i++)
                          Builder(
                            builder: (context) {
                              double dx = (i - progress) * itemWidth;
                              double distance = dx.abs();

                              double Rx = size.width * 0.8;
                              double Ry = 45.0;

                              double dy = 0;
                              if (distance < Rx) {
                                dy = Ry * math.sqrt(1 - (distance * distance) / (Rx * Rx));
                              }

                              double distanceRatio = (distance / itemWidth).clamp(0.0, 1.0);
                              double curveRatio = Curves.easeOut.transform(1.0 - distanceRatio);

                              double currentFontSize = 16.0 + (12.0 * curveRatio);
                              Color currentColor = Color.lerp(
                                Colors.white38,
                                Colors.white,
                                curveRatio,
                              )!;

                              double wordLeft = centerX + dx - (itemWidth / 2);
                              double wordBottom = 25.0 + dy;

                              return Positioned(
                                left: wordLeft,
                                bottom: wordBottom,
                                width: itemWidth,
                                child: GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(
                                      i,
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeOutExpo,
                                    );
                                  },
                                  child: Container(
                                    color: Colors.transparent, // Expand tap target
                                    alignment: Alignment.center,
                                    child: Text(
                                      _tabs[i],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: currentFontSize,
                                        color: currentColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
