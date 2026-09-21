import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_exception.dart';

// ============ MÀN 4: PHÂN CÔNG NHÂN VIÊN ============

class PhanCongBaoTriScreen extends StatefulWidget {
  final int maHoSoBaoTri;
  const PhanCongBaoTriScreen({super.key, required this.maHoSoBaoTri});

  @override
  State<PhanCongBaoTriScreen> createState() => _PhanCongBaoTriScreenState();
}

class _PhanCongBaoTriScreenState extends State<PhanCongBaoTriScreen> {
  final _controller = PhanCongBaoTriController();

  @override
  void initState() {
    super.initState();
    _controller.khoiTao(widget.maHoSoBaoTri);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _xacNhan() async {
    final ok = await _controller.xacNhan(widget.maHoSoBaoTri);
    if (ok && mounted) Navigator.pop(context, true);
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '—';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phân công công việc'),
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

          final hs = _controller.hoSo;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // ===== Header hồ sơ =====
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.precision_manufacturing_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hs?.tenThietBi ?? 'Thiết bị',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Hồ sơ #${widget.maHoSoBaoTri}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Người phân công: ${_controller.tenNguoiPhanCong ?? '—'}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Khung giờ từ hồ sơ (chỉ đọc) =====
                    Container(
                      padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Khung giờ theo hồ sơ',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Giờ lấy đúng từ hồ sơ bảo trì đã tạo — không chỉnh tại đây',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeInfoChip(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Ngày bảo trì',
                                  value: _fmtDate(_controller.ngayDuKien),
                                  color: const Color(0xFF0068A9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeInfoChip(
                                  icon: Icons.play_circle_rounded,
                                  label: 'Giờ bắt đầu',
                                  value: _fmtTime(_controller.gioBatDau),
                                  color: const Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TimeInfoChip(
                                  icon: Icons.stop_circle_rounded,
                                  label: 'Giờ kết thúc',
                                  value: _fmtTime(_controller.gioKetThuc),
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== Chọn NVKT =====
                    const Text(
                      'Chọn nhân viên thực hiện',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chọn nhân viên kỹ thuật. Nếu ai đã từ chối hồ sơ này thì không chọn lại được (thiết bị khác vẫn bình thường).',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (_controller.tenNhanVienBiLoai != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF5C896)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFC2410C)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_controller.tenNhanVienBiLoai} đã từ chối hồ sơ này — bấm chọn sẽ báo nhắc chọn người khác.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9A3412),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    if (_controller.dsNhanVien.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              _controller.loi ?? 'Không có nhân viên kỹ thuật trong hệ thống.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._controller.dsNhanVien.map((nv) {
                        final dangChon = _controller.chon?.maNhanVien == nv.maNhanVien;
                        final biTuChoi = _controller.laNhanVienBiTuChoi(nv.maNhanVien);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: biTuChoi
                                ? const Color(0xFFFFF8F0)
                                : (dangChon
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => _controller.chonNhanVien(nv),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: biTuChoi
                                        ? const Color(0xFFF5C896)
                                        : (dangChon ? AppColors.primary : Colors.grey.shade200),
                                    width: dangChon && !biTuChoi ? 1.6 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: biTuChoi
                                          ? const Color(0xFFFFEDD5)
                                          : (dangChon ? AppColors.primary : Colors.grey.shade200),
                                      child: Text(
                                        nv.hoTen.isNotEmpty ? nv.hoTen[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: biTuChoi
                                              ? const Color(0xFFC2410C)
                                              : (dangChon ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nv.hoTen,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14.5,
                                              color: biTuChoi ? const Color(0xFF9A3412) : null,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            biTuChoi
                                                ? 'Đã từ chối hồ sơ này'
                                                : [
                                              if (nv.chucVu != null && nv.chucVu!.isNotEmpty)
                                                nv.chucVu!,
                                              if (nv.soDienThoai != null &&
                                                  nv.soDienThoai!.isNotEmpty)
                                                nv.soDienThoai!,
                                              if (nv.soCongViecDangLam > 0)
                                                'Đang làm ${nv.soCongViecDangLam} việc',
                                            ].where((s) => s.isNotEmpty).join(' · '),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: biTuChoi
                                                  ? const Color(0xFFC2410C)
                                                  : Colors.grey.shade600,
                                              fontWeight: biTuChoi ? FontWeight.w600 : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (biTuChoi)
                                      const Icon(Icons.block_rounded,
                                          color: Color(0xFFC2410C), size: 24)
                                    else if (dangChon)
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.primary, size: 26)
                                    else
                                      Icon(Icons.circle_outlined, color: Colors.grey.shade400),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                    if (_controller.loi != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_controller.loi!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ],
                ),
              ),

              // ===== Nút xác nhận cố định dưới =====
              Container(
                padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom,
                ),
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
                  height: 52,
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _controller.dangLuu ? null : _xacNhan,
                    icon: _controller.dangLuu
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.assignment_ind_rounded),
                    label: Text(
                      _controller.dangLuu ? 'Đang phân công...' : 'Xác nhận phân công',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
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

class _TimeInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimeInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(icon, size: 18),
        ),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}