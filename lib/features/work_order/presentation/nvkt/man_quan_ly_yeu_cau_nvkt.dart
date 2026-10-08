part of technician_screens;

// ============ QUẢN LÝ YÊU CẦU (NVKT) ============

class QuanLyYeuCauScreen extends StatefulWidget {
  const QuanLyYeuCauScreen({super.key});

  @override
  State<QuanLyYeuCauScreen> createState() => _QuanLyYeuCauScreenState();
}

class _QuanLyYeuCauScreenState extends State<QuanLyYeuCauScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = QuanLyYeuCauController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _ctrl.doiTab(_tabCtrl.index == 0 ? 'Bảo trì' : 'Sửa chữa');
      }
    });
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _moChiTiet(YeuCauPhanCong y) async {
    final changed = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => ChiTietYeuCauScreen(yeuCau: y),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
    if (changed == true) _ctrl.tai();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0068A9), Color(0xFF004E80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Công việc của tôi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Xem chi tiết và hoàn thành khi xong việc — không cần xác nhận nhận việc',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Bảo trì'),
                    Tab(text: 'Sửa chữa'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _ctrl.dangTai
                ? const Center(child: CircularProgressIndicator())
                : _ctrl.loi != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.danger.withValues(alpha: 0.7)),
                    const SizedBox(height: 12),
                    Text(_ctrl.loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _ctrl.tai,
                        child: const Text('Thử lại')),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _ctrl.tai,
              color: AppColors.primary,
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final canLam = _ctrl.canThucHien;
    final hoTro = _ctrl.chiXemHoTro;
    final choXn = _ctrl.choXacNhanKetQua;
    final xong = _ctrl.daHoanThanh;
    final huy = _ctrl.danhSach
        .where((e) =>
    e.daHuy && !e.choXacNhanKetQua && !e.daHoanThanhPc && !e.canThucHien)
        .toList();

    if (canLam.isEmpty &&
        hoTro.isEmpty &&
        choXn.isEmpty &&
        xong.isEmpty &&
        huy.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Chưa có yêu cầu ${_ctrl.tabLoai.toLowerCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (canLam.isNotEmpty) ...[
          _sectionHeader('Cần thực hiện', canLam.length, const Color(0xFFD97706)),
          const SizedBox(height: 10),
          ...canLam.asMap().entries.map((e) => _YeuCauCard(
            yeuCau: e.value,
            index: e.key,
            onTap: () => _moChiTiet(e.value),
          )),
          const SizedBox(height: 18),
        ],
        // NV hỗ trợ (không ghi chép): vẫn thấy yêu cầu, chỉ không có nút Tiến hành
        if (hoTro.isNotEmpty) ...[
          _sectionHeader(
              'Được phân công (hỗ trợ)', hoTro.length, Colors.blueGrey),
          const SizedBox(height: 10),
          ...hoTro.asMap().entries.map((e) => _YeuCauCard(
            yeuCau: e.value,
            index: e.key,
            onTap: () => _moChiTiet(e.value),
          )),
          const SizedBox(height: 18),
        ],
        if (choXn.isNotEmpty) ...[
          _sectionHeader('Chờ xác nhận', choXn.length, const Color(0xFF0284C7)),
          const SizedBox(height: 10),
          ...choXn.asMap().entries.map((e) => _YeuCauCard(
            yeuCau: e.value,
            index: e.key,
            onTap: () => _moChiTiet(e.value),
          )),
          const SizedBox(height: 18),
        ],
        if (xong.isNotEmpty) ...[
          _sectionHeader('Xác nhận', xong.length, AppColors.success),
          const SizedBox(height: 10),
          ...xong.asMap().entries.map((e) => _YeuCauCard(
            yeuCau: e.value,
            index: e.key,
            onTap: () => _moChiTiet(e.value),
          )),
          const SizedBox(height: 18),
        ],
        if (huy.isNotEmpty) ...[
          _sectionHeader('Từ chối / đã hủy', huy.length, Colors.grey),
          const SizedBox(height: 10),
          ...huy.asMap().entries.map((e) => _YeuCauCard(
            yeuCau: e.value,
            index: e.key,
            onTap: () => _moChiTiet(e.value),
          )),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _YeuCauCard extends StatelessWidget {
  final YeuCauPhanCong yeuCau;
  final int index;
  final VoidCallback onTap;

  const _YeuCauCard({
    required this.yeuCau,
    required this.index,
    required this.onTap,
  });

  Color _statusColorFor(YeuCauPhanCong y) {
    if (y.daHoanThanhPc) return AppColors.success;
    if (y.daHuy || y.biTuChoi) return AppColors.danger;
    if (y.choXacNhanKetQua) return const Color(0xFF0284C7); // xanh dương — chờ Xưởng
    if (y.canThucHien) return const Color(0xFFD97706); // cam — cần làm
    switch (y.trangThaiPhanCong) {
      case 'Đang thực hiện':
        return AppColors.primary;
      case 'Hoàn thành':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(YeuCauPhanCong y) {
    // Xưởng đã xác nhận → yêu cầu công việc của NVKT coi như đã xong
    if (y.daHoanThanhPc) return 'Xác nhận';
    if (y.daHuy) return 'Đã hủy';
    if (y.choXacNhanKetQua) return 'Chờ xác nhận';
    if (y.biTuChoi) return 'Từ chối';
    if (y.canThucHien) return 'Cần làm';
    return y.trangThaiPhanCong;
  }

  @override
  Widget build(BuildContext context) {
    final c = _statusColorFor(yeuCau);
    final label = _statusLabel(yeuCau);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 35),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          yeuCau.laBaoTri
                              ? Icons.precision_manufacturing_rounded
                              : Icons.handyman_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              yeuCau.tenThietBi ??
                                  'Thiết bị #${yeuCau.maThietBi ?? '—'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${yeuCau.loai} · HS #${yeuCau.maHoSo ?? '—'}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: c,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (yeuCau.noiDung != null && yeuCau.noiDung!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      yeuCau.noiDung!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          yeuCau.tenNhanVienPhanCong ?? '—',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (yeuCau.ngayDuKienBaoTri != null) ...[
                        Icon(Icons.event_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _fmt(yeuCau.ngayDuKienBaoTri!),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ] else ...[
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _fmt(yeuCau.ngayPhanCong),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded,
                          size: 20, color: Colors.grey.shade400),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}