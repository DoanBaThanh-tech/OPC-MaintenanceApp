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
    _ctrl.tai().then((_) {
      final hs = _ctrl.hoSo;
      // Xưởng: xem quy trình khi Đang thực hiện / chờ duyệt / đã xong
      // Tổ trưởng & vai trò khác: chỉ khi Đã hoàn thành
      if (hs != null &&
          (hs.daHoanThanh ||
              (_laXuong &&
                  (hs.choXacNhanKetQua || hs.dangThucHien)))) {
        _taiQuyTrinhVatTu();
      }
    });
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

  Future<void> _load() => _ctrl.tai();

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
                        ],
                      ),
                    ),
                  ),
                  if (hs.daCoPhanCong &&
                      hs.tenNhanVienThucHiens != null &&
                      hs.tenNhanVienThucHiens!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ModernDetailUi.fadeSlide(
                      delayMs: 120,
                      child: ModernDetailUi.softCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.groups_rounded,
                                    color: ModernDetailUi.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                    hs.daHoanThanh
                                        ? 'Nhân viên đã đảm nhận'
                                        : 'Nhân viên đang được phân công',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(hs.tenNhanVienThucHiens!,
                                style: TextStyle(
                                    height: 1.45,
                                    color: Colors.grey.shade800)),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                  // Xưởng: quy trình ở Đang thực hiện + Đã hoàn thành
                  if (_laXuong &&
                      (hs.choXacNhanKetQua ||
                          hs.dangThucHien ||
                          hs.daHoanThanh)) ...[
                    const SizedBox(height: 16),
                    _buildXuongQuyTrinhVaDuyetSc(hs),
                  ]
                  // Tổ trưởng / vai trò khác: chỉ xem quy trình khi Đã hoàn thành
                  else if (!_laXuong && hs.daHoanThanh) ...[
                    const SizedBox(height: 16),
                    _buildQuyTrinhChiXemKhiHoanThanhSc(hs),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuyTrinhChiXemKhiHoanThanhSc(HoSoSuaChua hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border:
            Border.all(color: AppColors.success.withValues(alpha: 0.35)),
          ),
          child: const Text(
            'Xưởng đã xác nhận — hồ sơ Đã hoàn thành. Quy trình / vật tư bên dưới (chỉ xem).',
            style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
          ),
        ),
        const SizedBox(height: 12),
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
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.45)),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildQuyTrinhSuaChua(),
      ],
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
    final nhanTt = _nhanTtQuyTrinhSc(hs);
    final mauTt = _mauTtQuyTrinhSc(nhanTt);
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
              'NVKT đã gửi kết quả quy trình sửa chữa. Kiểm tra bước/vật tư rồi Xác nhận (→ Đã hoàn thành) hoặc Từ chối (quy trình giữ nguyên, vẫn Đang thực hiện).',
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
        _buildQuyTrinhSuaChua(),
        if (choDuyet) ...[
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