import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_logic.dart';
import '../../auth/presentation/auth_screens.dart';
import '../data/dashboard_logic.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PhienDangNhap? _phien;
  List<MenuGroup> _menu = [];
  MenuItemData? _dangChon;

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  Future<void> _taiDuLieu() async {
    final phien = await DashboardLogic.layPhienDangNhap();
    final menu = DashboardLogic.layMenuTheoVaiTro(phien.vaiTro);
    setState(() {
      _phien = phien;
      _menu = menu;
      _dangChon = menu.isNotEmpty ? menu.first.muc.first : null;
    });
  }

  Future<void> _dangXuat() async {
    await AuthService.dangXuat();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _chonMuc(MenuItemData muc) {
    setState(() => _dangChon = muc);
    Navigator.pop(context); // đóng slide menu sau khi chọn
  }

  @override
  Widget build(BuildContext context) {
    if (_phien == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Responsive(
      builder: (context, info) {
        final drawerWidth = info.isMobile
            ? MediaQuery.of(context).size.width * 0.82
            : 320.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(_dangChon?.label ?? 'Tổng quan'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          drawer: Drawer(
            width: drawerWidth,
            backgroundColor: const Color(0xFFF7F9FC),
            child: _SlideMenuContent(
              phien: _phien!,
              menu: _menu,
              dangChon: _dangChon,
              onChon: _chonMuc,
              onDangXuat: _dangXuat,
            ),
          ),
          body: _dangChon?.screenBuilder() ??
              const Center(child: Text('Chưa có chức năng cho vai trò này')),
        );
      },
    );
  }
}

// ============ SLIDE MENU — hiện đại, tên + vai trò rõ ràng ============

class _SlideMenuContent extends StatefulWidget {
  final PhienDangNhap phien;
  final List<MenuGroup> menu;
  final MenuItemData? dangChon;
  final void Function(MenuItemData) onChon;
  final VoidCallback onDangXuat;

  const _SlideMenuContent({
    required this.phien,
    required this.menu,
    required this.dangChon,
    required this.onChon,
    required this.onDangXuat,
  });

  @override
  State<_SlideMenuContent> createState() => _SlideMenuContentState();
}

class _SlideMenuContentState extends State<_SlideMenuContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String get _chuCai {
    final ten = widget.phien.hoTen.trim();
    if (ten.isEmpty) return '?';
    // Lấy chữ cái đầu của từ cuối (tên) nếu có
    final parts = ten.split(RegExp(r'\s+'));
    final last = parts.isNotEmpty ? parts.last : ten;
    return last[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: FadeTransition(
            opacity: _fade,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
              children: [
                for (var gi = 0; gi < widget.menu.length; gi++)
                  _buildNhom(widget.menu[gi], gi),
              ],
            ),
          ),
        ),
        _buildFooter(bottom),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 18,
        20,
        22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0077B8), Color(0xFF004E80)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _chuCai,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên người
                    Text(
                      widget.phien.hoTen.isNotEmpty
                          ? widget.phien.hoTen
                          : 'Người dùng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Badge vai trò
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        widget.phien.vaiTro,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.phien.email.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.mail_outline_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.phien.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNhom(MenuGroup nhom, int groupIndex) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Text(
              nhom.tieuDe.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          for (var i = 0; i < nhom.muc.length; i++)
            _buildMuc(nhom.muc[i], groupIndex * 10 + i),
        ],
      ),
    );
  }

  Widget _buildMuc(MenuItemData muc, int index) {
    final dangDuocChon = muc.label == widget.dangChon?.label;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(10 * (1 - t), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Material(
          color: dangDuocChon
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => widget.onChon(muc),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dangDuocChon
                      ? AppColors.primary.withValues(alpha: 0.22)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dangDuocChon
                          ? AppColors.primary
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      muc.icon,
                      size: 18,
                      color: dangDuocChon ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      muc.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                        dangDuocChon ? FontWeight.w700 : FontWeight.w500,
                        color: dangDuocChon
                            ? AppColors.primary
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  if (dangDuocChon)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onDangXuat,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      size: 18, color: AppColors.danger),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}