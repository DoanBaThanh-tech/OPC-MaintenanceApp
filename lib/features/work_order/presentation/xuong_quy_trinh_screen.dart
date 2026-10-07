import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/xuong_quy_trinh_logic.dart';
import '../data/models/work_order_models.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/work_order_service.dart';
import '../data/services/material_usage_service.dart';

/// Trang **Quy trình** của Xưởng — nhận quy trình NVKT đã bấm Xong.
/// Tab Bảo trì / Sửa chữa; chi tiết: bước + vật tư + Xác nhận / Từ chối.
class XuongQuyTrinhScreen extends StatefulWidget {
  const XuongQuyTrinhScreen({super.key});

  @override
  State<XuongQuyTrinhScreen> createState() => _XuongQuyTrinhScreenState();
}

class _XuongQuyTrinhScreenState extends State<XuongQuyTrinhScreen>
    with TickerProviderStateMixin {
  static const _blue = Color(0xFF0068A9);
  static const _blueMid = Color(0xFF0284C7);
  static const _blueSoft = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF0F7FC);

  final _ctrl = XuongQuyTrinhController();
  late final TabController _tab;
  late final AnimationController _headerAnim;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _ctrl.doiTab(_tab.index);
    });
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _tab.dispose();
    _headerAnim.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final nBt = _ctrl.dsBaoTri.length;
    final nSc = _ctrl.dsSuaChua.length;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          FadeTransition(
            opacity:
            CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.12),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOutCubic)),
              child: Container(
                width: double.infinity,
                // Không nút back: trang mở trong body Dashboard (slide menu),
                // pop() sẽ thoát luôn shell → màn hình đen.
                padding: EdgeInsets.fromLTRB(20, top + 12, 16, 0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_blue, _blueMid, _blueSoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.32),
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
                        const Expanded(
                          child: Text(
                            'Quy trình',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${nBt + nSc} chờ duyệt',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 8, 8),
                      child: Text(
                        'Quy trình NVKT đã gửi — Xác nhận hoặc Từ chối',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TabBar(
                      controller: _tab,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor:
                      Colors.white.withValues(alpha: 0.65),
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14.5),
                      tabs: [
                        Tab(text: 'Bảo trì ($nBt)'),
                        Tab(text: 'Sửa chữa ($nSc)'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _ctrl.dangTai
                ? const Center(
              child: CircularProgressIndicator(color: _blue),
            )
                : _ctrl.loi != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_ctrl.loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _ctrl.tai,
                      style: FilledButton.styleFrom(
                          backgroundColor: _blue),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
                : TabBarView(
              controller: _tab,
              children: [
                _buildListBt(),
                _buildListSc(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListBt() {
    final list = _ctrl.dsBaoTri;
    if (list.isEmpty) return _empty('Chưa có quy trình bảo trì chờ xác nhận');
    return RefreshIndicator(
      onRefresh: _ctrl.tai,
      color: _blue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final hs = list[i];
          return _card(
            index: i,
            title: hs.tenThietBi.isNotEmpty
                ? hs.tenThietBi
                : 'HS #${hs.maHoSoBaoTri}',
            subtitle: 'Hồ sơ #${hs.maHoSoBaoTri}',
            ngay: hs.ngayTao,
            icon: Icons.precision_manufacturing_rounded,
            onTap: () => _moChiTiet(
              laBaoTri: true,
              maHoSo: hs.maHoSoBaoTri,
              maThietBi: hs.maThietBi,
              tenThietBi: hs.tenThietBi,
              noiDung: hs.noiDungCongViec,
            ),
          );
        },
      ),
    );
  }

  Widget _buildListSc() {
    final list = _ctrl.dsSuaChua;
    if (list.isEmpty) return _empty('Chưa có quy trình sửa chữa chờ xác nhận');
    return RefreshIndicator(
      onRefresh: _ctrl.tai,
      color: _blue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final hs = list[i];
          return _card(
            index: i,
            title: hs.tenThietBi.isNotEmpty
                ? hs.tenThietBi
                : 'HS #${hs.maHoSoSuaChua}',
            subtitle: 'Hồ sơ SC #${hs.maHoSoSuaChua}',
            ngay: hs.ngayTao,
            icon: Icons.handyman_rounded,
            onTap: () => _moChiTiet(
              laBaoTri: false,
              maHoSo: hs.maHoSoSuaChua,
              maThietBi: hs.maThietBi,
              tenThietBi: hs.tenThietBi,
              noiDung: hs.moTaHuHong,
            ),
          );
        },
      ),
    );
  }

  Widget _empty(String msg) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: _ctrl.tai,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Làm mới'),
          ),
        ),
      ],
    );
  }

  Widget _card({
    required int index,
    required String title,
    required String subtitle,
    required DateTime ngay,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0F2FE)),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_blue, _blueSoft],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$subtitle · ${_fmt(ngay)}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12.5),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Chờ xác nhận',
                            style: TextStyle(
                              color: Color(0xFF0284C7),
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _moChiTiet({
    required bool laBaoTri,
    required int maHoSo,
    required int maThietBi,
    required String tenThietBi,
    String? noiDung,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => XuongQuyTrinhChiTietScreen(
          laBaoTri: laBaoTri,
          maHoSo: maHoSo,
          maThietBi: maThietBi,
          tenThietBi: tenThietBi,
          noiDungHoSo: noiDung,
          controller: _ctrl,
        ),
      ),
    );
    if (changed == true) await _ctrl.tai();
  }
}

// ============ CHI TIẾT QUY TRÌNH ============

class XuongQuyTrinhChiTietScreen extends StatefulWidget {
  final bool laBaoTri;
  final int maHoSo;
  final int maThietBi;
  final String tenThietBi;
  final String? noiDungHoSo;
  final XuongQuyTrinhController controller;

  const XuongQuyTrinhChiTietScreen({
    super.key,
    required this.laBaoTri,
    required this.maHoSo,
    required this.maThietBi,
    required this.tenThietBi,
    this.noiDungHoSo,
    required this.controller,
  });

  @override
  State<XuongQuyTrinhChiTietScreen> createState() =>
      _XuongQuyTrinhChiTietScreenState();
}

class _XuongQuyTrinhChiTietScreenState extends State<XuongQuyTrinhChiTietScreen> {
  static const _blue = Color(0xFF0068A9);
  static const _blueMid = Color(0xFF0284C7);
  static const _blueSoft = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF0F7FC);

  HoSoVatTuItem? _hsVt;
  /// Toàn bộ bước quy trình (kể cả chưa tích) + trạng thái NVKT.
  List<_BuocXuongView> _dsBuocFull = [];
  bool _dangTai = true;
  bool _dangXuLy = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final loai = widget.laBaoTri ? 'Bảo trì' : 'Sửa chữa';
      final results = await Future.wait([
        widget.controller.layQuyTrinhVatTu(
          maHoSoBaoTri: widget.laBaoTri ? widget.maHoSo : null,
          maHoSoSuaChua: widget.laBaoTri ? null : widget.maHoSo,
        ),
        WorkOrderService.layTienDoBuoc(
          maHoSoBaoTri: widget.laBaoTri ? widget.maHoSo : null,
          maHoSoSuaChua: widget.laBaoTri ? null : widget.maHoSo,
        ),
        widget.maThietBi > 0
            ? MaterialUsageService.layQuyTrinhThietBi(
          maThietBi: widget.maThietBi,
          loaiCongViec: loai,
        )
            : Future.value(<BuocQuyTrinh>[]),
      ]);
      final hs = results[0] as HoSoVatTuItem?;
      final tienDo = results[1] as List<Map<String, dynamic>>;
      final mau = results[2] as List<BuocQuyTrinh>;

      // Map vật tư theo bước từ hồ sơ VT
      final vtTheoBuoc = <int, List<ChiTietVatTuSuDung>>{};
      if (hs != null) {
        for (final c in hs.chiTiet) {
          vtTheoBuoc.putIfAbsent(c.soBuoc, () => []).add(c);
        }
      }

      // Map tiến độ NVKT theo bước
      final tdTheoBuoc = <int, Map<String, dynamic>>{};
      for (final row in tienDo) {
        final so = (row['soBuoc'] as num?)?.toInt() ??
            (row['SoBuoc'] as num?)?.toInt();
        if (so == null) continue;
        tdTheoBuoc[so] = row;
      }

      // Hợp nhất: ưu tiên mẫu 10 bước thiết bị, bổ sung bước chỉ có trong tiến độ/VT
      final soBuocSet = <int>{};
      for (final b in mau) {
        soBuocSet.add(b.soBuoc);
      }
      soBuocSet.addAll(tdTheoBuoc.keys);
      soBuocSet.addAll(vtTheoBuoc.keys);
      final sorted = soBuocSet.toList()..sort();

      final views = <_BuocXuongView>[];
      for (final so in sorted) {
        String? mauB;
        for (final e in mau) {
          if (e.soBuoc == so) {
            mauB = e.moTa;
            break;
          }
        }
        final td = tdTheoBuoc[so];
        final moTaTd = (td?['moTaBuoc'] ?? td?['MoTaBuoc'])?.toString();
        final tt = (td?['trangThai'] ?? td?['TrangThai'])?.toString() ?? '';
        final tenNv = (td?['tenNhanVien'] ?? td?['TenNhanVien'])?.toString();
        final moTaVt = vtTheoBuoc[so]
            ?.map((e) => e.moTaBuoc.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .join(' · ');
        final daThucHien = tt == 'DaXong' ||
            tt == 'DaCapNhat' ||
            (vtTheoBuoc[so]?.any((c) => c.soLuong > 0) ?? false);
        final daChon = daThucHien ||
            tt == 'DangLam' ||
            tt == 'DuocChon' ||
            (vtTheoBuoc.containsKey(so));
        views.add(_BuocXuongView(
          soBuoc: so,
          moTa: (moTaTd != null && moTaTd.isNotEmpty)
              ? moTaTd
              : (moTaVt != null && moTaVt.isNotEmpty)
              ? moTaVt
              : (mauB ?? 'Bước $so'),
          trangThai: tt,
          tenNhanVien: tenNv,
          daThucHien: daThucHien,
          daChon: daChon,
          vatTu: vtTheoBuoc[so] ?? const [],
        ));
      }

      if (!mounted) return;
      setState(() {
        _hsVt = hs;
        _dsBuocFull = views;
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e is ApiException ? e.message : '$e';
        _dangTai = false;
      });
    }
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

  Future<void> _xacNhan() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận quy trình?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Hồ sơ sẽ chuyển sang Hoàn thành và đồng bộ cho mọi vai trò.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _dangXuLy = true);
    final (success, msg) = await widget.controller.xacNhan(
      maHoSoBaoTri: widget.laBaoTri ? widget.maHoSo : null,
      maHoSoSuaChua: widget.laBaoTri ? null : widget.maHoSo,
    );
    if (!mounted) return;
    setState(() => _dangXuLy = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận — hồ sơ Hoàn thành'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg ?? 'Lỗi'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _tuChoi() async {
    final lyDoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Từ chối quy trình',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ghi rõ bước cần thêm/bỏ hoặc vật tư cần chỉnh để NVKT cập nhật lại.',
              style: TextStyle(height: 1.35),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lyDoCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Lý do từ chối…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _dangXuLy = true);
    final (success, msg) = await widget.controller.tuChoi(
      maHoSoBaoTri: widget.laBaoTri ? widget.maHoSo : null,
      maHoSoSuaChua: widget.laBaoTri ? null : widget.maHoSo,
      lyDo: lyDoCtrl.text,
    );
    lyDoCtrl.dispose();
    if (!mounted) return;
    setState(() => _dangXuLy = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã từ chối — NVKT có thể cập nhật quy trình'),
          backgroundColor: AppColors.danger,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg ?? 'Lỗi'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(8, top + 4, 16, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_blue, _blueMid, _blueSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.3),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.laBaoTri
                            ? 'Quy trình bảo trì'
                            : 'Quy trình sửa chữa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.tenThietBi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _dangTai
                ? const Center(child: CircularProgressIndicator(color: _blue))
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _infoBox(
                  'Hồ sơ #${widget.maHoSo} · ${widget.laBaoTri ? 'Bảo trì' : 'Sửa chữa'}',
                  widget.tenThietBi,
                ),
                if (widget.noiDungHoSo != null &&
                    widget.noiDungHoSo!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _sectionCard(
                    'Nội dung hồ sơ',
                    Text(widget.noiDungHoSo!,
                        style: const TextStyle(height: 1.4)),
                  ),
                ],
                const SizedBox(height: 14),
                if (_loi != null)
                  Text(_loi!, style: const TextStyle(color: AppColors.danger))
                else
                  _buildBuocVatTu(),
              ],
            ),
          ),
          if (!_dangTai)
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _dangXuLy ? null : _tuChoi,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Từ chối',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      onPressed: _dangXuLy ? null : _xacNhan,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _dangXuLy
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white),
                      )
                          : const Text('Xác nhận',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoBox(String sub, String title) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient:
              const LinearGradient(colors: [_blue, _blueSoft]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.laBaoTri
                  ? Icons.precision_manufacturing_rounded
                  : Icons.handyman_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 2),
                Text(sub,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildBuocVatTu() {
    if (_dsBuocFull.isEmpty) {
      return _sectionCard(
        'Quy trình thực hiện',
        Text(
          'Chưa có dữ liệu quy trình cho hồ sơ này.',
          style: TextStyle(
              color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      );
    }

    final soDaLam = _dsBuocFull.where((e) => e.daThucHien).length;
    final soVt = _dsBuocFull.fold<int>(
        0,
            (a, b) =>
        a +
            b.vatTu.where((c) => c.tenVatTu.isNotEmpty && c.soLuong > 0).length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quy trình thực hiện',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 4),
        Text(
          '${_dsBuocFull.length} bước (đủ quy trình) · $soDaLam đã làm · $soVt dòng vật tư',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        for (final b in _dsBuocFull)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 240 + b.soBuoc * 35),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - t)),
                child: child,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: b.daThucHien
                    ? Colors.white
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: b.daThucHien
                      ? const Color(0xFFBAE6FD)
                      : Colors.grey.shade200,
                ),
                boxShadow: b.daThucHien
                    ? [
                  BoxShadow(
                    color: _blue.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: b.daThucHien
                              ? const LinearGradient(
                              colors: [_blue, _blueSoft])
                              : null,
                          color: b.daThucHien ? null : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${b.soBuoc}',
                          style: TextStyle(
                              color: b.daThucHien
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w900,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b.moTa.isEmpty ? 'Bước ${b.soBuoc}' : b.moTa,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: b.daThucHien
                                ? const Color(0xFF0F172A)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: b.daThucHien
                              ? const Color(0xFFD1FAE5)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          b.daThucHien
                              ? 'Đã thực hiện'
                              : (b.daChon ? 'Đã chọn / nháp' : 'Không làm'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: b.daThucHien
                                ? const Color(0xFF047857)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((b.tenNhanVien ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'NVKT: ${b.tenNhanVien}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                  if (b.vatTu.any((c) => c.tenVatTu.isNotEmpty && c.soLuong > 0)) ...[
                    const SizedBox(height: 8),
                    for (final c in b.vatTu)
                      if (c.tenVatTu.isNotEmpty && c.soLuong > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 16, color: _blue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${c.tenVatTu} × ${c.soLuong}',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ] else if (!b.daThucHien) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Không có vật tư — bước không được NVKT hoàn thành.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BuocXuongView {
  final int soBuoc;
  final String moTa;
  final String trangThai;
  final String? tenNhanVien;
  final bool daThucHien;
  final bool daChon;
  final List<ChiTietVatTuSuDung> vatTu;
  _BuocXuongView({
    required this.soBuoc,
    required this.moTa,
    required this.trangThai,
    this.tenNhanVien,
    required this.daThucHien,
    required this.daChon,
    required this.vatTu,
  });
}