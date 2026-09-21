import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom Clipper for the highly professional Circular Reveal effect
class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset center;

  const CircularRevealClipper({required this.fraction, required this.center});

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
