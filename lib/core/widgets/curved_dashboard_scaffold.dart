import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splash_screen/l10n/app_localizations.dart';

class CurvedDashboardScaffold extends StatefulWidget {
  final List<String> tabs;
  final Widget Function(BuildContext context, int index, Color titleColor) pageBuilder;
  final Widget drawerContent;
  final List<Color> brandColors;
  final Map<int, Color>? tabBackgroundColorsOverrides;
  final Color drawerBackgroundColor;
  final String appBarTitle;

  const CurvedDashboardScaffold({
    super.key,
    required this.tabs,
    required this.pageBuilder,
    required this.drawerContent,
    required this.brandColors,
    required this.appBarTitle,
    this.tabBackgroundColorsOverrides,
    this.drawerBackgroundColor = Colors.white,
  });

  @override
  State<CurvedDashboardScaffold> createState() => _CurvedDashboardScaffoldState();
}

class _CurvedDashboardScaffoldState extends State<CurvedDashboardScaffold>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentIndex = 0;
  Drag? _drag;
  late final AnimationController _drawerController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  Color _getContrastColor(Color color) {
    final double luminance = color.computeLuminance();
    // Using W3C relative luminance ratio formula for contrast
    final double contrastWithWhite = 1.05 / (luminance + 0.05);
    final double contrastWithBlack = (luminance + 0.05) / 0.05;
    return contrastWithWhite > contrastWithBlack ? Colors.white : Colors.black;
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

    return Scaffold(
      backgroundColor: widget.drawerBackgroundColor,
      body: Stack(
        children: [
          // Drawer Content
          widget.drawerContent,

          // Main Content
          AnimatedBuilder(
            animation: _drawerController,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  PageView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _pageController,
                    itemCount: widget.tabs.length,
                    itemBuilder: (context, index) {
                      Color bgColor = widget.tabBackgroundColorsOverrides?[index] ?? widget.brandColors[index % widget.brandColors.length];
                      Color titleColor = _getContrastColor(bgColor);

                      return Container(
                        color: bgColor,
                        child: widget.pageBuilder(context, index, titleColor),
                      );
                    },
                  ),

                  // Semi-circle App Bar (Fixed at top, animates color)
                  Align(
                    alignment: Alignment.topCenter,
                    child: AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double progress = 0.0;
                        if (_pageController.hasClients) {
                          progress = _pageController.page ?? 0.0;
                        }

                        int lowerIndex = progress.floor().clamp(0, widget.tabs.length - 1);
                        int upperIndex = progress.ceil().clamp(0, widget.tabs.length - 1);
                        double t = progress - lowerIndex;

                        Color lowerColor = widget.brandColors[(lowerIndex + 1) % widget.brandColors.length];
                        Color upperColor = widget.brandColors[(upperIndex + 1) % widget.brandColors.length];
                        Color appBarColor = Color.lerp(lowerColor, upperColor, t) ?? lowerColor;
                        Color appBarTextColor = _getContrastColor(appBarColor);

                        SystemUiOverlayStyle overlayStyle = appBarTextColor == Colors.white
                            ? const SystemUiOverlayStyle(
                                statusBarColor: Colors.transparent,
                                statusBarIconBrightness: Brightness.light,
                                statusBarBrightness: Brightness.dark,
                              )
                            : const SystemUiOverlayStyle(
                                statusBarColor: Colors.transparent,
                                statusBarIconBrightness: Brightness.dark,
                                statusBarBrightness: Brightness.light,
                              );

                        return AnnotatedRegion<SystemUiOverlayStyle>(
                          value: overlayStyle,
                          child: Container(
                            width: size.width,
                            height: 120,
                            decoration: BoxDecoration(
                              color: appBarColor,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.elliptical(size.width, 60),
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
                                padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 20.0),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: TextButton(
                                        onPressed: () {
                                          if (_drawerController.isDismissed) {
                                            _drawerController.forward();
                                          } else {
                                            _drawerController.reverse();
                                          }
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!.menu,
                                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            color: appBarTextColor.withValues(alpha: 0.7),
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        widget.appBarTitle,
                                        style: GoogleFonts.pacifico(
                                          color: appBarTextColor,
                                          fontSize: 24,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
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

                  // Bottom Navigation Bar
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onHorizontalDragStart: (DragStartDetails details) {
                        if (_pageController.position.haveDimensions) {
                          _drag = _pageController.position.drag(
                            details,
                            () {
                              _drag = null;
                            },
                          );
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
                        height: 100,
                        width: size.width,
                        child: RepaintBoundary(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.elliptical(size.width, 60),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.elliptical(size.width, 60),
                                  ),
                                ),
                                child: AnimatedBuilder(
                                  animation: _pageController,
                                  builder: (context, child) {
                                    double progress = 0.0;
                                    if (_pageController.hasClients) {
                                      progress = _pageController.page ?? 0.0;
                                    }

                                    int lowerIndex = progress.floor().clamp(0, widget.tabs.length - 1);
                                    int upperIndex = progress.ceil().clamp(0, widget.tabs.length - 1);
                                    double t = progress - lowerIndex;
                                    Color currentBgColor = Color.lerp(
                                          widget.tabBackgroundColorsOverrides?[lowerIndex] ?? widget.brandColors[lowerIndex % widget.brandColors.length],
                                          widget.tabBackgroundColorsOverrides?[upperIndex] ?? widget.brandColors[upperIndex % widget.brandColors.length],
                                          t,
                                        ) ??
                                        (widget.tabBackgroundColorsOverrides?[lowerIndex] ?? widget.brandColors[lowerIndex % widget.brandColors.length]);

                                    Color activeColor = _getContrastColor(currentBgColor);
                                    Color inactiveColor = activeColor == Colors.black ? Colors.black54 : Colors.white54;

                                    final double centerX = size.width / 2;
                                    final double rx = size.width * 0.8;
                                    const double ry = 35.0;

                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned(
                                          bottom: 40,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: activeColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        for (int i = 0; i < widget.tabs.length; i++)
                                          () {
                                            double dx = (i - progress) * itemWidth;
                                            double distance = dx.abs();
                                            double dy = 0;
                                            if (distance < rx) {
                                              dy = ry *
                                                  math.sqrt(
                                                    1 - (distance * distance) / (rx * rx),
                                                  );
                                            }
                                            double distanceRatio =
                                                (distance / itemWidth).clamp(0.0, 1.0);
                                            double curveRatio =
                                                Curves.easeOut.transform(1.0 - distanceRatio);
                                                
                                            // Max font size was 28 (16 + 12). So max scale is 28 / 16 = 1.75
                                            double currentScale = 1.0 + (0.75 * curveRatio);
                                            Color currentColor = Color.lerp(
                                              inactiveColor,
                                              activeColor,
                                              curveRatio,
                                            )!;

                                            double wordLeft = centerX + dx - (itemWidth / 2);
                                            double wordBottom = 15.0 + dy;

                                            bool isRTL = Directionality.of(context) == TextDirection.rtl;

                                            return PositionedDirectional(
                                              start: 0,
                                              bottom: 0,
                                              child: Transform.translate(
                                                offset: Offset(isRTL ? -wordLeft : wordLeft, -wordBottom),
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
                                                      alignment: Alignment.center,
                                                      child: Transform.scale(
                                                        scale: currentScale,
                                                        child: Text(
                                                          widget.tabs[i],
                                                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                                            fontSize: 16.0,
                                                            color: currentColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }(),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            builder: (context, child) {
              bool isRTL = Directionality.of(context) == TextDirection.rtl;
              double slide = 250.0 * _drawerController.value * (isRTL ? -1 : 1);
              double scale = 1.0 - (0.2 * _drawerController.value);
              return Transform(
                transform: Matrix4.identity()
                  ..setTranslationRaw(slide, 0.0, 0.0)
                  ..scale(scale, scale, 1.0),
                alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_drawerController.value * 30),
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
