import 'package:flutter/material.dart';
class Breakpoints {
  Breakpoints._();
  static const double mobile = 600;
  static const double tablet = 1024;
}

class ResponsiveInfo {
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final double width;

  ResponsiveInfo({required this.width})
      : isMobile = width < Breakpoints.mobile,
        isTablet = width >= Breakpoints.mobile && width < Breakpoints.tablet,
        isDesktop = width >= Breakpoints.tablet;
}

/// Bọc quanh mỗi màn hình để lấy thông tin kích thước 1 lần,
/// dùng lại cho cả layout lẫn padding/font-size nếu cần
class Responsive extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveInfo info) builder;
  const Responsive({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, ResponsiveInfo(width: constraints.maxWidth));
      },
    );
  }
}