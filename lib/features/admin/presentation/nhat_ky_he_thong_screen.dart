import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/admin_logic.dart';
import 'quan_ly_nguoi_dung_screen.dart' show AdminGradientHeader;

/// Admin — Nhật ký hệ thống.
class NhatKyHeThongScreen extends StatefulWidget {
  const NhatKyHeThongScreen({super.key});

  @override
  State<NhatKyHeThongScreen> createState() => _NhatKyHeThongScreenState();
}

class _NhatKyHeThongScreenState extends State<NhatKyHeThongScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = NhatKyController();
  late final AnimationController _anim;
  final _searchCtrl = TextEditingController();

  static const _blue = Color(0xFF0B6BCB);
  static const _bg = Color(0xFFF0F7FC);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _ctrl.addListener(() {
      if (mounted) setState(() {});
      if (!_ctrl.dangTai) _anim.forward(from: 0);
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _anim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _mauMethod(String m) {
    switch (m.toUpperCase()) {
      case 'GET':
        return const Color(0xFF0B6BCB);
      case 'POST':
        return const Color(0xFF059669);
      case 'PUT':
      case 'PATCH':
        return const Color(0xFFD97706);
      case 'DELETE':
        return AppColors.danger;
      default:
        return Colors.grey;
    }
  }

  String _fmtTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _blue,
        onRefresh: _ctrl.tai,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            AdminGradientHeader(
              title: 'Nhật ký hệ thống',
              subtitle: 'Ai gọi API · xem / tạo / cập nhật / xóa',
              searchCtrl: _searchCtrl,
              onSearch: _ctrl.datTuKhoa,
              onSearchSubmit: _ctrl.tai,
              hint: 'Tìm theo tên người / API…',
            ),
            SliverToBoxAdapter(child: _boLocMethod()),
            if (_ctrl.dangTai)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_ctrl.loi != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_ctrl.loi!),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _ctrl.tai, child: const Text('Thử lại')),
                    ],
                  ),
                ),
              )
            else if (_ctrl.danhSach.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('Chưa có nhật ký truy cập',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final n = _ctrl.danhSach[i];
                        final mau = _mauMethod(n.phuongThucHttp);
                        return FadeTransition(
                          opacity: _anim,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 11),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border(
                                  left: BorderSide(color: mau, width: 4.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: _blue.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: mau.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          n.phuongThucHttp.toUpperCase(),
                                          style: TextStyle(
                                              color: mau,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                              letterSpacing: 0.3),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          n.moTa.isNotEmpty ? n.moTa : n.tenApi,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline_rounded,
                                          size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          n.tenNhanVien,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey.shade800),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.tenApi,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule_rounded,
                                          size: 14, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        _fmtTime(n.thoiGian),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                      if (n.diaChiIp != null &&
                                          n.diaChiIp!.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        Icon(Icons.lan_outlined,
                                            size: 14,
                                            color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(n.diaChiIp!,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _ctrl.danhSach.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _boLocMethod() {
    final methods = [null, 'GET', 'POST', 'PUT', 'DELETE'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: methods.map((m) {
            final on = _ctrl.phuongThuc == m;
            final label = m ?? 'Tất cả';
            final mau = m == null ? _blue : _mauMethod(m);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: on,
                label: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: on ? Colors.white : Colors.grey.shade800)),
                selectedColor: mau,
                backgroundColor: Colors.white,
                side: BorderSide(color: on ? mau : Colors.grey.shade300),
                onSelected: (_) => _ctrl.datPhuongThuc(m),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}