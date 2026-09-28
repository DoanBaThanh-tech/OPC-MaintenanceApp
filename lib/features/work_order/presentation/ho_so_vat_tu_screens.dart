import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/material_usage_service.dart';

/// Danh sách hồ sơ vật tư — Tổ trưởng cơ điện / Giám đốc.
class HoSoVatTuListScreen extends StatefulWidget {
  /// true: Giám đốc chỉ xem hồ sơ đã gửi
  final bool chiXemDaGui;

  const HoSoVatTuListScreen({super.key, this.chiXemDaGui = false});

  @override
  State<HoSoVatTuListScreen> createState() => _HoSoVatTuListScreenState();
}

class _HoSoVatTuListScreenState extends State<HoSoVatTuListScreen> {
  List<HoSoVatTuItem> _all = [];
  bool _dangTai = true;
  String? _loi;

  /// Tổ trưởng: Chờ gửi | Chờ duyệt | Xác nhận
  static const _tabsTt = ['Chờ gửi', 'Chờ duyệt', 'Xác nhận'];
  String _tab = 'Chờ gửi';

  @override
  void initState() {
    super.initState();
    if (widget.chiXemDaGui) _tab = 'Chờ duyệt';
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final all = await MaterialUsageService.layDanhSachHoSoVatTu();
      setState(() {
        _all = all;
        _dangTai = false;
      });
    } catch (e) {
      setState(() {
        _loi = e is ApiException ? e.message : '$e';
        _dangTai = false;
        _all = [];
      });
    }
  }

  List<HoSoVatTuItem> get _list {
    if (widget.chiXemDaGui) {
      // GĐ: hồ sơ đã gửi (Chờ duyệt / Xác nhận)
      final gui = _all.where((e) => e.daGuiGiamDoc).toList();
      if (_tab == 'Xác nhận') return gui.where((e) => e.daXacNhan).toList();
      if (_tab == 'Chờ duyệt') return gui.where((e) => e.choDuyet).toList();
      return gui;
    }
    switch (_tab) {
      case 'Chờ duyệt':
        return _all.where((e) => e.choDuyet).toList();
      case 'Xác nhận':
        return _all.where((e) => e.daXacNhan).toList();
      case 'Chờ gửi':
      default:
        return _all.where((e) => e.choGui).toList();
    }
  }

  String _nhanHienThi(String tt) {
    if (tt == 'Đã gửi GĐ') return 'Chờ duyệt';
    if (tt == 'Đã xem') return 'Xác nhận';
    return tt;
  }

  String _fmtDt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTien(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf ₫';
  }

  Color _mauTrangThai(String tt) {
    final n = _nhanHienThi(tt);
    if (n == 'Xác nhận') return AppColors.success;
    if (n == 'Chờ duyệt') return const Color(0xFF2563EB);
    return const Color(0xFFD97706); // Chờ gửi
  }

  Future<void> _moChiTiet(HoSoVatTuItem item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HoSoVatTuDetailScreen(
          maHoSoVatTu: item.maHoSoVatTu,
          choPhepGuiGiamDoc: !widget.chiXemDaGui,
        ),
      ),
    );
    if (changed == true) _tai();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0068A9), Color(0xFF0284C7), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chiXemDaGui
                            ? 'Duyệt hồ sơ vật tư'
                            : 'Hồ sơ vật tư',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.chiXemDaGui
                            ? 'Hồ sơ vật tư đã gửi từ Tổ trưởng cơ điện'
                            : 'Kiểm tra và gửi thủ công cho Giám đốc',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 26),
                ),
              ],
            ),
          ),

          // ===== Thanh trạng thái (Tổ trưởng + GĐ) =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: (widget.chiXemDaGui
                    ? const ['Chờ duyệt', 'Xác nhận']
                    : _tabsTt)
                    .map((tab) {
                  final selected = _tab == tab;
                  final count = () {
                    if (tab == 'Chờ gửi') {
                      return _all.where((e) => e.choGui).length;
                    }
                    if (tab == 'Chờ duyệt') {
                      return _all.where((e) => e.choDuyet).length;
                    }
                    return _all.where((e) => e.daXacNhan).length;
                  }();
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(
                            colors: [
                              Color(0xFF0068A9),
                              Color(0xFF0EA5E9),
                            ],
                          )
                              : null,
                          color: selected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: selected
                              ? [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              tab,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: _dangTai
                ? const Center(child: CircularProgressIndicator())
                : _loi != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48,
                        color:
                        AppColors.danger.withValues(alpha: 0.7)),
                    const SizedBox(height: 12),
                    Text(_loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _tai,
                        child: const Text('Thử lại')),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _tai,
              color: AppColors.primary,
              child: _list.isEmpty
                  ? ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                      height:
                      MediaQuery.of(context).size.height *
                          0.25),
                  Icon(Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có hồ sơ · $_tab',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15),
                  ),
                ],
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 28),
                itemCount: _list.length,
                itemBuilder: (_, i) {
                  final item = _list[i];
                  return _card(item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(HoSoVatTuItem item) {
    final mau = _mauTrangThai(item.trangThai);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _moChiTiet(item),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.tenThietBi,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: mau.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _nhanHienThi(item.trangThai),
                        style: TextStyle(
                          color: mau,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      item.loaiCongViec == 'Bảo trì'
                          ? Icons.precision_manufacturing_rounded
                          : Icons.handyman_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.loaiCongViec} · ${_fmtDt(item.ngayThucHien)}',
                      style: TextStyle(
                          color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Vật tư: ${item.chiTiet.map((c) => c.tenVatTu).where((t) => t.isNotEmpty).join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _fmtTien(item.tongTien),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 15,
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

class HoSoVatTuDetailScreen extends StatefulWidget {
  final int maHoSoVatTu;
  final bool choPhepGuiGiamDoc;

  const HoSoVatTuDetailScreen({
    super.key,
    required this.maHoSoVatTu,
    this.choPhepGuiGiamDoc = true,
  });

  @override
  State<HoSoVatTuDetailScreen> createState() => _HoSoVatTuDetailScreenState();
}

class _HoSoVatTuDetailScreenState extends State<HoSoVatTuDetailScreen>
    with SingleTickerProviderStateMixin {
  HoSoVatTuItem? _item;
  bool _dangTai = true;
  bool _dangGui = false;
  String? _loi;
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _tai();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final item = await MaterialUsageService.layChiTiet(widget.maHoSoVatTu);
      if (!mounted) return;
      setState(() {
        _item = item;
        _dangTai = false;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e is ApiException ? e.message : '$e';
        _dangTai = false;
      });
    }
  }

  String _fmtDt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTien(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf ₫';
  }

  String _nhanHienThi(String tt) {
    if (tt == 'Đã gửi GĐ') return 'Chờ duyệt';
    if (tt == 'Đã xem') return 'Xác nhận';
    return tt;
  }

  int get _tongSoLuong {
    final item = _item;
    if (item == null) return 0;
    return item.chiTiet.fold<int>(0, (s, c) => s + c.soLuong);
  }

  int get _tongTien {
    final item = _item;
    if (item == null) return 0;
    if (item.tongTien > 0) return item.tongTien;
    return item.chiTiet.fold<int>(0, (s, c) => s + c.thanhTien);
  }

  Future<void> _xacNhan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận hồ sơ?'),
        content: const Text(
            'Xác nhận đã xem / duyệt hồ sơ vật tư này.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _dangGui = true);
    try {
      await MaterialUsageService.xacNhan(widget.maHoSoVatTu);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xác nhận hồ sơ vật tư'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  Future<void> _guiGiamDoc() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Gửi Giám đốc?'),
          ],
        ),
        content: const Text(
            'Hồ sơ vật tư sẽ được gửi cho Giám đốc để xem và kiểm tra.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Gửi'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _dangGui = true);
    try {
      await MaterialUsageService.guiGiamDoc(widget.maHoSoVatTu);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã gửi hồ sơ vật tư cho Giám đốc'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final item = _item;
    final showGui = widget.choPhepGuiGiamDoc &&
        item != null &&
        item.trangThai == 'Chờ gửi';
    final showXacNhan = !widget.choPhepGuiGiamDoc &&
        item != null &&
        (item.trangThai == 'Chờ duyệt' || item.trangThai == 'Đã gửi GĐ');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: Column(
        children: [
          // ===== Header gradient =====
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(8, top + 6, 16, 22),
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
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Chi tiết hồ sơ vật tư',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (item != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          _nhanHienThi(item.trangThai),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                if (item != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      item.tenThietBi,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      '${item.loaiCongViec} · ${_fmtDt(item.ngayThucHien)}'
                          '${item.tenNhanVien != null ? ' · ${item.tenNhanVien}' : ''}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: _dangTai
                ? const Center(child: CircularProgressIndicator())
                : _loi != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.danger
                            .withValues(alpha: 0.7)),
                    const SizedBox(height: 12),
                    Text(_loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _tai, child: const Text('Thử lại')),
                  ],
                ),
              ),
            )
                : item == null
                ? const Center(child: Text('Không có dữ liệu'))
                : FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                      16, 18, 16, showGui ? 12 : 24 + bottom),
                  children: [
                    // ===== Info chips =====
                    Row(
                      children: [
                        Expanded(
                          child: _statChip(
                            Icons.category_rounded,
                            'Loại',
                            item.loaiCongViec,
                            const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statChip(
                            Icons.calendar_month_rounded,
                            'Ngày',
                            _fmtDt(item.ngayThucHien),
                            const Color(0xFF0EA5E9),
                          ),
                        ),
                      ],
                    ),
                    if (item.tenNhanVien != null) ...[
                      const SizedBox(height: 10),
                      _statChip(
                        Icons.engineering_rounded,
                        'NV kỹ thuật',
                        item.tenNhanVien!,
                        const Color(0xFF0369A1),
                        full: true,
                      ),
                    ],

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                            BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Chi tiết theo bước',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_nhomChiTietTheoBuoc(item.chiTiet).length} bước',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ===== Step cards (gộp nhiều vật tư cùng bước) =====
                    ..._nhomChiTietTheoBuoc(item.chiTiet)
                        .asMap()
                        .entries
                        .map((e) {
                      final i = e.key;
                      final nhom = e.value;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 320 + i * 70),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - v)),
                            child: child,
                          ),
                        ),
                        child: _buocCardNhom(nhom),
                      );
                    }),

                    const SizedBox(height: 8),

                    // ===== Tổng số lượng + Tổng tiền =====
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0068A9),
                            Color(0xFF0284C7),
                            Color(0xFF38BDF8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.summarize_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Tổng kết hồ sơ',
                                style: TextStyle(
                                  color: Colors.white
                                      .withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _tongItem(
                                  'Tổng số lượng',
                                  '$_tongSoLuong',
                                  Icons.inventory_2_outlined,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 48,
                                color: Colors.white
                                    .withValues(alpha: 0.28),
                              ),
                              Expanded(
                                child: _tongItem(
                                  'Tổng tiền',
                                  _fmtTien(_tongTien),
                                  Icons.payments_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          if (showGui || showXacNhan)
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _dangGui
                      ? null
                      : (showGui ? _guiGiamDoc : _xacNhan),
                  icon: _dangGui
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(showGui
                      ? Icons.send_rounded
                      : Icons.verified_rounded),
                  label: Text(
                    showGui ? 'Gửi Giám đốc' : 'Xác nhận hồ sơ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value, Color color,
      {bool full = false}) {
    return Container(
      width: full ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gộp các dòng chi tiết cùng số bước thành 1 nhóm (nhiều vật tư / bước).
  List<List<ChiTietVatTuSuDung>> _nhomChiTietTheoBuoc(
      List<ChiTietVatTuSuDung> chiTiet) {
    final map = <int, List<ChiTietVatTuSuDung>>{};
    for (final c in chiTiet) {
      map.putIfAbsent(c.soBuoc, () => []).add(c);
    }
    final keys = map.keys.toList()..sort();
    return [for (final k in keys) map[k]!];
  }

  /// 1 card / bước — liệt kê tất cả vật tư của bước đó bên trong.
  Widget _buocCardNhom(List<ChiTietVatTuSuDung> dong) {
    if (dong.isEmpty) return const SizedBox.shrink();
    final soBuoc = dong.first.soBuoc;
    final moTa = dong
        .map((e) => e.moTaBuoc.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .join(' · ');
    final vatTuCoSl =
    dong.where((c) => c.tenVatTu.isNotEmpty && c.soLuong > 0).toList();
    final tongTienBuoc =
    vatTuCoSl.fold<int>(0, (s, c) => s + c.thanhTien);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.03),
                ],
              ),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0068A9), Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '$soBuoc',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bước $soBuoc',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      if (vatTuCoSl.length > 1)
                        Text(
                          '${vatTuCoSl.length} vật tư',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (vatTuCoSl.isNotEmpty)
                  Text(
                    _fmtTien(tongTienBuoc),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (moTa.isNotEmpty)
                  Text(
                    moTa,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      height: 1.4,
                      fontSize: 13.5,
                    ),
                  ),
                if (vatTuCoSl.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Không dùng vật tư',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                      fontSize: 12.5,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  for (var i = 0; i < vatTuCoSl.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Column(
                        children: [
                          if (vatTuCoSl.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Vật tư ${i + 1}/${vatTuCoSl.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary.withValues(
                                        alpha: 0.85),
                                  ),
                                ),
                              ),
                            ),
                          _miniRow(Icons.inventory_2_outlined, 'Vật tư',
                              vatTuCoSl[i].tenVatTu),
                          const SizedBox(height: 6),
                          _miniRow(Icons.numbers_rounded, 'Số lượng',
                              '${vatTuCoSl[i].soLuong}'),
                          const SizedBox(height: 6),
                          _miniRow(Icons.sell_outlined, 'Đơn giá',
                              _fmtTien(vatTuCoSl[i].donGia)),
                          const SizedBox(height: 6),
                          _miniRow(
                              Icons.payments_outlined,
                              'Thành tiền',
                              _fmtTien(vatTuCoSl[i].thanhTien),
                              bold: true),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniRow(IconData icon, String label, String value,
      {bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: Text(label,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.primary : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tongItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}