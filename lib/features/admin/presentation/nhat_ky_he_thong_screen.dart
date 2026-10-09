import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/admin_logic.dart';

/// Admin — Nhật ký hệ thống: nhóm theo danh mục chức năng, GET/POST/PUT, link API & trạng thái.
class NhatKyHeThongScreen extends StatefulWidget {
  const NhatKyHeThongScreen({super.key});

  @override
  State<NhatKyHeThongScreen> createState() => _NhatKyHeThongScreenState();
}

class _NhatKyHeThongScreenState extends State<NhatKyHeThongScreen>
    with TickerProviderStateMixin {
  final _ctrl = NhatKyController();
  late final AnimationController _headerAnim;
  final _searchCtrl = TextEditingController();
  Timer? _liveTimer;
  final Set<int> _expandedLog = {};
  final Set<String> _collapsedCat = {};

  static const _blue = Color(0xFF0068A9);
  static const _blueMid = Color(0xFF0284C7);
  static const _blueSoft = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFEEF6FB);

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.tai();
    _startLive();
  }

  void _startLive() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_ctrl.live || _ctrl.dangTai) return;
      _ctrl.tai(ngam: true);
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _ctrl.dispose();
    _headerAnim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _mauMethod(String m) {
    switch (m.toUpperCase()) {
      case 'GET':
        return const Color(0xFF2563EB);
      case 'POST':
        return const Color(0xFF059669);
      case 'PUT':
        return const Color(0xFFD97706);
      default:
        return Colors.blueGrey;
    }
  }

  Color _mauStatus(int? code) {
    if (code == null) return Colors.blueGrey;
    if (code >= 200 && code < 300) return const Color(0xFF059669);
    if (code >= 400 && code < 500) return const Color(0xFFD97706);
    if (code >= 500) return const Color(0xFFDC2626);
    return Colors.blueGrey;
  }

  IconData _iconChucNang(String ten) {
    final t = ten.toLowerCase();
    if (t.contains('bảo trì')) return Icons.build_circle_rounded;
    if (t.contains('sửa chữa')) return Icons.handyman_rounded;
    if (t.contains('phân công')) return Icons.groups_rounded;
    if (t.contains('quy trình') || t.contains('bước')) {
      return Icons.account_tree_rounded;
    }
    if (t.contains('vật tư')) return Icons.inventory_2_rounded;
    if (t.contains('kế hoạch')) return Icons.calendar_month_rounded;
    if (t.contains('thiết bị')) return Icons.precision_manufacturing_rounded;
    if (t.contains('phê duyệt')) return Icons.fact_check_rounded;
    if (t.contains('người dùng')) return Icons.manage_accounts_rounded;
    if (t.contains('thống kê')) return Icons.bar_chart_rounded;
    if (t.contains('tài khoản')) return Icons.person_rounded;
    if (t.contains('hệ thống')) return Icons.settings_rounded;
    return Icons.api_rounded;
  }

  String _fmtTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  String _relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 30) return 'vừa xong';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s trước';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final nhom = _ctrl.nhomTheoChucNang;
    final cats = _ctrl.danhSachTenChucNang;

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _blue,
        onRefresh: () => _ctrl.tai(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(top)),
            if (!_ctrl.dangTai) ...[
              // Lọc danh mục chức năng
              if (cats.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danh mục chức năng',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _catChip(null, 'Tất cả', Icons.apps_rounded),
                              for (final c in cats)
                                _catChip(c, c, _iconChucNang(c)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Phương thức',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final m in [null, 'GET', 'POST', 'PUT'])
                                _methodChip(
                                  m,
                                  m ?? 'Tất cả',
                                  m == null ? _blue : _mauMethod(m),
                                ),
                              const SizedBox(width: 6),
                              FilterChip(
                                label: Text(
                                  'Chỉ lỗi API',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: _ctrl.chiLoi
                                        ? Colors.white
                                        : const Color(0xFFB91C1C),
                                  ),
                                ),
                                selected: _ctrl.chiLoi,
                                onSelected: (v) => _ctrl.datChiLoi(v),
                                selectedColor: const Color(0xFFDC2626),
                                backgroundColor: const Color(0xFFFEE2E2),
                                checkmarkColor: Colors.white,
                                side: BorderSide(
                                  color: const Color(0xFFDC2626)
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            if (_ctrl.dangTai)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_ctrl.loi != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_ctrl.loi!,
                          style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: () => _ctrl.tai(),
                          child: const Text('Thử lại')),
                    ],
                  ),
                ),
              )
            else if (nhom.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text('Chưa có nhật ký phù hợp bộ lọc',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final entry = nhom.entries.elementAt(index);
                        return _buildCategoryBlock(
                          entry.key,
                          entry.value,
                          index,
                        );
                      },
                      childCount: nhom.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double top) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: _headerAnim, curve: Curves.easeOutCubic)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, top + 12, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_blue, _blueMid, _blueSoft],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nhật ký hệ thống',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _ctrl.doiLive(!_ctrl.live);
                      if (_ctrl.live) _startLive();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _ctrl.live
                            ? Colors.white.withValues(alpha: 0.22)
                            : Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _ctrl.live
                                  ? const Color(0xFF4ADE80)
                                  : Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _ctrl.live ? 'Live' : 'Tạm dừng',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Nhóm theo chức năng · GET / POST / PUT · link API & trạng thái',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border:
                  Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  onChanged: _ctrl.datTuKhoa,
                  onSubmitted: (_) => _ctrl.tai(),
                  decoration: InputDecoration(
                    hintText: 'Tìm chức năng, link API, user…',
                    hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    prefixIcon:
                    const Icon(Icons.search_rounded, color: Colors.white),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white70),
                      onPressed: () => _ctrl.tai(),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _statChip('GET', _ctrl.demMethod('GET'),
                      const Color(0xFF93C5FD)),
                  const SizedBox(width: 8),
                  _statChip('POST', _ctrl.demMethod('POST'),
                      const Color(0xFF6EE7B7)),
                  const SizedBox(width: 8),
                  _statChip('PUT', _ctrl.demMethod('PUT'),
                      const Color(0xFFFCD34D)),
                  const SizedBox(width: 8),
                  _statChip('Lỗi', _ctrl.demLoi, const Color(0xFFFCA5A5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBlock(
      String tenChucNang, List<NhatKyItem> logs, int index) {
    final collapsed = _collapsedCat.contains(tenChucNang);
    final soLoi = logs.where((e) => e.laLoiApi).length;
    final icon = _iconChucNang(tenChucNang);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index % 6) * 50),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category header
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                onTap: () {
                  setState(() {
                    if (collapsed) {
                      _collapsedCat.remove(tenChucNang);
                    } else {
                      _collapsedCat.add(tenChucNang);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _blue.withValues(alpha: 0.08),
                        _blueSoft.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: collapsed
                        ? BorderRadius.circular(20)
                        : const BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_blue, _blueSoft],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenChucNang,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${logs.length} API call'
                                  '${soLoi > 0 ? ' · $soLoi lỗi' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: soLoi > 0
                                    ? const Color(0xFFDC2626)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: collapsed ? 0 : 0.5,
                        duration: const Duration(milliseconds: 240),
                        child: Icon(Icons.expand_more_rounded,
                            color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                child: Column(
                  children: [
                    for (var i = 0; i < logs.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _buildLogCard(logs[i]),
                    ],
                  ],
                ),
              ),
              crossFadeState: collapsed
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 260),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(NhatKyItem n) {
    final open = _expandedLog.contains(n.maNhatKy);
    final method = n.methodLabel;
    final mau = _mauMethod(method);
    final mauSt = _mauStatus(n.statusCode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            if (open) {
              _expandedLog.remove(n.maNhatKy);
            } else {
              _expandedLog.add(n.maNhatKy);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: n.laLoiApi
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: mau, width: 4),
              top: BorderSide(color: Colors.grey.shade200),
              right: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: mau.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      method,
                      style: TextStyle(
                        color: mau,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (n.statusCode != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: mauSt.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color: mauSt.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${n.statusCode}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: mauSt,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _relative(n.thoiGian),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                n.linkApi,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  height: 1.3,
                  color: Colors.grey.shade800,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: _blue.withValues(alpha: 0.12),
                    child: Text(
                      n.tenNhanVien.isNotEmpty
                          ? n.tenNhanVien[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      n.tenNhanVien,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  if (n.laLoiApi)
                    const Text(
                      'Lỗi',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(Icons.apps_rounded, 'Chức năng',
                            n.tenChucNang),
                        _detailRow(
                            Icons.link_rounded, 'Link API', n.linkApi),
                        _detailRow(Icons.http_rounded, 'Method', method),
                        if (n.statusCode != null)
                          _detailRow(
                            Icons.monitor_heart_outlined,
                            'Trạng thái',
                            '${n.statusCode} · ${n.trangThaiNhan}',
                          ),
                        _detailRow(Icons.schedule_rounded, 'Thời gian',
                            _fmtTime(n.thoiGian)),
                        if ((n.diaChiIp ?? '').isNotEmpty)
                          _detailRow(
                              Icons.lan_outlined, 'IP', n.diaChiIp!),
                        const SizedBox(height: 6),
                        Text(
                          'Người dùng đã làm gì',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (n.chiTiet != null && n.chiTiet!.trim().isNotEmpty)
                              ? n.chiTiet!
                              : (n.moTa.isNotEmpty
                              ? n.moTa
                              : 'Không có payload chi tiết.'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                crossFadeState: open
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 240),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catChip(String? value, String label, IconData icon) {
    final selected = _ctrl.tenChucNang == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        avatar: Icon(icon,
            size: 16, color: selected ? Colors.white : _blue),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: selected ? Colors.white : Colors.grey.shade800,
          ),
        ),
        selectedColor: _blue,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? _blue : Colors.grey.shade300),
        onSelected: (_) => _ctrl.datTenChucNang(value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }

  Widget _methodChip(String? value, String label, Color mau) {
    final selected = _ctrl.phuongThuc == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: selected ? Colors.white : Colors.grey.shade800,
          ),
        ),
        selectedColor: mau,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? mau : Colors.grey.shade300),
        onSelected: (_) => _ctrl.datPhuongThuc(value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }

  Widget _statChip(String label, int count, Color soft) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: soft,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: _blue),
          const SizedBox(width: 6),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}