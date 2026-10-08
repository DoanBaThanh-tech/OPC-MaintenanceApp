part of work_order_detail_screen;

/// Widget phụ trợ header / card / định dạng trên màn chi tiết BT.
extension _ChiTietBaoTriWidgetPhu on _WorkOrderBaoTriDetailScreenState {
  Widget _dong(String nhan, String giaTri) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(nhan, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
          Flexible(
            child: Text(
              giaTri,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  /// Tổ trưởng sửa ngày dự kiến của chính hồ sơ đang Chờ gửi (không tạo HS mới).
  Future<void> _suaNgayDuKienChoGui(HoSoBaoTri hs) async {
    final goc = hs.ngayDuKienBaoTri ?? hs.ngayTao ?? DateTime.now();
    const namKeHoach = 2026;
    final now = DateTime.now();
    final ngayMai =
    DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    var first = DateTime(namKeHoach, 1, 1);
    if (ngayMai.isAfter(first)) first = ngayMai;
    final last = DateTime(namKeHoach, 12, 31);
    if (first.isAfter(last)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không còn ngày hợp lệ trong năm 2026.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    var initial = goc;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Chỉnh ngày dự kiến hồ sơ này (năm $namKeHoach)',
      cancelText: 'Hủy',
      confirmText: 'Lưu',
    );
    if (picked == null || !mounted) return;

    try {
      // Kiểm tra trùng tháng khác (client)
      if (picked.month != goc.month || picked.year != goc.year) {
        final thangCo = await WorkOrderService.layThangCoBaoTri(
          hs.maThietBi,
          nam: picked.year,
        );
        if (thangCo.contains(picked.month) && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Thiết bị đã có bảo trì trong tháng ${picked.month}/${picked.year}.',
              ),
              backgroundColor: Colors.red.shade700,
            ),
          );
          return;
        }
      }
      await WorkOrderService.capNhatHoSoChoGui(
        maHoSoBaoTri: hs.maHoSoBaoTri,
        ngayDuKienBaoTri: picked,
      );
      if (!mounted) return;
      await _controller.taiChiTiet();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật ngày dự kiến bảo trì.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _guiDenXuong(HoSoBaoTri hs) async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gửi đến xưởng?'),
        content: const Text(
          'Sau khi gửi, hồ sơ chuyển sang Chờ duyệt và xưởng sẽ nhận được. '
              'Bạn vẫn nên kiểm tra ngày dự kiến trước khi gửi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    if (xacNhan != true || !mounted) return;
    try {
      await WorkOrderService.guiDenXuong(maHoSoBaoTri: hs.maHoSoBaoTri);
      if (!mounted) return;
      await _controller.taiChiTiet();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi đến xưởng — trạng thái Chờ duyệt.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Color _mauTrangThai(String tt) {
    switch (tt) {
      case 'Đã duyệt':
        return AppColors.primary;
      case 'Đang thực hiện':
        return const Color(0xFF1D4ED8);
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      case 'Chờ gửi':
        return const Color(0xFF0EA5E9);
      case 'Chờ duyệt':
      case 'Chờ xưởng':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  Widget _cardBox({required List<Widget> children, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _kBtPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _btHeaderBar({
    required double top,
    required String title,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 4, 16, 20),
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: _kBtPrimary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}