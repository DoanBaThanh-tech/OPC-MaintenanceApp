import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../../equipment/data/equipment_logic.dart' show ThietBiModel;
import '../data/work_order_logic.dart';
import 'work_order_assign_screen.dart';

// Accent riêng cho sửa chữa (tím) — khác bảo trì (xanh dương)
const _scPrimary = Color(0xFF7C3AED);
const _scDark = Color(0xFF5B21B6);
const _scSoft = Color(0xFFF5F3FF);

// ============ DANH SÁCH HỒ SƠ SỬA CHỮA ============

class WorkOrderSuaChuaListScreen extends StatefulWidget {
  /// null = tất cả; 'Chờ phân công' cho Tổ trưởng ưu tiên
  final String? trangThaiMacDinh;

  /// true = hiện FAB tạo hồ sơ (vai trò Xưởng)
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

class _WorkOrderSuaChuaListScreenState extends State<WorkOrderSuaChuaListScreen> {
  late final WorkOrderSuaChuaListController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = WorkOrderSuaChuaListController(
        trangThaiMacDinh: widget.trangThaiMacDinh);
    _ctrl.tai();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tai() async {
    await _ctrl.tai();
    if (mounted) setState(() {});
  }

  Color _mauTt(String tt) {
    switch (tt) {
      case 'Chờ phân công':
      case 'Đã duyệt':
        return const Color(0xFFD97706);
      case 'Đang thực hiện':
        return _scPrimary;
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      floatingActionButton: widget.hienFabTao
          ? FloatingActionButton.extended(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, __) => const TaoHoSoSuaChuaScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
            ),
          );
          if (ok == true) _tai();
        },
        backgroundColor: _scPrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tạo hồ sơ SC',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      )
          : null,
      body: _ctrl.dangTai
          ? const Center(child: CircularProgressIndicator(color: _scPrimary))
          : _ctrl.loi != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_ctrl.loi!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: _tai,
                style: FilledButton.styleFrom(
                    backgroundColor: _scPrimary),
                child: const Text('Thử lại')),
          ],
        ),
      )
          : RefreshIndicator(
        color: _scPrimary,
        onRefresh: _tai,
        child: _ctrl.danhSach.isEmpty
            ? ListView(
          children: [
            SizedBox(
                height:
                MediaQuery.of(context).size.height * 0.25),
            Icon(Icons.handyman_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Chưa có hồ sơ sửa chữa',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: _ctrl.danhSach.length,
          itemBuilder: (context, i) {
            final hs = _ctrl.danhSach[i];
            final c = _mauTt(hs.trangThai);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 280 + i * 35),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - t)),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChiTietHoSoSuaChuaScreen(
                                  maHoSo: hs.maHoSoSuaChua),
                        ),
                      );
                      if (changed == true) _tai();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _scSoft,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.handyman_rounded,
                                    color: _scPrimary,
                                    size: 22),
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
                                          fontWeight:
                                          FontWeight.w800,
                                          fontSize: 15),
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'HS SC #${hs.maHoSoSuaChua}',
                                      style: TextStyle(
                                          color: Colors
                                              .grey.shade600,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5),
                                decoration: BoxDecoration(
                                  color: c.withValues(
                                      alpha: 0.12),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: Text(
                                  hs.trangThai,
                                  style: TextStyle(
                                      color: c,
                                      fontWeight:
                                      FontWeight.w700,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          if (hs.moTaHuHong != null &&
                              hs.moTaHuHong!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              hs.moTaHuHong!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                  height: 1.35),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 14,
                                  color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hs.tenNhanVienTao ?? '—',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                      Colors.grey.shade600),
                                  overflow:
                                  TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${hs.ngayTao.day.toString().padLeft(2, '0')}/${hs.ngayTao.month.toString().padLeft(2, '0')}/${hs.ngayTao.year}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                    Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============ TẠO HỒ SƠ SỬA CHỮA (XƯỞNG) ============
// Presentation only — ràng buộc nghiệp vụ ở CreateHoSoSuaChuaController

class TaoHoSoSuaChuaScreen extends StatefulWidget {
  const TaoHoSoSuaChuaScreen({super.key});

  @override
  State<TaoHoSoSuaChuaScreen> createState() => _TaoHoSoSuaChuaScreenState();
}

class _TaoHoSoSuaChuaScreenState extends State<TaoHoSoSuaChuaScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = CreateHoSoSuaChuaController();
  final _moTaCtrl = TextEditingController();
  final _phuongAnCtrl = TextEditingController();
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _ctrl.khoiTao().then((_) {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefixIcon,
        errorText: errorText,
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(8, top + 6, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_scPrimary, _scDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: _scPrimary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tạo hồ sơ sửa chữa',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hư đột ngột → sửa ngay trong ngày',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDBA74)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: Color(0xFFC2410C), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Hư đột ngột cần sửa liền — ngày sửa chữa cố định hôm nay. Chỉ chọn thiết bị đang Sản xuất; sau khi tạo, thiết bị chuyển Sửa chữa và không lập được hồ sơ bảo trì cho đến khi hoàn thành SC.',
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: Color(0xFF9A3412),
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Ngày sửa chữa (logic: cố định hôm nay)
                      const Text('Ngày sửa chữa *',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14.5)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: _scSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _scPrimary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: _scPrimary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _ctrl.ngaySuaChuaHienThi,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cố định hôm nay — hư đột ngột cần sửa liền',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _scPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Hôm nay',
                                style: TextStyle(
                                    color: _scPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Danh mục
                      const Text('Danh mục thiết bị *',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14.5)),
                      const SizedBox(height: 8),
                      if (_ctrl.dangTai)
                        const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child:
                              CircularProgressIndicator(color: _scPrimary),
                            ))
                      else if (_ctrl.nhoms.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                              'Không có thiết bị đang Sản xuất để tạo hồ sơ SC.'),
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

                      // Thiết bị theo danh mục
                      const Text('Thiết bị hư hỏng *',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14.5)),
                      const SizedBox(height: 8),
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
                                Icons.precision_manufacturing,
                                color: _scPrimary),
                          ),
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

                      const Text('Mô tả hư hỏng *',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _moTaCtrl,
                        maxLines: 4,
                        onChanged: (_) => _ctrl.xoaLoiMoTa(),
                        decoration: _fieldDeco(
                          hint:
                          'Mô tả hiện tượng hư hỏng, vị trí, mức độ…',
                          errorText: _ctrl.loiMoTa,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Phương án sửa chữa (tuỳ chọn)',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phuongAnCtrl,
                        maxLines: 3,
                        decoration: _fieldDeco(
                          hint: 'Gợi ý cách xử lý nếu có…',
                        ),
                      ),
                      if (_ctrl.loi != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                            AppColors.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_ctrl.loi!,
                              style: const TextStyle(color: AppColors.danger)),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _scPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _ctrl.dangGui ? null : _gui,
                          child: _ctrl.dangGui
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white),
                          )
                              : const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded),
                              SizedBox(width: 8),
                              Text('Gửi Tổ trưởng phân công',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ],
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

class _ChiTietHoSoSuaChuaScreenState extends State<ChiTietHoSoSuaChuaScreen> {
  late final ChiTietHoSoSuaChuaController _ctrl;

  bool get _laToTruong => _ctrl.laToTruong;
  bool get _laNvkt => _ctrl.laNvkt;

  @override
  void initState() {
    super.initState();
    _ctrl = ChiTietHoSoSuaChuaController(widget.maHoSo);
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _ctrl.tai();
    if (mounted) setState(() {});
  }

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    if (_ctrl.dangTai) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _scPrimary)),
      );
    }
    if (_ctrl.loi != null || _ctrl.hoSo == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Chi tiết SC'),
            backgroundColor: _scPrimary,
            foregroundColor: Colors.white),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_ctrl.loi ?? 'Không có dữ liệu'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: _scPrimary),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    final hs = _ctrl.hoSo!;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      appBar: AppBar(
        title: Text('Hồ sơ SC #${hs.maHoSoSuaChua}'),
        backgroundColor: _scPrimary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - t)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_scPrimary, _scDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _scPrimary.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.handyman_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hs.tenThietBi,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(hs.trangThai,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _infoCard([
            _row('Người tạo', hs.tenNhanVienTao ?? '—'),
            _row('Ngày tạo', _fmt(hs.ngayTao)),
            if (hs.tenNhanVienThucHiens != null &&
                hs.tenNhanVienThucHiens!.isNotEmpty)
              _row('NV thực hiện', hs.tenNhanVienThucHiens!),
          ]),
          const SizedBox(height: 12),
          _infoCard([
            const Text('Mô tả hư hỏng',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 8),
            Text(hs.moTaHuHong ?? '—',
                style: TextStyle(height: 1.4, color: Colors.grey.shade800)),
            if (hs.phuongAnSuaChua != null &&
                hs.phuongAnSuaChua!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Phương án SC',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 6),
              Text(hs.phuongAnSuaChua!,
                  style: TextStyle(height: 1.4, color: Colors.grey.shade800)),
            ],
          ]),
          if (hs.daHoanThanh &&
              hs.tenNhanVienThucHiens != null &&
              hs.tenNhanVienThucHiens!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoCard([
              const Row(
                children: [
                  Icon(Icons.groups_rounded, color: _scPrimary, size: 20),
                  SizedBox(width: 8),
                  Text('Nhân viên đã đảm nhận',
                      style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Text(hs.tenNhanVienThucHiens!,
                  style: TextStyle(height: 1.4, color: Colors.grey.shade800)),
            ]),
          ],
          const SizedBox(height: 20),
          if (_laToTruong && (hs.choPhanCong || hs.coTheCapNhatPhanCong))
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _scPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(hs.coTheCapNhatPhanCong
                  ? Icons.manage_accounts_rounded
                  : Icons.groups_rounded),
              label: Text(hs.coTheCapNhatPhanCong
                  ? 'Cập nhật phân công'
                  : 'Phân công nhân viên'),
              onPressed: () async {
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
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('Hoàn thành sửa chữa'),
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
          ],
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
            width: 120,
            child: Text(l,
                style:
                TextStyle(color: Colors.grey.shade600, fontSize: 13))),
        Expanded(
          child: Text(v,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13.5)),
        ),
      ],
    ),
  );
}