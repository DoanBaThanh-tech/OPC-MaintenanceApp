part of work_order_detail_screen;

// ============ MÀN: SỬA HỒ SƠ BỊ TỪ CHỐI ============

class SuaHoSoBiTuChoiScreen extends StatefulWidget {
  final HoSoBaoTri hoSo;
  const SuaHoSoBiTuChoiScreen({super.key, required this.hoSo});

  @override
  State<SuaHoSoBiTuChoiScreen> createState() => _SuaHoSoBiTuChoiScreenState();
}

class _SuaHoSoBiTuChoiScreenState extends State<SuaHoSoBiTuChoiScreen> {
  final _controller = SuaHoSoBiTuChoiController();
  late final TextEditingController _noiDung;
  late final TextEditingController _thoiGian;
  DateTime? _ngayDuKien;
  TimeOfDay? _gioBatDau;
  TimeOfDay? _gioKetThuc;

  /// Giờ: 1–24 · Phút: 1–1440 (số nguyên dương). Dùng controller chung.
  bool get _choPhepChonGioBatDau => _controller.choPhepChonGioBatDau;
  String? get _loiThoiGian => _controller.loiThoiGianDuKien;

  @override
  void initState() {
    super.initState();
    _noiDung = TextEditingController(text: widget.hoSo.noiDungCongViec ?? '');
    // Giữ chuỗi gốc ("15p" / "4") để nhận đúng đơn vị; ô nhập chỉ hiện số
    final raw = (widget.hoSo.thoiGianDuKien ?? '').trim();
    final chiSo = raw.replaceAll(RegExp(r'[^0-9]'), '');
    _thoiGian = TextEditingController(text: chiSo);
    _ngayDuKien = widget.hoSo.ngayDuKienBaoTri;
    _gioBatDau = _parseTime(widget.hoSo.gioBatDauDuKien);
    _gioKetThuc = _parseTime(widget.hoSo.gioKetThucDuKien);
    _controller.khoiTaoTuHoSo(
      thoiGianDuKienStr: raw.isEmpty ? chiSo : raw,
      gioBatDauStr: widget.hoSo.gioBatDauDuKien,
      gioKetThucStr: widget.hoSo.gioKetThucDuKien,
      ngayDuKien: widget.hoSo.ngayDuKienBaoTri,
    );
    if (_gioBatDau != null) {
      _controller.gioBatDau = _gioBatDau;
      _controller.datThoiGianDuKienTuChuoi(raw.isEmpty ? chiSo : raw);
    }
    _gioKetThuc = _controller.gioKetThuc ?? _gioKetThuc;
  }

  @override
  void dispose() {
    _noiDung.dispose();
    _thoiGian.dispose();
    _controller.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s.trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? _fmtTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _onThoiGianChanged(String v) {
    _controller.datThoiGianDuKienTuChuoi(v);
    setState(() {
      _gioKetThuc = _controller.gioKetThuc;
    });
  }

  Future<void> _chonNgay() async {
    // Xưởng: trong tháng kế hoạch + sau ngày hiện tại
    final goc = widget.hoSo.ngayDuKienBaoTri ?? _ngayDuKien ?? DateTime.now();
    final now = DateTime.now();
    final ngayMai =
    DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
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
    var initial = _ngayDuKien ?? firstOfRange;
    if (initial.isBefore(firstOfRange)) initial = firstOfRange;
    if (initial.isAfter(lastOfRange)) initial = lastOfRange;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstOfRange,
      lastDate: lastOfRange,
      helpText: 'Tháng ${goc.month}/${goc.year} — sau ngày hiện tại',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null) {
      setState(() {
        _ngayDuKien = picked;
        _controller.loi = null;
      });
      try {
        final thangCo = await WorkOrderService.layThangCoBaoTri(
          widget.hoSo.maThietBi,
          nam: goc.year,
        );
        if (thangCo.contains(picked.month) &&
            picked.month != goc.month &&
            mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lưu ý: tháng ${picked.month}/${goc.year} thiết bị này đã có lịch bảo trì.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _chonGioBatDau() async {
    if (!_choPhepChonGioBatDau) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _loiThoiGian ??
                'Nhập đúng thời gian dự kiến (giờ 1–24 hoặc phút 1–1440) trước khi chọn giờ bắt đầu',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    final initial = _gioBatDau ?? const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    _controller.datGioBatDau(picked);
    setState(() {
      _gioBatDau = picked;
      _gioKetThuc = _controller.gioKetThuc;
    });
  }

  Future<void> _luu() async {
    // Thời gian chỉ hiển thị — không bắt buộc nhập khi sửa từ chối
    final ok = await _controller.luu(
      maHoSoBaoTri: widget.hoSo.maHoSoBaoTri,
      noiDungCongViec: _noiDung.text,
      ngayDuKienBaoTri: _ngayDuKien,
      ngayDuKienGoc: widget.hoSo.ngayDuKienBaoTri,
      ngayTao: widget.hoSo.ngayTao,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã gửi lại hồ sơ để duyệt'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } else if (_controller.loi != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.loi!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final hs = widget.hoSo;
    final thoiGianHien = (hs.thoiGianDuKien == null ||
        hs.thoiGianDuKien!.trim().isEmpty)
        ? '?'
        : formatThoiGianDuKienHienThi(hs.thoiGianDuKien);
    final gioBd = (hs.gioBatDauDuKien == null ||
        hs.gioBatDauDuKien!.trim().isEmpty)
        ? '?'
        : hs.gioBatDauDuKien!;
    final gioKt = (hs.gioKetThucDuKien == null ||
        hs.gioKetThucDuKien!.trim().isEmpty)
        ? '?'
        : hs.gioKetThucDuKien!;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FC),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              // Header gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(8, top + 4, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B6BCB),
                      Color(0xFF0284C7),
                      Color(0xFF0EA5E9),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x400B6BCB),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const Expanded(
                          child: Text(
                            'Sửa hồ sơ bị từ chối',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'HS #${hs.maHoSoBaoTri}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: Text(
                        hs.tenThietBi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    // Lý do từ chối
                    if (hs.lyDoTuChoi != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - t)),
                            child: child,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFEE2E2),
                                Colors.white,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFFECACA)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.danger
                                    .withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.danger
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.report_gmailerrorred_rounded,
                                    color: AppColors.danger,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lý do từ chối',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hs.lyDoTuChoi!,
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        height: 1.4,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Nội dung
                    _sectionCard(
                      title: 'Nội dung công việc',
                      child: TextField(
                        controller: _noiDung,
                        maxLines: 4,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, height: 1.35),
                        decoration: _inputDeco(
                          hint: 'Mô tả công việc bảo trì…',
                          icon: Icons.description_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Thời gian chỉ xem
                    _sectionCard(
                      title: 'Thời gian thực hiện',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _pillInfo(
                                      'Dự kiến', thoiGianHien)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _pillInfo('Bắt đầu', gioBd)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _pillInfo('Kết thúc', gioKt)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Chỉ xem — ghi nhận khi NVKT Tiến hành / hoàn thành.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ngày dự kiến
                    _sectionCard(
                      title: 'Lịch bảo trì dự kiến',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Material(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _chonNgay,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF0B6BCB),
                                            Color(0xFF0EA5E9),
                                          ],
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                          Icons.calendar_month_rounded,
                                          color: Colors.white,
                                          size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ngày bảo trì dự kiến',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _ngayDuKien == null
                                                ? 'Chạm để chọn ngày'
                                                : '${_ngayDuKien!.day.toString().padLeft(2, '0')}/${_ngayDuKien!.month.toString().padLeft(2, '0')}/${_ngayDuKien!.year}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: Colors.grey.shade400),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hs.ngayDuKienBaoTri != null
                                ? 'Chỉ chọn ngày trong tháng ${hs.ngayDuKienBaoTri!.month}/${hs.ngayDuKienBaoTri!.year} (kế hoạch Tổ trưởng).'
                                : 'Chỉ chọn ngày trong đúng tháng kế hoạch.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_controller.loi != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          _controller.loi!,
                          style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),
                    // CTA gradient
                    SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _controller.dangLuu
                              ? null
                              : const LinearGradient(
                            colors: [
                              Color(0xFF0B6BCB),
                              Color(0xFF0284C7),
                            ],
                          ),
                          color: _controller.dangLuu
                              ? Colors.grey.shade300
                              : null,
                          boxShadow: _controller.dangLuu
                              ? null
                              : [
                            BoxShadow(
                              color: const Color(0xFF0B6BCB)
                                  .withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap:
                            _controller.dangLuu ? null : _luu,
                            child: Center(
                              child: _controller.dangLuu
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                                  : const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded,
                                      color: Colors.white,
                                      size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Gửi lại duyệt',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pillInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dongChiXem(String nhan, String giaTri) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            nhan,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            giaTri,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    String? suffix,
    String? label,
    String? errorText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixText: suffix,
      errorText: errorText,
      errorMaxLines: 3,
      helperText: helperText,
      helperMaxLines: 2,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (showChevron)
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}