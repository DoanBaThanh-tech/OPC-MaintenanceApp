import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/thong_ke_giam_doc_logic.dart';

/// Thống kê sơ đồ cho Giám đốc: BT/SC theo tháng + vật tư & chi phí.
class ThongKeGiamDocScreen extends StatefulWidget {
  const ThongKeGiamDocScreen({super.key});

  @override
  State<ThongKeGiamDocScreen> createState() => _ThongKeGiamDocScreenState();
}

class _ThongKeGiamDocScreenState extends State<ThongKeGiamDocScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = ThongKeGiamDocController();
  late final AnimationController _anim;

  static const _blue = Color(0xFF0B6BCB);
  static const _blueSoft = Color(0xFF38BDF8);
  static const _orange = Color(0xFFF59E0B);
  static const _green = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ctrl.addListener(() {
      if (mounted) setState(() {});
      if (!_ctrl.dangTai && _ctrl.data != null) _anim.forward(from: 0);
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  String _fmtTien(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf ₫';
  }

  @override
  Widget build(BuildContext context) {
    final d = _ctrl.data;
    return Container(
      color: const Color(0xFFF0F7FC),
      child: RefreshIndicator(
        color: _blue,
        onRefresh: () => _ctrl.tai(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            if (_ctrl.dangTai)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_ctrl.loi != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 40),
                        const SizedBox(height: 12),
                        Text(_ctrl.loi!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: () => _ctrl.tai(),
                            child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                ),
              )
            else if (d != null) ...[
                SliiverPad(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _tongQuan(d),
                ),
                SliiverPad(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _cardBieuDo(
                    title: 'Thiết bị bảo trì & sửa chữa theo tháng',
                    subtitle: 'Số hồ sơ theo tháng năm ${d.nam}',
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (_, __) => _BarChartBtSc(
                        data: d.theoThang,
                        progress: Curves.easeOutCubic.transform(_anim.value),
                      ),
                    ),
                  ),
                ),
                SliiverPad(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _cardBieuDo(
                    title: 'Vật tư sử dụng theo tháng',
                    subtitle: 'Số lượng vật tư · Chi phí (₫)',
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (_, __) => _BarChartVatTu(
                        data: d.theoThang,
                        progress: Curves.easeOutCubic.transform(_anim.value),
                        fmtTien: _fmtTien,
                      ),
                    ),
                  ),
                ),
                SliiverPad(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: _bangChiTiet(d),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, 16 + MediaQuery.paddingOf(context).top * 0.15, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B6BCB), Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê tổng quan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bảo trì · Sửa chữa · Vật tư theo tháng',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: years.contains(_ctrl.nam) ? _ctrl.nam : years.last,
                dropdownColor: _blue,
                iconEnabledColor: Colors.white,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800),
                items: years
                    .map((y) => DropdownMenuItem(
                  value: y,
                  child: Text('Năm $y'),
                ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _ctrl.doiNam(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tongQuan(ThongKeGiamDocData d) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                icon: Icons.build_circle_rounded,
                label: 'Bảo trì',
                value: '${d.tongBaoTri}',
                sub: 'HT: ${d.tongBaoTriHoanThanh}',
                color: _blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                icon: Icons.handyman_rounded,
                label: 'Sửa chữa',
                value: '${d.tongSuaChua}',
                sub: 'HT: ${d.tongSuaChuaHoanThanh}',
                color: _orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                icon: Icons.inventory_2_rounded,
                label: 'Vật tư (SL)',
                value: '${d.tongSoLuongVatTu}',
                sub: 'Cả năm ${d.nam}',
                color: _green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                icon: Icons.payments_rounded,
                label: 'Chi phí VT',
                value: _fmtTien(d.tongTienVatTu),
                sub: 'Cả năm ${d.nam}',
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: value.length > 12 ? 15 : 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _cardBieuDo({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _bangChiTiet(ThongKeGiamDocData d) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text('Chi tiết theo tháng',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
              WidgetStatePropertyAll(const Color(0xFF0B6BCB).withValues(alpha: 0.08)),
              columns: const [
                DataColumn(label: Text('Th')),
                DataColumn(label: Text('BT')),
                DataColumn(label: Text('SC')),
                DataColumn(label: Text('SL VT')),
                DataColumn(label: Text('Tiền VT')),
              ],
              rows: d.theoThang.map((t) {
                return DataRow(cells: [
                  DataCell(Text('T${t.thang}',
                      style: const TextStyle(fontWeight: FontWeight.w800))),
                  DataCell(Text('${t.soBaoTri}')),
                  DataCell(Text('${t.soSuaChua}')),
                  DataCell(Text('${t.soLuongVatTu}')),
                  DataCell(Text(_fmtTien(t.tongTienVatTu))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class SliiverPad extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;
  const SliiverPad({super.key, required this.padding, required this.child});
  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: padding,
    sliver: SliverToBoxAdapter(child: child),
  );
}

/// Biểu đồ cột kép: Bảo trì (xanh) + Sửa chữa (cam)
class _BarChartBtSc extends StatelessWidget {
  final List<ThongKeThang> data;
  final double progress;
  const _BarChartBtSc({required this.data, required this.progress});

  @override
  Widget build(BuildContext context) {
    final maxV = data
        .map((e) => e.soBaoTri > e.soSuaChua ? e.soBaoTri : e.soSuaChua)
        .fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((t) {
              final hBt = (t.soBaoTri / maxV) * 150 * progress;
              final hSc = (t.soSuaChua / maxV) * 150 * progress;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Tooltip(
                              message: 'BT: ${t.soBaoTri}',
                              child: Container(
                                height: hBt.clamp(0, 150),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0B6BCB),
                                      Color(0xFF38BDF8)
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Tooltip(
                              message: 'SC: ${t.soSuaChua}',
                              child: Container(
                                height: hSc.clamp(0, 150),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFD97706),
                                      Color(0xFFFBBF24)
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('T${t.thang}',
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(const Color(0xFF0B6BCB), 'Bảo trì'),
            const SizedBox(width: 16),
            _legend(const Color(0xFFD97706), 'Sửa chữa'),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color c, String t) => Row(
    children: [
      Container(
          width: 12,
          height: 12,
          decoration:
          BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ],
  );
}

/// Biểu đồ cột: số lượng VT + hiển thị tiền dưới dạng chú thích
class _BarChartVatTu extends StatelessWidget {
  final List<ThongKeThang> data;
  final double progress;
  final String Function(int) fmtTien;
  const _BarChartVatTu({
    required this.data,
    required this.progress,
    required this.fmtTien,
  });

  @override
  Widget build(BuildContext context) {
    final maxSl =
    data.map((e) => e.soLuongVatTu).fold<int>(1, (a, b) => a > b ? a : b);
    final maxTien =
    data.map((e) => e.tongTienVatTu).fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((t) {
              final hSl = (t.soLuongVatTu / maxSl) * 150 * progress;
              final hTien = (t.tongTienVatTu / maxTien) * 150 * progress;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Tooltip(
                              message: 'SL: ${t.soLuongVatTu}',
                              child: Container(
                                height: hSl.clamp(0, 150),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Tooltip(
                              message: fmtTien(t.tongTienVatTu),
                              child: Container(
                                height: hTien.clamp(0, 150),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('T${t.thang}',
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(const Color(0xFF059669), 'Số lượng VT'),
            const SizedBox(width: 16),
            _legend(const Color(0xFF7C3AED), 'Chi phí VT'),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color c, String t) => Row(
    children: [
      Container(
          width: 12,
          height: 12,
          decoration:
          BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ],
  );
}