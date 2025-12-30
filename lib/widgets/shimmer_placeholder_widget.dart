import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPlaceholder extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w =
            width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 100.0);
        final h =
            height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 56.0);

        return Container(
          width: w,
          height: h,
          margin: margin,
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(color: baseColor, width: w, height: h),
            ),
          ),
        );
      },
    );
  }
}
