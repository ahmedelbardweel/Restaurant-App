import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLoader extends StatefulWidget {
  final double size;

  const CustomLoader({
    super.key,
    this.size = 12.0,
  });

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value;
        final double angle = progress * 2 * math.pi;
        final double distance = widget.size * 0.7;

        final double x1 = math.cos(angle) * distance;
        // Use sin for Z-index / scaling to simulate depth
        final double z1 = math.sin(angle);
        final double scale1 = 1.0 + (z1 * 0.3);

        final double x2 = math.cos(angle + math.pi) * distance;
        final double z2 = math.sin(angle + math.pi);
        final double scale2 = 1.0 + (z2 * 0.3);

        Widget circle1 = Transform.translate(
          offset: Offset(x1, 0),
          child: Transform.scale(
            scale: scale1,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );

        Widget circle2 = Transform.translate(
          offset: Offset(x2, 0),
          child: Transform.scale(
            scale: scale2,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );

        return SizedBox(
          width: widget.size * 4,
          height: widget.size * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Draw the one with smaller Z first so it appears behind
              if (z1 < z2) circle1 else circle2,
              if (z1 < z2) circle2 else circle1,
            ],
          ),
        );
      },
    ));
  }
}
