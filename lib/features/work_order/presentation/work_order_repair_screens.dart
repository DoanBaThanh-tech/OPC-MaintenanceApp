import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_detail_ui.dart';
import '../../../core/network/api_exception.dart';
import '../../equipment/data/equipment_logic.dart' show ThietBiModel;
import '../data/work_order_logic.dart';
import '../data/work_order_validators.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/material_usage_service.dart';
import '../data/services/work_order_service.dart';
import 'work_order_assign_screen.dart';
import 'widgets/to_truong_chon_buoc_quy_trinh.dart';
import '../data/to_truong_ke_hoach_buoc_logic.dart';
import '../data/to_truong_quy_trinh_tao_logic.dart';
import 'widgets/to_truong_chon_quy_trinh_tao.dart';

// Theme xanh dương (đồng bộ AppColors) — hiện đại, nhiều hiệu ứng
const _scPrimary = AppColors.primary; // #0068A9
const _scDark = AppColors.primaryDark; // #004E80
const _scSoft = Color(0xFFE8F4FC);
const _scBg = Color(0xFFF0F6FB);
const _scAccent = Color(0xFF0EA5E9); // cyan highlight

// ============ DANH SÁCH HỒ SƠ SỬA CHỮA ============

class WorkOrderSuaChuaListScreen extends StatefulWidget {
  final String? trangThaiMacDinh;
  final bool hienFabTao;

  const WorkOrderSuaChuaListScreen({
    super.key,
    this.trangThaiMacDinh,
    this.hienFabTao = false,
  });

  @override
  State<WorkOrderSuaChuaListScreen> createState() =>
      _WorkOrderSuaChuaListScreenState();
}

class _WorkOrderSuaChuaListScreenState extends State<WorkOrderSuaChuaListScreen>
    with TickerProviderStateMixin {
  late final WorkOrderSuaChuaListController _ctrl;
  late final AnimationController _headerAnim;
  late final TabController _tab;

  // Không hiện tab "Chờ xác nhận" trên Hồ sơ SC — map sang Đang thực hiện; quy trình xem trong chi tiết.
  static const _tabs = [
    'Tất cả',
    'Chờ phân công',
    'Đang thực hiện',
    'Đã hoàn thành',
  ];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _tab = TabController(length: _tabs.length, vsync: this);
    if (widget.trangThaiMacDinh != null) {
      final idx = _tabs.indexOf(widget.trangThaiMacDinh!);
      if (idx >= 0) _tab.index = idx;
    }
    _tab.addListener(() {
      if (!_tab.indexIsChanging && mounted) setState(() {});
    });
    _ctrl = WorkOrderSuaChuaListController(
        trangThaiMacDinh: widget.trangThaiMacDinh);
    _ctrl.addListener(_onCtrl);
    _ctrl.tai();
  }

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrl);
    _ctrl.dispose();
    _headerAnim.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _tai() => _ctrl.tai();

  Color _mauTt(String tt) {
    switch (tt) {
      case 'Chờ phân công':
      case 'Đã duyệt':
        return const Color(0xFFF59E0B);
      case 'Đang thực hiện':
      case 'Chờ xác nhận': // dữ liệu cũ trên HS → coi như Đang thực hiện
        return _scPrimary;
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      default:
        return Colors.blueGrey;
    }
  }

  String _tenTt(String tt) =>
      tt == 'Chờ xác nhận' ? 'Đang thực hiện' : tt;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _scBg,
      extendBodyBehindAppBar: false,
      floatingActionButton: widget.hienFabTao
          ? ScaleTransition(
        scale: CurvedAnimation(
            parent: _headerAnim, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final ok = await Navigator.push<bool>(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 380),
                pageBuilder: (_, a, __) => const TaoHoSoSuaChuaScreen(),
                transitionsBuilder: (_, a, __, child) {
                  final curved =
                  CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
              ),
            );
            if (ok == true) _tai();
          },
          backgroundColor: _scPrimary,
          elevation: 8,
          highlightElevation: 12,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Tạo hồ sơ SC',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      )
          : null,
      body: Column(
        children: [
          // ===== Header gradient + TabBar (đồng bộ hồ sơ bảo trì) =====
          FadeTransition(
            opacity: _headerAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.15),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOutCubic)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, top + 10, 12, 0),
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
                      color: _scPrimary.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
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
                                'Hồ sơ sửa chữa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _ctrl.dangTai
                                    ? 'Đang tải…'
                                    : '${_ctrl.danhSach.length} hồ sơ',
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
                          final count = _ctrl.locTheoTab(_tabs[i]).length;
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
                                          : Colors.white
                                          .withValues(alpha: 0.2),
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

  Widget _buildBody() {
    if (_ctrl.dangTai) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                  color: _scPrimary, strokeWidth: 3),
            ),
            SizedBox(height: 14),
            Text('Đang tải hồ sơ…',
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (_ctrl.loi != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    size: 36, color: AppColors.danger),
              ),
              const SizedBox(height: 14),
              Text(_ctrl.loi!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.4)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _tai,
                style: FilledButton.styleFrom(
                  backgroundColor: _scPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    final list = _ctrl.locTheoTab(_tabs[_tab.index]);
    return RefreshIndicator(
      color: _scPrimary,
      onRefresh: _tai,
      child: list.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                        _scSoft,
                        _scPrimary.withValues(alpha: 0.12),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.handyman_outlined,
                      size: 48, color: _scPrimary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có hồ sơ sửa chữa',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.hienFabTao
                      ? 'Bấm + để tạo hồ sơ khi thiết bị hư đột ngột'
                      : 'Danh sách sẽ hiện khi có hồ sơ mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      )
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final hs = list[i];
          final c = _mauTt(hs.trangThai);
          final tenTt = _tenTt(hs.trangThai);
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 320 + i * 45),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 22 * (1 - t)),
                child: Transform.scale(
                  scale: 0.96 + 0.04 * t,
                  child: child,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScCard(
                onTap: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    PageRouteBuilder(
                      transitionDuration:
                      const Duration(milliseconds: 320),
                      pageBuilder: (_, a, __) =>
                          ChiTietHoSoSuaChuaScreen(
                              maHoSo: hs.maHoSoSuaChua),
                      transitionsBuilder: (_, a, __, child) =>
                          FadeTransition(
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
                  if (changed == true) _tai();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _scPrimary.withValues(alpha: 0.15),
                                _scAccent.withValues(alpha: 0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.handyman_rounded,
                              color: _scPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                hs.tenThietBi.isEmpty
                                    ? 'Thiết bị #${hs.maThietBi}'
                                    : hs.tenThietBi,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'HS SC #${hs.maHoSoSuaChua}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: c.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            tenTt,
                            style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hs.moTaHuHong != null &&
                        hs.moTaHuHong!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hs.moTaHuHong!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 15, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hs.tenNhanVienTao ?? '—',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.calendar_today_rounded,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${hs.ngayTao.day.toString().padLeft(2, '0')}/${hs.ngayTao.month.toString().padLeft(2, '0')}/${hs.ngayTao.year}',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            size: 20, color: Colors.grey.shade400),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============ TẠO HỒ SƠ SỬA CHỮA (XƯỞNG) ============

class TaoHoSoSuaChuaScreen extends StatefulWidget {
  const TaoHoSoSuaChuaScreen({super.key});

  @override
  State<TaoHoSoSuaChuaScreen> createState() => _TaoHoSoSuaChuaScreenState();
}

class _TaoHoSoSuaChuaScreenState extends State<TaoHoSoSuaChuaScreen>
    with TickerProviderStateMixin {
  final _ctrl = CreateHoSoSuaChuaController();
  final _qtCtrl = ToTruongQuyTrinhTaoController(loaiCongViec: 'Sửa chữa');
  final _moTaCtrl = TextEditingController();
  final _phuongAnCtrl = TextEditingController();
  final _thoiGianCtrl = TextEditingController();
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _ctrl.khoiTao().then((_) {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _pulse.dispose();
    _ctrl.dispose();
    _qtCtrl.dispose();
    _moTaCtrl.dispose();
    _phuongAnCtrl.dispose();
    _thoiGianCtrl.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    final errQt = _qtCtrl.validate();
    if (errQt != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errQt),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final ok = await _ctrl.gui(
      moTaHuHong: _moTaCtrl.text,
      phuongAnSuaChua: _phuongAnCtrl.text,
      danhSachBuoc: _qtCtrl.payloadBuoc(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đã tạo hồ sơ SC ngày ${_ctrl.ngaySuaChuaHienThi} — thiết bị chuyển Sửa chữa'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  InputDecoration _fieldDeco({
    String? hint,
    Widget? prefixIcon,
    String? errorText,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _scPrimary, width: 1.6),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefixIcon,
        errorText: errorText,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _sectionLabel(String text, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: _scPrimary),
          const SizedBox(width: 6),
        ],
        Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _scBg,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(8, top + 4, 16, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF004E80),
                  Color(0xFF0068A9),
                  Color(0xFF0EA5E9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: _scPrimary.withValues(alpha: 0.32),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tạo hồ sơ sửa chữa',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Hư đột ngột → sửa ngay trong ngày',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final s = 0.9 + 0.1 * _pulse.value;
                    return Transform.scale(
                      scale: s,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.build_circle_rounded,
                            color: Colors.white, size: 26),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final dsTb = _ctrl.dsThietBiTheoDanhMuc;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    children: [
                      // Info banner
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutBack,
                        builder: (context, t, child) => Transform.scale(
                          scale: 0.92 + 0.08 * t,
                          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFFF7ED),
                                const Color(0xFFFFEDD5).withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFDBA74)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFDBA74)
                                    .withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.flash_on_rounded,
                                  color: Color(0xFFC2410C), size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Hư đột ngột cần sửa liền — ngày cố định hôm nay. Chỉ thiết bị đang Sản xuất; sau khi tạo, TB chuyển Sửa chữa.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Color(0xFF9A3412),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Ngày SC
                      _sectionLabel('Ngày sửa chữa *',
                          icon: Icons.event_available_rounded),
                      _ScCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _scPrimary.withValues(alpha: 0.15),
                                    _scAccent.withValues(alpha: 0.12),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calendar_today_rounded,
                                  color: _scPrimary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _ctrl.ngaySuaChuaHienThi,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cố định hôm nay — sửa liền',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_scPrimary, _scAccent],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    _scPrimary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Hôm nay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Thời gian không nhập khi tạo — ghi nhận khi NVKT Tiến hành / hoàn thành
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _scPrimary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 18,
                                color: _scPrimary.withValues(alpha: 0.9)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Thời gian dự kiến / bắt đầu / kết thúc sẽ hiển thị trên chi tiết '
                                    'sau khi NVKT bấm Tiến hành quy trình và khi hoàn thành.',
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
                      const SizedBox(height: 18),

                      // Danh mục
                      _sectionLabel('Danh mục thiết bị *',
                          icon: Icons.category_rounded),
                      if (_ctrl.dangTai)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: _scPrimary, strokeWidth: 2.8),
                          ),
                        )
                      else if (_ctrl.nhoms.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFFDBA74)),
                          ),
                          child: const Text(
                            'Không có thiết bị đang Sản xuất để tạo hồ sơ SC.',
                            style: TextStyle(
                                color: Color(0xFF9A3412),
                                fontWeight: FontWeight.w600),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _ctrl.danhMucChon,
                          isExpanded: true,
                          decoration: _fieldDeco(
                            hint: 'Chọn danh mục…',
                            prefixIcon: const Icon(Icons.category_rounded,
                                color: _scPrimary),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          items: _ctrl.nhoms
                              .map((n) => DropdownMenuItem(
                            value: n.tenDanhMuc,
                            child: Text(
                              '${n.tenDanhMuc} (${n.danhSach.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                              .toList(),
                          onChanged: _ctrl.chonDanhMuc,
                        ),
                      const SizedBox(height: 16),

                      // Thiết bị
                      _sectionLabel('Thiết bị hư hỏng *',
                          icon: Icons.precision_manufacturing_rounded),
                      if (!_ctrl.dangTai && _ctrl.nhoms.isNotEmpty)
                        DropdownButtonFormField<ThietBiModel>(
                          value: _ctrl.thietBiChon,
                          isExpanded: true,
                          decoration: _fieldDeco(
                            hint: _ctrl.danhMucChon == null
                                ? 'Chọn danh mục trước…'
                                : (dsTb.isEmpty
                                ? 'Không có thiết bị trong danh mục'
                                : 'Chọn thiết bị…'),
                            prefixIcon: const Icon(
                                Icons.precision_manufacturing_rounded,
                                color: _scPrimary),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          items: dsTb
                              .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              '${t.tenThietBi}${t.viTriLapDat != null && t.viTriLapDat!.isNotEmpty ? ' · ${t.viTriLapDat}' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                              .toList(),
                          onChanged:
                          _ctrl.danhMucChon == null || dsTb.isEmpty
                              ? null
                              : _ctrl.chonThietBi,
                        ),
                      const SizedBox(height: 16),

                      ToTruongChonQuyTrinhTao(
                        loaiCongViec: 'Sửa chữa',
                        controller: _qtCtrl,
                      ),
                      const SizedBox(height: 16),
                      _sectionLabel('Mô tả hư hỏng *',
                          icon: Icons.description_outlined),
                      TextField(
                        controller: _moTaCtrl,
                        maxLines: 4,
                        onChanged: (_) {
                          _ctrl.xoaLoiMoTa();
                        },
                        style: const TextStyle(height: 1.4),
                        decoration: _fieldDeco(
                          hint: 'Hiện tượng hư hỏng, vị trí, mức độ…',
                          errorText: _ctrl.loiMoTa,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _sectionLabel('Phương án sửa chữa (tuỳ chọn)',
                          icon: Icons.lightbulb_outline_rounded),
                      TextField(
                        controller: _phuongAnCtrl,
                        maxLines: 3,
                        style: const TextStyle(height: 1.4),
                        decoration: _fieldDeco(
                          hint: 'Gợi ý cách xử lý nếu có…',
                        ),
                      ),

                      if (_ctrl.loi != null) ...[
                        const SizedBox(height: 14),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 280),
                          builder: (context, t, child) => Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, 8 * (1 - t)),
                              child: child,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                              AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.danger
                                      .withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.danger, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_ctrl.loi!,
                                      style: const TextStyle(
                                          color: AppColors.danger,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // CTA
                      AnimatedScale(
                        scale: _ctrl.dangGui ? 0.98 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF004E80),
                                Color(0xFF0068A9),
                                Color(0xFF0EA5E9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _scPrimary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _ctrl.dangGui ? null : _gui,
                              child: Center(
                                child: _ctrl.dangGui
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded,
                                        color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      'Gửi Tổ trưởng phân công',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ CHI TIẾT HỒ SƠ SỬA CHỮA ============

class ChiTietHoSoSuaChuaScreen extends StatefulWidget {
  final int maHoSo;
  const ChiTietHoSoSuaChuaScreen({super.key, required this.maHoSo});

  @override
  State<ChiTietHoSoSuaChuaScreen> createState() =>
      _ChiTietHoSoSuaChuaScreenState();
}

class _ChiTietHoSoSuaChuaScreenState extends State<ChiTietHoSoSuaChuaScreen>
    with SingleTickerProviderStateMixin {
  late final ChiTietHoSoSuaChuaController _ctrl;
  late final AnimationController _anim;

  HoSoVatTuItem? _hoSoVatTu;
  bool _dangTaiQuyTrinh = false;
  String? _loiQuyTrinh;
  bool _daLuuKeHoachBuoc = false;

  bool get _laToTruong => _ctrl.laToTruong;
  bool get _laNvkt => _ctrl.laNvkt;
  bool get _laXuong => _ctrl.laXuong;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _ctrl = ChiTietHoSoSuaChuaController(widget.maHoSo);
    _ctrl.addListener(_onCtrl);
    _ctrl.tai().then((_) {
      final hs = _ctrl.hoSo;
      // Xưởng: xem quy trình khi Đang thực hiện / chờ duyệt / đã xong
      // Tổ trưởng & vai trò khác: chỉ khi Đã hoàn thành
      if (hs != null &&
          (hs.daHoanThanh ||
              (_laXuong &&
                  (hs.choXacNhanKetQua || hs.dangThucHien)))) {
        _taiQuyTrinhVatTu();
      }
    });
  }

  Future<void> _taiQuyTrinhVatTu() async {
    setState(() {
      _dangTaiQuyTrinh = true;
      _loiQuyTrinh = null;
    });
    try {
      final hs = await MaterialUsageService.layHoSoTheoCongViec(
        maHoSoSuaChua: widget.maHoSo,
      );
      if (!mounted) return;
      setState(() {
        _hoSoVatTu = hs;
        _dangTaiQuyTrinh = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loiQuyTrinh = e is ApiException ? e.message : '$e';
        _dangTaiQuyTrinh = false;
      });
    }
  }

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrl);
    _ctrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _load() => _ctrl.tai();

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    if (_ctrl.dangTai) {
      return const Scaffold(
        backgroundColor: _scBg,
        body: Center(
          child: CircularProgressIndicator(color: _scPrimary, strokeWidth: 3),
        ),
      );
    }
    if (_ctrl.loi != null || _ctrl.hoSo == null) {
      return Scaffold(
        backgroundColor: _scBg,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(8, top + 6, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF004E80), Color(0xFF0068A9)],
                ),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                  const Text('Chi tiết SC',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_ctrl.loi ?? 'Không có dữ liệu'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      style: FilledButton.styleFrom(
                          backgroundColor: _scPrimary),
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
    final hs = _ctrl.hoSo!;
    return Scaffold(
      backgroundColor: ModernDetailUi.bg,
      body: Column(
        children: [
          ModernDetailUi.headerBar(
            context: context,
            topPadding: top,
            title: 'Hồ sơ SC #${hs.maHoSoSuaChua}',
            subtitle: hs.trangThai,
          ),
          Expanded(
            child: FadeTransition(
              opacity: CurvedAnimation(
                  parent: _anim, curve: Curves.easeOutCubic),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  // Hero card — đồng bộ ModernDetailUi
                  ModernDetailUi.fadeSlide(
                    delayMs: 0,
                    child: ModernDetailUi.heroCard(
                      icon: Icons.handyman_rounded,
                      title: hs.tenThietBi,
                      statusLabel: hs.trangThai,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ModernDetailUi.fadeSlide(
                    delayMs: 40,
                    child: ModernDetailUi.softCard(
                      child: Column(
                        children: [
                          ModernDetailUi.sectionTitle(
                            icon: Icons.info_outline_rounded,
                            title: 'Thông tin hồ sơ',
                            trailing: ModernDetailUi.statusChip(hs.trangThai),
                          ),
                          const SizedBox(height: 8),
                          ModernDetailUi.infoRow(
                              'Người tạo', hs.tenNhanVienTao ?? '—'),
                          Divider(height: 1, color: Colors.grey.shade200),
                          ModernDetailUi.infoRow(
                              'Ngày tạo', _fmt(hs.ngayTao)),
                          if (hs.ngayDuyet != null) ...[
                            Divider(height: 1, color: Colors.grey.shade200),
                            ModernDetailUi.infoRow(
                                'Ngày duyệt', _fmt(hs.ngayDuyet)),
                          ],
                          Divider(height: 1, color: Colors.grey.shade200),
                          ModernDetailUi.infoRow(
                            'Thời gian dự kiến',
                            (hs.thoiGianDuKien == null ||
                                hs.thoiGianDuKien!.trim().isEmpty)
                                ? '?'
                                : formatThoiGianDuKienHienThi(hs.thoiGianDuKien),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          ModernDetailUi.infoRow(
                            'Giờ bắt đầu',
                            (hs.gioBatDauDuKien != null &&
                                hs.gioBatDauDuKien!.trim().isNotEmpty)
                                ? hs.gioBatDauDuKien!
                                : '?',
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          ModernDetailUi.infoRow(
                            'Giờ kết thúc',
                            (hs.gioKetThucDuKien != null &&
                                hs.gioKetThucDuKien!.trim().isNotEmpty)
                                ? hs.gioKetThucDuKien!
                                : '?',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ModernDetailUi.fadeSlide(
                    delayMs: 80,
                    child: ModernDetailUi.softCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.report_problem_outlined,
                                  size: 18, color: _scPrimary),
                              SizedBox(width: 8),
                              Text('Mô tả hư hỏng',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(hs.moTaHuHong ?? '—',
                              style: TextStyle(
                                  height: 1.45,
                                  color: Colors.grey.shade800,
                                  fontSize: 14)),
                          if (hs.phuongAnSuaChua != null &&
                              hs.phuongAnSuaChua!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded,
                                    size: 18, color: _scPrimary),
                                SizedBox(width: 8),
                                Text('Phương án SC',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(hs.phuongAnSuaChua!,
                                style: TextStyle(
                                    height: 1.45,
                                    color: Colors.grey.shade800,
                                    fontSize: 14)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (hs.daCoPhanCong &&
                      hs.tenNhanVienThucHiens != null &&
                      hs.tenNhanVienThucHiens!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ModernDetailUi.fadeSlide(
                      delayMs: 120,
                      child: ModernDetailUi.softCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.groups_rounded,
                                    color: ModernDetailUi.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                    hs.daHoanThanh
                                        ? 'Nhân viên đã đảm nhận'
                                        : 'Nhân viên đang được phân công',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(hs.tenNhanVienThucHiens!,
                                style: TextStyle(
                                    height: 1.45,
                                    color: Colors.grey.shade800)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (_laToTruong &&
                      (hs.choPhanCong || hs.coTheCapNhatPhanCong)) ...[
                    if (hs.maThietBi > 0)
                      const SizedBox.shrink(),
                    _gradientBtn(
                      icon: hs.coTheCapNhatPhanCong
                          ? Icons.manage_accounts_rounded
                          : Icons.groups_rounded,
                      label: hs.coTheCapNhatPhanCong
                          ? 'Cập nhật phân công'
                          : 'Phân công nhân viên',
                      onTap: () async {
                        if (!hs.coTheCapNhatPhanCong) {
                          final block =
                          ToTruongKeHoachBuocRules.kiemTraTruocKhiPhanCong(
                            daLuuKeHoach: _daLuuKeHoachBuoc,
                          );
                          if (block != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(block),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                        }
                        final ok = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhanCongBaoTriScreen(
                              maHoSoBaoTri: hs.maHoSoSuaChua,
                              isCapNhat: hs.coTheCapNhatPhanCong,
                              isSuaChua: true,
                            ),
                          ),
                        );
                        if (ok == true) _load();
                      },
                    ),
                  ],
                  if (_laNvkt && hs.dangThucHien) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor:
                          AppColors.success.withValues(alpha: 0.4),
                        ),
                        icon: const Icon(Icons.task_alt_rounded),
                        label: const Text('Hoàn thành sửa chữa',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        onPressed: () async {
                          final ok = await _ctrl.nhanVienHoanThanh();
                          if (!mounted) return;
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Đã hoàn thành — thiết bị trở về Sản xuất'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            Navigator.pop(context, true);
                          } else if (_ctrl.loi != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_ctrl.loi!)),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                  // Xưởng: quy trình ở Đang thực hiện + Đã hoàn thành
                  if (_laXuong &&
                      (hs.choXacNhanKetQua ||
                          hs.dangThucHien ||
                          hs.daHoanThanh)) ...[
                    const SizedBox(height: 16),
                    _buildXuongQuyTrinhVaDuyetSc(hs),
                  ]
                  // Tổ trưởng / vai trò khác: chỉ xem quy trình khi Đã hoàn thành
                  else if (!_laXuong && hs.daHoanThanh) ...[
                    const SizedBox(height: 16),
                    _buildQuyTrinhChiXemKhiHoanThanhSc(hs),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuyTrinhChiXemKhiHoanThanhSc(HoSoSuaChua hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border:
            Border.all(color: AppColors.success.withValues(alpha: 0.35)),
          ),
          child: const Text(
            'Xưởng đã xác nhận — hồ sơ Đã hoàn thành. Quy trình / vật tư bên dưới (chỉ xem).',
            style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Quy trình',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.45)),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildQuyTrinhSuaChua(),
      ],
    );
  }

  String _nhanTtQuyTrinhSc(HoSoSuaChua hs) {
    if (hs.daHoanThanh || hs.trangThaiPhanCong == 'Hoàn thành') {
      return 'Xác nhận';
    }
    if (hs.trangThaiPhanCong == 'Từ chối') return 'Từ chối';
    if (hs.choXacNhanKetQua) return 'Chờ xác nhận';
    if (hs.dangThucHien) return 'Đang thực hiện';
    return hs.trangThaiPhanCong ?? hs.trangThai;
  }

  Color _mauTtQuyTrinhSc(String nhan) {
    switch (nhan) {
      case 'Xác nhận':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      case 'Chờ xác nhận':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildXuongQuyTrinhVaDuyetSc(HoSoSuaChua hs) {
    final nhanTt = _nhanTtQuyTrinhSc(hs);
    final mauTt = _mauTtQuyTrinhSc(nhanTt);
    final choDuyet = hs.choXacNhanKetQua;
    final biTuChoiPc = hs.trangThaiPhanCong == 'Từ chối' && hs.dangThucHien;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (choDuyet)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
            ),
            child: const Text(
              'NVKT đã gửi kết quả quy trình sửa chữa. Kiểm tra bước/vật tư rồi Xác nhận (→ Đã hoàn thành) hoặc Từ chối (quy trình giữ nguyên, vẫn Đang thực hiện).',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          )
        else if (biTuChoiPc)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Text(
              (hs.lyDoTuChoiPhanCong != null &&
                  hs.lyDoTuChoiPhanCong!.isNotEmpty)
                  ? 'Đã từ chối quy trình — hồ sơ vẫn Đang thực hiện. Lý do: ${hs.lyDoTuChoiPhanCong}'
                  : 'Đã từ chối quy trình — hồ sơ vẫn Đang thực hiện. Chờ NVKT chỉnh sửa và gửi lại.',
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          )
        else if (hs.daHoanThanh)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: AppColors.success.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'Đã xác nhận quy trình — hồ sơ Đã hoàn thành.',
                style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
              ),
            ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Quy trình',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: mauTt.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mauTt.withValues(alpha: 0.45)),
              ),
              child: Text(
                nhanTt,
                style: TextStyle(
                  color: mauTt,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildQuyTrinhSuaChua(),
        if (choDuyet) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success),
                  onPressed: () async {
                    try {
                      await WorkOrderService.xuongXacNhanKetQua(
                        maHoSoSuaChua: hs.maHoSoSuaChua,
                        xacNhan: true,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Đã xác nhận — hồ sơ chuyển Đã hoàn thành'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      await _load();
                      await _taiQuyTrinhVatTu();
                    } on ApiException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.message),
                            backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Xác nhận'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger),
                  onPressed: () async {
                    final lyDoCtrl = TextEditingController();
                    final lyDo = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Từ chối kết quả'),
                        content: TextField(
                          controller: lyDoCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Lý do để NVKT chỉnh sửa…',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Hủy')),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(ctx, lyDoCtrl.text.trim()),
                            child: const Text('Từ chối'),
                          ),
                        ],
                      ),
                    );
                    if (lyDo == null || lyDo.isEmpty) return;
                    try {
                      await WorkOrderService.xuongXacNhanKetQua(
                        maHoSoSuaChua: hs.maHoSoSuaChua,
                        xacNhan: false,
                        lyDo: lyDo,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Đã từ chối — quy trình giữ nguyên, hồ sơ vẫn Đang thực hiện'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      await _load();
                      await _taiQuyTrinhVatTu();
                    } on ApiException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.message),
                            backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Từ chối'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuyTrinhSuaChua() {
    if (_dangTaiQuyTrinh) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loiQuyTrinh != null) {
      return _ScCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quy trình sửa chữa',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 8),
            Text(_loiQuyTrinh!,
                style: TextStyle(color: Colors.grey.shade700)),
            TextButton(
                onPressed: _taiQuyTrinhVatTu, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    final hsVt = _hoSoVatTu;
    if (hsVt == null || hsVt.chiTiet.isEmpty) {
      return _ScCard(
        child: Text(
          'Chưa có dữ liệu bước/vật tư (có thể không dùng vật tư).',
          style: TextStyle(
              color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      );
    }
    final map = <int, List<ChiTietVatTuSuDung>>{};
    for (final c in hsVt.chiTiet) {
      map.putIfAbsent(c.soBuoc, () => []).add(c);
    }
    final keys = map.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScCard(
          child: Row(
            children: [
              const Icon(Icons.account_tree_rounded,
                  size: 18, color: _scPrimary),
              const SizedBox(width: 8),
              const Text('Quy trình sửa chữa',
                  style:
                  TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const Spacer(),
              Text('${keys.length} bước',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final k in keys)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _scPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$k',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Text('Bước $k',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
                if (map[k]!.any((e) => e.moTaBuoc.trim().isNotEmpty)) ...[
                  const SizedBox(height: 6),
                  Text(
                    map[k]!
                        .map((e) => e.moTaBuoc.trim())
                        .where((s) => s.isNotEmpty)
                        .toSet()
                        .join(' · '),
                    style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.35,
                        fontSize: 13),
                  ),
                ],
                const SizedBox(height: 6),
                for (final c in map[k]!)
                  if (c.tenVatTu.isNotEmpty && c.soLuong > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 15, color: _scPrimary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('${c.tenVatTu} × ${c.soLuong}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _gradientBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF004E80), Color(0xFF0068A9), Color(0xFF0EA5E9)],
        ),
        boxShadow: [
          BoxShadow(
            color: _scPrimary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(l,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(v,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A))),
        ),
      ],
    ),
  );
}

/// Card trắng bo góc + shadow mềm
class _ScCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const _ScCard({required this.child, this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    final body = Container(
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
            color: _scPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: body,
      ),
    );
  }
}