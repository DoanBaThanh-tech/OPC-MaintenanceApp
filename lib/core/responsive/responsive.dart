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

/// Widget căn giữa nội dung và giới hạn chiều rộng tối đa (cho Desktop/Tablet)
class ResponsiveCenteredContent extends StatelessWidget {
  final Widget child;
  final double maxContentWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenteredContent({
    super.key,
    required this.child,
    this.maxContentWidth = 600,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Không dùng Center (dễ làm constraint cao bị “lỏng” → Column overflow).
    // Align topCenter + maxWidth giữ nội dung căn giữa theo chiều ngang, scroll theo dọc.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}