import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';

// ============ MÀN: PHÂN CÔNG / CẬP NHẬT PHÂN CÔNG NHÂN VIÊN ============

class PhanCongBaoTriScreen extends StatefulWidget {
  final int maHoSoBaoTri;
  /// true = cập nhật danh sách NV đã phân công (bỏ người bận / thêm người thay)
  final bool isCapNhat;

  const PhanCongBaoTriScreen({
    super.key,
    required this.maHoSoBaoTri,
    this.isCapNhat = false,
  });

  @override
  State<PhanCongBaoTriScreen> createState() => _PhanCongBaoTriScreenState();
}

class _PhanCongBaoTriScreenState extends State<PhanCongBaoTriScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PhanCongBaoTriController();
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _controller.khoiTao(widget.maHoSoBaoTri, capNhat: widget.isCapNhat).then((_) {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _xacNhan() async {
    final ok = await _controller.xacNhan(widget.maHoSoBaoTri);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isCapNhat
              ? 'Đã cập nhật phân công nhân viên'
              : 'Đã phân công nhân viên'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    }
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
    final isCapNhat = widget.isCapNhat;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(child: CircularProgressIndicator());
          }

          final hs = _controller.hoSo;
          final soChon = _controller.maNhanVienDaChon.length;

          return Column(
            children: [
              // ===== App bar custom =====
              _AssignHeader(
                title: isCapNhat ? 'Cập nhật phân công' : 'Phân công nhân viên',
                subtitle: hs?.tenThietBi ?? 'Hồ sơ #${widget.maHoSoBaoTri}',
                maHoSo: widget.maHoSoBaoTri,
                isCapNhat: isCapNhat,
                onBack: () => Navigator.pop(context),
              ),

              Expanded(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      // ===== Khung giờ =====
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.schedule_rounded,
                                      color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Lịch bảo trì theo hồ sơ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 14.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniStat(
                                    icon: Icons.calendar_month_rounded,
                                    label: 'Ngày',
                                    value: _fmtDate(_controller.ngayDuKien),
                                    color: const Color(0xFF0068A9),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MiniStat(
                                    icon: Icons.play_arrow_rounded,
                                    label: 'Bắt đầu',
                                    value: _fmtTime(_controller.gioBatDau),
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MiniStat(
                                    icon: Icons.stop_rounded,
                                    label: 'Kết thúc',
                                    value: _fmtTime(_controller.gioKetThuc),
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ===== Hint =====
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCapNhat
                              ? const Color(0xFFFFF7ED)
                              : AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCapNhat
                                ? const Color(0xFFFDBA74)
                                : AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isCapNhat
                                  ? Icons.edit_calendar_rounded
                                  : Icons.info_outline_rounded,
                              size: 20,
                              color: isCapNhat
                                  ? const Color(0xFFC2410C)
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isCapNhat
                                    ? 'Bỏ tích nhân viên bận, hoặc thêm người thay thế. Nhân viên đã phân công thiết bị khác vẫn có thể chọn.'
                                    : 'Chọn một hoặc nhiều nhân viên kỹ thuật. Cùng một người có thể được phân công cho nhiều thiết bị khác nhau.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: isCapNhat
                                      ? const Color(0xFF9A3412)
                                      : Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ===== Tiêu đề list =====
                      Row(
                        children: [
                          const Text(
                            'Nhân viên kỹ thuật',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const Spacer(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: soChon > 0
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              soChon > 0 ? 'Đã chọn $soChon' : 'Chưa chọn',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: soChon > 0 ? AppColors.primary : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (_controller.dsNhanVien.isEmpty)
                        _GlassCard(
                          child: Column(
                            children: [
                              Icon(Icons.person_off_outlined,
                                  size: 40, color: Colors.orange.shade400),
                              const SizedBox(height: 8),
                              Text(
                                _controller.loi ??
                                    'Không có nhân viên kỹ thuật trong hệ thống.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.orange.shade900),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._controller.dsNhanVien.asMap().entries.map((entry) {
                          final i = entry.key;
                          final nv = entry.value;
                          final dangChon = _controller.daChon(nv.maNhanVien);
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 280 + i * 40),
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
                              child: _NvCard(
                                nv: nv,
                                dangChon: dangChon,
                                onTap: () => _controller.toggleNhanVien(nv),
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
                          child: Text(
                            _controller.loi!,
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ===== Bottom CTA =====
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _controller.dangLuu ? null : _xacNhan,
                    child: _controller.dangLuu
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCapNhat
                              ? Icons.sync_rounded
                              : Icons.assignment_ind_rounded,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCapNhat
                              ? (soChon > 0
                              ? 'Lưu cập nhật ($soChon người)'
                              : 'Lưu cập nhật')
                              : (soChon > 0
                              ? 'Xác nhận phân công ($soChon người)'
                              : 'Xác nhận phân công'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
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

// ---------- UI helpers ----------

class _AssignHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int maHoSo;
  final bool isCapNhat;
  final VoidCallback onBack;

  const _AssignHeader({
    required this.title,
    required this.subtitle,
    required this.maHoSo,
    required this.isCapNhat,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCapNhat
              ? const [Color(0xFF0F766E), Color(0xFF0D9488)]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: (isCapNhat ? const Color(0xFF0F766E) : AppColors.primary)
                .withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle · HS #$maHoSo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NvCard extends StatelessWidget {
  final NhanVienRutGon nv;
  final bool dangChon;
  final VoidCallback onTap;

  const _NvCard({
    required this.nv,
    required this.dangChon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sub = [
      if (nv.chucVu != null && nv.chucVu!.isNotEmpty) nv.chucVu!,
      if (nv.soDienThoai != null && nv.soDienThoai!.isNotEmpty) nv.soDienThoai!,
      if (nv.soCongViecDangLam > 0) 'Đang làm ${nv.soCongViecDangLam} việc',
    ].join(' · ');

    return Material(
      color: dangChon
          ? AppColors.primary.withValues(alpha: 0.07)
          : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dangChon ? AppColors.primary : Colors.grey.shade200,
              width: dangChon ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dangChon ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: dangChon ? AppColors.primary : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: dangChon
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 22,
                backgroundColor: dangChon
                    ? AppColors.primary
                    : const Color(0xFFE8EEF5),
                child: Text(
                  nv.hoTen.isNotEmpty ? nv.hoTen[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: dangChon ? Colors.white : AppColors.primaryDark,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}