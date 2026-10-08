part of maintenance_request_screens;

// =============================================================================
// Xưởng (TTSX): Xác nhận yêu cầu bảo trì — Đồng ý / Từ chối
// =============================================================================

class XacNhanYeuCauBaoTriScreen extends StatefulWidget {
  const XacNhanYeuCauBaoTriScreen({super.key});

  @override
  State<XacNhanYeuCauBaoTriScreen> createState() => _XacNhanYeuCauBaoTriScreenState();
}

class _XacNhanYeuCauBaoTriScreenState extends State<XacNhanYeuCauBaoTriScreen> {
  final _c = XacNhanYeuCauController();

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _c.tai();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _dongY(YeuCauBaoTriItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đồng ý yêu cầu'),
        content: Text(
          'Đồng ý yêu cầu #${item.maYeuCauBaoTri} cho thiết bị '
              '"${item.tenThietBi ?? item.maThietBi}" '
              'ngày ${item.ngayBaoTri.day.toString().padLeft(2, '0')}/'
              '${item.ngayBaoTri.month.toString().padLeft(2, '0')}/'
              '${item.ngayBaoTri.year}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final success = await _c.xuLy(item.maYeuCauBaoTri, quyetDinh: 'Xác nhận');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã đồng ý yêu cầu.' : (_c.loi ?? 'Lỗi')),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _tuChoi(YeuCauBaoTriItem item) async {
    final lyDoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Từ chối yêu cầu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Từ chối YC #${item.maYeuCauBaoTri} — ${item.tenThietBi ?? item.maThietBi}. '
                  'Nhập lý do để Tổ trưởng cơ điện chỉnh sửa.',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lyDoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (lyDoCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    final lyDo = lyDoCtrl.text.trim();
    lyDoCtrl.dispose();
    if (ok != true || lyDo.isEmpty) return;

    final success = await _c.xuLy(item.maYeuCauBaoTri, quyetDinh: 'Từ chối', lyDo: lyDo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã từ chối yêu cầu.' : (_c.loi ?? 'Lỗi')),
        backgroundColor: success ? AppColors.warning : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_c.dangTai) return const Center(child: CircularProgressIndicator());
    if (_c.loi != null && _c.danhSach.isEmpty) {
      return Center(child: Text(_c.loi!, style: const TextStyle(color: AppColors.danger)));
    }
    if (_c.danhSach.isEmpty) {
      return RefreshIndicator(
        onRefresh: _c.tai,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(Icons.task_alt_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Không có yêu cầu chờ xác nhận',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _c.tai,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _c.danhSach.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final y = _c.danhSach[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.precision_manufacturing_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            y.tenThietBi ?? 'Thiết bị #${y.maThietBi}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'YC #${y.maYeuCauBaoTri} · ${y.danhMuc ?? '—'}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Chờ xác nhận',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(
                  Icons.event_rounded,
                  'Ngày bảo trì: ${y.ngayBaoTri.day.toString().padLeft(2, '0')}/'
                      '${y.ngayBaoTri.month.toString().padLeft(2, '0')}/'
                      '${y.ngayBaoTri.year}',
                ),
                _infoRow(
                  Icons.schedule_rounded,
                  '${y.thoiGianDuKien} giờ'
                      '${y.gioBatDau != null ? ' · ${y.gioBatDau} – ${y.gioKetThuc}' : ''}',
                ),
                _infoRow(Icons.person_outline_rounded, 'Người gửi: ${y.tenNguoiYeuCau ?? '—'}'),
                if (y.ghiChu != null && y.ghiChu!.isNotEmpty)
                  _infoRow(Icons.notes_rounded, y.ghiChu!),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _tuChoi(y),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _dongY(y),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3)),
          ),
        ],
      ),
    );
  }
}