part of xuong_quy_trinh_screen;

class XuongQuyTrinhScreen extends StatefulWidget {
  const XuongQuyTrinhScreen({super.key});

  @override
  State<XuongQuyTrinhScreen> createState() => _XuongQuyTrinhScreenState();
}

class _XuongQuyTrinhScreenState extends State<XuongQuyTrinhScreen>
    with TickerProviderStateMixin {
  static const _blue = Color(0xFF0068A9);
  static const _blueMid = Color(0xFF0284C7);
  static const _blueSoft = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF0F7FC);

  final _ctrl = XuongQuyTrinhController();
  late final TabController _tab;
  late final AnimationController _headerAnim;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _ctrl.doiTab(_tab.index);
    });
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _tab.dispose();
    _headerAnim.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final nBt = _ctrl.dsBaoTri.length;
    final nSc = _ctrl.dsSuaChua.length;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          FadeTransition(
            opacity:
            CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.12),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOutCubic)),
              child: Container(
                width: double.infinity,
                // Không nút back: trang mở trong body Dashboard (slide menu),
                // pop() sẽ thoát luôn shell → màn hình đen.
                padding: EdgeInsets.fromLTRB(20, top + 12, 16, 0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_blue, _blueMid, _blueSoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Quy trình',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${nBt + nSc} chờ duyệt',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 8, 8),
                      child: Text(
                        'Quy trình NVKT đã gửi — Xác nhận hoặc Từ chối',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TabBar(
                      controller: _tab,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor:
                      Colors.white.withValues(alpha: 0.65),
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14.5),
                      tabs: [
                        Tab(text: 'Bảo trì ($nBt)'),
                        Tab(text: 'Sửa chữa ($nSc)'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _ctrl.dangTai
                ? const Center(
              child: CircularProgressIndicator(color: _blue),
            )
                : _ctrl.loi != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_ctrl.loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _ctrl.tai,
                      style: FilledButton.styleFrom(
                          backgroundColor: _blue),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
                : TabBarView(
              controller: _tab,
              children: [
                _buildListBt(),
                _buildListSc(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListBt() {
    final list = _ctrl.dsBaoTri;
    if (list.isEmpty) return _empty('Chưa có quy trình bảo trì chờ xác nhận');
    return RefreshIndicator(
      onRefresh: _ctrl.tai,
      color: _blue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final hs = list[i];
          return _card(
            index: i,
            title: hs.tenThietBi.isNotEmpty
                ? hs.tenThietBi
                : 'HS #${hs.maHoSoBaoTri}',
            subtitle: 'Hồ sơ #${hs.maHoSoBaoTri}',
            ngay: hs.ngayTao,
            icon: Icons.precision_manufacturing_rounded,
            onTap: () => _moChiTiet(
              laBaoTri: true,
              maHoSo: hs.maHoSoBaoTri,
              maThietBi: hs.maThietBi,
              tenThietBi: hs.tenThietBi,
              noiDung: hs.noiDungCongViec,
            ),
          );
        },
      ),
    );
  }

  Widget _buildListSc() {
    final list = _ctrl.dsSuaChua;
    if (list.isEmpty) return _empty('Chưa có quy trình sửa chữa chờ xác nhận');
    return RefreshIndicator(
      onRefresh: _ctrl.tai,
      color: _blue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final hs = list[i];
          return _card(
            index: i,
            title: hs.tenThietBi.isNotEmpty
                ? hs.tenThietBi
                : 'HS #${hs.maHoSoSuaChua}',
            subtitle: 'Hồ sơ SC #${hs.maHoSoSuaChua}',
            ngay: hs.ngayTao,
            icon: Icons.handyman_rounded,
            onTap: () => _moChiTiet(
              laBaoTri: false,
              maHoSo: hs.maHoSoSuaChua,
              maThietBi: hs.maThietBi,
              tenThietBi: hs.tenThietBi,
              noiDung: hs.moTaHuHong,
            ),
          );
        },
      ),
    );
  }

  Widget _empty(String msg) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: _ctrl.tai,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Làm mới'),
          ),
        ),
      ],
    );
  }

  Widget _card({
    required int index,
    required String title,
    required String subtitle,
    required DateTime ngay,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0F2FE)),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_blue, _blueSoft],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$subtitle · ${_fmt(ngay)}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12.5),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Chờ xác nhận',
                            style: TextStyle(
                              color: Color(0xFF0284C7),
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
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
      ),
    );
  }

  Future<void> _moChiTiet({
    required bool laBaoTri,
    required int maHoSo,
    required int maThietBi,
    required String tenThietBi,
    String? noiDung,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => XuongQuyTrinhChiTietScreen(
          laBaoTri: laBaoTri,
          maHoSo: maHoSo,
          maThietBi: maThietBi,
          tenThietBi: tenThietBi,
          noiDungHoSo: noiDung,
          controller: _ctrl,
        ),
      ),
    );
    if (changed == true) await _ctrl.tai();
  }
}