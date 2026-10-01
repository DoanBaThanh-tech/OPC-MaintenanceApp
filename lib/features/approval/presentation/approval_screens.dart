import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_detail_ui.dart';
import '../../../core/network/api_exception.dart';
import '../data/approval_logic.dart';
import '../../work_order/data/services/work_order_service.dart';
import '../../work_order/data/models/work_order_models.dart';
import '../../work_order/presentation/work_order_repair_screens.dart';

// ═══════════════════════════════════════════════════════════════
// UI chung Giám đốc — xanh chủ đạo, hiện đại, có hiệu ứng
// ═══════════════════════════════════════════════════════════════

class _GdUi {
  static const bg = Color(0xFFF0F7FC);
  static const primary = Color(0xFF0B6BCB);
  static const gradient = LinearGradient(
    colors: [Color(0xFF0B6BCB), Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color mauTrangThai(String tt) {
    switch (tt) {
      case 'Chờ duyệt':
      case 'Chờ GĐ duyệt':
      case 'Chờ gửi':
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

  static Widget header({
    required BuildContext context,
    required String title,
    String? subtitle,
    List<Widget>? actions,
    bool showBack = true,
    IconData icon = Icons.fact_check_rounded,
  }) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(showBack ? 4 : 16, top + 6, 12, 18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            )
          else
            const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18.5,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions,
        ],
      ),
    );
  }

  /// Hàng chip thống kê nhanh (Chờ duyệt / Theo dõi…)
  static Widget summaryChips(List<(String, int, Color)> items) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, count, color) = items[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget sectionLabel(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget listCard({
    required int index,
    required Color accent,
    required String title,
    required List<Widget> lines,
    required VoidCallback onTap,
    Widget? trailing,
    IconData icon = Icons.build_rounded,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index.clamp(0, 8) * 45)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final v = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - v)),
            child: Transform.scale(
              scale: 0.96 + 0.04 * v,
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: accent, width: 4),
                  top: const BorderSide(color: Color(0xFFE2E8F0)),
                  right: const BorderSide(color: Color(0xFFE2E8F0)),
                  bottom: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.18),
                          const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (trailing != null) trailing,
                          ],
                        ),
                        const SizedBox(height: 5),
                        ...lines,
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget emptyState({
    required IconData icon,
    required String message,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
      ],
    );
  }
}

// ============ MÀN 1: DANH SÁCH HỒ SƠ BẢO TRÌ (UI = Hồ sơ BT Xưởng) ============

class ApprovalBaoTriListScreen extends StatefulWidget {
  const ApprovalBaoTriListScreen({super.key});
  @override
  State<ApprovalBaoTriListScreen> createState() =>
      _ApprovalBaoTriListScreenState();
}

class _ApprovalBaoTriListScreenState extends State<ApprovalBaoTriListScreen>
    with TickerProviderStateMixin {
  final _controller = ApprovalBaoTriListController();
  late TabController _tab;
  late AnimationController _headerAnim;

  final _tabs = const [
    'Tất cả',
    'Chờ duyệt',
    'Đang thực hiện',
    'Đã hoàn thành',
    'Từ chối',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.taiDanhSachChoDuyet();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _tab.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  List<HoSoBaoTriDuyet> _locTab(String tab) {
    final all = _controller.danhSach;
    switch (tab) {
      case 'Chờ duyệt':
        return all.where((h) => h.choDuyet).toList();
      case 'Đang thực hiện':
        return all.where((h) => h.dangThucHien).toList();
      case 'Đã hoàn thành':
        return all.where((h) => h.daHoanThanh).toList();
      case 'Từ chối':
        return all.where((h) => h.biTuChoi).toList();
      default:
        return all;
    }
  }

  Color _mau(String tt) => _GdUi.mauTrangThai(tt);

  IconData _icon(String tt) {
    switch (tt) {
      case 'Đã duyệt':
        return Icons.verified_outlined;
      case 'Đang thực hiện':
      case 'Chờ xác nhận':
        return Icons.engineering_outlined;
      case 'Đã hoàn thành':
        return Icons.task_alt_rounded;
      case 'Từ chối':
        return Icons.cancel_outlined;
      case 'Chờ duyệt':
      case 'Chờ GĐ duyệt':
        return Icons.schedule_rounded;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LichSuPheDuyetScreen()),
          );
        },
        backgroundColor: const Color(0xFF0068A9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.history_rounded),
        label: const Text(
          'Lịch sử phê duyệt',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          FadeTransition(
            opacity: _headerAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.12),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOutCubic)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12, top + 10, 12, 0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0068A9),
                      Color(0xFF0284C7),
                      Color(0xFF0EA5E9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0068A9).withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: const Icon(Icons.build_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Duyệt hồ sơ bảo trì',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _controller.dangTai
                                    ? 'Đang tải…'
                                    : '${_locTab('Tất cả').length} hồ sơ'
                                    '${_controller.namLoc != null ? ' · ${_controller.namLoc}' : ''}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          child: PopupMenuButton<int>(
                            tooltip: 'Lọc năm',
                            offset: const Offset(0, 44),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            onSelected: (v) =>
                                _controller.datNamLoc(v == -1 ? null : v),
                            itemBuilder: (ctx) {
                              final nams = _controller.cacNamCoDuLieu;
                              return [
                                const PopupMenuItem(
                                    value: -1, child: Text('Tất cả năm')),
                                ...nams.map((n) => PopupMenuItem(
                                    value: n, child: Text('Năm $n'))),
                              ];
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Badge(
                                isLabelVisible: _controller.namLoc != null,
                                label: Text('${_controller.namLoc}',
                                    style: const TextStyle(fontSize: 9)),
                                child: const Icon(Icons.filter_list_rounded,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _controller.taiDanhSachChoDuyet,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tabs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final selected = _tab.index == i;
                          final count = _locTab(_tabs[i]).length;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _tab.animateTo(i));
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.25),
                                ),
                                boxShadow: selected
                                    ? [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _tabs[i],
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF0369A1)
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF0EA5E9)
                                          .withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFF0369A1)
                                            : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.dangTai) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                  color: Color(0xFF0068A9), strokeWidth: 3),
            ),
            SizedBox(height: 14),
            Text('Đang tải hồ sơ…',
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (_controller.loi != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_controller.loi!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _controller.taiDanhSachChoDuyet,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0068A9)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tab,
      children: _tabs.map((tab) {
        final list = _locTab(tab);
        if (list.isEmpty) {
          return RefreshIndicator(
            color: const Color(0xFF0068A9),
            onRefresh: _controller.taiDanhSachChoDuyet,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) => Transform.scale(
                    scale: 0.7 + 0.3 * t,
                    child: Opacity(opacity: t, child: child),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE8F4FC),
                              const Color(0xFF0068A9).withValues(alpha: 0.12),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inbox_outlined,
                            size: 48, color: Color(0xFF0068A9)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có hồ sơ · $tab',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF0068A9),
          onRefresh: _controller.taiDanhSachChoDuyet,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final hs = list[i];
              final mau = _mau(hs.trangThai);
              return _GdHsCard(
                index: i,
                tenThietBi: hs.tenThietBi,
                maHoSo: hs.maHoSoBaoTri,
                ngayTao: _fmt(hs.ngayTao),
                ngayDuKien: hs.ngayDuKienBaoTri != null
                    ? _fmt(hs.ngayDuKienBaoTri!)
                    : null,
                noiDung: hs.noiDungCongViec,
                subLine:
                'Người lập: ${hs.tenNguoiLap ?? '—'} · KH ${hs.nam}${hs.namTuKeHoach ? '' : ' · đột xuất'}',
                trangThai: hs.trangThai,
                mau: mau,
                icon: _icon(hs.trangThai),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final changed = await Navigator.push<bool>(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 320),
                      pageBuilder: (_, a, __) => ApprovalBaoTriDetailScreen(
                          maHoSoBaoTri: hs.maHoSoBaoTri),
                      transitionsBuilder: (_, a, __, child) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: a, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      ),
                    ),
                  );
                  if (changed == true) _controller.taiDanhSachChoDuyet();
                },
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

/// Thẻ hồ sơ — copy hiệu ứng _HsCard trang Hồ sơ bảo trì Xưởng.
class _GdHsCard extends StatefulWidget {
  final int index;
  final String tenThietBi;
  final int maHoSo;
  final String ngayTao;
  final String? ngayDuKien;
  final String? noiDung;
  final String subLine;
  final String trangThai;
  final Color mau;
  final IconData icon;
  final VoidCallback onTap;

  const _GdHsCard({
    required this.index,
    required this.tenThietBi,
    required this.maHoSo,
    required this.ngayTao,
    this.ngayDuKien,
    this.noiDung,
    required this.subLine,
    required this.trangThai,
    required this.mau,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GdHsCard> createState() => _GdHsCardState();
}

class _GdHsCardState extends State<_GdHsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _enter;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 320 + (widget.index.clamp(0, 8) * 45)),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_enter.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - t)),
            child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              transform: Matrix4.identity()..scale(_pressed ? 0.985 : 1.0),
              transformAlignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: widget.mau, width: 4),
                  top: const BorderSide(color: Color(0xFFE2E8F0)),
                  right: const BorderSide(color: Color(0xFFE2E8F0)),
                  bottom: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.mau.withValues(alpha: _pressed ? 0.06 : 0.1),
                    blurRadius: _pressed ? 8 : 14,
                    offset: Offset(0, _pressed ? 2 : 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.mau.withValues(alpha: 0.18),
                              const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: widget.mau, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tenThietBi,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'HS #${widget.maHoSo} · ${widget.ngayTao}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.mau.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: widget.mau.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          widget.trangThai,
                          style: TextStyle(
                            color: widget.mau,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.ngayDuKien != null)
                          Row(
                            children: [
                              const Icon(Icons.event_available_rounded,
                                  size: 15, color: Color(0xFF0068A9)),
                              const SizedBox(width: 6),
                              Text(
                                'Dự kiến: ${widget.ngayDuKien}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        if (widget.ngayDuKien != null) const SizedBox(height: 6),
                        Text(
                          widget.subLine,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (widget.noiDung != null &&
                            widget.noiDung!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.noiDung!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
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
}

// ============ MÀN 2: CHI TIẾT + PHÊ DUYỆT / TỪ CHỐI ============

class ApprovalBaoTriDetailScreen extends StatefulWidget {
  final int maHoSoBaoTri;
  const ApprovalBaoTriDetailScreen({super.key, required this.maHoSoBaoTri});
  @override
  State<ApprovalBaoTriDetailScreen> createState() => _ApprovalBaoTriDetailScreenState();
}

class _ApprovalBaoTriDetailScreenState extends State<ApprovalBaoTriDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFF0F6FB);
  static const _primary = Color(0xFF0068A9);

  late final ApprovalBaoTriDetailController _controller;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _controller = ApprovalBaoTriDetailController(widget.maHoSoBaoTri);
    _controller.taiChiTiet();
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtThoiGianDuKien(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final v = raw.trim();
    if (v.toLowerCase().endsWith('p')) {
      return '${v.substring(0, v.length - 1)} phút';
    }
    if (v.contains('giờ') || v.contains('phút')) return v;
    return '$v giờ';
  }

  Color _mauTrangThai(String tt) {
    switch (tt) {
      case 'Chờ duyệt':
      case 'Chờ GĐ duyệt':
        return AppColors.warning;
      case 'Đã duyệt':
        return const Color(0xFF0284C7);
      case 'Đang thực hiện':
      case 'Chờ xác nhận':
        return AppColors.primary;
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _duyet() async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận phê duyệt'),
        content:
        const Text('Bạn chắc chắn muốn phê duyệt hồ sơ bảo trì này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Phê duyệt'),
          ),
        ],
      ),
    );
    if (xacNhan != true) return;

    final ok = await _controller.xuLy(quyetDinh: 'Duyệt');
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<void> _tuChoi() async {
    final lyDoController = TextEditingController();
    final lyDo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Từ chối hồ sơ'),
        content: TextField(
          controller: lyDoController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            border: OutlineInputBorder(),
            hintText: 'VD: Nội dung công việc chưa rõ ràng...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, lyDoController.text.trim()),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (lyDo == null || lyDo.isEmpty) return;

    final ok = await _controller.xuLy(quyetDinh: 'Từ chối', lyDo: lyDo);
    if (ok && mounted) Navigator.pop(context, true);
  }

  Widget _headerBar({
    required double top,
    required String title,
    String? subtitle,
  }) =>
      ModernDetailUi.headerBar(
        context: context,
        topPadding: top,
        title: title,
        subtitle: subtitle,
      );

  Widget _softCard({required Widget child}) =>
      ModernDetailUi.softCard(child: child);

  Widget _row(String nhan, String giaTri) =>
      ModernDetailUi.infoRow(nhan, giaTri);

  Widget _fadeSlide({required int delayMs, required Widget child}) =>
      ModernDetailUi.fadeSlide(delayMs: delayMs, child: child);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.dangTai) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: CircularProgressIndicator(color: _primary, strokeWidth: 3),
            ),
          );
        }
        if (_controller.hoSo == null) {
          return Scaffold(
            backgroundColor: _bg,
            body: Column(
              children: [
                _headerBar(top: top, title: 'Chi tiết hồ sơ BT'),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_controller.loi ?? 'Không tải được hồ sơ'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _controller.taiChiTiet,
                          style: FilledButton.styleFrom(
                              backgroundColor: _primary),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final hs = _controller.hoSo!;
        final mauTt = _mauTrangThai(hs.trangThai);

        return Scaffold(
          backgroundColor: _bg,
          body: Column(
            children: [
              _headerBar(
                top: top,
                title: 'Hồ sơ BT #${hs.maHoSoBaoTri}',
                subtitle: hs.trangThai,
              ),
              Expanded(
                child: FadeTransition(
                  opacity:
                  CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      // Hero — đồng bộ ModernDetailUi
                      _fadeSlide(
                        delayMs: 0,
                        child: ModernDetailUi.heroCard(
                          icon: Icons.precision_manufacturing_rounded,
                          title: hs.tenThietBi,
                          statusLabel: hs.trangThai,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Thông tin
                      _fadeSlide(
                        delayMs: 60,
                        child: _softCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 18,
                                      color: _primary.withValues(alpha: 0.95)),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Thông tin hồ sơ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: mauTt.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      hs.trangThai,
                                      style: TextStyle(
                                        color: mauTt,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _row('Người lập', hs.tenNguoiLap ?? '—'),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row('Ngày tạo', _fmt(hs.ngayTao)),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row(
                                  'Ngày dự kiến BT',
                                  _fmt(hs.ngayDuKienBaoTri)),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row(
                                'Thời gian dự kiến',
                                _fmtThoiGianDuKien(hs.thoiGianDuKien),
                              ),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row('Giờ bắt đầu', hs.gioBatDauDuKien ?? '—'),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row('Giờ kết thúc', hs.gioKetThucDuKien ?? '—'),
                              if (hs.nam > 0) ...[
                                Divider(height: 1, color: Colors.grey.shade200),
                                _row(
                                  'Kế hoạch năm',
                                  '${hs.nam}${hs.namTuKeHoach ? '' : ' (đột xuất)'}',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nội dung CV
                      _fadeSlide(
                        delayMs: 120,
                        child: _softCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.description_outlined,
                                      size: 18, color: _primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Nội dung công việc',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                hs.noiDungCongViec ?? '—',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (hs.lyDoTuChoi != null &&
                          hs.lyDoTuChoi!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _fadeSlide(
                          delayMs: 150,
                          child: _softCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.report_outlined,
                                        size: 18, color: AppColors.danger),
                                    SizedBox(width: 8),
                                    Text(
                                      'Lý do từ chối',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hs.lyDoTuChoi!,
                                  style: const TextStyle(
                                    height: 1.4,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (_controller.loi != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _controller.loi!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // Hành động
                      _fadeSlide(
                        delayMs: 180,
                        child: hs.choDuyet
                            ? (_controller.dangXuLy
                            ? const Center(
                          child: CircularProgressIndicator(
                              color: _primary),
                        )
                            : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(
                                      color: AppColors.danger),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.close_rounded),
                                label: const Text('Từ chối'),
                                onPressed: _tuChoi,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF15803D),
                                      Color(0xFF22C55E),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                    onTap: _duyet,
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Phê duyệt',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                            FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ))
                            : Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: mauTt.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: mauTt.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hs.daHoanThanh
                                    ? Icons.verified_rounded
                                    : hs.biTuChoi
                                    ? Icons.cancel_outlined
                                    : Icons.timeline_rounded,
                                color: mauTt,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  hs.daHoanThanh
                                      ? 'Hồ sơ đã hoàn thành — chỉ theo dõi, không cần duyệt lại.'
                                      : hs.biTuChoi
                                      ? 'Hồ sơ đã từ chối — chỉ xem lại.'
                                      : 'Hồ sơ đang ở trạng thái «${hs.trangThai}» — theo dõi tiến độ.',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade800,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
// ============ LỊCH SỬ PHÊ DUYỆT (Giám đốc) — chỉ Bảo trì ============

class LichSuPheDuyetScreen extends StatefulWidget {
  const LichSuPheDuyetScreen({super.key});

  @override
  State<LichSuPheDuyetScreen> createState() => _LichSuPheDuyetScreenState();
}

class _LichSuPheDuyetScreenState extends State<LichSuPheDuyetScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = LichSuPheDuyetController();
  late final AnimationController _headerAnim;
  int _filter = 0; // 0 tất cả · 1 đã duyệt · 2 từ chối

  static const _filters = ['Tất cả', 'Đã duyệt', 'Từ chối'];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _ctrl.tabLoai = 'Bảo trì';
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String _fmtNgay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtGio(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  List<LichSuPheDuyetItem> get _list {
    final all = _ctrl.danhSach;
    if (_filter == 1) return all.where((e) => e.daDuyet).toList();
    if (_filter == 2) return all.where((e) => e.tuChoi).toList();
    return all;
  }

  int _count(int i) {
    final all = _ctrl.danhSach;
    if (i == 1) return all.where((e) => e.daDuyet).length;
    if (i == 2) return all.where((e) => e.tuChoi).length;
    return all.length;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: Column(
        children: [
          FadeTransition(
            opacity: _headerAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.12),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOutCubic)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12, top + 8, 12, 0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0068A9),
                      Color(0xFF0284C7),
                      Color(0xFF0EA5E9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0068A9).withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: const Icon(Icons.history_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lịch sử phê duyệt',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _ctrl.dangTai
                                    ? 'Đang tải…'
                                    : '${_ctrl.danhSach.length} bản ghi bảo trì'
                                    '${_ctrl.namLoc != null ? ' · ${_ctrl.namLoc}' : ''}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _ctrl.tai,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Chip: Tất cả / Đã duyệt / Từ chối
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final selected = _filter == i;
                          return GestureDetector(
                            onTap: () => setState(() => _filter = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _filters[i],
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF0369A1)
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_count(i)}',
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF0369A1)
                                          : Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Lọc năm
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _yearChip('Tất cả năm', null),
                          ..._ctrl.cacNam.map((y) => _yearChip('$y', y)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _yearChip(String label, int? value) {
    final selected = _ctrl.namLoc == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _ctrl.datNam(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF0369A1) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_ctrl.dangTai) {
      return const Center(
        child: CircularProgressIndicator(
            color: Color(0xFF0068A9), strokeWidth: 3),
      );
    }
    if (_ctrl.loi != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_ctrl.loi!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _ctrl.tai,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0068A9)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final list = _list;
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _ctrl.tai,
        color: const Color(0xFF0068A9),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            const Icon(Icons.history_toggle_off_rounded,
                size: 56, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'Chưa có lịch sử · ${_filters[_filter]}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    // Nhóm: Đã duyệt trước, Từ chối sau (khi xem Tất cả)
    final daDuyet = list.where((e) => e.daDuyet).toList();
    final tuChoi = list.where((e) => e.tuChoi).toList();

    return RefreshIndicator(
      onRefresh: _ctrl.tai,
      color: const Color(0xFF0068A9),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          if (_filter == 0 || _filter == 1) ...[
            if (daDuyet.isNotEmpty) ...[
              _sectionHeader(
                'Đã duyệt',
                daDuyet.length,
                const Color(0xFF0B6BCB),
                Icons.verified_rounded,
              ),
              ...daDuyet.asMap().entries.map(
                    (e) => _LichSuCard(
                  item: e.value,
                  index: e.key,
                  fmtNgay: _fmtNgay,
                  fmtGio: _fmtGio,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (_filter == 0 || _filter == 2) ...[
            if (tuChoi.isNotEmpty) ...[
              _sectionHeader(
                'Từ chối',
                tuChoi.length,
                const Color(0xFFDC2626),
                Icons.cancel_rounded,
              ),
              ...tuChoi.asMap().entries.map(
                    (e) => _LichSuCard(
                  item: e.value,
                  index: e.key,
                  fmtNgay: _fmtNgay,
                  fmtGio: _fmtGio,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(
      String title, int count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LichSuCard extends StatelessWidget {
  final LichSuPheDuyetItem item;
  final int index;
  final String Function(DateTime) fmtNgay;
  final String Function(DateTime) fmtGio;

  const _LichSuCard({
    required this.item,
    required this.index,
    required this.fmtNgay,
    required this.fmtGio,
  });

  @override
  Widget build(BuildContext context) {
    final daDuyet = item.daDuyet;
    // Nền trung tính — chỉ badge màu trạng thái (không tô cả thẻ)
    final badgeColor =
    daDuyet ? const Color(0xFF0B6BCB) : const Color(0xFFDC2626);
    final nhan = daDuyet ? 'Đã duyệt' : 'Từ chối';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index % 6) * 40),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.tenThietBi ??
                                    'Hồ sơ #${item.maHoSo ?? '—'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                nhan,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'HS #${item.maHoSo ?? '—'} · ${fmtNgay(item.ngayDuyet)} ${fmtGio(item.ngayDuyet)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Người lập: ${item.tenNguoiLap ?? '—'}  ·  Duyệt: ${item.tenNguoiDuyet ?? '—'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (item.tuChoi &&
                            item.lyDo != null &&
                            item.lyDo!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Lý do: ${item.lyDo}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF334155),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ],
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
}

class ApprovalSuaChuaListScreen extends StatefulWidget {
  const ApprovalSuaChuaListScreen({super.key});

  @override
  State<ApprovalSuaChuaListScreen> createState() =>
      _ApprovalSuaChuaListScreenState();
}

class _ApprovalSuaChuaListScreenState extends State<ApprovalSuaChuaListScreen>
    with TickerProviderStateMixin {
  List<HoSoSuaChua> _list = [];
  bool _dangTai = true;
  String? _loi;
  late TabController _tab;
  late AnimationController _headerAnim;

  final _tabs = const [
    'Tất cả',
    'Chờ duyệt',
    'Đang thực hiện',
    'Đã hoàn thành',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _tai();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final all = await WorkOrderService.layDanhSachHoSoSuaChua();
      final list = all
          .where((h) =>
      h.trangThai == 'Chờ duyệt' ||
          h.trangThai == 'Đã duyệt' ||
          h.trangThai == 'Đang thực hiện' ||
          h.trangThai == 'Chờ xác nhận' ||
          h.trangThai == 'Đã hoàn thành' ||
          h.trangThai == 'Từ chối')
          .toList()
        ..sort((a, b) {
          int rank(String tt) {
            switch (tt) {
              case 'Chờ duyệt':
                return 0;
              case 'Đang thực hiện':
              case 'Chờ xác nhận':
                return 1;
              case 'Đã duyệt':
                return 2;
              case 'Đã hoàn thành':
                return 3;
              case 'Từ chối':
                return 4;
              default:
                return 5;
            }
          }

          final r = rank(a.trangThai).compareTo(rank(b.trangThai));
          if (r != 0) return r;
          return b.ngayTao.compareTo(a.ngayTao);
        });
      if (!mounted) return;
      setState(() {
        _list = list;
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e is ApiException ? e.message : '$e';
        _dangTai = false;
        _list = [];
      });
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  List<HoSoSuaChua> _locTab(String tab) {
    switch (tab) {
      case 'Chờ duyệt':
        return _list.where((h) => h.trangThai == 'Chờ duyệt').toList();
      case 'Đang thực hiện':
        return _list
            .where((h) =>
        h.trangThai == 'Đang thực hiện' ||
            h.trangThai == 'Chờ xác nhận')
            .toList();
      case 'Đã hoàn thành':
        return _list.where((h) => h.trangThai == 'Đã hoàn thành').toList();
      default:
        return _list;
    }
  }

  Color _mau(String tt) => _GdUi.mauTrangThai(tt);

  IconData _icon(String tt) {
    switch (tt) {
      case 'Đã duyệt':
        return Icons.verified_outlined;
      case 'Đang thực hiện':
      case 'Chờ xác nhận':
        return Icons.engineering_outlined;
      case 'Đã hoàn thành':
        return Icons.task_alt_rounded;
      case 'Từ chối':
        return Icons.cancel_outlined;
      case 'Chờ duyệt':
        return Icons.schedule_rounded;
      default:
        return Icons.handyman_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: Column(
        children: [
          FadeTransition(
            opacity: _headerAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.12),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOutCubic)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12, top + 10, 12, 0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0068A9),
                      Color(0xFF0284C7),
                      Color(0xFF0EA5E9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0068A9).withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: const Icon(Icons.handyman_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Duyệt hồ sơ sửa chữa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _dangTai
                                    ? 'Đang tải…'
                                    : '${_list.length} hồ sơ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _tai,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tabs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final selected = _tab.index == i;
                          final count = _locTab(_tabs[i]).length;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _tab.animateTo(i));
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.25),
                                ),
                                boxShadow: selected
                                    ? [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _tabs[i],
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF0369A1)
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF0EA5E9)
                                          .withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFF0369A1)
                                            : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_dangTai) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                  color: Color(0xFF0068A9), strokeWidth: 3),
            ),
            SizedBox(height: 14),
            Text('Đang tải hồ sơ…',
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (_loi != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loi!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _tai,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0068A9)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tab,
      children: _tabs.map((tab) {
        final list = _locTab(tab);
        if (list.isEmpty) {
          return RefreshIndicator(
            color: const Color(0xFF0068A9),
            onRefresh: _tai,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) => Transform.scale(
                    scale: 0.7 + 0.3 * t,
                    child: Opacity(opacity: t, child: child),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE8F4FC),
                              const Color(0xFF0068A9).withValues(alpha: 0.12),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handyman_outlined,
                            size: 48, color: Color(0xFF0068A9)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có hồ sơ · $tab',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF0068A9),
          onRefresh: _tai,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final hs = list[i];
              final mau = _mau(hs.trangThai);
              return _GdHsCard(
                index: i,
                tenThietBi: hs.tenThietBi,
                maHoSo: hs.maHoSoSuaChua,
                ngayTao: _fmt(hs.ngayTao),
                ngayDuKien: null,
                noiDung: hs.moTaHuHong,
                subLine: 'Người lập: ${hs.tenNhanVienTao ?? '—'}',
                trangThai: hs.trangThai,
                mau: mau,
                icon: _icon(hs.trangThai),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 320),
                      pageBuilder: (_, a, __) =>
                          ChiTietHoSoSuaChuaScreen(maHoSo: hs.maHoSoSuaChua),
                      transitionsBuilder: (_, a, __, child) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: a, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      ),
                    ),
                  );
                  _tai();
                },
              );
            },
          ),
        );
      }).toList(),
    );
  }
}