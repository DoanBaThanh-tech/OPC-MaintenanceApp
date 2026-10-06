import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/admin_logic.dart';

/// Admin — Nhật ký hệ thống: ai gọi API nào, làm gì (xem / tạo / cập nhật / xóa).
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

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
      backgroundColor: const Color(0xFFF0F7FC),
      body: RefreshIndicator(
        color: _blue,
        onRefresh: _ctrl.tai,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _boLocMethod()),
            if (_ctrl.dangTai)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_ctrl.loi != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_ctrl.loi!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _ctrl.tai,
                            child: const Text('Thử lại')),
                      ],
                    ),
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
                SliiverListNhatKy(
                  items: _ctrl.danhSach,
                  anim: _anim,
                  mauMethod: _mauMethod,
                  fmtTime: _fmtTime,
                ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B6BCB), Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhật ký hệ thống',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'Ai gọi API nào · xem / tạo / cập nhật / xóa gì',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onSubmitted: (v) {
              _ctrl.datTuKhoa(v);
              _ctrl.tai();
            },
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên người / API…',
              hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              prefixIcon: Icon(Icons.search,
                  color: Colors.white.withValues(alpha: 0.9)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  _ctrl.datTuKhoa(_searchCtrl.text);
                  _ctrl.tai();
                },
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boLocMethod() {
    final methods = [null, 'GET', 'POST', 'PUT', 'DELETE'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: methods.map((m) {
            final on = _ctrl.phuongThuc == m;
            final label = m ?? 'Tất cả';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: on,
                label: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: on ? Colors.white : Colors.grey.shade800)),
                selectedColor: m == null ? _blue : _mauMethod(m),
                backgroundColor: Colors.white,
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

class SliiverListNhatKy extends StatelessWidget {
  final List<NhatKyItem> items;
  final AnimationController anim;
  final Color Function(String) mauMethod;
  final String Function(DateTime) fmtTime;

  const SliiverListNhatKy({
    super.key,
    required this.items,
    required this.anim,
    required this.mauMethod,
    required this.fmtTime,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, i) {
            final n = items[i];
            final mau = mauMethod(n.phuongThucHttp);
            return FadeTransition(
              opacity: anim,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(color: mau, width: 4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B6BCB).withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: mau.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              n.phuongThucHttp.toUpperCase(),
                              style: TextStyle(
                                  color: mau,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              n.moTa.isNotEmpty ? n.moTa : n.tenApi,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
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
                            fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            fmtTime(n.thoiGian),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          if (n.diaChiIp != null && n.diaChiIp!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.lan_outlined,
                                size: 14, color: Colors.grey.shade500),
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
          childCount: items.length,
        ),
      ),
    );
  }
}