part of work_order_detail_screen;

/// Tách phần dựng UI quy trình / hành động Xưởng khỏi màn chi tiết (dễ tìm & sửa).
extension _ChiTietBaoTriQuyTrinhUi on _WorkOrderBaoTriDetailScreenState {
  Widget _buildQuyTrinhChiXemToTruong(HoSoBaoTri hs) {
    final nhanTt = _nhanTrangThaiQuyTrinh(hs);
    final mauTt = _mauTrangThaiQuyTrinh(nhanTt);
    final String banner;
    final Color bannerBg;
    final Color bannerBd;
    if (hs.daHoanThanh) {
      banner =
      'Xưởng đã xác nhận — hồ sơ Đã hoàn thành. Quy trình bên dưới là bản NVKT đã gửi (chỉ xem).';
      bannerBg = AppColors.success.withValues(alpha: 0.1);
      bannerBd = AppColors.success.withValues(alpha: 0.35);
    } else if (hs.trangThaiPhanCong == 'Từ chối') {
      banner =
      'Xưởng đã từ chối quy trình. Đang chờ NVKT cập nhật gửi lại. Tổ trưởng chỉ xem — không duyệt.';
      bannerBg = AppColors.danger.withValues(alpha: 0.08);
      bannerBd = AppColors.danger.withValues(alpha: 0.3);
    } else {
      banner =
      'NVKT đã gửi quy trình (đủ bước, kể cả bước không làm). Đã thay bản tổ trưởng chọn lúc tạo. Chỉ Xưởng được Xác nhận / Từ chối.';
      bannerBg = AppColors.primary.withValues(alpha: 0.08);
      bannerBd = AppColors.primary.withValues(alpha: 0.3);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bannerBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bannerBd),
          ),
          child: Text(
            banner,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Quy trình thực hiện',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: mauTt.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mauTt.withValues(alpha: 0.45)),
              ),
              child: Text(
                nhanTt,
                style: TextStyle(
                  color: mauTt,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildQuyTrinhDuoiThongTin(),
      ],
    );
  }

  /// Trạng thái hiển thị quy trình cho Xưởng (dưới thông tin hồ sơ).
  String _nhanTrangThaiQuyTrinh(HoSoBaoTri hs) {
    if (hs.daHoanThanh || hs.trangThaiPhanCong == 'Hoàn thành') {
      return 'Xác nhận';
    }
    if (hs.trangThaiPhanCong == 'Từ chối') return 'Từ chối';
    if (hs.choXacNhanKetQua) return 'Chờ xác nhận';
    if (hs.dangThucHien) return 'Đang thực hiện';
    return hs.trangThaiPhanCong ?? hs.trangThai;
  }

  Color _mauTrangThaiQuyTrinh(String nhan) {
    switch (nhan) {
      case 'Xác nhận':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      case 'Chờ xác nhận':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildXuongQuyTrinhVaDuyet(HoSoBaoTri hs) {
    final nhanTt = _nhanTrangThaiQuyTrinh(hs);
    final mauTt = _mauTrangThaiQuyTrinh(nhanTt);
    final choDuyet = hs.choXacNhanKetQua;
    final biTuChoiPc = hs.trangThaiPhanCong == 'Từ chối' && hs.dangThucHien;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (choDuyet)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
            ),
            child: const Text(
              'NVKT đã gửi kết quả quy trình. Xưởng kiểm tra từng bước / vật tư rồi Xác nhận (→ Đã hoàn thành) hoặc Từ chối (quy trình giữ nguyên, vẫn Đang thực hiện để NVKT chỉnh lại).',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          )
        else if (biTuChoiPc)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Text(
              (hs.lyDoTuChoiPhanCong != null &&
                  hs.lyDoTuChoiPhanCong!.isNotEmpty)
                  ? 'Đã từ chối quy trình — hồ sơ vẫn Đang thực hiện. Lý do: ${hs.lyDoTuChoiPhanCong}'
                  : 'Đã từ chối quy trình — hồ sơ vẫn Đang thực hiện. Chờ NVKT chỉnh sửa và gửi lại.',
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          )
        else if (hs.daHoanThanh)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: AppColors.success.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'Đã xác nhận quy trình — hồ sơ Đã hoàn thành.',
                style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
              ),
            ),
        const SizedBox(height: 12),
        // Badge trạng thái quy trình
        Row(
          children: [
            const Text(
              'Quy trình',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: mauTt.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mauTt.withValues(alpha: 0.45)),
              ),
              child: Text(
                nhanTt,
                style: TextStyle(
                  color: mauTt,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Quy trình / vật tư — luôn giữ khi từ chối, không xóa
        _buildQuyTrinhDuoiThongTin(),
        if (choDuyet) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success),
                  onPressed: () async {
                    try {
                      await WorkOrderService.xuongXacNhanKetQua(
                        maHoSoBaoTri: hs.maHoSoBaoTri,
                        xacNhan: true,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Đã xác nhận — hồ sơ chuyển Đã hoàn thành'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      await _controller.taiChiTiet();
                      await _taiQuyTrinhVatTu();
                      setState(() {});
                    } on ApiException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.message),
                            backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Xác nhận'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger),
                  onPressed: () async {
                    final lyDoCtrl = TextEditingController();
                    final lyDo = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Từ chối kết quả'),
                        content: TextField(
                          controller: lyDoCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Lý do để NVKT chỉnh sửa…',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Hủy')),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(ctx, lyDoCtrl.text.trim()),
                            child: const Text('Từ chối'),
                          ),
                        ],
                      ),
                    );
                    if (lyDo == null || lyDo.isEmpty) return;
                    try {
                      await WorkOrderService.xuongXacNhanKetQua(
                        maHoSoBaoTri: hs.maHoSoBaoTri,
                        xacNhan: false,
                        lyDo: lyDo,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Đã từ chối — quy trình giữ nguyên, hồ sơ vẫn Đang thực hiện'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      await _controller.taiChiTiet();
                      await _taiQuyTrinhVatTu();
                      setState(() {});
                    } on ApiException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.message),
                            backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Từ chối'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Hiển thị quy trình đủ bước (mẫu + tiến độ NVKT + vật tư) — một khối duy nhất.
  Widget _buildQuyTrinhDuoiThongTin() {
    if (_dangTaiQuyTrinh) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loiQuyTrinh != null) {
      return _cardBox(children: [
        const Text('Quy trình bảo trì',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        Text(_loiQuyTrinh!, style: TextStyle(color: Colors.grey.shade700)),
        TextButton(
            onPressed: () => _taiQuyTrinhVatTu(),
            child: const Text('Thử lại')),
      ]);
    }
    if (_dsBuocFull.isEmpty) {
      return _cardBox(children: [
        const Text('Quy trình bảo trì',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        Text(
          'Chưa có dữ liệu bước/vật tư.',
          style: TextStyle(
              color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      ]);
    }

    final soDaLam = _dsBuocFull.where((e) => e.daThucHien).length;
    final soVt = _dsBuocFull.fold<int>(
        0,
            (a, b) =>
        a +
            b.vatTu.where((c) => c.tenVatTu.isNotEmpty && c.soLuong > 0).length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardBox(children: [
          Row(
            children: [
              Icon(Icons.account_tree_rounded,
                  size: 18, color: AppColors.primary.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Quy trình bảo trì',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF0F172A))),
              ),
              Text(
                '${_dsBuocFull.length} bước · $soDaLam đã làm · $soVt VT',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        for (final b in _dsBuocFull)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: b.daThucHien ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: b.daThucHien
                    ? const Color(0xFFBAE6FD)
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: b.daThucHien
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${b.soBuoc}',
                        style: TextStyle(
                            color: b.daThucHien
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w900,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b.moTa.isEmpty ? 'Bước ${b.soBuoc}' : b.moTa,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: b.daThucHien
                              ? const Color(0xFF0F172A)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: b.daThucHien
                            ? const Color(0xFFD1FAE5)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b.daThucHien
                            ? 'Đã thực hiện'
                            : (b.daChon ? 'Đã chọn / nháp' : 'Không làm'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: b.daThucHien
                              ? const Color(0xFF047857)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((b.tenNhanVien ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'NVKT: ${b.tenNhanVien}',
                    style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                if (b.vatTu
                    .any((c) => c.tenVatTu.isNotEmpty && c.soLuong > 0)) ...[
                  const SizedBox(height: 8),
                  for (final c in b.vatTu)
                    if (c.tenVatTu.isNotEmpty && c.soLuong > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 15, color: Color(0xFF0068A9)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${c.tenVatTu} × ${c.soLuong}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                ] else if (!b.daThucHien) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Không có vật tư — bước không được NVKT hoàn thành.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildXuongActions(HoSoBaoTri hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.factory_outlined, color: AppColors.primary.withValues(alpha: 0.9)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _dangChinhSuaXuong
                      ? 'Đang chỉnh sửa — sửa xong bấm Lưu. Bấm Hủy để bỏ thay đổi.'
                      : 'Xưởng xem lịch bảo trì. Bấm Chỉnh sửa nếu cần đổi ngày/nội dung, hoặc xác nhận gửi Giám đốc.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_dangChinhSuaXuong) ...[
          _cardBox(
            children: [
              const Text('Nội dung công việc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _noiDungXuongCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Mô tả công việc...',
                ),
              ),
              const SizedBox(height: 14),
              const Text('Ngày dự kiến bảo trì', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  // Xưởng: trong tháng kế hoạch + sau ngày hiện tại
                  final goc = _xuongCtrl.ngayDuKienGoc ??
                      _ngayDuKienXuong ??
                      DateTime.now();
                  final now = DateTime.now();
                  final ngayMai = DateTime(now.year, now.month, now.day)
                      .add(const Duration(days: 1));
                  var firstOfRange = DateTime(goc.year, goc.month, 1);
                  final lastOfRange = DateTime(goc.year, goc.month + 1, 0);
                  if (ngayMai.isAfter(firstOfRange)) firstOfRange = ngayMai;
                  if (firstOfRange.isAfter(lastOfRange)) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Không còn ngày hợp lệ trong tháng ${goc.month}/${goc.year} '
                              '(phải sau ngày hiện tại).',
                        ),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                    return;
                  }
                  var initial = _ngayDuKienXuong ?? firstOfRange;
                  if (initial.isBefore(firstOfRange)) initial = firstOfRange;
                  if (initial.isAfter(lastOfRange)) initial = lastOfRange;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: firstOfRange,
                    lastDate: lastOfRange,
                    helpText:
                    'Tháng ${goc.month}/${goc.year} — sau ngày hiện tại',
                    cancelText: 'Hủy',
                    confirmText: 'Chọn',
                  );
                  if (picked != null) {
                    _xuongCtrl.datNgayDuKien(picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.event_available_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    errorText: (_xuongCtrl.loi != null &&
                        (_xuongCtrl.loi!.contains('tháng') ||
                            _xuongCtrl.loi!.contains('ngày dự kiến') ||
                            _xuongCtrl.loi!.contains('Ngày dự kiến')))
                        ? _xuongCtrl.loi
                        : null,
                    errorMaxLines: 4,
                    helperText: _xuongCtrl.ngayDuKienGoc != null
                        ? 'Chỉ chọn ngày trong tháng ${_xuongCtrl.ngayDuKienGoc!.month}/${_xuongCtrl.ngayDuKienGoc!.year} (không đổi tháng)'
                        : 'Chỉ chọn ngày trong tháng kế hoạch Tổ trưởng đã lập',
                    helperMaxLines: 2,
                  ),
                  child: Text(
                    _ngayDuKienXuong == null ? 'Chọn ngày' : _fmt(_ngayDuKienXuong),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _ngayDuKienXuong == null ? Colors.grey : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              if (_xuongCtrl.loi != null &&
                  !(_xuongCtrl.loi!.contains('tháng') ||
                      _xuongCtrl.loi!.contains('ngày dự kiến') ||
                      _xuongCtrl.loi!.contains('Ngày dự kiến'))) ...[
                const SizedBox(height: 8),
                Text(
                  _xuongCtrl.loi!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12.5, height: 1.3),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.primary.withValues(alpha: 0.9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thời gian dự kiến / bắt đầu / kết thúc không chỉnh tại đây. '
                            'Hệ thống ghi nhận khi NVKT bấm Tiến hành quy trình và khi hoàn thành.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _dangLuuXuong ? null : _huyChinhSuaXuong,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: _dangLuuXuong
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.save_rounded),
                  label: Text(_dangLuuXuong ? 'Đang lưu…' : 'Lưu'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _dangLuuXuong ? null : () => _luuChinhSuaXuong(hs),
                ),
              ),
            ],
          ),
        ] else ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Chỉnh sửa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              _batDauChinhSuaXuong(hs);
            },
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            icon: const Icon(Icons.send_rounded),
            label: const Text('Xác nhận lịch · gửi Giám đốc'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final (ok, msg) = await _controller.xuongGuiGiamDoc(
                noiDungCongViec: hs.noiDungCongViec,
                thoiGianDuKien: hs.thoiGianDuKien,
                gioBatDauDuKien: hs.gioBatDauDuKien,
                gioKetThucDuKien: hs.gioKetThucDuKien,
              );
              if (!mounted) return;
              if (ok) {
                _xuongCtrl.huyChinhSua();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi Giám đốc. Hồ sơ chuyển sang Chờ GĐ duyệt.'),
                  ),
                );
                setState(() {});
              } else if (msg != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
          ),
        ],
      ],
    );
  }


}