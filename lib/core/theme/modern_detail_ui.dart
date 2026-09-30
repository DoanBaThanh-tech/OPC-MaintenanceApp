import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Bộ UI chi tiết hồ sơ dùng chung (BT / SC / vật tư) — xanh chủ đạo, hiện đại.
class ModernDetailUi {
  static const bg = Color(0xFFF0F6FB);
  static const primary = Color(0xFF0068A9);

  static const headerGradient = LinearGradient(
    colors: [Color(0xFF004E80), Color(0xFF0068A9), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0068A9), Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color mauTrangThai(String tt) {
    switch (tt) {
      case 'Chờ duyệt':
      case 'Chờ GĐ duyệt':
      case 'Chờ gửi':
      case 'Đã gửi GĐ':
        return AppColors.warning;
      case 'Đã duyệt':
        return const Color(0xFF0284C7);
      case 'Đang thực hiện':
      case 'Chờ xác nhận':
        return primary;
      case 'Đã hoàn thành':
      case 'Xác nhận':
      case 'Đã xem':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      default:
        return Colors.blueGrey;
    }
  }

  /// Header gradient bo góc dưới + nút back.
  static Widget headerBar({
    required BuildContext context,
    required double topPadding,
    required String title,
    String? subtitle,
    List<Widget>? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, topPadding + 4, 12, 20),
      decoration: BoxDecoration(
        gradient: headerGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...trailing,
        ],
      ),
    );
  }

  /// Hero card gradient — icon + tiêu đề + badge trạng thái.
  static Widget heroCard({
    required IconData icon,
    required String title,
    String? subtitle,
    String? statusLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (statusLabel != null && statusLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card trắng bo góc + shadow mềm.
  static Widget softCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Hàng nhãn — giá trị trong card thông tin.
  static Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget sectionTitle({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primary.withValues(alpha: 0.95)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  static Widget statusChip(String text, [Color? color]) {
    final c = color ?? mauTrangThai(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  /// Fade + slide xuất hiện.
  static Widget fadeSlide({
    required int delayMs,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: c,
        ),
      ),
      child: child,
    );
  }
}