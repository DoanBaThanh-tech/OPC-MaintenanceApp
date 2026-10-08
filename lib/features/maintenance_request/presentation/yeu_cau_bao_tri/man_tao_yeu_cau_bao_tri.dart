part of maintenance_request_screens;

// =============================================================================
// TTSX: Form tạo yêu cầu bảo trì (mở từ nút +)
// =============================================================================

class TaoYeuCauBaoTriScreen extends StatefulWidget {
  /// null = tạo mới; có giá trị = sửa yêu cầu bị từ chối
  final YeuCauBaoTriItem? yeuCauSua;

  const TaoYeuCauBaoTriScreen({super.key, this.yeuCauSua});

  @override
  State<TaoYeuCauBaoTriScreen> createState() => _TaoYeuCauBaoTriScreenState();
}

class _TaoYeuCauBaoTriScreenState extends State<TaoYeuCauBaoTriScreen> {
  final _c = TaoYeuCauBaoTriController();

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _init();
  }

  Future<void> _init() async {
    await _c.taiThietBi();
    if (widget.yeuCauSua != null) {
      await _c.napTuYeuCau(widget.yeuCauSua!);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // Ngày bảo trì phải > ngày tạo yêu cầu (hôm nay)
    final minDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    var first = DateTime(_c.nam, _c.thang, 1);
    final last = DateTime(_c.nam, _c.thang + 1, 0);
    if (first.isBefore(minDay)) first = minDay;
    if (first.isAfter(last)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tháng đã chọn không còn ngày hợp lệ (phải sau ngày hôm nay).'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final initial = _c.ngayBaoTri != null && !_c.ngayBaoTri!.isBefore(first) ? _c.ngayBaoTri! : first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      _c.ngayBaoTri = picked;
      _c.notifyListeners();
    }
  }

  Future<void> _pickTime({required bool batDau}) async {
    if (!_c.thoiGianHopLe) return;
    final t = await showTimePicker(
      context: context,
      initialTime: batDau
          ? (_c.gioBatDau ?? const TimeOfDay(hour: 8, minute: 0))
          : (_c.gioKetThuc ?? const TimeOfDay(hour: 10, minute: 0)),
    );
    if (t == null) return;
    if (batDau) {
      _c.gioBatDau = t;
    } else {
      _c.gioKetThuc = t;
    }
    _c.notifyListeners();
  }

  Future<void> _gui() async {
    final ok = await _c.gui();
    if (!mounted) return;
    if (ok) {
      final msg = _c.dangSua
          ? 'Đã cập nhật và gửi lại yêu cầu cho xưởng.'
          : 'Đã gửi yêu cầu bảo trì.';
      _c.resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_c.loi ?? 'Không gửi được yêu cầu'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _fmtTime(TimeOfDay? t) =>
      t == null ? 'Chọn giờ' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_c.dangSua ? 'Sửa yêu cầu bảo trì' : 'Tạo yêu cầu bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _c.dangTai
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm thiết bị theo tên hoặc danh mục…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _c.setTimKiem,
          ),
          const SizedBox(height: 14),
          _card([
            const Text('Danh mục thiết bị', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _c.danhMucChon,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _c.cacDanhMuc
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: _c.chonDanhMuc,
              hint: const Text('Chọn danh mục'),
            ),
            const SizedBox(height: 14),
            const Text('Tên thiết bị', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ThietBiModel>(
              value: _c.thietBiChon,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _c.thietBiTheoDanhMuc
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.tenThietBi, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: _c.danhMucChon == null ? null : _c.chonThietBi,
              hint: Text(
                _c.danhMucChon == null ? 'Chọn danh mục trước' : 'Chọn thiết bị',
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _card([
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _c.thang,
                    decoration: const InputDecoration(
                      labelText: 'Tháng bảo trì',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text('Tháng $m')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _c.setThangNam(v, _c.nam);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _c.nam,
                    decoration: const InputDecoration(
                      labelText: 'Năm',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [DateTime.now().year, DateTime.now().year + 1]
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _c.setThangNam(_c.thang, v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày bảo trì',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  child: Text(
                    _c.ngayBaoTri == null
                        ? 'Chọn ngày (sau ngày hôm nay)'
                        : '${_c.ngayBaoTri!.day.toString().padLeft(2, '0')}/'
                        '${_c.ngayBaoTri!.month.toString().padLeft(2, '0')}/'
                        '${_c.ngayBaoTri!.year}',
                    style: TextStyle(
                      color: _c.ngayBaoTri == null ? Colors.grey.shade600 : Colors.black87,
                      fontWeight: _c.ngayBaoTri == null ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ngày bảo trì phải sau ngày tạo yêu cầu.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c.thoiGianCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
                signed: false,
              ),
              decoration: InputDecoration(
                labelText: 'Thời gian dự kiến (giờ)',
                helperText: 'Số nguyên dương 1–24 (không thập phân)',
                border: const OutlineInputBorder(),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                errorText: _c.loiThoiGian,
                errorStyle: const TextStyle(fontSize: 12, height: 1.2),
                errorMaxLines: 2,
              ),
              onChanged: (_) {
                _c.validateThoiGian();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: _c.thoiGianHopLe ? 1 : 0.45,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                      _c.thoiGianHopLe ? () => _pickTime(batDau: true) : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(_fmtTime(_c.gioBatDau),
                          overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _c.thoiGianHopLe
                          ? () => _pickTime(batDau: false)
                          : null,
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: Text(_fmtTime(_c.gioKetThuc),
                          overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_c.thoiGianHopLe)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Nhập số giờ nguyên hợp lệ (1–24) để chọn giờ bắt đầu / kết thúc.',
                  style: TextStyle(
                      fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _c.ghiChuCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ]),
          if (_c.loi != null) ...[
            const SizedBox(height: 10),
            Text(_c.loi!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _c.dangGui ? null : _gui,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _c.dangGui
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Text(
              _c.dangSua ? 'Gửi lại yêu cầu cho xưởng' : 'Gửi yêu cầu bảo trì',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}