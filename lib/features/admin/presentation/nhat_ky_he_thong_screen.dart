import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/admin_logic.dart';

/// Admin — Nhật ký hệ thống (CRUD real-time, chi tiết API).
class NhatKyHeThongScreen extends StatefulWidget {
  const NhatKyHeThongScreen({super.key});

  @override
  State<NhatKyHeThongScreen> createState() => _NhatKyHeThongScreenState();
}

class _NhatKyHeThongScreenState extends State<NhatKyHeThongScreen>
    with TickerProviderStateMixin {
  final _ctrl = NhatKyController();
  late final AnimationController _headerAnim;
  late final AnimationController _listAnim;
  final _searchCtrl = TextEditingController();
  Timer? _liveTimer;
  final Set<int> _expanded = {};

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
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _ctrl.addListener(() {
      if (mounted) setState(() {});
      if (!_ctrl.dangTai) _listAnim.forward(from: 0);
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
    _listAnim.dispose();
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
      case 'PATCH':
        return const Color(0xFFD97706);
      case 'DELETE':
        return const Color(0xFFDC2626);
      default:
        return Colors.blueGrey;
    }
  }

  Color _mauLoai(String loai) {
    switch (loai.toLowerCase()) {
      case 'read':
        return const Color(0xFF2563EB);
      case 'create':
        return const Color(0xFF059669);
      case 'update':
        return const Color(0xFFD97706);
      case 'delete':
        return const Color(0xFFDC2626);
      default:
        return _blue;
    }
  }

  IconData _iconLoai(String loai) {
    switch (loai.toLowerCase()) {
      case 'read':
        return Icons.visibility_rounded;
      case 'create':
        return Icons.add_circle_outline_rounded;
      case 'update':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_outline_rounded;
      default:
        return Icons.api_rounded;
    }
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
    final list = _ctrl.danhSachLoc;

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _blue,
        onRefresh: () => _ctrl.tai(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(
                    parent: _headerAnim, curve: Curves.easeOut),
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
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(28)),
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
                            // Live toggle
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
                                    AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 280),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _ctrl.live
                                            ? const Color(0xFF4ADE80)
                                            : Colors.white54,
                                        shape: BoxShape.circle,
                                        boxShadow: _ctrl.live
                                            ? [
                                          BoxShadow(
                                            color: const Color(0xFF4ADE80)
                                                .withValues(alpha: 0.7),
                                            blurRadius: 8,
                                          )
                                        ]
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _ctrl.live ? 'LIVE' : 'Tạm dừng',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    if (_ctrl.dangTaiNgam) ...[
                                      const SizedBox(width: 6),
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.6,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Theo dõi API real-time · Read / Create / Update / Delete',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Search
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            onChanged: _ctrl.datTuKhoa,
                            onSubmitted: (_) => _ctrl.tai(),
                            decoration: InputDecoration(
                              hintText:
                              'Tìm user, API, field, IP…',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65)),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: Colors.white),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.tune_rounded,
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
                        // Stats
                        Row(
                          children: [
                            _statChip('Read', _ctrl.demLoai('Read'),
                                const Color(0xFF93C5FD)),
                            const SizedBox(width: 8),
                            _statChip('Create', _ctrl.demLoai('Create'),
                                const Color(0xFF6EE7B7)),
                            const SizedBox(width: 8),
                            _statChip('Update', _ctrl.demLoai('Update'),
                                const Color(0xFFFCD34D)),
                            const SizedBox(width: 8),
                            _statChip('Delete', _ctrl.demLoai('Delete'),
                                const Color(0xFFFCA5A5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Filters
            if (!_ctrl.dangTai)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loại thao tác',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip(null, 'Tất cả', _blue, isLoai: true),
                            _filterChip('Read', 'Read', _mauLoai('Read'),
                                isLoai: true),
                            _filterChip('Create', 'Create', _mauLoai('Create'),
                                isLoai: true),
                            _filterChip('Update', 'Update', _mauLoai('Update'),
                                isLoai: true),
                            _filterChip('Delete', 'Delete', _mauLoai('Delete'),
                                isLoai: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('HTTP method',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final m in [null, 'GET', 'POST', 'PUT', 'DELETE'])
                              _filterChip(
                                m,
                                m ?? 'Tất cả',
                                m == null ? _blue : _mauMethod(m),
                                isLoai: false,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
            else if (list.isEmpty)
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final n = list[i];
                        final open = _expanded.contains(n.maNhatKy);
                        final mau = _mauMethod(n.phuongThucHttp);
                        final mauL = _mauLoai(n.loaiLabel);
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 280 + (i % 8) * 40),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, child) => Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, 14 * (1 - t)),
                              child: child,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (open) {
                                  _expanded.remove(n.maNhatKy);
                                } else {
                                  _expanded.add(n.maNhatKy);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border(
                                  left: BorderSide(color: mau, width: 4.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: mau.withValues(alpha: 0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding:
                                const EdgeInsets.fromLTRB(14, 12, 12, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: mau.withValues(alpha: 0.12),
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            n.phuongThucHttp.toUpperCase(),
                                            style: TextStyle(
                                              color: mau,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: mauL.withValues(alpha: 0.12),
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_iconLoai(n.loaiLabel),
                                                  size: 12, color: mauL),
                                              const SizedBox(width: 4),
                                              Text(
                                                n.loaiLabel,
                                                style: TextStyle(
                                                  color: mauL,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (n.statusCode != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (n.statusCode! >= 200 &&
                                                  n.statusCode! < 300)
                                                  ? const Color(0xFFD1FAE5)
                                                  : const Color(0xFFFEE2E2),
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${n.statusCode}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11,
                                                color: (n.statusCode! >= 200 &&
                                                    n.statusCode! < 300)
                                                    ? const Color(0xFF047857)
                                                    : const Color(0xFFB91C1C),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        Text(
                                          _relative(n.thoiGian),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(
                                          open
                                              ? Icons.expand_less_rounded
                                              : Icons.expand_more_rounded,
                                          color: Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      n.tenApi,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        height: 1.3,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor:
                                          _blue.withValues(alpha: 0.12),
                                          child: Text(
                                            n.tenNhanVien.isNotEmpty
                                                ? n.tenNhanVien[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: _blue,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            n.tenNhanVien,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _fmtTime(n.thoiGian),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey.shade600,
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
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              _detailRow(
                                                  Icons.api_rounded,
                                                  'Endpoint',
                                                  n.tenApi),
                                              if ((n.queryString ?? '')
                                                  .isNotEmpty)
                                                _detailRow(
                                                    Icons.filter_alt_outlined,
                                                    'Query',
                                                    n.queryString!),
                                              if ((n.diaChiIp ?? '').isNotEmpty)
                                                _detailRow(Icons.lan_outlined,
                                                    'IP', n.diaChiIp!),
                                              if (n.statusCode != null)
                                                _detailRow(
                                                    Icons.http_rounded,
                                                    'Status',
                                                    '${n.statusCode}'),
                                              _detailRow(
                                                  Icons.category_outlined,
                                                  'Hành động',
                                                  n.loaiLabel),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Chi tiết field / mô tả',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (n.chiTiet != null &&
                                                    n.chiTiet!
                                                        .trim()
                                                        .isNotEmpty)
                                                    ? n.chiTiet!
                                                    : (n.moTa.isNotEmpty
                                                    ? n.moTa
                                                    : 'Không có payload chi tiết (GET hoặc body rỗng).'),
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
                                      duration:
                                      const Duration(milliseconds: 220),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: list.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, int count, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String? value, String label, Color mau,
      {required bool isLoai}) {
    final selected = isLoai
        ? (_ctrl.loaiHanhDong == value)
        : (_ctrl.phuongThuc == value);
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
        onSelected: (_) {
          if (isLoai) {
            _ctrl.datLoaiHanhDong(value);
          } else {
            _ctrl.datPhuongThuc(value);
          }
        },
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
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