import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splash_screen/core/widgets/custom_loader.dart';
import 'package:splash_screen/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splash_screen/logic/locale_bloc/locale_cubit.dart';

import '../../../data/repositories/supabase_repository.dart';
import '../../../core/widgets/sheets/app_bottom_sheets.dart';
import '../customer_home_screen.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  final PageController _pageController = PageController();
  Drag? _drag;
  List<Map<String, dynamic>> _words = [];
  bool _isLoading = true;

  bool _showExpansion = false;
  final double _dotSize = 50.0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        int newIndex = _pageController.page!.round();
        if (newIndex != _currentIndex &&
            newIndex >= 0 &&
            newIndex < _words.length) {
          setState(() {
            _currentIndex = newIndex;
          });
          HapticFeedback.selectionClick();
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
    final restaurants = await SupabaseRepository().getActiveRestaurants();
    if (mounted) {
      setState(() {
        _words = restaurants;
        _isLoading = false;
      });
    }
  }

  void _onRestaurantSelected() {
    if (_showExpansion) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _showExpansion = true;
    });

    final selectedRestaurant = _words[_currentIndex];

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              CustomerHomeScreen(restaurantData: selectedRestaurant),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ).then((_) {
        // When coming back, reset the expansion animation so the list is visible
        if (mounted) {
          setState(() {
            _showExpansion = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (_isLoading)
              const Center(child: CustomLoader())
            else ...[
              Positioned.fill(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    final restaurant = _words[index];
                    final logoUrl = restaurant['logo_url'];
                    
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 150.0), // Padding to avoid overlapping with bottom navigation
                        child: AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_pageController.position.haveDimensions) {
                              value = _pageController.page! - index;
                              value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                            }
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'restaurant_logo_${restaurant['id']}',
                            child: logoUrl != null && logoUrl.toString().isNotEmpty
                                ? Container(
                                    width: 300,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(logoUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 300,
                                    height: 300,
                                    child: const Icon(Icons.storefront, size: 200, color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!_showExpansion)
                Positioned(
                  bottom: 105,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onHorizontalDragStart: (DragStartDetails details) {
                      if (_pageController.position.haveDimensions) {
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
                      height: 150,
                      width: size.width,
                      child: RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.elliptical(size.width, 150),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
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

                                  Color activeColor = Colors.white;
                                  Color inactiveColor = Colors.white54;
                                  final double itemWidth = size.width / 2.5;
                                  final double centerX = size.width / 2;
                                  final double rx = size.width * 0.8;
                                  const double ry = 35.0;

                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned(
                                        bottom: 10,
                                        child: Container(
                                          width: 25,
                                          height: 25,
                                          decoration: const BoxDecoration(
                                            color: Colors.blueAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      for (int i = 0; i < _words.length; i++)
                                        () {
                                          double dx =
                                              (i - progress) * itemWidth;
                                          double distance = dx.abs();
                                          double dy = 0;
                                          if (distance < rx) {
                                            dy =
                                                ry *
                                                math.sqrt(
                                                  1 -
                                                      (distance * distance) /
                                                          (rx * rx),
                                                );
                                          }
                                          double distanceRatio =
                                              (distance / itemWidth).clamp(
                                                0.0,
                                                1.0,
                                              );
                                          double curveRatio = Curves.easeOut
                                              .transform(1.0 - distanceRatio);

                                          double currentScale =
                                              1.0 + (0.75 * curveRatio);
                                          Color currentColor = Color.lerp(
                                            inactiveColor,
                                            activeColor,
                                            curveRatio,
                                          )!;

                                          double wordLeft =
                                              centerX + dx - (itemWidth / 2);
                                          double wordBottom = 45.0 + dy;

                                          bool isRTL =
                                              Directionality.of(context) ==
                                              TextDirection.rtl;

                                          String text =
                                              context
                                                      .read<LocaleCubit>()
                                                      .state
                                                      .languageCode ==
                                                  'ar'
                                              ? (_words[i]['name_ar'] ??
                                                    _words[i]['text'])
                                              : (_words[i]['name_en'] ??
                                                    _words[i]['text']);

                                          return PositionedDirectional(
                                            start: 0,
                                            bottom: 0,
                                            child: Transform.translate(
                                              offset: Offset(
                                                isRTL ? -wordLeft : wordLeft,
                                                -wordBottom,
                                              ),
                                              child: SizedBox(
                                                width: itemWidth,
                                                child: GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () {
                                                    if (i == _currentIndex) {
                                                      _onRestaurantSelected();
                                                    } else {
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
                                                    }
                                                  },
                                                  child: Container(
                                                    color: Colors.transparent,
                                                    alignment: Alignment.center,
                                                    child: Transform.scale(
                                                      scale: currentScale,
                                                      child: Text(
                                                        text,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displaySmall
                                                            ?.copyWith(
                                                              fontSize: 16.0,
                                                              color:
                                                                  currentColor,
                                                            ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
              if (_showExpansion)
                Positioned(
                  left: (size.width / 2) - (_dotSize / 2),
                  bottom: 165,
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
            if (!_showExpansion)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.black87,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 30.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(context)!.chooseRestaurant,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 22,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: IconButton(
                                icon: Image.asset(
                                  context
                                              .read<LocaleCubit>()
                                              .state
                                              .languageCode ==
                                          'ar'
                                      ? 'assets/images/flag_ps.png'
                                      : 'assets/images/flag_us.png',
                                  width: 24,
                                  height: 24,
                                ),
                                onPressed: () {
                                  AppBottomSheets.showLanguageSheet(context);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!_showExpansion)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: RepaintBoundary(
                    child: GestureDetector(
                      onTap: () {
                        AppBottomSheets.showCustomerAuthSheet(
                          context,
                          onAuthSuccess: () {},
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.restaurantOwnerLogin,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 15,
                                decorationColor: Colors.white.withValues(
                                  alpha: 0.9,
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
    );
  }
}
