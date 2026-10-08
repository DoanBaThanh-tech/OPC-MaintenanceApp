part of '../work_order_repair_screens.dart';

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