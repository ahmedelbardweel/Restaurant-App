import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  final List<Map<String, dynamic>> _words = const [
    {'text': 'McDonald\'s'},
    {'text': 'Burger King'},
    {'text': 'Pizza Hut'},
    {'text': 'Domino\'s'},
    {'text': 'Subway'},
    {'text': 'KFC'}, // Animation currently stops here (Index 5)
    {'text': 'Starbucks'},
    {'text': 'Wendy\'s'},
    {'text': 'Taco Bell'},
    {'text': 'Dunkin\''},
    {'text': 'Chipotle'},
    {'text': 'Papa John\'s'},
  ];

  bool _showExpansion = false;
  final double _dotSize = 30.0;
  final double _itemHeight = 80.0;
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 5.0, // Stop on 'Nike' (Index 5)
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));

    _controller.addListener(() {
      int newIndex = _progressAnimation.value.round();
      if (newIndex != _currentIndex) {
        _currentIndex = newIndex;
        HapticFeedback.selectionClick();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showExpansion = true;
        });

        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const HomePage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. The moving words container
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final progress = _progressAnimation.value;
              final double translateY =
                  (size.height / 2) - (progress * _itemHeight) - 18;

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Stack(
                  children: [
                    for (int i = 0; i < _words.length; i++)
                      Builder(
                        builder: (context) {
                          double dy = (i - progress) * _itemHeight;
                          double Ry = size.height * 0.65;
                          double Rx = 150.0;

                          double dx = 0;
                          if (dy.abs() < Ry) {
                            dx = Rx * math.sqrt(1 - (dy * dy) / (Ry * Ry));
                          }

                          double wordLeft = 30.0 + dx;
                          double distanceRatio = (dy.abs() / _itemHeight).clamp(0.0, 1.0);
                          double curveRatio = Curves.easeOut.transform(1.0 - distanceRatio);
                          double currentFontSize = 20.0 + (12.0 * curveRatio);
                          
                          Color currentColor = Color.lerp(
                            Colors.white24,
                            Colors.white,
                            curveRatio,
                          )!;

                          return Positioned(
                            top: i * _itemHeight,
                            left: wordLeft,
                            child: Text(
                              _words[i]['text'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: currentFontSize,
                                color: currentColor,
                                shadows: curveRatio > 0.5
                                    ? const [
                                        Shadow(
                                          color: Colors.blueAccent,
                                          blurRadius: 0,
                                        ),
                                      ]
                                    : null,
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

          // 3. The expanding circle transition
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
        ],
      ),
    );
  }
}
