import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../equipment/data/equipment_logic.dart' show ThietBiModel;
import '../data/work_order_logic.dart';
import 'work_order_assign_screen.dart';

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
    with SingleTickerProviderStateMixin {
  late final WorkOrderSuaChuaListController _ctrl;
  late final AnimationController _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
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
    super.dispose();
  }

  Future<void> _tai() => _ctrl.tai();

  Color _mauTt(String tt) {
    switch (tt) {
      case 'Chờ phân công':
      case 'Đã duyệt':
        return const Color(0xFFF59E0B);
      case 'Đang thực hiện':
        return _scPrimary;
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      default:
        return Colors.blueGrey;
    }
  }

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
          // ===== Header gradient + glass =====
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
                padding: EdgeInsets.fromLTRB(20, top + 14, 20, 22),
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
                      bottom: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: _scPrimary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.handyman_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
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
                          const SizedBox(height: 4),
                          Text(
                            _ctrl.dangTai
                                ? 'Đang tải…'
                                : '${_ctrl.danhSach.length} hồ sơ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
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
              ),
            ),
          ),
          // Thanh trạng thái SC: Tất cả | Chờ phân công | Đang thực hiện | Đã hoàn thành
          _buildStatusBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  static const _tabsSc = [
    (null, 'Tất cả'),
    ('Chờ phân công', 'Chờ phân công'),
    ('Đang thực hiện', 'Đang thực hiện'),
    ('Đã hoàn thành', 'Đã hoàn thành'),
  ];

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (key, label) in _tabsSc) ...[
              _statusChip(key, label),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String? key, String label) {
    final selected = _ctrl.locTrangThai == key;
    return Material(
      color: selected ? _scPrimary : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _ctrl.datLocTrangThai(key),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
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
    return RefreshIndicator(
      color: _scPrimary,
      onRefresh: _tai,
      child: _ctrl.danhSach.isEmpty
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
        itemCount: _ctrl.danhSach.length,
        itemBuilder: (context, i) {
          final hs = _ctrl.danhSach[i];
          final c = _mauTt(hs.trangThai);
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
                            hs.trangThai,
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
  final _moTaCtrl = TextEditingController();
  final _phuongAnCtrl = TextEditingController();
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
    _moTaCtrl.dispose();
    _phuongAnCtrl.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    final ok = await _ctrl.gui(
      moTaHuHong: _moTaCtrl.text,
      phuongAnSuaChua: _phuongAnCtrl.text,
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

                      _sectionLabel('Mô tả hư hỏng *',
                          icon: Icons.description_outlined),
                      TextField(
                        controller: _moTaCtrl,
                        maxLines: 4,
                        onChanged: (_) => _ctrl.xoaLoiMoTa(),
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

  bool get _laToTruong => _ctrl.laToTruong;
  bool get _laNvkt => _ctrl.laNvkt;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _ctrl = ChiTietHoSoSuaChuaController(widget.maHoSo);
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
      backgroundColor: _scBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(8, top + 4, 16, 20),
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
              const BorderRadius.vertical(bottom: Radius.circular(26)),
              boxShadow: [
                BoxShadow(
                  color: _scPrimary.withValues(alpha: 0.3),
                  blurRadius: 18,
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
                      Text(
                        'Hồ sơ SC #${hs.maHoSoSuaChua}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hs.trangThai,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: CurvedAnimation(
                  parent: _anim, curve: Curves.easeOutCubic),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  // Hero card
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - t)),
                        child: child,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
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
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _scPrimary.withValues(alpha: 0.32),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.handyman_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hs.tenThietBi,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hs.trangThai,
                                  style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ScCard(
                    child: Column(
                      children: [
                        _row('Người tạo', hs.tenNhanVienTao ?? '—'),
                        _row('Ngày tạo', _fmt(hs.ngayTao)),
                        if (hs.tenNhanVienThucHiens != null &&
                            hs.tenNhanVienThucHiens!.isNotEmpty)
                          _row('NV thực hiện', hs.tenNhanVienThucHiens!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ScCard(
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
                  if (hs.daHoanThanh &&
                      hs.tenNhanVienThucHiens != null &&
                      hs.tenNhanVienThucHiens!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ScCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.groups_rounded,
                                  color: _scPrimary, size: 20),
                              SizedBox(width: 8),
                              Text('Nhân viên đã đảm nhận',
                                  style: TextStyle(
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
                  ],
                  const SizedBox(height: 22),
                  if (_laToTruong &&
                      (hs.choPhanCong || hs.coTheCapNhatPhanCong))
                    _gradientBtn(
                      icon: hs.coTheCapNhatPhanCong
                          ? Icons.manage_accounts_rounded
                          : Icons.groups_rounded,
                      label: hs.coTheCapNhatPhanCong
                          ? 'Cập nhật phân công'
                          : 'Phân công nhân viên',
                      onTap: () async {
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
                ],
              ),
            ),
          ),
        ],
      ),
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