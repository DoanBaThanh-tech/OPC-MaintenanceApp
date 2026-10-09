part of technician_screens;

// ============ CHI TIẾT YÊU CẦU ============

class ChiTietYeuCauScreen extends StatefulWidget {
  final YeuCauPhanCong yeuCau;
  const ChiTietYeuCauScreen({super.key, required this.yeuCau});

  @override
  State<ChiTietYeuCauScreen> createState() => _ChiTietYeuCauScreenState();
}

class _ChiTietYeuCauScreenState extends State<ChiTietYeuCauScreen> {
  bool _dangXuLy = false;
  bool _dangTaiQuyTrinh = false;
  HoSoVatTuItem? _hoSoVatTu;
  String? _loiQuyTrinh;
  /// Đủ bước mẫu thiết bị + tiến độ + vật tư (kể cả bước tổ trưởng/NVKT chưa chọn).
  List<_BuocQtNvktView> _dsBuocFull = [];
  /// Tên NV được phân công trên hồ sơ (BT/SC).
  String? _tenNhanVienDuocPhanCong;

  String _fmtDt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtGio(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _fmtTien(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf ₫';
  }

  @override
  void initState() {
    super.initState();
    // Luôn tải đủ bước (đã chọn + chưa chọn) khi có hồ sơ — kể cả lúc mới phân công.
    if (widget.yeuCau.maHoSo != null) {
      _taiQuyTrinhVatTu();
    }
  }

  Future<void> _taiQuyTrinhVatTu() async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;
    setState(() {
      _dangTaiQuyTrinh = true;
      _loiQuyTrinh = null;
    });
    try {
      final maTb = y.maThietBi ?? 0;
      final results = await Future.wait([
        MaterialUsageService.layHoSoTheoCongViec(
          maHoSoBaoTri: y.laBaoTri ? y.maHoSo : null,
          maHoSoSuaChua: y.laBaoTri ? null : y.maHoSo,
        ),
        WorkOrderService.layTienDoBuoc(
          maHoSoBaoTri: y.laBaoTri ? y.maHoSo : null,
          maHoSoSuaChua: y.laBaoTri ? null : y.maHoSo,
        ),
        maTb > 0
            ? MaterialUsageService.layQuyTrinhThietBi(
          maThietBi: maTb,
          loaiCongViec: y.laBaoTri ? 'Bảo trì' : 'Sửa chữa',
        )
            : Future.value(<BuocQuyTrinh>[]),
      ]);
      final hsVt = results[0] as HoSoVatTuItem?;
      final tienDo = results[1] as List<Map<String, dynamic>>;
      final mau = results[2] as List<BuocQuyTrinh>;
      String? tenNvPc;
      try {
        if (y.laBaoTri) {
          final hs =
          await WorkOrderService.layChiTietHoSoBaoTri(y.maHoSo!);
          tenNvPc =
              (hs.tenNhanVienThucHiens ?? hs.tenNhanVienThucHien)?.trim();
        } else {
          final hs =
          await WorkOrderService.layChiTietHoSoSuaChua(y.maHoSo!);
          tenNvPc = hs.tenNhanVienThucHiens?.trim();
        }
      } catch (_) {
        // Không chặn hiển thị quy trình nếu tải danh sách NV lỗi
      }

      final vtTheoBuoc = <int, List<ChiTietVatTuSuDung>>{};
      if (hsVt != null) {
        for (final c in hsVt.chiTiet) {
          vtTheoBuoc.putIfAbsent(c.soBuoc, () => []).add(c);
        }
      }
      final tdTheoBuoc = <int, Map<String, dynamic>>{};
      for (final row in tienDo) {
        final so = (row['soBuoc'] as num?)?.toInt() ??
            (row['SoBuoc'] as num?)?.toInt();
        if (so == null) continue;
        tdTheoBuoc[so] = row;
      }

      final soBuocSet = <int>{};
      for (final b in mau) {
        soBuocSet.add(b.soBuoc);
      }
      soBuocSet.addAll(tdTheoBuoc.keys);
      soBuocSet.addAll(vtTheoBuoc.keys);
      final sorted = soBuocSet.toList()..sort();

      final views = <_BuocQtNvktView>[];
      for (final so in sorted) {
        String? mauB;
        for (final e in mau) {
          if (e.soBuoc == so) {
            mauB = e.moTa;
            break;
          }
        }
        final td = tdTheoBuoc[so];
        final moTaTd = (td?['moTaBuoc'] ?? td?['MoTaBuoc'])?.toString();
        final tt = (td?['trangThai'] ?? td?['TrangThai'])?.toString() ?? '';
        final tenNv = (td?['tenNhanVien'] ?? td?['TenNhanVien'])?.toString();
        final moTaVt = vtTheoBuoc[so]
            ?.map((e) => e.moTaBuoc.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .join(' · ');
        final daThucHien = tt == 'DaXong' ||
            tt == 'DaCapNhat' ||
            (vtTheoBuoc[so]?.any((c) => c.soLuong > 0) ?? false);
        final daChon = daThucHien ||
            tt == 'DangLam' ||
            tt == 'DuocChon' ||
            vtTheoBuoc.containsKey(so);
        views.add(_BuocQtNvktView(
          soBuoc: so,
          moTa: (moTaTd != null && moTaTd.isNotEmpty)
              ? moTaTd
              : (moTaVt != null && moTaVt.isNotEmpty)
              ? moTaVt
              : (mauB ?? 'Bước $so'),
          trangThai: tt,
          tenNhanVien: tenNv,
          daThucHien: daThucHien,
          daChon: daChon,
          vatTu: vtTheoBuoc[so] ?? const [],
        ));
      }

      if (!mounted) return;
      setState(() {
        _hoSoVatTu = hsVt;
        _dsBuocFull = views;
        if (tenNvPc != null && tenNvPc.isNotEmpty) {
          _tenNhanVienDuocPhanCong = tenNvPc;
        }
        _dangTaiQuyTrinh = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loiQuyTrinh = e is ApiException ? e.message : '$e';
        _dangTaiQuyTrinh = false;
      });
    }
  }

  Future<void> _tienHanh() async {
    final y = widget.yeuCau;
    // Ghi nhận thời điểm bắt đầu thực tế (BT + SC)
    if (y.maHoSo != null) {
      setState(() => _dangXuLy = true);
      try {
        if (y.laBaoTri) {
          await WorkOrderService.nhanVienTienHanhBaoTri(y.maHoSo!);
        } else {
          await WorkOrderService.nhanVienTienHanhSuaChua(y.maHoSo!);
        }
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _dangXuLy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() => _dangXuLy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
        );
        return;
      }
      if (mounted) setState(() => _dangXuLy = false);
    }

    final changed = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            QuyTrinhNvktScreen(yeuCau: widget.yeuCau),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final y = widget.yeuCau;
    final top = MediaQuery.paddingOf(context).top;
    // Mọi NV được phân công + còn cần làm đều hiện Tiến hành
    final showTienHanh = !y.daHuy &&
        !y.daHoanThanhPc &&
        !y.choXacNhanKetQua &&
        y.maHoSo != null &&
        y.canThucHien;

    String trangThaiHienThi;
    if (y.daHoanThanhPc) {
      // Xưởng đã xác nhận → yêu cầu công việc của NVKT đã xong
      trangThaiHienThi = 'Xác nhận';
    } else if (y.choXacNhanKetQua) {
      trangThaiHienThi = 'Chờ xác nhận';
    } else if (y.biTuChoi && y.laNguoiGhiChep) {
      trangThaiHienThi = 'Từ chối — cập nhật quy trình';
    } else if (y.canThucHien) {
      trangThaiHienThi = 'Cần thực hiện';
    } else if (y.chiXem) {
      trangThaiHienThi = 'Chỉ xem (không ghi chép)';
    } else {
      trangThaiHienThi = y.trangThaiPhanCong;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(8, top + 4, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
                        y.laBaoTri ? 'Chi tiết bảo trì' : 'Chi tiết sửa chữa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        y.tenThietBi ?? 'HS #${y.maHoSo ?? '—'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Device card
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          y.laBaoTri
                              ? Icons.precision_manufacturing_rounded
                              : Icons.handyman_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              y.tenThietBi ?? '—',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hồ sơ #${y.maHoSo ?? '—'} · PC #${y.maPhanCong}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _infoCard([
                  _row('Loại', y.loai),
                  _row('Trạng thái', trangThaiHienThi),
                  _row('Trạng thái hồ sơ', y.trangThaiHoSo ?? '—'),
                  _row('Người phân công', y.tenNhanVienPhanCong ?? '—'),
                  _row('Ngày phân công', _fmtDt(y.ngayPhanCong)),
                  if (y.ngayDuKienBaoTri != null)
                    _row('Ngày dự kiến BT', _fmtDt(y.ngayDuKienBaoTri!)),
                  if (y.thoiGianDuKien != null)
                    _row('Thời gian dự kiến',
                        formatThoiGianDuKienHienThi(y.thoiGianDuKien)),
                  if (y.ngayBatDauDuKien != null)
                    _row('Giờ bắt đầu', _fmtGio(y.ngayBatDauDuKien!)),
                  if (y.ngayKetThucDuKien != null)
                    _row('Giờ kết thúc', _fmtGio(y.ngayKetThucDuKien!)),
                ]),

                // Nội dung công việc + Nhân viên được phân công (ngay dưới)
                const SizedBox(height: 14),
                _infoCard([
                  const Text(
                    'Nội dung công việc (hồ sơ)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (y.noiDung != null && y.noiDung!.trim().isNotEmpty)
                        ? y.noiDung!
                        : '—',
                    style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                  ),
                  if ((_tenNhanVienDuocPhanCong ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Divider(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.groups_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Nhân viên được phân công',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tenNhanVienDuocPhanCong!.trim(),
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ]),

                // NV không ghi chép: chỉ xem
                if (y.chiXem && !y.daHoanThanhPc && !y.choXacNhanKetQua) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.blueGrey.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            color: Colors.blueGrey),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bạn được phân công hỗ trợ — chỉ xem chi tiết. '
                                'Người ghi chép mới được Tiến hành / gửi quy trình.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Một frame duy nhất: Quy trình + lý do từ chối (nếu có)
                if (y.maHoSo != null) ...[
                  const SizedBox(height: 14),
                  _buildQuyTrinhDaThucHien(),
                ],

                // Chỉ hiện khi đang chờ Xưởng
                if (y.choXacNhanKetQua) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded,
                            color: Color(0xFF0284C7)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Đã gửi quy trình — đang chờ Xưởng xác nhận. Không thể tiến hành lại.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (y.daHuy) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.block_rounded, color: AppColors.danger),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Yêu cầu này đã được tổ trưởng hủy phân công',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (y.daHoanThanhPc) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Công việc đã hoàn thành',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Nút Tiến hành — ẩn khi đã Chờ xác nhận / Hoàn thành
          if (showTienHanh)
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _dangXuLy ? null : _tienHanh,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _dangXuLy
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        TechnicianYeuCauRules.dangCapNhatSauTuChoi(y)
                            ? Icons.edit_note_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        TechnicianYeuCauRules.nhanNutTienHanh(y),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Một frame: tiêu đề + lý do từ chối + đủ bước quy trình.
  Widget _buildQuyTrinhDaThucHien() {
    final y = widget.yeuCau;
    final lyDo = (y.lyDoTuChoi ?? '').trim();
    final hienLyDoTuChoi =
        y.biTuChoi && !y.choXacNhanKetQua && !y.daHoanThanhPc;

    if (_dangTaiQuyTrinh) {
      return _infoCard([
        const Text('Quy trình thực hiện',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 12),
        const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      ]);
    }
    if (_loiQuyTrinh != null) {
      return _infoCard([
        const Text('Quy trình thực hiện',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        if (hienLyDoTuChoi && lyDo.isNotEmpty) ...[
          const SizedBox(height: 8),
          _lyDoTuChoiTrongQuyTrinh(lyDo),
        ],
        const SizedBox(height: 8),
        Text(_loiQuyTrinh!, style: TextStyle(color: Colors.grey.shade700)),
        TextButton(onPressed: _taiQuyTrinhVatTu, child: const Text('Thử lại')),
      ]);
    }
    if (_dsBuocFull.isEmpty) {
      return _infoCard([
        const Text('Quy trình thực hiện',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        if (hienLyDoTuChoi && lyDo.isNotEmpty) ...[
          const SizedBox(height: 8),
          _lyDoTuChoiTrongQuyTrinh(lyDo),
        ],
        const SizedBox(height: 8),
        Text(
          'Chưa có mẫu quy trình cho thiết bị này hoặc chưa có dữ liệu bước.',
          style: TextStyle(
              color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      ]);
    }

    final soDaLam = _dsBuocFull.where((e) => e.daThucHien).length;
    final soDaChon = _dsBuocFull.where((e) => e.daChon).length;
    final soVt = _dsBuocFull.fold<int>(
      0,
          (a, b) =>
      a +
          b.vatTu
              .where((c) => c.tenVatTu.isNotEmpty && c.soLuong > 0)
              .length,
    );

    return _infoCard([
      Row(
        children: [
          Icon(Icons.account_tree_rounded,
              size: 18, color: AppColors.primary.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Quy trình thực hiện',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
      // Lý do từ chối ngay dưới tiêu đề
      if (hienLyDoTuChoi) ...[
        const SizedBox(height: 8),
        _lyDoTuChoiTrongQuyTrinh(lyDo.isNotEmpty
            ? lyDo
            : 'Xưởng đã từ chối — vui lòng cập nhật quy trình và gửi lại.'),
      ],
      const SizedBox(height: 6),
      Text(
        '${_dsBuocFull.length} bước · $soDaChon đã chọn · $soDaLam đã làm · $soVt VT',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < _dsBuocFull.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        Builder(builder: (_) {
          final b = _dsBuocFull[i];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: b.daThucHien
                  ? const Color(0xFFF0FDF4)
                  : (b.daChon
                  ? const Color(0xFFF0F9FF)
                  : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: b.daThucHien
                    ? const Color(0xFF86EFAC)
                    : (b.daChon
                    ? const Color(0xFFBAE6FD)
                    : Colors.grey.shade200),
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
                            : (b.daChon
                            ? const Color(0xFF0284C7)
                            : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${b.soBuoc}',
                        style: TextStyle(
                          color: (b.daThucHien || b.daChon)
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b.moTa.isEmpty ? 'Bước ${b.soBuoc}' : b.moTa,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: b.daChon
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
                            : (b.daChon
                            ? const Color(0xFFE0F2FE)
                            : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b.daThucHien
                            ? (b.trangThai == 'DaCapNhat'
                            ? 'Đã cập nhật'
                            : 'Đã thực hiện')
                            : (b.daChon
                            ? (b.trangThai == 'DuocChon'
                            ? 'Tổ trưởng chọn'
                            : 'Đã chọn / nháp')
                            : 'Chưa chọn'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: b.daThucHien
                              ? const Color(0xFF065F46)
                              : (b.daChon
                              ? const Color(0xFF075985)
                              : Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ],
                ),
                if (b.tenNhanVien != null &&
                    b.tenNhanVien!.trim().isNotEmpty &&
                    b.daChon) ...[
                  const SizedBox(height: 6),
                  Text(
                    'NVKT: ${b.tenNhanVien}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
                if (b.vatTu
                    .any((c) => c.tenVatTu.isNotEmpty && c.soLuong > 0)) ...[
                  const SizedBox(height: 8),
                  for (final c in b.vatTu)
                    if (c.tenVatTu.isNotEmpty && c.soLuong > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${c.tenVatTu} × ${c.soLuong}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              _fmtTien(c.thanhTien),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                ] else if (!b.daChon) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Bước không được chọn — vẫn hiển thị để tham khảo đầy đủ quy trình.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    ]);
  }

  Widget _lyDoTuChoiTrongQuyTrinh(String lyDo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Lý do từ chối: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: AppColors.danger,
                    ),
                  ),
                  TextSpan(
                    text: lyDo,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.35,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}