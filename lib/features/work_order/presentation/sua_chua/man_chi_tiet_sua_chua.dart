part of work_order_repair_screens;

// ============ CHI TIẾT HỒ SƠ SỬA CHỮA ============

class ChiTietHoSoSuaChuaScreen extends StatefulWidget {
  final int maHoSo;
  const ChiTietHoSoSuaChuaScreen({super.key, required this.maHoSo});

  @override
  State<ChiTietHoSoSuaChuaScreen> createState() =>
      _ChiTietHoSoSuaChuaScreenState();
}

class _ChiTietHoSoSuaChuaScreenState extends State<ChiTietHoSoSuaChuaScreen>
    with SingleTickerProviderStateMixin {
  late final ChiTietHoSoSuaChuaController _ctrl;
  late final AnimationController _anim;

  HoSoVatTuItem? _hoSoVatTu;
  bool _dangTaiQuyTrinh = false;
  String? _loiQuyTrinh;
  bool _daLuuKeHoachBuoc = false;

  /// Đủ bước mẫu SC (kể cả bước không chọn lúc tạo).
  List<_BuocScQtView> _dsBuocDayDu = [];
  bool _dangTaiBuocDayDu = false;

  bool get _laToTruong => _ctrl.laToTruong;
  bool get _laNvkt => _ctrl.laNvkt;
  bool get _laXuong => _ctrl.laXuong;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _ctrl = ChiTietHoSoSuaChuaController(widget.maHoSo);
    _ctrl.addListener(_onCtrl);
    _ctrl.tai().then((_) async {
      final hs = _ctrl.hoSo;
      if (hs != null) {
        await _dongBoCoKeHoachBuocSc(hs);
        if (!mounted) return;
        setState(() {});
        // Luôn tải đủ bước mẫu + đã chọn (kể cả bước không chọn)
        await _taiDuBuocQuyTrinh(hs);
        if (!mounted) return;
        // Xưởng: xem quy trình NVKT khi Đang thực hiện / chờ duyệt / đã xong
        // Tổ trưởng & vai trò khác: chỉ khi Đã hoàn thành
        if (hs.daHoanThanh ||
            (_laXuong && (hs.choXacNhanKetQua || hs.dangThucHien))) {
          _taiQuyTrinhVatTu();
        }
      }
    });
  }

  /// Gộp mẫu quy trình + bước đã chọn / tiến độ + vật tư NVKT → đủ danh sách.
  Future<void> _taiDuBuocQuyTrinh(HoSoSuaChua hs) async {
    setState(() => _dangTaiBuocDayDu = true);
    try {
      final maTb = hs.maThietBi;
      final results = await Future.wait([
        maTb > 0
            ? MaterialUsageService.layQuyTrinhThietBi(
          maThietBi: maTb,
          loaiCongViec: 'Sửa chữa',
        )
            : Future.value(<BuocQuyTrinh>[]),
        WorkOrderService.layTienDoBuoc(maHoSoSuaChua: hs.maHoSoSuaChua),
        MaterialUsageService.layHoSoTheoCongViec(
          maHoSoSuaChua: hs.maHoSoSuaChua,
        ),
      ]);
      final mau = results[0] as List<BuocQuyTrinh>;
      final tienDo = results[1] as List<Map<String, dynamic>>;
      final hsVt = results[2] as HoSoVatTuItem?;

      final chonSet = <int>{};
      final moTaTheoBuoc = <int, String>{};
      final ttTheoBuoc = <int, String>{};
      final vtTheoBuoc = <int, List<_VatTuBuocSc>>{};

      for (final b in hs.danhSachBuocQuyTrinh) {
        chonSet.add(b.soBuoc);
        if (b.moTaBuoc.trim().isNotEmpty) {
          moTaTheoBuoc[b.soBuoc] = b.moTaBuoc.trim();
        }
        final tt = (b.trangThai ?? '').trim();
        if (tt.isNotEmpty) ttTheoBuoc[b.soBuoc] = tt;
      }
      for (final row in tienDo) {
        final so = (row['soBuoc'] as num?)?.toInt() ??
            (row['SoBuoc'] as num?)?.toInt();
        if (so == null || so <= 0) continue;
        final tt = (row['trangThai'] ?? row['TrangThai'])?.toString() ?? '';
        if (tt == 'DuocChon' ||
            tt == 'DangLam' ||
            tt == 'DaXong' ||
            tt == 'DaCapNhat') {
          chonSet.add(so);
        }
        if (tt.isNotEmpty) ttTheoBuoc[so] = tt;
        final moTa = (row['moTaBuoc'] ?? row['MoTaBuoc'])?.toString() ?? '';
        if (moTa.trim().isNotEmpty) moTaTheoBuoc[so] = moTa.trim();
      }
      if (hsVt != null) {
        for (final c in hsVt.chiTiet) {
          if (c.tenVatTu.isEmpty || c.soLuong <= 0) continue;
          chonSet.add(c.soBuoc);
          vtTheoBuoc.putIfAbsent(c.soBuoc, () => []).add(
            _VatTuBuocSc(ten: c.tenVatTu, soLuong: c.soLuong),
          );
          if (c.moTaBuoc.trim().isNotEmpty) {
            moTaTheoBuoc.putIfAbsent(c.soBuoc, () => c.moTaBuoc.trim());
          }
        }
      }

      final soBuocSet = <int>{};
      for (final b in mau) {
        soBuocSet.add(b.soBuoc);
      }
      soBuocSet.addAll(chonSet);
      soBuocSet.addAll(vtTheoBuoc.keys);
      if (soBuocSet.isEmpty) {
        for (final b in hs.danhSachBuocQuyTrinh) {
          soBuocSet.add(b.soBuoc);
        }
      }
      final sorted = soBuocSet.toList()..sort();

      final views = <_BuocScQtView>[];
      for (final so in sorted) {
        String? mauMoTa;
        for (final e in mau) {
          if (e.soBuoc == so) {
            mauMoTa = e.moTa;
            break;
          }
        }
        final moTa = (moTaTheoBuoc[so] ?? '').trim().isNotEmpty
            ? moTaTheoBuoc[so]!.trim()
            : ((mauMoTa ?? '').trim().isNotEmpty
            ? mauMoTa!.trim()
            : 'Bước $so');
        final daChon = chonSet.contains(so);
        views.add(_BuocScQtView(
          soBuoc: so,
          moTa: moTa,
          daChon: daChon,
          trangThai: ttTheoBuoc[so] ?? (daChon ? 'DuocChon' : ''),
          vatTu: vtTheoBuoc[so] ?? const [],
        ));
      }

      if (!mounted) return;
      setState(() {
        _dsBuocDayDu = views;
        _hoSoVatTu = hsVt;
        _dangTaiBuocDayDu = false;
        if (views.any((e) => e.daChon)) {
          _daLuuKeHoachBuoc = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dsBuocDayDu = hs.danhSachBuocQuyTrinh
            .map((b) => _BuocScQtView(
          soBuoc: b.soBuoc,
          moTa: b.moTaBuoc.trim().isEmpty
              ? 'Bước ${b.soBuoc}'
              : b.moTaBuoc.trim(),
          daChon: true,
          trangThai: b.trangThai ?? 'DuocChon',
          vatTu: const [],
        ))
            .toList();
        _dangTaiBuocDayDu = false;
      });
    }
  }

  /// Bước đã chọn lúc tạo SC → đủ điều kiện phân công.
  Future<void> _dongBoCoKeHoachBuocSc(HoSoSuaChua hs) async {
    if (hs.danhSachBuocQuyTrinh.isNotEmpty) {
      _daLuuKeHoachBuoc = true;
      return;
    }
    try {
      final soBuoc = await ToTruongKeHoachBuocService.laySoBuocDaChon(
        maHoSoSuaChua: hs.maHoSoSuaChua,
      );
      _daLuuKeHoachBuoc = soBuoc.isNotEmpty;
    } catch (_) {
      _daLuuKeHoachBuoc = false;
    }
  }

  Future<void> _taiQuyTrinhVatTu() async {
    setState(() {
      _dangTaiQuyTrinh = true;
      _loiQuyTrinh = null;
    });
    try {
      final hs = await MaterialUsageService.layHoSoTheoCongViec(
        maHoSoSuaChua: widget.maHoSo,
      );
      if (!mounted) return;
      setState(() {
        _hoSoVatTu = hs;
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

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrl);
    _ctrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _ctrl.tai();
    final hs = _ctrl.hoSo;
    if (hs != null) {
      await _dongBoCoKeHoachBuocSc(hs);
      await _taiDuBuocQuyTrinh(hs);
    }
  }

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    if (_ctrl.dangTai) {
      return const Scaffold(
        backgroundColor: _scBg,
        body: Center(
          child: CircularProgressIndicator(color: _scPrimary, strokeWidth: 3),
        ),
      );
    }
    if (_ctrl.loi != null || _ctrl.hoSo == null) {
      return Scaffold(
        backgroundColor: _scBg,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(8, top + 6, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF004E80), Color(0xFF0068A9)],
                ),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                  const Text('Chi tiết SC',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_ctrl.loi ?? 'Không có dữ liệu'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      style: FilledButton.styleFrom(
                          backgroundColor: _scPrimary),
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
    final hs = _ctrl.hoSo!;
    return Scaffold(
      backgroundColor: ModernDetailUi.bg,
      body: Column(
        children: [
          ModernDetailUi.headerBar(
            context: context,
            topPadding: top,
            title: 'Hồ sơ SC #${hs.maHoSoSuaChua}',
            subtitle: hs.trangThai,
          ),
          Expanded(
            child: FadeTransition(
              opacity: CurvedAnimation(
                  parent: _anim, curve: Curves.easeOutCubic),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  // Hero card — đồng bộ ModernDetailUi
                  ModernDetailUi.fadeSlide(
                    delayMs: 0,
                    child: ModernDetailUi.heroCard(
                      icon: Icons.handyman_rounded,
                      title: hs.tenThietBi,
                      statusLabel: hs.trangThai,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 1) Thông tin hồ sơ trước
                  ModernDetailUi.fadeSlide(
                    delayMs: 40,
                    child: ModernDetailUi.softCard(
                      child: Column(
                        children: [
                          ModernDetailUi.sectionTitle(
                            icon: Icons.info_outline_rounded,
                            title: 'Thông tin hồ sơ',
                            trailing: ModernDetailUi.statusChip(hs.trangThai),
                          ),
                          const SizedBox(height: 8),
                          ModernDetailUi.infoRow(
                              'Người tạo', hs.tenNhanVienTao ?? '—'),
                          Divider(height: 1, color: Colors.grey.shade200),
                          ModernDetailUi.infoRow(
                              'Ngày tạo', _fmt(hs.ngayTao)),
                          if (hs.ngayDuyet != null) ...[
                            Divider(height: 1, color: Colors.grey.shade200),
                            ModernDetailUi.infoRow(
                                'Ngày duyệt', _fmt(hs.ngayDuyet)),
                          ],
                          Divider(height: 1, color: Colors.grey.shade200),
                          ModernDetailUi.infoRow(
                            'Thời gian dự kiến',
                            (hs.thoiGianDuKien == null ||
                                hs.thoiGianDuKien!.trim().isEmpty)
                                ? '?'
                                : formatThoiGianDuKienHienThi(hs.thoiGianDuKien),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          ModernDetailUi.infoRow(
                            'Giờ bắt đầu',
                            (hs.gioBatDauDuKien != null &&
                                hs.gioBatDauDuKien!.trim().isNotEmpty)
                                ? hs.gioBatDauDuKien!
                                : '?',
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          ModernDetailUi.infoRow(
                            'Giờ kết thúc',
                            (hs.gioKetThucDuKien != null &&
                                hs.gioKetThucDuKien!.trim().isNotEmpty)
                                ? hs.gioKetThucDuKien!
                                : '?',
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 2) Nhân viên phân công — ngay sau Thông tin hồ sơ
                  if (hs.daCoPhanCong ||
                      (hs.tenNhanVienThucHiens ?? '').trim().isNotEmpty ||
                      hs.maNhanVienThucHiens.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ModernDetailUi.fadeSlide(
                      delayMs: 60,
                      child: ModernDetailUi.softCard(
                        child: Builder(builder: (_) {
                          final tenHienThi =
                          (hs.tenNhanVienThucHiens ?? '—').trim();
                          final soNguoi = hs.maNhanVienThucHiens.isNotEmpty
                              ? hs.maNhanVienThucHiens.length
                              : tenHienThi
                              .split(',')
                              .where((e) => e.trim().isNotEmpty)
                              .length;
                          final nhan = hs.daHoanThanh
                              ? 'Nhân viên đã sửa chữa'
                              : 'Nhân viên được phân công';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    hs.daHoanThanh
                                        ? Icons.verified_rounded
                                        : Icons.groups_rounded,
                                    color: hs.daHoanThanh
                                        ? AppColors.success
                                        : ModernDetailUi.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      nhan,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (hs.daHoanThanh
                                          ? AppColors.success
                                          : _scPrimary)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$soNguoi người',
                                      style: TextStyle(
                                        color: hs.daHoanThanh
                                            ? AppColors.success
                                            : _scPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                tenHienThi.isEmpty ? '—' : tenHienThi,
                                style: TextStyle(
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ModernDetailUi.fadeSlide(
                    delayMs: 80,
                    child: ModernDetailUi.softCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.report_problem_outlined,
                                  size: 18, color: _scPrimary),
                              SizedBox(width: 8),
                              Text('Mô tả hư hỏng',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(hs.moTaHuHong ?? '—',
                              style: TextStyle(
                                  height: 1.45,
                                  color: Colors.grey.shade800,
                                  fontSize: 14)),
                          if (hs.phuongAnSuaChua != null &&
                              hs.phuongAnSuaChua!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded,
                                    size: 18, color: _scPrimary),
                                SizedBox(width: 8),
                                Text('Phương án SC',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(hs.phuongAnSuaChua!,
                                style: TextStyle(
                                    height: 1.45,
                                    color: Colors.grey.shade800,
                                    fontSize: 14)),
                          ],
                          if (_dsBuocDayDu.isNotEmpty ||
                              hs.danhSachBuocQuyTrinh.isNotEmpty ||
                              _dangTaiBuocDayDu ||
                              _coHienTrangThaiQuyTrinhSc(hs)) ...[
                            const SizedBox(height: 14),
                            Builder(builder: (_) {
                              final coTt = _coHienTrangThaiQuyTrinhSc(hs);
                              final nhanTt = coTt
                                  ? _nhanTtQuyTrinhSc(hs)
                                  : null;
                              final mauTt = nhanTt != null
                                  ? _mauTtQuyTrinhSc(nhanTt)
                                  : _scPrimary;
                              final lyDo =
                              (hs.lyDoTuChoiPhanCong ?? '').trim();
                              final biTuChoi = nhanTt == 'Từ chối';
                              return Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.checklist_rtl_rounded,
                                          size: 18,
                                          color: _scPrimary),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Quy trình đã chọn',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5),
                                        ),
                                      ),
                                      if (nhanTt != null)
                                        Container(
                                          padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                          decoration: BoxDecoration(
                                            color: mauTt.withValues(
                                                alpha: 0.14),
                                            borderRadius:
                                            BorderRadius.circular(20),
                                            border: Border.all(
                                                color: mauTt.withValues(
                                                    alpha: 0.45)),
                                          ),
                                          child: Text(
                                            nhanTt,
                                            style: TextStyle(
                                              color: mauTt,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      else if (_dsBuocDayDu.isNotEmpty)
                                        Text(
                                          '${_dsBuocDayDu.where((e) => e.daChon).length}/${_dsBuocDayDu.length} chọn',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (nhanTt != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (_dsBuocDayDu.isNotEmpty)
                                          Text(
                                            '${_dsBuocDayDu.where((e) => e.daChon).length}/${_dsBuocDayDu.length} chọn · ',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            switch (nhanTt) {
                                              'Xác nhận' =>
                                              'Xưởng đã xác nhận quy trình.',
                                              'Từ chối' =>
                                              'Quy trình bị từ chối — NVKT chỉnh sửa và gửi lại.',
                                              'Chờ xác nhận' =>
                                              'Đang chờ Xưởng xác nhận.',
                                              'Đang thực hiện' =>
                                              'NVKT đang thực hiện quy trình.',
                                              _ => 'Trạng thái: $nhanTt',
                                            },
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hiển thị cả bước đã chọn và chưa chọn lúc tạo hồ sơ.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  // Lý do từ chối gắn ngay trong khối quy trình
                                  if (biTuChoi && lyDo.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 8, 10, 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger
                                            .withValues(alpha: 0.06),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.danger
                                              .withValues(alpha: 0.28),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                              Icons.info_outline_rounded,
                                              size: 16,
                                              color: AppColors.danger),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  const TextSpan(
                                                    text: 'Lý do: ',
                                                    style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.w800,
                                                      fontSize: 12.5,
                                                      color:
                                                      AppColors.danger,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: lyDo,
                                                    style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      fontSize: 12.5,
                                                      height: 1.35,
                                                      color: Colors
                                                          .grey.shade900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                ],
                              );
                            }),
                            if (_dangTaiBuocDayDu)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: _scPrimary),
                                  ),
                                ),
                              )
                            else
                              ...(_dsBuocDayDu.isNotEmpty
                                  ? _dsBuocDayDu
                                  : hs.danhSachBuocQuyTrinh
                                  .map((b) => _BuocScQtView(
                                soBuoc: b.soBuoc,
                                moTa: b.moTaBuoc.trim().isEmpty
                                    ? 'Bước ${b.soBuoc}'
                                    : b.moTaBuoc.trim(),
                                daChon: true,
                                trangThai:
                                b.trangThai ?? 'DuocChon',
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
                                    : _scPrimary);
                                return Opacity(
                                  opacity: chon ? 1 : 0.72,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 10, 10, 10),
                                      decoration: BoxDecoration(
                                        color: chon
                                            ? _scPrimary.withValues(alpha: 0.05)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: chon
                                              ? _scPrimary.withValues(
                                              alpha: 0.22)
                                              : Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 26,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: chon
                                                  ? _scPrimary.withValues(
                                                  alpha: 0.14)
                                                  : Colors.grey.shade200,
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${b.soBuoc}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
                                                color: chon
                                                    ? _scPrimary
                                                    : Colors.grey.shade600,
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
                                                    height: 1.35,
                                                    color: chon
                                                        ? Colors.grey.shade900
                                                        : Colors.grey.shade600,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: chipColor.withValues(
                                                        alpha: 0.12),
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                                  ),
                                                  child: Text(
                                                    chip,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                      FontWeight.w800,
                                                      color: chipColor,
                                                    ),
                                                  ),
                                                ),
                                                if (chon &&
                                                    b.vatTu.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  for (final vt in b.vatTu)
                                                    Padding(
                                                      padding:
                                                      const EdgeInsets.only(
                                                          bottom: 3),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .inventory_2_outlined,
                                                            size: 15,
                                                            color: _scPrimary,
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              '${vt.ten} × ${vt.soLuong}',
                                                              style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600,
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
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_laToTruong &&
                      (hs.choPhanCong || hs.coTheCapNhatPhanCong)) ...[
                    if (hs.maThietBi > 0)
                      const SizedBox.shrink(),
                    _gradientBtn(
                      icon: hs.coTheCapNhatPhanCong
                          ? Icons.manage_accounts_rounded
                          : Icons.groups_rounded,
                      label: hs.coTheCapNhatPhanCong
                          ? 'Cập nhật phân công'
                          : 'Phân công nhân viên',
                      onTap: () async {
                        if (!hs.coTheCapNhatPhanCong) {
                          final block =
                          ToTruongKeHoachBuocRules.kiemTraTruocKhiPhanCong(
                            daLuuKeHoach: _daLuuKeHoachBuoc,
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
                        }
                        final ok = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhanCongBaoTriScreen(
                              maHoSoBaoTri: hs.maHoSoSuaChua,
                              isCapNhat: hs.coTheCapNhatPhanCong,
                              isSuaChua: true,
                            ),
                          ),
                        );
                        if (ok == true) _load();
                      },
                    ),
                  ],
                  if (_laNvkt && hs.dangThucHien) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor:
                          AppColors.success.withValues(alpha: 0.4),
                        ),
                        icon: const Icon(Icons.task_alt_rounded),
                        label: const Text('Hoàn thành sửa chữa',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        onPressed: () async {
                          final ok = await _ctrl.nhanVienHoanThanh();
                          if (!mounted) return;
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Đã hoàn thành — thiết bị trở về Sản xuất'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            Navigator.pop(context, true);
                          } else if (_ctrl.loi != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_ctrl.loi!)),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                  // Xưởng: nút Xác nhận / Từ chối khi chờ duyệt (banner trạng thái đã ở đầu trang)
                  if (_laXuong &&
                      (hs.choXacNhanKetQua ||
                          hs.dangThucHien ||
                          hs.daHoanThanh)) ...[
                    const SizedBox(height: 16),
                    _buildXuongQuyTrinhVaDuyetSc(hs),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Có tiến độ quy trình (đã bắt đầu / chờ duyệt / từ chối / xong) → hiện banner.
  bool _coHienTrangThaiQuyTrinhSc(HoSoSuaChua hs) {
    if (hs.daHoanThanh) return true;
    if (hs.choXacNhanKetQua) return true;
    if (hs.trangThaiPhanCong == 'Từ chối') return true;
    if (hs.trangThaiPhanCong == 'Hoàn thành') return true;
    if (hs.trangThaiPhanCong == 'Chờ xác nhận') return true;
    if (hs.dangThucHien && hs.thoiDiemBatDauThucTe != null) return true;
    if (hs.dangThucHien && hs.daCoPhanCong) return true;
    return false;
  }

  /// Banner trạng thái quy trình + lý do từ chối (đầu trang — Xưởng & Tổ trưởng).
  Widget _buildBannerTrangThaiQuyTrinhSc(HoSoSuaChua hs) {
    final nhan = _nhanTtQuyTrinhSc(hs);
    final mau = _mauTtQuyTrinhSc(nhan);
    final lyDo = (hs.lyDoTuChoiPhanCong ?? '').trim();
    final biTuChoi = nhan == 'Từ chối';
    final moTa = switch (nhan) {
      'Xác nhận' => 'Xưởng đã xác nhận quy trình — hồ sơ Đã hoàn thành.',
      'Từ chối' => lyDo.isNotEmpty
          ? 'Quy trình bị từ chối. Hồ sơ vẫn Đang thực hiện — NVKT chỉnh sửa và gửi lại.'
          : 'Quy trình bị từ chối. Hồ sơ vẫn Đang thực hiện — chờ NVKT gửi lại.',
      'Chờ xác nhận' =>
      'NVKT đã gửi quy trình — đang chờ Xưởng xác nhận hoặc từ chối.',
      'Đang thực hiện' =>
      'Nhân viên kỹ thuật đang thực hiện quy trình sửa chữa.',
      _ => 'Trạng thái quy trình: $nhan',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: mau.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mau.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                biTuChoi
                    ? Icons.cancel_rounded
                    : (nhan == 'Xác nhận'
                    ? Icons.verified_rounded
                    : Icons.account_tree_rounded),
                size: 20,
                color: mau,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Trạng thái quy trình',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: mau.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: mau.withValues(alpha: 0.45)),
                ),
                child: Text(
                  nhan,
                  style: TextStyle(
                    color: mau,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            moTa,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          if (biTuChoi && lyDo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mau.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 18, color: mau),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lý do từ chối',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: mau,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lyDo,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _nhanTtQuyTrinhSc(HoSoSuaChua hs) {
    if (hs.daHoanThanh || hs.trangThaiPhanCong == 'Hoàn thành') {
      return 'Xác nhận';
    }
    if (hs.trangThaiPhanCong == 'Từ chối') return 'Từ chối';
    if (hs.choXacNhanKetQua) return 'Chờ xác nhận';
    if (hs.dangThucHien) return 'Đang thực hiện';
    return hs.trangThaiPhanCong ?? hs.trangThai;
  }

  Color _mauTtQuyTrinhSc(String nhan) {
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

  Widget _buildXuongQuyTrinhVaDuyetSc(HoSoSuaChua hs) {
    // Banner trạng thái đã ở đầu trang — dưới chỉ nút duyệt khi chờ xác nhận
    final choDuyet = hs.choXacNhanKetQua;
    if (!choDuyet) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kiểm tra bước/vật tư ở khối «Quy trình đã chọn» phía trên, rồi xác nhận hoặc từ chối.',
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success),
                onPressed: () async {
                  try {
                    await WorkOrderService.xuongXacNhanKetQua(
                      maHoSoSuaChua: hs.maHoSoSuaChua,
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
                    await _load();
                    await _taiQuyTrinhVatTu();
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
                      maHoSoSuaChua: hs.maHoSoSuaChua,
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
                    await _load();
                    await _taiQuyTrinhVatTu();
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
    );
  }

  Widget _buildQuyTrinhSuaChua() {
    if (_dangTaiQuyTrinh) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loiQuyTrinh != null) {
      return _ScCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quy trình sửa chữa',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 8),
            Text(_loiQuyTrinh!,
                style: TextStyle(color: Colors.grey.shade700)),
            TextButton(
                onPressed: _taiQuyTrinhVatTu, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    final hsVt = _hoSoVatTu;
    if (hsVt == null || hsVt.chiTiet.isEmpty) {
      return _ScCard(
        child: Text(
          'Chưa có dữ liệu bước/vật tư (có thể không dùng vật tư).',
          style: TextStyle(
              color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      );
    }
    final map = <int, List<ChiTietVatTuSuDung>>{};
    for (final c in hsVt.chiTiet) {
      map.putIfAbsent(c.soBuoc, () => []).add(c);
    }
    final keys = map.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScCard(
          child: Row(
            children: [
              const Icon(Icons.account_tree_rounded,
                  size: 18, color: _scPrimary),
              const SizedBox(width: 8),
              const Text('Quy trình sửa chữa',
                  style:
                  TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const Spacer(),
              Text('${keys.length} bước',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final k in keys)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD)),
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
                        color: _scPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$k',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Text('Bước $k',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
                if (map[k]!.any((e) => e.moTaBuoc.trim().isNotEmpty)) ...[
                  const SizedBox(height: 6),
                  Text(
                    map[k]!
                        .map((e) => e.moTaBuoc.trim())
                        .where((s) => s.isNotEmpty)
                        .toSet()
                        .join(' · '),
                    style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.35,
                        fontSize: 13),
                  ),
                ],
                const SizedBox(height: 6),
                for (final c in map[k]!)
                  if (c.tenVatTu.isNotEmpty && c.soLuong > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 15, color: _scPrimary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('${c.tenVatTu} × ${c.soLuong}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _gradientBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF004E80), Color(0xFF0068A9), Color(0xFF0EA5E9)],
        ),
        boxShadow: [
          BoxShadow(
            color: _scPrimary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(l,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(v,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A))),
        ),
      ],
    ),
  );
}

/// Bước quy trình SC trên chi tiết (đủ mẫu + trạng thái chọn + vật tư NVKT).
class _BuocScQtView {
  final int soBuoc;
  final String moTa;
  final bool daChon;
  final String trangThai;
  final List<_VatTuBuocSc> vatTu;

  const _BuocScQtView({
    required this.soBuoc,
    required this.moTa,
    required this.daChon,
    required this.trangThai,
    this.vatTu = const [],
  });
}

class _VatTuBuocSc {
  final String ten;
  final int soLuong;
  const _VatTuBuocSc({required this.ten, required this.soLuong});
}