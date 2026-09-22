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
          return CustomPaint(
            size: Size(widget.size * 4, widget.size * 2),
            painter: _LoaderPainter(_controller.value, widget.size),
          );
        },
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double progress;
  final double circleSize;

  _LoaderPainter(this.progress, this.circleSize);

  @override
  void paint(Canvas canvas, Size size) {
    final double angle = progress * 2 * math.pi;
    final double distance = circleSize * 0.7;

    final double x1 = math.cos(angle) * distance;
    final double z1 = math.sin(angle);
    final double scale1 = 1.0 + (z1 * 0.3);

    final double x2 = math.cos(angle + math.pi) * distance;
    final double z2 = math.sin(angle + math.pi);
    final double scale2 = 1.0 + (z2 * 0.3);

    final paint1 = Paint()..color = Colors.blue;
    final paint2 = Paint()..color = Colors.amber;

    final center = Offset(size.width / 2, size.height / 2);

    final radius1 = (circleSize / 2) * scale1;
    final radius2 = (circleSize / 2) * scale2;

    if (z1 < z2) {
      canvas.drawCircle(center + Offset(x1, 0), radius1, paint1);
      canvas.drawCircle(center + Offset(x2, 0), radius2, paint2);
    } else {
      canvas.drawCircle(center + Offset(x2, 0), radius2, paint2);
      canvas.drawCircle(center + Offset(x1, 0), radius1, paint1);
    }
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.circleSize != circleSize;
  }
}
