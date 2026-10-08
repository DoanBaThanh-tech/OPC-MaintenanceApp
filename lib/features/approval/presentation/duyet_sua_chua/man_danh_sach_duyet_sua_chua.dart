part of approval_screens;

class ApprovalSuaChuaListScreen extends StatefulWidget {
  const ApprovalSuaChuaListScreen({super.key});

  @override
  State<ApprovalSuaChuaListScreen> createState() =>
      _ApprovalSuaChuaListScreenState();
}

class _ApprovalSuaChuaListScreenState extends State<ApprovalSuaChuaListScreen>
    with TickerProviderStateMixin {
  List<HoSoSuaChua> _list = [];
  bool _dangTai = true;
  String? _loi;
  late TabController _tab;
  late AnimationController _headerAnim;

  final _tabs = const [
    'Tất cả',
    'Chờ duyệt',
    'Đang thực hiện',
    'Đã hoàn thành',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _tai();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final all = await WorkOrderService.layDanhSachHoSoSuaChua();
      final list = all
          .where((h) =>
      h.trangThai == 'Chờ duyệt' ||
          h.trangThai == 'Đã duyệt' ||
          h.trangThai == 'Đang thực hiện' ||
          h.trangThai == 'Chờ xác nhận' ||
          h.trangThai == 'Đã hoàn thành' ||
          h.trangThai == 'Từ chối')
          .toList()
        ..sort((a, b) {
          int rank(String tt) {
            switch (tt) {
              case 'Chờ duyệt':
                return 0;
              case 'Đang thực hiện':
              case 'Chờ xác nhận':
                return 1;
              case 'Đã duyệt':
                return 2;
              case 'Đã hoàn thành':
                return 3;
              case 'Từ chối':
                return 4;
              default:
                return 5;
            }
          }

          final r = rank(a.trangThai).compareTo(rank(b.trangThai));
          if (r != 0) return r;
          return b.ngayTao.compareTo(a.ngayTao);
        });
      if (!mounted) return;
      setState(() {
        _list = list;
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e is ApiException ? e.message : '$e';
        _dangTai = false;
        _list = [];
      });
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  List<HoSoSuaChua> _locTab(String tab) {
    switch (tab) {
      case 'Chờ duyệt':
        return _list.where((h) => h.trangThai == 'Chờ duyệt').toList();
      case 'Đang thực hiện':
        return _list
            .where((h) =>
        h.trangThai == 'Đang thực hiện' ||
            h.trangThai == 'Chờ xác nhận')
            .toList();
      case 'Đã hoàn thành':
        return _list.where((h) => h.trangThai == 'Đã hoàn thành').toList();
      default:
        return _list;
    }
  }

  Color _mau(String tt) => _GdUi.mauTrangThai(tt);

  IconData _icon(String tt) {
    switch (tt) {
      case 'Đã duyệt':
        return Icons.verified_outlined;
      case 'Đang thực hiện':
      case 'Chờ xác nhận':
        return Icons.engineering_outlined;
      case 'Đã hoàn thành':
        return Icons.task_alt_rounded;
      case 'Từ chối':
        return Icons.cancel_outlined;
      case 'Chờ duyệt':
        return Icons.schedule_rounded;
      default:
        return Icons.handyman_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: Column(
        children: [
          FadeTransition(
            opacity: _headerAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.12),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOutCubic)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12, top + 10, 12, 0),
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
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0068A9).withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: const Icon(Icons.handyman_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Duyệt hồ sơ sửa chữa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _dangTai
                                    ? 'Đang tải…'
                                    : '${_list.length} hồ sơ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _tai,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tabs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final selected = _tab.index == i;
                          final count = _locTab(_tabs[i]).length;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _tab.animateTo(i));
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.25),
                                ),
                                boxShadow: selected
                                    ? [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _tabs[i],
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF0369A1)
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF0EA5E9)
                                          .withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFF0369A1)
                                            : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_dangTai) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                  color: Color(0xFF0068A9), strokeWidth: 3),
            ),
            SizedBox(height: 14),
            Text('Đang tải hồ sơ…',
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (_loi != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loi!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _tai,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0068A9)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tab,
      children: _tabs.map((tab) {
        final list = _locTab(tab);
        if (list.isEmpty) {
          return RefreshIndicator(
            color: const Color(0xFF0068A9),
            onRefresh: _tai,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) => Transform.scale(
                    scale: 0.7 + 0.3 * t,
                    child: Opacity(opacity: t, child: child),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE8F4FC),
                              const Color(0xFF0068A9).withValues(alpha: 0.12),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handyman_outlined,
                            size: 48, color: Color(0xFF0068A9)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có hồ sơ · $tab',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF0068A9),
          onRefresh: _tai,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final hs = list[i];
              final mau = _mau(hs.trangThai);
              return _GdHsCard(
                index: i,
                tenThietBi: hs.tenThietBi,
                maHoSo: hs.maHoSoSuaChua,
                ngayTao: _fmt(hs.ngayTao),
                ngayDuKien: null,
                noiDung: hs.moTaHuHong,
                subLine: 'Người lập: ${hs.tenNhanVienTao ?? '—'}',
                trangThai: hs.trangThai,
                mau: mau,
                icon: _icon(hs.trangThai),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 320),
                      pageBuilder: (_, a, __) =>
                          ChiTietHoSoSuaChuaScreen(maHoSo: hs.maHoSoSuaChua),
                      transitionsBuilder: (_, a, __, child) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: a, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      ),
                    ),
                  );
                  _tai();
                },
              );
            },
          ),
        );
      }).toList(),
    );
  }
}