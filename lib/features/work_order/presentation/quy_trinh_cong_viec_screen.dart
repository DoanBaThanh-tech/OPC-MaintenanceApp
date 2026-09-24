import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/models/work_order_models.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/work_order_service.dart';
import '../data/services/material_usage_service.dart';

/// Trang 2: Quy trình bảo trì / sửa chữa — từng bước + kết quả thực hiện + Hoàn thành.
/// Nút Hoàn thành đồng bộ trạng thái hồ sơ / phân công / thiết bị cho mọi vai trò.
class QuyTrinhCongViecScreen extends StatefulWidget {
  final YeuCauPhanCong yeuCau;

  const QuyTrinhCongViecScreen({super.key, required this.yeuCau});

  @override
  State<QuyTrinhCongViecScreen> createState() => _QuyTrinhCongViecScreenState();
}

class _QuyTrinhCongViecScreenState extends State<QuyTrinhCongViecScreen>
    with TickerProviderStateMixin {
  List<BuocQuyTrinh> _buoc = [];
  final Map<int, TextEditingController> _ketQuaCtrls = {};
  final Map<int, bool> _daXongBuoc = {};
  bool _dangTai = true;
  String? _loiTai;
  bool _dangXuLy = false;
  late final AnimationController _headerAnim;
  late final AnimationController _pulseAnim;

  bool get _laBaoTri => widget.yeuCau.laBaoTri;

  bool get _tatCaBuocCoKetQua {
    if (_buoc.isEmpty) return false;
    for (final b in _buoc) {
      final text = _ketQuaCtrls[b.soBuoc]?.text.trim() ?? '';
      if (text.isEmpty) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _taiQuyTrinh();
  }

  Future<void> _taiQuyTrinh() async {
    setState(() {
      _dangTai = true;
      _loiTai = null;
    });
    try {
      final y = widget.yeuCau;
      final loai = _laBaoTri ? 'Bảo trì' : 'Sửa chữa';
      final maTb = y.maThietBi ?? 0;
      final buoc = maTb > 0
          ? await MaterialUsageService.layQuyTrinhThietBi(
        maThietBi: maTb,
        loaiCongViec: loai,
      )
          : <BuocQuyTrinh>[];
      if (!mounted) return;
      for (final c in _ketQuaCtrls.values) {
        c.dispose();
      }
      _ketQuaCtrls.clear();
      _daXongBuoc.clear();
      for (final b in buoc) {
        _ketQuaCtrls[b.soBuoc] = TextEditingController();
        _daXongBuoc[b.soBuoc] = false;
      }
      setState(() {
        _buoc = buoc;
        _dangTai = false;
        if (buoc.isEmpty) {
          _loiTai = maTb <= 0
              ? 'Thiếu mã thiết bị.'
              : 'Chưa có quy trình $loai cho thiết bị trong database.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loiTai = e.toString();
        _dangTai = false;
        _buoc = [];
      });
    }
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _pulseAnim.dispose();
    for (final c in _ketQuaCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _hoanThanh() async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;

    if (!_tatCaBuocCoKetQua) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vui lòng điền kết quả thực hiện cho tất cả các bước trước khi hoàn thành.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  _laBaoTri ? 'Hoàn thành bảo trì?' : 'Hoàn thành sửa chữa?'),
            ),
          ],
        ),
        content: const Text(
          'Xác nhận đã hoàn thành toàn bộ quy trình. Hệ thống sẽ đồng bộ trạng thái hồ sơ, phân công và thiết bị trên tất cả các vai trò.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _dangXuLy = true);
    try {
      // Gộp kết quả các bước (ghi chú phân công nếu có API)
      final buffer = StringBuffer();
      for (final b in _buoc) {
        final kq = _ketQuaCtrls[b.soBuoc]?.text.trim() ?? '';
        buffer.writeln('Bước ${b.soBuoc}: $kq');
      }
      if (y.maPhanCong != null && buffer.isNotEmpty) {
        try {
          await WorkOrderService.ghiNhanKetQua(
            maPhanCong: y.maPhanCong!,
            maNhanVienGhiNhan: 0,
            ghiChu: buffer.toString().trim(),
            soLieuGhiNhan: buffer.toString().trim(),
          );
        } catch (_) {
          // Không chặn hoàn thành nếu đã có kết quả / API lệch trạng thái PC
        }
      }

      // Đồng bộ trạng thái HS + PC + thiết bị cho mọi vai trò
      if (_laBaoTri) {
        await WorkOrderService.nhanVienHoanThanhBaoTri(y.maHoSo!);
      } else {
        await WorkOrderService.nhanVienHoanThanhSuaChua(y.maHoSo!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_laBaoTri
              ? 'Đã hoàn thành bảo trì — trạng thái đã đồng bộ'
              : 'Đã hoàn thành sửa chữa — trạng thái đã đồng bộ'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final title = _laBaoTri ? 'Quy trình bảo trì' : 'Quy trình sửa chữa';
    final subtitle = widget.yeuCau.tenThietBi ?? 'Thiết bị';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _canhBaoKhongQuayLai();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6FB),
        body: Column(
          children: [
            // Header hiện đại
            FadeTransition(
              opacity: CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(0, -0.2), end: Offset.zero)
                    .animate(CurvedAnimation(
                    parent: _headerAnim, curve: Curves.easeOutCubic)),
                child: Container(
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
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(26)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _canhBaoKhongQuayLai,
                        icon: const Icon(Icons.lock_outline_rounded,
                            color: Colors.white70),
                        tooltip: 'Phải hoàn thành quy trình',
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 19,
                                    letterSpacing: -0.3)),
                            const SizedBox(height: 4),
                            Text(subtitle,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) {
                          final s = 0.92 + 0.08 * _pulseAnim.value;
                          return Transform.scale(
                            scale: s,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color:
                                    Colors.white.withValues(alpha: 0.35)),
                              ),
                              child: Icon(
                                _laBaoTri
                                    ? Icons.build_circle_rounded
                                    : Icons.handyman_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Progress chips
            if (!_dangTai && _buoc.isNotEmpty)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    for (var i = 0; i < _buoc.length; i++) ...[
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: (_daXongBuoc[_buoc[i].soBuoc] == true)
                                  ? AppColors.primary
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      _stepDot(_buoc[i].soBuoc),
                    ],
                  ],
                ),
              ),

            if (_dangTai) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _dangTai
                  ? const Center(child: CircularProgressIndicator())
                  : _loiTai != null && _buoc.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_loiTai!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: _taiQuyTrinh,
                          child: const Text('Thử lại')),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _buoc.length,
                itemBuilder: (_, i) =>
                    _buildBuocCard(_buoc[i], i),
              ),
            ),

            // Footer Hoàn thành
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _tatCaBuocCoKetQua
                        ? 'Đã điền đủ kết quả — có thể hoàn thành'
                        : 'Điền kết quả thực hiện từng bước để bật nút Hoàn thành',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _tatCaBuocCoKetQua
                          ? AppColors.success
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: (_dangXuLy || !_tatCaBuocCoKetQua)
                        ? null
                        : _hoanThanh,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _dangXuLy
                        ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Hoàn thành',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _canhBaoKhongQuayLai() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Không thể quay lại'),
        content: Text(
          _laBaoTri
              ? 'Bạn đang trong quy trình bảo trì. Hãy điền kết quả từng bước và bấm Hoàn thành. Không được quay lại để tránh trùng / lệch trạng thái hồ sơ.'
              : 'Bạn đang trong quy trình sửa chữa. Hãy điền kết quả từng bước và bấm Hoàn thành. Không được quay lại để tránh trùng / lệch trạng thái hồ sơ.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int soBuoc) {
    final done = _daXongBuoc[soBuoc] == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? AppColors.primary : Colors.white,
        border: Border.all(
            color: done ? AppColors.primary : const Color(0xFFCBD5E1),
            width: 2),
        shape: BoxShape.circle,
        boxShadow: done
            ? [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 8)
        ]
            : null,
      ),
      child: done
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Text('$soBuoc',
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Color(0xFF64748B))),
    );
  }

  Widget _buildBuocCard(BuocQuyTrinh b, int index) {
    final done = _daXongBuoc[b.soBuoc] == true;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - t)),
          child: child,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done
                ? AppColors.primary.withValues(alpha: 0.45)
                : const Color(0xFFE2E8F0),
            width: done ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (done ? AppColors.primary : Colors.black)
                  .withValues(alpha: done ? 0.1 : 0.04),
              blurRadius: done ? 16 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: done
                          ? [AppColors.success, const Color(0xFF34D399)]
                          : [AppColors.primary, const Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: (done ? AppColors.success : AppColors.primary)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20)
                      : Text('${b.soBuoc}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bước ${b.soBuoc}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: done
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.moTa,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Kết quả thực hiện',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ketQuaCtrls[b.soBuoc],
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung kết quả thực hiện bước này…',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: done
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _daXongBuoc[b.soBuoc] = v.trim().isNotEmpty;
                  b.ketQuaThucHien = v;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}