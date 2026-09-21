import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../main.dart'; // To navigate to the main list

class SplashLoaderScreen extends StatefulWidget {
  const SplashLoaderScreen({super.key});

  @override
  State<SplashLoaderScreen> createState() => _SplashLoaderScreenState();
}

class _SplashLoaderScreenState extends State<SplashLoaderScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _loadData();
  }

  Future<void> _loadData() async {
    // Artificial minimum delay for the animation to look good
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      // In the future, we could preload Supabase data here:
      // SupabaseService().getRestaurants(),
    ]);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RestaurantListScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark aesthetic
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Text(
              'Restaurant',
              style: GoogleFonts.originalSurfer(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
