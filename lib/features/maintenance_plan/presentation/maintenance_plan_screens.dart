import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../data/maintenance_plan_logic.dart';
import 'hang_cho_bao_tri_screen.dart';

const _tenThangNgan = [
  '', 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12',
];
const _tenThang = [
  '',
  'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
  'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
];

// ============ MÀN 1: LỊCH 12 THÁNG (dạng cuốn lịch) ============

class MaintenancePlanListScreen extends StatefulWidget {
  const MaintenancePlanListScreen({super.key});
  @override
  State<MaintenancePlanListScreen> createState() => _MaintenancePlanListScreenState();
}

class _MaintenancePlanListScreenState extends State<MaintenancePlanListScreen> {
  final _controller = MaintenancePlanListController();

  @override
  void initState() {
    super.initState();
    _controller.taiDanhSach();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _moMenuTaoKeHoach() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Lập kế hoạch', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _MenuOption(
                icon: Icons.playlist_add_check_rounded,
                color: AppColors.primary,
                title: 'Lập kế hoạch',
                subtitle: 'Thiết bị đến hạn / trễ hạn — tạo hồ sơ gửi xưởng',
                onTap: () => Navigator.pop(ctx, 'hangCho'),
              ),
              const SizedBox(height: 10),
              _MenuOption(
                icon: Icons.calendar_month_rounded,
                color: AppColors.success,
                title: 'Lập kế hoạch theo năm',
                subtitle: 'Tạo khung kế hoạch trống cho 1 năm mới',
                onTap: () => Navigator.pop(ctx, 'namMoi'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action == 'namMoi') {
      // Dialog nhỏ — không mở full page (tiết kiệm giao diện / dung lượng)
      final namMoi = await showDialogLapKeHoachNam(
        context,
        namDaCo: List<int>.from(_controller.danhSachNam),
      );
      if (namMoi != null && mounted) {
        await _controller.sauKhiTaoNam(namMoi);
      }
    } else if (action == 'hangCho') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HangChoBaoTriScreen(namBanDau: _controller.namDangChon),
        ),
      );
      if (mounted) await _controller.taiDanhSach();
    }
  }

  void _moChiTietThang(int thang) {
    final mucs = _controller.mucTrongThang(thang);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceMonthDetailScreen(
          nam: _controller.namDangChon,
          thang: thang,
          mucBanDau: mucs,
        ),
      ),
    ).then((_) {
      _controller.taiDanhSach();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FC),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0B6BCB), Color(0xFF0284C7)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B6BCB).withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          onPressed: _moMenuTaoKeHoach,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Lập kế hoạch',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0B6BCB)),
            );
          }
          if (_controller.loi != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(_controller.loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _controller.taiDanhSach,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final nam = _controller.namDangChon;
          final nams = _controller.danhSachNam;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0B6BCB),
                        Color(0xFF0284C7),
                        Color(0xFF0EA5E9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B6BCB).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kế hoạch bảo trì',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Lịch 12 tháng · chạm tháng để xem chi tiết',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: nams.contains(nam)
                                    ? nam
                                    : (nams.isEmpty ? nam : nams.last),
                                icon: const Icon(
                                  Icons.expand_more_rounded,
                                  color: Color(0xFF0B6BCB),
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                items: nams
                                    .map(
                                      (n) => DropdownMenuItem(
                                    value: n,
                                    child: Text('$n'),
                                  ),
                                )
                                    .toList(),
                                onChanged: (n) {
                                  if (n != null) _controller.doiNam(n);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _StatChip(
                            label: 'Năm KH',
                            value: '${nams.length}',
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'Đang xem',
                            value: '$nam',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final thang = index + 1;
                      final mucs = _controller.mucTrongThang(thang);
                      final isCurrent = thang == DateTime.now().month &&
                          _controller.namDangChon == DateTime.now().year;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(
                          milliseconds: 260 + (index * 35).clamp(0, 280),
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, child) => Opacity(
                          opacity: v,
                          child: Transform.scale(
                            scale: 0.92 + 0.08 * v,
                            child: child,
                          ),
                        ),
                        child: _OThangLich(
                          thang: thang,
                          mucs: mucs,
                          isCurrent: isCurrent,
                          onTap: () => _moChiTietThang(thang),
                        ),
                      );
                    },
                    childCount: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog lập kế hoạch năm — gọn, xanh hiện đại (không full page).
Future<int?> showDialogLapKeHoachNam(
    BuildContext context, {
      required List<int> namDaCo,
    }) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Đóng',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
          child: _DialogLapKeHoachNam(namDaCo: namDaCo),
        ),
      );
    },
  );
}

class _DialogLapKeHoachNam extends StatefulWidget {
  final List<int> namDaCo;
  const _DialogLapKeHoachNam({required this.namDaCo});

  @override
  State<_DialogLapKeHoachNam> createState() => _DialogLapKeHoachNamState();
}

class _DialogLapKeHoachNamState extends State<_DialogLapKeHoachNam> {
  late final CreateYearPlanController _ctrl;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = CreateYearPlanController(widget.namDaCo);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tao() async {
    final ok = await _ctrl.luu();
    if (ok && mounted) Navigator.pop(context, _ctrl.nam);
  }

  @override
  Widget build(BuildContext context) {
    final maxNam = widget.namDaCo.isEmpty
        ? null
        : widget.namDaCo.reduce((a, b) => a > b ? a : b);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.88,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B6BCB).withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header gradient xanh
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0B6BCB),
                          Color(0xFF0284C7),
                          Color(0xFF38BDF8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Lập kế hoạch năm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          maxNam != null
                              ? 'Bạn muốn lập kế hoạch năm nào?\n(Phải lớn hơn $maxNam)'
                              : 'Bạn muốn lập kế hoạch năm nào?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          focusNode: _focus,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: Color(0xFF0B6BCB),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'VD: ${maxNam != null ? maxNam + 1 : 2027}',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                              fontSize: 22,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF0F9FF),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: Color(0xFFBAE6FD), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: Color(0xFF0B6BCB), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppColors.danger, width: 1.5),
                            ),
                          ),
                          onChanged: _ctrl.datNam,
                          onSubmitted: (_) => _tao(),
                        ),
                        if (_ctrl.loi != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 16, color: AppColors.danger),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _ctrl.loi!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (widget.namDaCo.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Đã có: ${widget.namDaCo.join(', ')}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _ctrl.dangLuu
                                ? null
                                : () => Navigator.pop(context),
                            child: Text(
                              'Hủy',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0B6BCB),
                                    Color(0xFF0284C7),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0B6BCB)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _ctrl.dangLuu ? null : _tao,
                                  child: Center(
                                    child: _ctrl.dangLuu
                                        ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Text(
                                      'Tạo kế hoạch',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
class _MenuOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _OThangLich extends StatelessWidget {
  final int thang;
  final List<MucThietBiTrongThang> mucs;
  final bool isCurrent;
  final VoidCallback onTap;

  const _OThangLich({required this.thang, required this.mucs, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final coDuLieu = mucs.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: isCurrent ? 4 : 1.2,
      shadowColor: isCurrent
          ? const Color(0xFF0B6BCB).withValues(alpha: 0.35)
          : Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent
                  ? const Color(0xFF0B6BCB)
                  : Colors.grey.shade200,
              width: isCurrent ? 1.8 : 1,
            ),
            gradient: isCurrent
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0B6BCB).withValues(alpha: 0.06),
                Colors.white,
              ],
            )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: isCurrent
                      ? const LinearGradient(
                    colors: [Color(0xFF0B6BCB), Color(0xFF0284C7)],
                  )
                      : null,
                  color: isCurrent ? null : const Color(0xFFF1F5F9),
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(17)),
                ),
                child: Center(
                  child: Text(
                    _tenThangNgan[thang],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isCurrent ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: coDuLieu
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final m in mucs.take(2))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            m.chiTiet.tenThietBi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B6BCB)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          mucs.length > 2
                              ? '${mucs.length} TB'
                              : '${mucs.length} TB',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0B6BCB),
                          ),
                        ),
                      ),
                    ],
                  )
                      : Center(
                    child: Text(
                      'Trống',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ MÀN CHI TIẾT THEO THÁNG (chỉ thiết bị đúng tháng) ============

class MaintenanceMonthDetailScreen extends StatefulWidget {
  final int nam;
  final int thang;
  final List<MucThietBiTrongThang> mucBanDau;

  const MaintenanceMonthDetailScreen({
    super.key,
    required this.nam,
    required this.thang,
    required this.mucBanDau,
  });

  @override
  State<MaintenanceMonthDetailScreen> createState() => _MaintenanceMonthDetailScreenState();
}

class _MaintenanceMonthDetailScreenState extends State<MaintenanceMonthDetailScreen> {
  late final MaintenancePlanMonthDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MaintenancePlanMonthDetailController(
      nam: widget.nam,
      thang: widget.thang,
      mucBanDau: widget.mucBanDau,
    );
    _controller.khoiTao();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Color _mauTT(String tt) {
    switch (phanLoaiTrangThai(tt)) {
      case TrangThaiKeHoach.choDuyet:
        return AppColors.warning;
      case TrangThaiKeHoach.daDuyet:
        return const Color(0xFF0068A9);
      case TrangThaiKeHoach.tuChoi:
        return AppColors.danger;
      case TrangThaiKeHoach.dangThucHien:
        return const Color(0xFF1D4ED8);
      case TrangThaiKeHoach.daHoanThanh:
        return AppColors.success;
      case TrangThaiKeHoach.chuaTao:
        return Colors.grey;
      case TrangThaiKeHoach.choXuLy:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${_tenThang[widget.thang]} · ${widget.nam}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = _controller.danhSach;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có thiết bị nào trong ${_tenThang[widget.thang].toLowerCase()}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dùng nút "+" → Lập kế hoạch',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final muc = list[i];
              final ct = muc.chiTiet;
              // Ưu tiên trạng thái HỒ SƠ bảo trì (giống màn hồ sơ), không dùng trạng thái kế hoạch năm
              final nhanTT = ct.nhanTrangThaiHienThi;
              final mau = _mauTT(nhanTT);
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 0.8,
                shadowColor: Colors.black26,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border(left: BorderSide(color: mau, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ct.tenThietBi,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: mau.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              nhanTT,
                              style: TextStyle(color: mau, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Dự kiến: ${_fmt(ct.ngayDuKienBaoTri)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      if (muc.keHoach.tenChuKy != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          muc.keHoach.tenChuKy!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: mau.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ct.daTaoHoSo
                                  ? (ct.trangThaiHoSo == 'Đã duyệt' ||
                                  ct.trangThaiHoSo == 'Hoàn thành' ||
                                  ct.trangThaiHoSo == 'Đã hoàn thành'
                                  ? Icons.check_circle
                                  : ct.trangThaiHoSo == 'Từ chối'
                                  ? Icons.cancel
                                  : Icons.info_outline)
                                  : Icons.schedule_outlined,
                              size: 16,
                              color: mau,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ct.daTaoHoSo ? 'Hồ sơ: $nhanTT' : nhanTT,
                              style: TextStyle(
                                color: mau,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============ MÀN LẬP KẾ HOẠCH ============

class CreateMaintenancePlanScreen extends StatefulWidget {
  final int nam;
  final int? thangKhoiTao;
  final int? maThietBiKhoiTao;

  const CreateMaintenancePlanScreen({
    super.key,
    required this.nam,
    this.thangKhoiTao,
    this.maThietBiKhoiTao,
  });

  @override
  State<CreateMaintenancePlanScreen> createState() => _CreateMaintenancePlanScreenState();
}

class _CreateMaintenancePlanScreenState extends State<CreateMaintenancePlanScreen>
    with SingleTickerProviderStateMixin {
  late final CreateMaintenancePlanController _controller;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = CreateMaintenancePlanController(
      nam: widget.nam,
      thangKhoiTao: widget.thangKhoiTao,
      maThietBiKhoiTao: widget.maThietBiKhoiTao,
    );
    _controller.taiDuLieuBanDau();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _controller.noiDungCongViecController.dispose();
    _controller.thoiGianTextController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chonNgay() async {
    var first = _controller.ngayDuKienToiThieu;
    final last = _controller.ngayKetThuc;
    if (first.isAfter(last)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tháng này không còn ngày hợp lệ (phải sau ngày lập kế hoạch). Chọn tháng khác.',
          ),
        ),
      );
      return;
    }
    var initial = _controller.chiTietChon?.ngayDuKienBaoTri ?? first;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final ngay = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Chọn ngày dự kiến bảo trì',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (ngay != null) _controller.datNgayDuKien(ngay);
  }

  Future<void> _luu() async {
    final ok = await _controller.luuKeHoach();
    if (ok && mounted) Navigator.pop(context, true);
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  InputDecoration _fieldDeco({
    String? hint,
    String? helper,
    String? error,
    Widget? prefix,
    Widget? suffix,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      errorText: error,
      prefixIcon: prefix,
      suffixIcon: suffix,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }

  Widget _sectionLabel(String text, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              letterSpacing: 0.15,
              color: Color(0xFF1E293B),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3)),
          ],
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _tapField({
    required VoidCallback? onTap,
    required IconData icon,
    required String value,
    required bool enabled,
    String? placeholder,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? AppColors.primary.withValues(alpha: 0.55) : Colors.grey.shade300,
              width: enabled ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: enabled ? AppColors.primary : Colors.grey.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : (placeholder ?? 'Chọn'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: value.isNotEmpty ? FontWeight.w600 : FontWeight.w500,
                    color: value.isNotEmpty ? const Color(0xFF0F172A) : Colors.grey.shade500,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: enabled ? AppColors.primary : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Lập bảo trì · ${widget.nam}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.build_circle_outlined, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lập bảo trì cho thiết bị',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Chọn thiết bị · tháng · ngày dự kiến rồi gửi xưởng',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      fontSize: 12.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // --- Thiết bị ---
                      _card(
                        children: [
                          _sectionLabel(
                            'Thiết bị',
                            hint: 'Gõ 2–3 chữ (có/không dấu) là hiện danh sách khớp',
                          ),
                          TextField(
                            decoration: _fieldDeco(
                              hint: 'VD: lo, auto, hap, autoclave…',
                              prefix: const Icon(Icons.search_rounded, size: 22),
                              suffix: _controller.tuKhoaTimKiem.isEmpty
                                  ? null
                                  : IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: _controller.xoaTuKhoaTimKiem,
                                tooltip: 'Xóa tìm kiếm',
                              ),
                            ),
                            onChanged: _controller.datTuKhoaTimKiem,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _controller.danhMucChon,
                            isExpanded: true,
                            decoration: _fieldDeco(
                              hint: 'Tất cả danh mục',
                              prefix: const Icon(Icons.category_outlined, size: 22),
                            ),
                            hint: const Text('Tất cả danh mục'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Tất cả danh mục'),
                              ),
                              ..._controller.danhSachDanhMuc.map(
                                    (dm) => DropdownMenuItem(
                                  value: dm,
                                  child: Text(dm, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                            onChanged: _controller.chonDanhMuc,
                          ),
                          const SizedBox(height: 12),
                          // Danh sách kết quả tìm kiếm — bấm chọn thiết bị
                          Builder(
                            builder: (context) {
                              final list = _controller.dsThietBiDaLoc;
                              final coTuKhoa =
                                  _controller.tuKhoaTimKiem.trim().isNotEmpty;
                              if (list.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    coTuKhoa
                                        ? 'Không tìm thấy thiết bị khớp «${_controller.tuKhoaTimKiem.trim()}»'
                                        : 'Không có thiết bị trong danh mục đã chọn',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13.5),
                                  ),
                                );
                              }
                              // Giới hạn chiều cao khi nhiều kết quả
                              final maxH = coTuKhoa || list.length <= 6
                                  ? null
                                  : 220.0;
                              final content = ListView.separated(
                                shrinkWrap: true,
                                physics: maxH == null
                                    ? const NeverScrollableScrollPhysics()
                                    : const BouncingScrollPhysics(),
                                itemCount: list.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 1, color: Colors.grey.shade200),
                                itemBuilder: (_, i) {
                                  final tb = list[i];
                                  final dangChon = _controller.thietBiChon
                                      ?.maThietBi ==
                                      tb.maThietBi;
                                  return ListTile(
                                    dense: true,
                                    selected: dangChon,
                                    selectedTileColor: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    leading: Icon(
                                      dangChon
                                          ? Icons.check_circle_rounded
                                          : Icons.precision_manufacturing_outlined,
                                      color: dangChon
                                          ? AppColors.primary
                                          : Colors.grey.shade600,
                                      size: 22,
                                    ),
                                    title: Text(
                                      tb.tenThietBi,
                                      style: TextStyle(
                                        fontWeight: dangChon
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      tb.loaiThietBi ?? 'Chưa phân loại',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                    onTap: () {
                                      _controller.chonThietBi(tb);
                                    },
                                  );
                                },
                              );
                              return Container(
                                width: double.infinity,
                                constraints: maxH != null
                                    ? BoxConstraints(maxHeight: maxH)
                                    : null,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: content,
                              );
                            },
                          ),
                          if (_controller.thietBiChon != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.success
                                        .withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.success, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Đã chọn: ${_controller.thietBiChon!.tenThietBi}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            child: _controller.chuKyCoDinh == null
                                ? const SizedBox.shrink()
                                : Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.autorenew_rounded, size: 18, color: AppColors.primary.withValues(alpha: 0.9)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Chu kỳ đề xuất: ${_controller.chuKyCoDinh!.soThangChuKyDeXuat} tháng/lần',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // --- Thời gian: Tháng TRƯỚC, Ngày SAU ---
                      _card(
                        children: [
                          _sectionLabel(
                            'Thời gian bảo trì',
                            hint: 'Chọn tháng trước, sau đó chọn ngày dự kiến trong tháng đó',
                          ),
                          _sectionLabel('Tháng *'),
                          DropdownButtonFormField<int>(
                            value: _controller.thang,
                            decoration: _fieldDeco(
                              prefix: const Icon(Icons.calendar_view_month_rounded, size: 22),
                            ),
                            items: List.generate(12, (i) => i + 1)
                                .map((m) => DropdownMenuItem(value: m, child: Text('Tháng $m / ${_controller.nam}')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _controller.doiThang(v);
                            },
                          ),
                          const SizedBox(height: 16),
                          _sectionLabel(
                            'Ngày dự kiến bảo trì *',
                            hint: _controller.thietBiChon == null
                                ? 'Chọn thiết bị trước để chọn ngày'
                                : 'Ngày trong tháng ${_controller.thang}/${_controller.nam}, sau hôm nay',
                          ),
                          _tapField(
                            onTap: _controller.thietBiChon == null ? null : _chonNgay,
                            icon: Icons.event_available_rounded,
                            enabled: _controller.thietBiChon != null,
                            value: _controller.chiTietChon != null
                                ? _fmt(_controller.chiTietChon!.ngayDuKienBaoTri)
                                : '',
                            placeholder: _controller.thietBiChon == null
                                ? 'Chọn thiết bị trước'
                                : 'Chạm để chọn ngày',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // --- Công việc & giờ ---
                      _card(
                        children: [
                          _sectionLabel('Nội dung công việc *'),
                          TextField(
                            controller: _controller.noiDungCongViecController,
                            maxLines: 3,
                            decoration: _fieldDeco(hint: 'Mô tả công việc cần bảo trì...'),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppColors.primary.withValues(alpha: 0.9)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Thời gian dự kiến / bắt đầu / kết thúc không nhập khi tạo. '
                                        'Hệ thống ghi nhận khi NVKT bấm Tiến hành quy trình và khi hoàn thành.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey.shade700,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Lỗi đỏ
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: _controller.loi == null
                            ? const SizedBox.shrink()
                            : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _controller.loi!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),
                      AnimatedScale(
                        scale: _controller.dangLuu ? 0.98 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _controller.dangLuu ? null : _luu,
                          child: _controller.dangLuu
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Tạo bảo trì',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                              ),
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
        },
      ),
    );
  }
}