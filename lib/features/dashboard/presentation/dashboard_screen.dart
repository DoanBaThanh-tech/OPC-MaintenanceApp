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
            backgroundColor: Colors.white,
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

// ============ NỘI DUNG SLIDE MENU — thiết kế riêng, đồng bộ ngôn ngữ đã chốt ============

class _SlideMenuContent extends StatelessWidget {
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

  String get _tenChuCai =>
      phien.vaiTro.isNotEmpty ? phien.vaiTro[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final nhom in menu) _buildNhom(nhom),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: _SongClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                _tenChuCai,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phien.vaiTro,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'OPC Bảo trì · Sửa chữa cơ điện',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNhom(MenuGroup nhom) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Text(
              nhom.tieuDe.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          for (final muc in nhom.muc) _buildMuc(muc),
        ],
      ),
    );
  }

  Widget _buildMuc(MenuItemData muc) {
    final dangDuocChon = muc.label == dangChon?.label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: dangDuocChon ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChon(muc),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                if (dangDuocChon)
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const SizedBox(width: 3),
                const SizedBox(width: 12),
                Icon(
                  muc.icon,
                  size: 21,
                  color: dangDuocChon ? AppColors.primary : Colors.grey.shade600,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    muc.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: dangDuocChon ? FontWeight.w700 : FontWeight.w500,
                      color: dangDuocChon ? AppColors.primary : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onDangXuat,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Text(
                      'Đăng xuất',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vẽ viền sóng ở đáy header slide menu — đúng ngôn ngữ thiết kế
/// đã chốt (viền sóng thay bo góc thẳng, tạo điểm nhấn bố cục)
class _SongClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 24);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 14);
    path.quadraticBezierTo(size.width * 0.75, size.height - 28, size.width, size.height - 8);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}