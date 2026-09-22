import 'dart:math' as math;
import 'dart:ui';
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

    _pageController = PageController(viewportFraction: 0.15);

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        int newIndex = _pageController.page!.round();
        if (newIndex != _currentIndex) {
          _currentIndex = newIndex;
          HapticFeedback.lightImpact();
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
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              CustomerHomeScreen(restaurantData: selectedRestaurant),
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
            else if (_words.isEmpty)
              const Center(
                child: Text(
                  'No restaurants created yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
              )
            else ...[
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double progress = 0.0;
                    if (_pageController.hasClients) {
                      progress = _pageController.page ?? 0.0;
                    }

                    final double translateY =
                        (size.height / 2) - (progress * _itemHeight) - 28;

                    final double ry = size.height * 0.65;
                    const double rx = 150.0;
                    const double baseLeft = 30.0;

                    return Transform.translate(
                      offset: Offset(0, translateY),
                      child: Stack(
                        children: [
                          for (int i = 0; i < _words.length; i++)
                            Builder(
                              builder: (context) {
                                double dy = (i - progress) * _itemHeight;

                                double dx = 0;
                                if (dy.abs() < ry) {
                                  dx =
                                      rx * math.sqrt(1 - (dy * dy) / (ry * ry));
                                }

                                double wordLeft = baseLeft + dx;

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

                                final textDir = Directionality.of(context);
                                // Invert direction: Arabic -> Left, English -> Right
                                final invertedDir = textDir == TextDirection.rtl
                                    ? TextDirection.ltr
                                    : TextDirection.rtl;
                                final isInvertedRtl =
                                    invertedDir == TextDirection.rtl;

                                return Positioned.directional(
                                  textDirection: invertedDir,
                                  top: 0,
                                  start: 0,
                                  child: Transform.translate(
                                    offset: Offset(
                                      isInvertedRtl ? -wordLeft : wordLeft,
                                      i * _itemHeight,
                                    ),
                                    child: GestureDetector(
                                      onTap: _onRestaurantSelected,
                                      child: Container(
                                        color: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 20,
                                        ),
                                        child: Text(
                                          context
                                                      .read<LocaleCubit>()
                                                      .state
                                                      .languageCode ==
                                                  'ar'
                                              ? (_words[i]['name_ar'] ??
                                                    _words[i]['text'])
                                              : (_words[i]['name_en'] ??
                                                    _words[i]['text']),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: currentFontSize,
                                            color: currentColor,
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
              if (!_showExpansion)
                Positioned.directional(
                  textDirection: Directionality.of(context) == TextDirection.rtl
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  start: 30,
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
              if (_showExpansion)
                Positioned.directional(
                  textDirection: Directionality.of(context) == TextDirection.rtl
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  start: 30,
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
              if (!_showExpansion)
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
                          horizontal: 24,
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
                                decoration: TextDecoration.underline,
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
