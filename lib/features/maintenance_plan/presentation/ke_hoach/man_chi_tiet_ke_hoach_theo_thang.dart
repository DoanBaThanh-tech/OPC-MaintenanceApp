part of maintenance_plan_screens;

// ============ MÀN CHI TIẾT THEO THÁNG (chỉ thiết bị đúng tháng) ============

class MaintenanceMonthDetailScreen extends StatefulWidget {
  final int nam;
  final int thang;
  final List<MucThietBiTrongThang> mucBanDau;

  const MaintenanceMonthDetailScreen({
    super.key,
    required this.nam,
    required this.thang,
    required this.mucBanDau,
  });

  @override
  State<MaintenanceMonthDetailScreen> createState() => _MaintenanceMonthDetailScreenState();
}

class _MaintenanceMonthDetailScreenState extends State<MaintenanceMonthDetailScreen> {
  late final MaintenancePlanMonthDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MaintenancePlanMonthDetailController(
      nam: widget.nam,
      thang: widget.thang,
      mucBanDau: widget.mucBanDau,
    );
    _controller.khoiTao();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Color _mauTT(String tt) {
    switch (phanLoaiTrangThai(tt)) {
      case TrangThaiKeHoach.choDuyet:
        return AppColors.warning;
      case TrangThaiKeHoach.daDuyet:
        return const Color(0xFF0068A9);
      case TrangThaiKeHoach.tuChoi:
        return AppColors.danger;
      case TrangThaiKeHoach.dangThucHien:
        return const Color(0xFF1D4ED8);
      case TrangThaiKeHoach.daHoanThanh:
        return AppColors.success;
      case TrangThaiKeHoach.chuaTao:
        return Colors.grey;
      case TrangThaiKeHoach.choXuLy:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${_tenThang[widget.thang]} · ${widget.nam}'),
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
          final list = _controller.danhSach;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có thiết bị nào trong ${_tenThang[widget.thang].toLowerCase()}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dùng nút "+" → Lập kế hoạch',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final muc = list[i];
              final ct = muc.chiTiet;
              // Ưu tiên trạng thái HỒ SƠ bảo trì (giống màn hồ sơ), không dùng trạng thái kế hoạch năm
              final nhanTT = ct.nhanTrangThaiHienThi;
              final mau = _mauTT(nhanTT);
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 0.8,
                shadowColor: Colors.black26,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border(left: BorderSide(color: mau, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ct.tenThietBi,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: mau.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              nhanTT,
                              style: TextStyle(color: mau, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Dự kiến: ${_fmt(ct.ngayDuKienBaoTri)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      if (muc.keHoach.tenChuKy != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          muc.keHoach.tenChuKy!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: mau.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ct.daTaoHoSo
                                  ? (ct.trangThaiHoSo == 'Đã duyệt' ||
                                  ct.trangThaiHoSo == 'Hoàn thành' ||
                                  ct.trangThaiHoSo == 'Đã hoàn thành'
                                  ? Icons.check_circle
                                  : ct.trangThaiHoSo == 'Từ chối'
                                  ? Icons.cancel
                                  : Icons.info_outline)
                                  : Icons.schedule_outlined,
                              size: 16,
                              color: mau,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ct.daTaoHoSo ? 'Hồ sơ: $nhanTT' : nhanTT,
                              style: TextStyle(
                                color: mau,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}