import 'package:flutter/material.dart';
import 'dart:math' as math;

class ShimmerPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const ShimmerPlaceholder({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  }) : super(key: key);

  @override
  _ShimmerPlaceholderState createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    return LayoutBuilder(builder: (context, constraints) {
      final w = widget.width ?? (constraints.maxWidth.isFinite ? constraints.maxWidth : 100.0);
      final h = widget.height ?? (constraints.maxHeight.isFinite ? constraints.maxHeight : 56.0);
      final shineWidth = math.max(24.0, w * 0.25);

      return Container(
        width: w,
        height: h,
        margin: widget.margin,
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: baseColor),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  final animValue = _ctrl.value;
                  final dx = (w + shineWidth) * animValue - shineWidth;
                  return Transform.translate(
                    offset: Offset(dx - (w/2), 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: shineWidth,
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              baseColor,
                              highlightColor,
                              baseColor,
                            ],
                            stops: const [0.0, 0.5, 1.0],
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
      );
    });
  }
}
