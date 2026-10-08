part of work_order_detail_screen;


// ============ MÀN 3: CHI TIẾT HỒ SƠ BẢO TRÌ + PHÂN CÔNG (khi đã duyệt) ============

class WorkOrderBaoTriDetailScreen extends StatefulWidget {
  final int maHoSoBaoTri;
  const WorkOrderBaoTriDetailScreen({super.key, required this.maHoSoBaoTri});
  @override
  State<WorkOrderBaoTriDetailScreen> createState() => _WorkOrderBaoTriDetailScreenState();
}

class _WorkOrderBaoTriDetailScreenState extends State<WorkOrderBaoTriDetailScreen> {
  late final WorkOrderBaoTriDetailController _controller;
  final _xuongCtrl = XuongChinhSuaHoSoController();

  final _noiDungXuongCtrl = TextEditingController();
  final _thoiGianXuongCtrl = TextEditingController();

  /// Quy trình / vật tư NVKT đã gửi (một khối — thay bản tổ trưởng chọn khi đã gửi Xưởng).
  HoSoVatTuItem? _hoSoVatTu;
  List<_BuocQtDetailView> _dsBuocFull = [];
  bool _dangTaiQuyTrinh = false;
  String? _loiQuyTrinh;

  /// Tổ trưởng đã Lưu kế hoạch bước (bắt buộc trước phân công).
  bool _daLuuKeHoachBuoc = false;

  bool get _laToTruong => _controller.laToTruong;
  bool get _laNvkt => _controller.laNvkt;
  bool get _laXuong => _controller.laXuong;

  // Alias UI bindings → logic Xưởng
  bool get _dangChinhSuaXuong => _xuongCtrl.dangChinhSua;
  bool get _dangLuuXuong => _xuongCtrl.dangLuu;
  String? get _loiThoiGianXuong => _xuongCtrl.loiThoiGian;
  bool get _thoiGianXuongHopLe => _xuongCtrl.thoiGianHopLe;
  TimeOfDay? get _gioBatDauXuong => _xuongCtrl.gioBatDau;
  TimeOfDay? get _gioKetThucXuong => _xuongCtrl.gioKetThuc;
  DateTime? get _ngayDuKienXuong => _xuongCtrl.ngayDuKien;

  @override
  void initState() {
    super.initState();
    _controller = WorkOrderBaoTriDetailController(widget.maHoSoBaoTri);
    _controller.taiChiTiet().then((_) async {
      if (!mounted) return;
      final hs = _controller.hoSo;
      if (hs != null) {
        await _dongBoCoKeHoachBuoc(hs);
        if (!mounted) return;
        setState(() {});
        // Luôn tải đủ bước mẫu + đã chọn (Tổ trưởng xem cả bước không chọn)
        _taiQuyTrinhVatTu(hs);
      } else {
        setState(() {});
      }
    });
    _xuongCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  bool _canhBaoCanTaiQuyTrinhNvkt(HoSoBaoTri hs) =>
      hs.daHoanThanh ||
          hs.choXacNhanKetQua ||
          (hs.dangThucHien &&
              (hs.trangThaiPhanCong == 'Chờ xác nhận' ||
                  hs.trangThaiPhanCong == 'Từ chối' ||
                  hs.trangThaiPhanCong == 'Hoàn thành'));

  /// Đã có quy trình NVKT gửi → chỉ 1 khối mới nhất (không hiện bản tổ trưởng chọn lúc tạo).
  bool _daCoQuyTrinhNvktGui(HoSoBaoTri hs) => _canhBaoCanTaiQuyTrinhNvkt(hs);

  /// Bước đã chọn lúc tạo / đã lưu trên server → cho phép phân công (không bắt Lưu lại).
  Future<void> _dongBoCoKeHoachBuoc(HoSoBaoTri hs) async {
    if (hs.danhSachBuocQuyTrinh.isNotEmpty) {
      _daLuuKeHoachBuoc = true;
      return;
    }
    try {
      final soBuoc = await ToTruongKeHoachBuocService.laySoBuocDaChon(
        maHoSoBaoTri: hs.maHoSoBaoTri,
      );
      _daLuuKeHoachBuoc = soBuoc.isNotEmpty;
    } catch (_) {
      _daLuuKeHoachBuoc = false;
    }
  }

  void dispose() {
    _noiDungXuongCtrl.dispose();
    _thoiGianXuongCtrl.dispose();
    _xuongCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.dangTai) {
          return const Scaffold(
            backgroundColor: _kBtBg,
            body: Center(
              child: CircularProgressIndicator(
                  color: _kBtPrimary, strokeWidth: 3),
            ),
          );
        }
        if (_controller.loi != null || _controller.hoSo == null) {
          return Scaffold(
            backgroundColor: _kBtBg,
            body: Column(
              children: [
                _btHeaderBar(top: top, title: 'Chi tiết hồ sơ BT'),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_controller.loi ?? 'Không tải được hồ sơ'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _controller.taiChiTiet,
                          style: FilledButton.styleFrom(
                              backgroundColor: _kBtPrimary),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final hs = _controller.hoSo!;
        final mauTt = _mauTrangThai(hs.trangThai);
        final tenTt = (hs.trangThai == 'Chờ xưởng')
            ? 'Chờ duyệt'
            : (hs.trangThai == 'Chờ GĐ duyệt'
            ? 'Chờ GĐ duyệt'
            : hs.trangThai);

        return Scaffold(
          backgroundColor: _kBtBg,
          body: Column(
            children: [
              _btHeaderBar(
                top: top,
                title: 'Hồ sơ BT #${hs.maHoSoBaoTri}',
                subtitle: tenTt,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await _controller.taiChiTiet();
                    final h = _controller.hoSo;
                    if (h != null &&
                        (h.daHoanThanh ||
                            (_laXuong &&
                                (h.choXacNhanKetQua || h.dangThucHien)))) {
                      await _taiQuyTrinhVatTu();
                    }
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      // Hero card — đồng bộ giao diện SC
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 480),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - t)),
                            child: child,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0068A9),
                                Color(0xFF0284C7),
                                Color(0xFF0EA5E9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _kBtPrimary.withValues(alpha: 0.32),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
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
                                    size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hs.tenThietBi,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16.5,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tenTt,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Thông tin hồ sơ
                      _cardBox(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18,
                                  color: AppColors.primary
                                      .withValues(alpha: 0.9)),
                              const SizedBox(width: 8),
                              const Text(
                                'Thông tin hồ sơ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: mauTt.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tenTt,
                                  style: TextStyle(
                                      color: mauTt,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _dong('Người lập', hs.tenNhanVienTao ?? '—'),
                          const Divider(height: 18, color: Color(0xFFE8EEF4)),
                          _dong('Ngày tạo', _fmt(hs.ngayTao)),
                          if (hs.ngayDuyet != null) ...[
                            const Divider(
                                height: 18, color: Color(0xFFE8EEF4)),
                            _dong('Ngày duyệt', _fmt(hs.ngayDuyet)),
                          ],
                          const Divider(height: 18, color: Color(0xFFE8EEF4)),
                          // Tổ trưởng: chỉ sửa ngày của chính hồ sơ này khi còn Chờ gửi
                          if (_laToTruong && hs.choGui)
                            InkWell(
                              onTap: () => _suaNgayDuKienChoGui(hs),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _dong(
                                        'Ngày bảo trì dự kiến',
                                        _fmt(hs.ngayDuKienBaoTri),
                                      ),
                                    ),
                                    Icon(Icons.edit_calendar_outlined,
                                        size: 18,
                                        color: AppColors.primary
                                            .withValues(alpha: 0.85)),
                                  ],
                                ),
                              ),
                            )
                          else
                            _dong('Ngày bảo trì dự kiến',
                                _fmt(hs.ngayDuKienBaoTri)),
                          const Divider(height: 18, color: Color(0xFFE8EEF4)),
                          _dong(
                            'Thời gian dự kiến',
                            (hs.thoiGianDuKien == null ||
                                hs.thoiGianDuKien!.trim().isEmpty)
                                ? '?'
                                : formatThoiGianDuKienHienThi(hs.thoiGianDuKien),
                          ),
                          const Divider(height: 18, color: Color(0xFFE8EEF4)),
                          _dong(
                            'Giờ bắt đầu',
                            (hs.gioBatDauDuKien == null ||
                                hs.gioBatDauDuKien!.trim().isEmpty)
                                ? '?'
                                : hs.gioBatDauDuKien!,
                          ),
                          const Divider(height: 18, color: Color(0xFFE8EEF4)),
                          _dong(
                            'Giờ kết thúc',
                            (hs.gioKetThucDuKien == null ||
                                hs.gioKetThucDuKien!.trim().isEmpty)
                                ? '?'
                                : hs.gioKetThucDuKien!,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Nội dung công việc
                      _cardBox(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 18, color: _kBtPrimary),
                              SizedBox(width: 8),
                              Text(
                                'Nội dung công việc',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hs.noiDungCongViec ?? '—',
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),

                      // Phân công → «được phân công»; hoàn thành → đổi nhãn «đã bảo trì»
                      if ((hs.tenNhanVienThucHiens ?? '').trim().isNotEmpty ||
                          hs.maNhanVienThucHiens.isNotEmpty ||
                          (hs.daHoanThanh &&
                              ((hs.tenNhanVienHoanThanhs ?? '').trim().isNotEmpty ||
                                  hs.maNhanVienHoanThanhs.isNotEmpty))) ...[
                        const SizedBox(height: 12),
                        _cardBox(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  hs.daHoanThanh
                                      ? Icons.verified_rounded
                                      : Icons.people_alt_rounded,
                                  size: 18,
                                  color: hs.daHoanThanh
                                      ? AppColors.success
                                      : _kBtPrimary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hs.daHoanThanh
                                        ? 'Nhân viên đã bảo trì'
                                        : 'Nhân viên được phân công',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                Builder(builder: (_) {
                                  final mau = hs.daHoanThanh
                                      ? AppColors.success
                                      : _kBtPrimary;
                                  final so = hs.daHoanThanh &&
                                      hs.maNhanVienHoanThanhs.isNotEmpty
                                      ? hs.maNhanVienHoanThanhs.length
                                      : (hs.maNhanVienThucHiens.isNotEmpty
                                      ? hs.maNhanVienThucHiens.length
                                      : (hs.tenNhanVienThucHiens ?? '')
                                      .split(',')
                                      .where((e) => e.trim().isNotEmpty)
                                      .length);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: mau.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$so người',
                                      style: TextStyle(
                                        color: mau,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ((hs.daHoanThanh
                                  ? (hs.tenNhanVienHoanThanhs ??
                                  hs.tenNhanVienThucHiens ??
                                  hs.tenNhanVienThucHien)
                                  : (hs.tenNhanVienThucHiens ??
                                  hs.tenNhanVienThucHien)) ??
                                  '—')
                                  .trim(),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: hs.daHoanThanh
                                    ? AppColors.success
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Quy trình: đủ bước mẫu; ẩn khối này khi NVKT đã gửi (dùng khối riêng)
                      if (!_daCoQuyTrinhNvktGui(hs)) ...[
                        const SizedBox(height: 12),
                        _cardBox(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_tree_rounded,
                                    size: 18, color: _kBtPrimary),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Quy trình thực hiện',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                if (_dsBuocFull.isNotEmpty)
                                  Text(
                                    '${_dsBuocFull.where((e) => e.daChon).length}/${_dsBuocFull.length} chọn',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hiển thị cả bước đã chọn và chưa chọn lúc tạo hồ sơ.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_dangTaiQuyTrinh)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            else if (_dsBuocFull.isEmpty &&
                                hs.danhSachBuocQuyTrinh.isEmpty)
                              Text(
                                'Chưa có dữ liệu quy trình.',
                                style: TextStyle(color: Colors.grey.shade600),
                              )
                            else
                              ...(_dsBuocFull.isNotEmpty
                                  ? _dsBuocFull
                                  : hs.danhSachBuocQuyTrinh
                                  .map((b) => _BuocQtDetailView(
                                soBuoc: b.soBuoc,
                                moTa: b.moTaBuoc.isEmpty
                                    ? 'Bước ${b.soBuoc}'
                                    : b.moTaBuoc,
                                trangThai: b.trangThai ?? 'DuocChon',
                                tenNhanVien: b.tenNhanVien,
                                daThucHien: false,
                                daChon: true,
                                vatTu: const [],
                              ))
                                  .toList())
                                  .map((b) {
                                final chon = b.daChon;
                                final tt = b.trangThai.trim();
                                final chip = !chon
                                    ? 'Không chọn'
                                    : (tt == 'DaXong' || tt == 'DaCapNhat'
                                    ? 'Đã xong'
                                    : tt == 'DangLam'
                                    ? 'Đang làm'
                                    : 'Đã chọn');
                                final chipColor = !chon
                                    ? Colors.grey
                                    : (tt == 'DaXong' || tt == 'DaCapNhat'
                                    ? AppColors.success
                                    : tt == 'DangLam'
                                    ? AppColors.warning
                                    : _kBtPrimary);
                                return Opacity(
                                  opacity: chon ? 1 : 0.72,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                      decoration: BoxDecoration(
                                        color: chon
                                            ? _kBtPrimary.withValues(alpha: 0.05)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: chon
                                              ? _kBtPrimary.withValues(alpha: 0.28)
                                              : Colors.grey.shade300,
                                          width: chon ? 1.2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: chon
                                                  ? _kBtPrimary
                                                  : Colors.grey.shade400,
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${b.soBuoc}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  b.moTa,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13.5,
                                                    height: 1.35,
                                                    color: chon
                                                        ? const Color(0xFF0F172A)
                                                        : Colors.grey.shade700,
                                                    decoration: chon
                                                        ? null
                                                        : TextDecoration
                                                        .lineThrough,
                                                    decorationColor:
                                                    Colors.grey.shade500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: chipColor
                                                        .withValues(alpha: 0.12),
                                                    borderRadius:
                                                    BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: chipColor
                                                          .withValues(alpha: 0.35),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    chip,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      color: chipColor,
                                                    ),
                                                  ),
                                                ),
                                                if (chon &&
                                                    (b.tenNhanVien ?? '')
                                                        .trim()
                                                        .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                    const EdgeInsets.only(
                                                        top: 4),
                                                    child: Text(
                                                      b.tenNhanVien!.trim(),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                        Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ],

                      // Lý do từ chối hồ sơ (GĐ từ chối duyệt)
                      if (hs.biTuChoi && hs.lyDoTuChoi != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          color: AppColors.danger.withValues(alpha: 0.06),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Lý do từ chối (duyệt hồ sơ)',
                                    style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(hs.lyDoTuChoi!, style: const TextStyle(color: AppColors.danger)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // NVKT từ chối nhận phân công — tông cam nhạt, dễ nhìn
                      if (hs.phanCongBiTuChoi) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF5C896)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEDD5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.person_off_outlined, size: 14, color: Color(0xFFC2410C)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Phân công: Từ chối',
                                          style: TextStyle(
                                            color: Color(0xFFC2410C),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _dong('Nhân viên từ chối', hs.tenNhanVienThucHien ?? '—'),
                              if (hs.ngayPhanCong != null) ...[
                                const Divider(height: 20, color: Color(0xFFF5C896)),
                                _dong('Ngày phân công', _fmt(hs.ngayPhanCong)),
                              ],
                              const Divider(height: 20, color: Color(0xFFF5C896)),
                              const Text(
                                'Lý do từ chối nhận việc',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF9A3412),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (hs.lyDoTuChoiPhanCong != null && hs.lyDoTuChoiPhanCong!.isNotEmpty)
                                    ? hs.lyDoTuChoiPhanCong!
                                    : '—',
                                style: const TextStyle(
                                  color: Color(0xFF431407),
                                  height: 1.4,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Tổ trưởng: hồ sơ mới tạo — Gửi đến xưởng
                      if (_laToTruong && hs.choGui)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                                ),
                              ),
                              child: const Text(
                                'Hồ sơ đang Chờ gửi — chưa gửi xưởng. '
                                    'Có thể chỉnh ngày dự kiến nếu cần, rồi bấm Gửi đến xưởng.',
                                style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => _guiDenXuong(hs),
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('Gửi đến xưởng'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ],
                        )
                      // Xưởng — quy trình + nút Xác nhận/Từ chối
                      else if (_laXuong &&
                          (hs.choXacNhanKetQua ||
                              hs.dangThucHien ||
                              hs.daHoanThanh))
                        _buildXuongQuyTrinhVaDuyet(hs)
                      // Tổ trưởng / khác: xem quy trình mới nhất — không nút duyệt
                      else if (!_laXuong && _daCoQuyTrinhNvktGui(hs))
                          _buildQuyTrinhChiXemToTruong(hs)
                        // Xưởng: còn chỉnh sửa/gửi HOẶC đã gửi → chỉ hiện chờ GĐ
                        else if (_laXuong && hs.choXuong)
                            _buildXuongActions(hs)
                          else if (_laXuong && hs.daGuiGiamDoc)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 22),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Đã gửi Giám đốc — đang chờ duyệt. Không thể chỉnh sửa hay gửi lại.',
                                        style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if ((hs.daDuyetChuaPhanCong || hs.phanCongBiTuChoi) && _laToTruong)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (hs.maThietBi > 0)
                                    // Quy trình chọn lúc tạo hồ sơ — không chỉnh ở chi tiết
                                      const SizedBox.shrink(),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.groups_rounded),
                                      label: Text(hs.phanCongBiTuChoi
                                          ? 'Phân công lại nhân viên khác'
                                          : 'Phân công nhân viên'),
                                      onPressed: () async {
                                        final block =
                                        ToTruongKeHoachBuocRules.kiemTraTruocKhiPhanCong(
                                          daLuuKeHoach: _daLuuKeHoachBuoc ||
                                              hs.danhSachBuocQuyTrinh.isNotEmpty ||
                                              _dsBuocFull.any((e) => e.daChon),
                                        );
                                        if (block != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(block),
                                              backgroundColor: AppColors.danger,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        final ok = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PhanCongBaoTriScreen(
                                                maHoSoBaoTri: hs.maHoSoBaoTri),
                                          ),
                                        );
                                        if (ok == true && mounted) {
                                          await _controller.taiChiTiet();
                                        }
                                      },
                                    ),
                                  ],
                                )
                              else if (hs.coTheCapNhatPhanCong && _laToTruong)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (hs.maThietBi > 0)
                                      // Quy trình chọn lúc tạo hồ sơ — không chỉnh ở chi tiết
                                        const SizedBox.shrink(),
                                      if ((hs.tenNhanVienThucHiens ?? hs.tenNhanVienThucHien) != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.07),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.people_alt_rounded, size: 20, color: AppColors.primary),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Đang phân công: ${hs.tenNhanVienThucHiens ?? hs.tenNhanVienThucHien}',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.manage_accounts_rounded),
                                        label: const Text('Cập nhật phân công'),
                                        onPressed: () async {
                                          final ok = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PhanCongBaoTriScreen(
                                                maHoSoBaoTri: hs.maHoSoBaoTri,
                                                isCapNhat: true,
                                              ),
                                            ),
                                          );
                                          if (ok == true && mounted) {
                                            await _controller.taiChiTiet();
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                else if (hs.dangThucHien && _laNvkt)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.task_alt_rounded),
                                      label: const Text('Hoàn thành bảo trì'),
                                      onPressed: () async {
                                        final ok = await _controller.nhanVienHoanThanhBaoTri();
                                        if (!mounted) return;
                                        if (ok) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Đã hoàn thành. Đồng bộ trạng thái hồ sơ và kế hoạch bảo trì.')),
                                          );
                                          setState(() {});
                                        } else if (_controller.loi != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(_controller.loi!)),
                                          );
                                        }
                                      },
                                    )
                                  else if (hs.biTuChoi && _laXuong)
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.edit_rounded),
                                        label: const Text('Chỉnh sửa & gửi lại duyệt'),
                                        onPressed: () async {
                                          final ok = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SuaHoSoBiTuChoiScreen(hoSo: hs),
                                            ),
                                          );
                                          if (ok == true && mounted) {
                                            await _controller.taiChiTiet();
                                          }
                                        },
                                      )
                                    else if (hs.choDuyet)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.hourglass_top_rounded,
                                                  color: AppColors.warning, size: 20),
                                              SizedBox(width: 8),
                                              Expanded(
                                                  child: Text(
                                                      'Đang chờ Giám đốc/Phó giám đốc duyệt')),
                                            ],
                                          ),
                                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}