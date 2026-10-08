part of equipment_screens;

class EquipmentDetailScreen extends StatefulWidget {
  final int maThietBi;
  const EquipmentDetailScreen({super.key, required this.maThietBi});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final _controller = EquipmentDetailController();

  @override
  void initState() {
    super.initState();
    _controller.taiChiTiet(widget.maThietBi);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Chi tiết thiết bị'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _controller.taiChiTiet(widget.maThietBi),
              ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.dangTai) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_controller.loi != null || _controller.thietBi == null) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Không tải được chi tiết',
        subtitle: _controller.loi ?? 'Không tìm thấy thiết bị',
        actionLabel: 'Thử lại',
        onAction: () => _controller.taiChiTiet(widget.maThietBi),
      );
    }

    final tb = _controller.thietBi!;
    final statusColor = _statusColor(tb.tinhTrangHienTai);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.precision_manufacturing_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(tb.tinhTrangHienTai), size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            tb.tinhTrangHienTai,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  tb.tenThietBi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã TB · ${tb.maThietBi}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'Thông tin chung',
            icon: Icons.info_outline_rounded,
            rows: [
              _InfoItem('Danh mục', tb.danhMuc),
              _InfoItem('Vị trí lắp đặt', tb.viTriLapDat ?? '—'),
              _InfoItem('Ngày lắp đặt', _fmtDate(tb.ngayLapDat)),
              _InfoItem(
                'Chu kỳ bảo trì',
                tb.soThangDeXuat != null ? '${tb.soThangDeXuat} tháng/lần' : '—',
              ),
              if (tb.moTaChuKy != null && tb.moTaChuKy!.isNotEmpty)
                _InfoItem('Mô tả chu kỳ', tb.moTaChuKy!),
              if (tb.ghiChu != null && tb.ghiChu!.trim().isNotEmpty)
                _InfoItem('Ghi chú', tb.ghiChu!),
            ],
          ),
          const SizedBox(height: 12),
          // Đang sửa chữa: hiện lịch SC (gần nhất = ngày tạo HS SC; tiếp theo = ? / ngày SC sau)
          Builder(builder: (context) {
            final dangSc = tb.tinhTrangHienTai == TrangThaiThietBi.suaChua ||
                tb.tinhTrangHienTai.toLowerCase().contains('sửa');
            if (dangSc) {
              return _InfoSection(
                title: 'Lịch sửa chữa',
                icon: Icons.handyman_rounded,
                rows: [
                  _InfoItem(
                    'Sửa chữa gần nhất',
                    tb.ngayBaoTriGanNhat != null
                        ? _fmtDate(tb.ngayBaoTriGanNhat)
                        : 'Chưa có',
                  ),
                  _InfoItem(
                    'Sửa chữa tiếp theo',
                    tb.ngayBaoTriTiepTheo != null
                        ? _fmtDate(tb.ngayBaoTriTiepTheo)
                        : 'Chưa rõ (? )',
                  ),
                ],
              );
            }
            return _InfoSection(
              title: 'Lịch bảo trì',
              icon: Icons.event_available_rounded,
              rows: [
                _InfoItem(
                  'Bảo trì gần nhất',
                  tb.ngayBaoTriGanNhat != null
                      ? _fmtDate(tb.ngayBaoTriGanNhat)
                      : 'Chưa có',
                ),
                _InfoItem(
                  'Bảo trì tiếp theo',
                  tb.ngayBaoTriTiepTheo != null
                      ? _fmtDate(tb.ngayBaoTriTiepTheo)
                      : 'Chưa lên lịch',
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_statusIcon(tb.tinhTrangHienTai), color: statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusHint(tb.tinhTrangHienTai),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: statusColor.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _QuyTrinhSection(
            title: 'Quy trình bảo trì',
            icon: Icons.build_circle_outlined,
            accent: AppColors.primary,
            buoc: _controller.quyTrinhBaoTri,
          ),
          const SizedBox(height: 12),
          _QuyTrinhSection(
            title: 'Quy trình sửa chữa',
            icon: Icons.handyman_rounded,
            accent: AppColors.warning,
            buoc: _controller.quyTrinhSuaChua,
          ),
        ],
      ),
    );
  }

  Color _statusColor(String tt) {
    if (tt == TrangThaiThietBi.baoTri) return AppColors.warning;
    if (tt == TrangThaiThietBi.suaChua) return AppColors.danger;
    return AppColors.success;
  }

  IconData _statusIcon(String tt) {
    if (tt == TrangThaiThietBi.baoTri) return Icons.build_circle_outlined;
    if (tt == TrangThaiThietBi.suaChua) return Icons.handyman_rounded;
    return Icons.play_circle_outline_rounded;
  }

  String _statusHint(String tt) {
    if (tt == TrangThaiThietBi.baoTri) {
      return 'Thiết bị đang được phân công bảo trì. Sau khi hoàn thành, trạng thái sẽ trở về Sản xuất.';
    }
    if (tt == TrangThaiThietBi.suaChua) {
      return 'Thiết bị đang được phân công sửa chữa. Sau khi hoàn thành, trạng thái sẽ trở về Sản xuất.';
    }
    return 'Thiết bị đang ở trạng thái Sản xuất — chưa được phân công bảo trì hoặc sửa chữa.';
  }
}
