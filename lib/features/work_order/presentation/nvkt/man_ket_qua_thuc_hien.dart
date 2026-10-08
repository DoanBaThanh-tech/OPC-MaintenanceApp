part of technician_screens;

// ============ KẾT QUẢ THỰC HIỆN ============

class KetQuaThucHienScreen extends StatefulWidget {
  const KetQuaThucHienScreen({super.key});

  @override
  State<KetQuaThucHienScreen> createState() => _KetQuaThucHienScreenState();
}

class _KetQuaThucHienScreenState extends State<KetQuaThucHienScreen> {
  final _ctrl = KetQuaThucHienController();
  final _ghiChuCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _ghiChuCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _chonNgay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _ctrl.ngayGhiNhan ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) _ctrl.datNgayGhiNhan(picked);
  }

  Future<void> _luu() async {
    // Server tự lấy MaNhanVienThucHien nếu gửi 0
    _ctrl.ghiChu = _ghiChuCtrl.text;
    final ok = await _ctrl.xacNhanHoanThanh(maNhanVienGhiNhan: 0);
    if (ok && mounted) {
      _ghiChuCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã ghi nhận kết quả'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ghi nhận kết quả'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _ctrl.dangTai
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Chọn yêu cầu đã xác nhận',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_ctrl.dsXacNhan.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Không có yêu cầu ở trạng thái Xác nhận',
                style: TextStyle(color: Color(0xFF9A3412)),
              ),
            )
          else
            DropdownButtonFormField<YeuCauPhanCong?>(
              value: _ctrl.chon,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                const DropdownMenuItem<YeuCauPhanCong?>(
                  value: null,
                  child: Text('— Chọn hồ sơ —'),
                ),
                ..._ctrl.dsXacNhan.map(
                      (y) => DropdownMenuItem(
                    value: y,
                    child: Text(
                      '${y.tenThietBi ?? 'HS #${y.maHoSo}'} · ${y.trangThaiPhanCong}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => _ctrl.chonYeuCau(v),
            ),
          const SizedBox(height: 16),
          const Text('Ngày ghi nhận',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _chonNgay,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _ctrl.ngayGhiNhan == null
                        ? 'Chọn ngày'
                        : '${_ctrl.ngayGhiNhan!.day.toString().padLeft(2, '0')}/${_ctrl.ngayGhiNhan!.month.toString().padLeft(2, '0')}/${_ctrl.ngayGhiNhan!.year}',
                  ),
                ],
              ),
            ),
          ),
          if (_ctrl.loiNgay != null) ...[
            const SizedBox(height: 6),
            Text(_ctrl.loiNgay!,
                style: const TextStyle(
                    color: AppColors.danger, fontSize: 12.5)),
          ],
          const SizedBox(height: 16),
          const Text('Ghi chú',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _ghiChuCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ghi chú kết quả thực hiện…',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_ctrl.loi != null) ...[
            const SizedBox(height: 12),
            Text(_ctrl.loi!,
                style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _ctrl.dangLuu ? null : _luu,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _ctrl.dangLuu
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text(
                'Xác nhận hoàn thành',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}