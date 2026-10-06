import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/to_truong_ke_hoach_buoc_logic.dart';

/// Khối chọn bước quy trình trên chi tiết hồ sơ (Tổ trưởng) — không chọn vật tư.
class ToTruongChonBuocQuyTrinh extends StatefulWidget {
  final int? maHoSoBaoTri;
  final int? maHoSoSuaChua;
  final int maThietBi;
  final String loaiCongViec;
  /// true = chỉ xem (đã phân công / hoàn thành)
  final bool chiXem;
  /// NVKT đã bấm Tiến hành quy trình (ThoiDiemBatDauThucTe có giá trị).
  final bool nvktDaTienHanh;
  final ValueChanged<bool>? onDaLuuChanged;

  const ToTruongChonBuocQuyTrinh({
    super.key,
    this.maHoSoBaoTri,
    this.maHoSoSuaChua,
    required this.maThietBi,
    required this.loaiCongViec,
    this.chiXem = false,
    this.nvktDaTienHanh = false,
    this.onDaLuuChanged,
  });

  @override
  State<ToTruongChonBuocQuyTrinh> createState() =>
      _ToTruongChonBuocQuyTrinhState();
}

class _ToTruongChonBuocQuyTrinhState extends State<ToTruongChonBuocQuyTrinh> {
  late final ToTruongKeHoachBuocController _ctrl;

  static const _blue = Color(0xFF0B6BCB);

  @override
  void initState() {
    super.initState();
    _ctrl = ToTruongKeHoachBuocController(
      maHoSoBaoTri: widget.maHoSoBaoTri,
      maHoSoSuaChua: widget.maHoSoSuaChua,
      maThietBi: widget.maThietBi,
      loaiCongViec: widget.loaiCongViec,
      chiXem: widget.chiXem,
      forceNvktDaTienHanh: widget.nvktDaTienHanh,
    );
    _ctrl.addListener(() {
      if (mounted) setState(() {});
      widget.onDaLuuChanged?.call(_ctrl.daLuuServer);
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.checklist_rtl_rounded,
                    color: _blue, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quy trình cần thực hiện',
                      style:
                      TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    Text(
                      widget.chiXem
                          ? 'Các bước đã chọn cho hồ sơ này'
                          : 'Tích chọn bước → bấm Lưu (không chọn vật tư)',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (_ctrl.daKhoa && !_ctrl.cheDoCapNhat)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: Colors.orange),
                      SizedBox(width: 4),
                      Text('Đã khóa',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w800,
                              fontSize: 11)),
                    ],
                  ),
                )
              else if (_ctrl.cheDoCapNhat)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_open_rounded, size: 12, color: _blue),
                      SizedBox(width: 4),
                      Text('Đang sửa',
                          style: TextStyle(
                              color: _blue,
                              fontWeight: FontWeight.w800,
                              fontSize: 11)),
                    ],
                  ),
                )
              else if (_ctrl.daLuuServer)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Đã lưu',
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 11)),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          if (_ctrl.dangTai)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_ctrl.loi != null)
            Text(_ctrl.loi!,
                style: const TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w600))
          else if (_ctrl.mau.isEmpty)
              Text(
                'Thiết bị chưa có mẫu quy trình ${widget.loaiCongViec}.',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ..._ctrl.mau.map((b) {
                final chon = _ctrl.daChon.contains(b.soBuoc);
                final khoa = !_ctrl.coTheTich;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: khoa
                        ? Colors.grey.shade100
                        : (chon
                        ? _blue.withValues(alpha: 0.06)
                        : const Color(0xFFF8FBFE)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: khoa
                          ? Colors.grey.shade300
                          : (chon
                          ? _blue.withValues(alpha: 0.35)
                          : Colors.grey.shade200),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: chon,
                    onChanged:
                    khoa ? null : (v) => _ctrl.doiTich(b.soBuoc, v),
                    activeColor: _blue,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'Bước ${b.soBuoc}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: khoa ? Colors.grey.shade600 : null,
                      ),
                    ),
                    subtitle: Text(
                      b.moTa.isEmpty ? '—' : b.moTa,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                );
              }),
          if (!widget.chiXem && _ctrl.mau.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (_ctrl.nvktDaTienHanh)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded, color: AppColors.danger, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'NVKT đã tiến hành quy trình — Tổ trưởng không được chỉnh sửa bước nữa.',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, height: 1.35),
                      ),
                    ),
                  ],
                ),
              )
            else
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _ctrl.daKhoa && !_ctrl.cheDoCapNhat
                      ? const Color(0xFFD97706)
                      : _blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _ctrl.dangLuu
                    ? null
                    : () async {
                  final dangMoKhoa =
                      _ctrl.daKhoa && !_ctrl.cheDoCapNhat;
                  final err = await _ctrl.xuLyNutChinh();
                  if (!context.mounted) return;
                  if (dangMoKhoa && err == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Đã mở khóa — tích/bỏ tích bước rồi bấm «Lưu cập nhật bước»'),
                        backgroundColor: Color(0xFFD97706),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err ??
                        'Đã lưu ${_ctrl.daChon.length} bước — đã khóa tích chọn'),
                    backgroundColor: err == null
                        ? AppColors.success
                        : AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                icon: _ctrl.dangLuu
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : Icon(_ctrl.daKhoa && !_ctrl.cheDoCapNhat
                    ? Icons.lock_open_rounded
                    : Icons.save_rounded),
                label: Text(
                  _ctrl.nhanNut,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              _ctrl.nvktDaTienHanh
                  ? 'Chỉ xem các bước đã chọn — NVKT đang/đã thực hiện quy trình.'
                  : _ctrl.daKhoa && !_ctrl.cheDoCapNhat
                  ? 'Bước đã khóa. Bấm «Cập nhật bước quy trình» để mở khóa chỉnh sửa.'
                  : _ctrl.cheDoCapNhat
                  ? 'Đang mở khóa — chỉnh tích chọn rồi bấm «Lưu cập nhật bước» để khóa lại.'
                  : 'Chọn xong và Lưu rồi mới được phân công nhân viên.',
              style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}