part of approval_screens;

// ============ MÀN 2: CHI TIẾT + PHÊ DUYỆT / TỪ CHỐI ============

class ApprovalBaoTriDetailScreen extends StatefulWidget {
  final int maHoSoBaoTri;
  const ApprovalBaoTriDetailScreen({super.key, required this.maHoSoBaoTri});
  @override
  State<ApprovalBaoTriDetailScreen> createState() => _ApprovalBaoTriDetailScreenState();
}

class _ApprovalBaoTriDetailScreenState extends State<ApprovalBaoTriDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFF0F6FB);
  static const _primary = Color(0xFF0068A9);

  late final ApprovalBaoTriDetailController _controller;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _controller = ApprovalBaoTriDetailController(widget.maHoSoBaoTri);
    _controller.taiChiTiet();
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtThoiGianDuKien(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final v = raw.trim();
    if (v.toLowerCase().endsWith('p')) {
      return '${v.substring(0, v.length - 1)} phút';
    }
    if (v.contains('giờ') || v.contains('phút')) return v;
    return '$v giờ';
  }

  Color _mauTrangThai(String tt) {
    switch (tt) {
      case 'Chờ duyệt':
      case 'Chờ GĐ duyệt':
        return AppColors.warning;
      case 'Đã duyệt':
        return const Color(0xFF0284C7);
      case 'Đang thực hiện':
      case 'Chờ xác nhận':
        return AppColors.primary;
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _duyet() async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận phê duyệt'),
        content:
        const Text('Bạn chắc chắn muốn phê duyệt hồ sơ bảo trì này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Phê duyệt'),
          ),
        ],
      ),
    );
    if (xacNhan != true) return;

    final ok = await _controller.xuLy(quyetDinh: 'Duyệt');
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<void> _tuChoi() async {
    final lyDoController = TextEditingController();
    final lyDo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Từ chối hồ sơ'),
        content: TextField(
          controller: lyDoController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            border: OutlineInputBorder(),
            hintText: 'VD: Nội dung công việc chưa rõ ràng...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, lyDoController.text.trim()),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (lyDo == null || lyDo.isEmpty) return;

    final ok = await _controller.xuLy(quyetDinh: 'Từ chối', lyDo: lyDo);
    if (ok && mounted) Navigator.pop(context, true);
  }

  Widget _headerBar({
    required double top,
    required String title,
    String? subtitle,
  }) =>
      ModernDetailUi.headerBar(
        context: context,
        topPadding: top,
        title: title,
        subtitle: subtitle,
      );

  Widget _softCard({required Widget child}) =>
      ModernDetailUi.softCard(child: child);

  Widget _row(String nhan, String giaTri) =>
      ModernDetailUi.infoRow(nhan, giaTri);

  Widget _fadeSlide({required int delayMs, required Widget child}) =>
      ModernDetailUi.fadeSlide(delayMs: delayMs, child: child);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.dangTai) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: CircularProgressIndicator(color: _primary, strokeWidth: 3),
            ),
          );
        }
        if (_controller.hoSo == null) {
          return Scaffold(
            backgroundColor: _bg,
            body: Column(
              children: [
                _headerBar(top: top, title: 'Chi tiết hồ sơ BT'),
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
                              backgroundColor: _primary),
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

        return Scaffold(
          backgroundColor: _bg,
          body: Column(
            children: [
              _headerBar(
                top: top,
                title: 'Hồ sơ BT #${hs.maHoSoBaoTri}',
                subtitle: hs.trangThai,
              ),
              Expanded(
                child: FadeTransition(
                  opacity:
                  CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      // Hero — đồng bộ ModernDetailUi
                      _fadeSlide(
                        delayMs: 0,
                        child: ModernDetailUi.heroCard(
                          icon: Icons.precision_manufacturing_rounded,
                          title: hs.tenThietBi,
                          statusLabel: hs.trangThai,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Thông tin
                      _fadeSlide(
                        delayMs: 60,
                        child: _softCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 18,
                                      color: _primary.withValues(alpha: 0.95)),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Thông tin hồ sơ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
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
                                      hs.trangThai,
                                      style: TextStyle(
                                        color: mauTt,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _row('Người lập', hs.tenNguoiLap ?? '—'),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row('Ngày tạo', _fmt(hs.ngayTao)),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row(
                                  'Ngày dự kiến BT',
                                  _fmt(hs.ngayDuKienBaoTri)),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row(
                                'Thời gian dự kiến',
                                _fmtThoiGianDuKien(hs.thoiGianDuKien),
                              ),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row('Giờ bắt đầu', hs.gioBatDauDuKien ?? '—'),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row('Giờ kết thúc', hs.gioKetThucDuKien ?? '—'),
                              if (hs.nam > 0) ...[
                                Divider(height: 1, color: Colors.grey.shade200),
                                _row(
                                  'Kế hoạch năm',
                                  '${hs.nam}${hs.namTuKeHoach ? '' : ' (đột xuất)'}',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nội dung CV
                      _fadeSlide(
                        delayMs: 120,
                        child: _softCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.description_outlined,
                                      size: 18, color: _primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Nội dung công việc',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                hs.noiDungCongViec ?? '—',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (hs.lyDoTuChoi != null &&
                          hs.lyDoTuChoi!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _fadeSlide(
                          delayMs: 150,
                          child: _softCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.report_outlined,
                                        size: 18, color: AppColors.danger),
                                    SizedBox(width: 8),
                                    Text(
                                      'Lý do từ chối',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hs.lyDoTuChoi!,
                                  style: const TextStyle(
                                    height: 1.4,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (_controller.loi != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _controller.loi!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // Hành động
                      _fadeSlide(
                        delayMs: 180,
                        child: hs.choDuyet
                            ? (_controller.dangXuLy
                            ? const Center(
                          child: CircularProgressIndicator(
                              color: _primary),
                        )
                            : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(
                                      color: AppColors.danger),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.close_rounded),
                                label: const Text('Từ chối'),
                                onPressed: _tuChoi,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF15803D),
                                      Color(0xFF22C55E),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                    onTap: _duyet,
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Phê duyệt',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                            FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ))
                            : Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: mauTt.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: mauTt.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hs.daHoanThanh
                                    ? Icons.verified_rounded
                                    : hs.biTuChoi
                                    ? Icons.cancel_outlined
                                    : Icons.timeline_rounded,
                                color: mauTt,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  hs.daHoanThanh
                                      ? 'Hồ sơ đã hoàn thành — chỉ theo dõi, không cần duyệt lại.'
                                      : hs.biTuChoi
                                      ? 'Hồ sơ đã từ chối — chỉ xem lại.'
                                      : 'Hồ sơ đang ở trạng thái «${hs.trangThai}» — theo dõi tiến độ.',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade800,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
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