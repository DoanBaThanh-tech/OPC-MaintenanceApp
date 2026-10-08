part of maintenance_plan_screens;

// ============ MÀN 1: LỊCH 12 THÁNG (dạng cuốn lịch) ============

class MaintenancePlanListScreen extends StatefulWidget {
  const MaintenancePlanListScreen({super.key});
  @override
  State<MaintenancePlanListScreen> createState() => _MaintenancePlanListScreenState();
}

class _MaintenancePlanListScreenState extends State<MaintenancePlanListScreen>
    with SingleTickerProviderStateMixin {
  final _controller = MaintenancePlanListController();
  late final AnimationController _fabAnim;
  bool _fabMo = false;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _controller.taiDanhSach();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _doiFab() {
    setState(() => _fabMo = !_fabMo);
    if (_fabMo) {
      _fabAnim.forward();
    } else {
      _fabAnim.reverse();
    }
  }

  Future<void> _moThuCong() async {
    if (_fabMo) _doiFab();
    final ok = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const TaoHoSoBaoTriThuCongScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
    if (ok == true && mounted) _controller.taiDanhSach();
  }


  Widget _buildSpeedDial() {
    final items = <Map<String, dynamic>>[
      {
        'icon': Icons.playlist_add_check_rounded,
        'label': 'Lập nhanh',
        'color': const Color(0xFF0B6BCB),
        'onTap': () async {
          if (_fabMo) _doiFab();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  HangChoBaoTriScreen(namBanDau: _controller.namDangChon),
            ),
          );
          if (mounted) _controller.taiDanhSach();
        },
      },
      {
        'icon': Icons.handyman_rounded,
        'label': 'Thủ công',
        'color': const Color(0xFF0284C7),
        'onTap': _moThuCong,
      },
      {
        'icon': Icons.calendar_month_rounded,
        'label': 'Theo năm',
        'color': const Color(0xFF059669),
        'onTap': () async {
          if (_fabMo) _doiFab();
          final namMoi = await showDialogLapKeHoachNam(
            context,
            namDaCo: List<int>.from(_controller.danhSachNam),
          );
          if (namMoi != null && mounted) {
            await _controller.sauKhiTaoNam(namMoi);
          }
        },
      },
    ];

    const radius = 100.0;

    return SizedBox(
      width: 210,
      height: 210,
      child: AnimatedBuilder(
        animation: _fabAnim,
        builder: (_, __) {
          final tAnim =
          Curves.easeOutBack.transform(_fabAnim.value.clamp(0.0, 1.0));
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < items.length; i++)
                Builder(builder: (context) {
                  final ang = (-math.pi / 2) - (i * (math.pi / 4));
                  final x = radius * tAnim * math.cos(ang);
                  final y = radius * tAnim * math.sin(ang);
                  final color = items[i]['color'] as Color;
                  return Positioned(
                    right: 6 - x,
                    bottom: 6 - y,
                    child: Opacity(
                      opacity: tAnim.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.5 + 0.5 * tAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: color,
                              shape: const CircleBorder(),
                              elevation: 6,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: items[i]['onTap'] as VoidCallback,
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: Icon(items[i]['icon'] as IconData,
                                      color: Colors.white, size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                items[i]['label'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _doiFab,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _fabMo
                            ? [
                          const Color(0xFF64748B),
                          const Color(0xFF475569)
                        ]
                            : [
                          const Color(0xFF0B6BCB),
                          const Color(0xFF0284C7)
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          const Color(0xFF0B6BCB).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AnimatedRotation(
                      turns: _fabMo ? 0.125 : 0,
                      duration: const Duration(milliseconds: 280),
                      child: Icon(
                        _fabMo ? Icons.close_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _moMenuTaoKeHoach() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Lập kế hoạch', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _MenuOption(
                icon: Icons.playlist_add_check_rounded,
                color: AppColors.primary,
                title: 'Lập kế hoạch',
                subtitle: 'Thiết bị đến hạn / trễ hạn — tạo hồ sơ gửi xưởng',
                onTap: () => Navigator.pop(ctx, 'hangCho'),
              ),
              const SizedBox(height: 10),
              _MenuOption(
                icon: Icons.calendar_month_rounded,
                color: AppColors.success,
                title: 'Lập kế hoạch theo năm',
                subtitle: 'Tạo khung kế hoạch trống cho 1 năm mới',
                onTap: () => Navigator.pop(ctx, 'namMoi'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action == 'namMoi') {
      // Dialog nhỏ — không mở full page (tiết kiệm giao diện / dung lượng)
      final namMoi = await showDialogLapKeHoachNam(
        context,
        namDaCo: List<int>.from(_controller.danhSachNam),
      );
      if (namMoi != null && mounted) {
        await _controller.sauKhiTaoNam(namMoi);
      }
    } else if (action == 'hangCho') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HangChoBaoTriScreen(namBanDau: _controller.namDangChon),
        ),
      );
      if (mounted) await _controller.taiDanhSach();
    }
  }

  void _moChiTietThang(int thang) {
    final mucs = _controller.mucTrongThang(thang);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceMonthDetailScreen(
          nam: _controller.namDangChon,
          thang: thang,
          mucBanDau: mucs,
        ),
      ),
    ).then((_) {
      _controller.taiDanhSach();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FC),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildSpeedDial(),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0B6BCB)),
            );
          }
          if (_controller.loi != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(_controller.loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _controller.taiDanhSach,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final nam = _controller.namDangChon;
          final nams = _controller.danhSachNam;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0B6BCB),
                        Color(0xFF0284C7),
                        Color(0xFF0EA5E9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B6BCB).withValues(alpha: 0.35),
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
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kế hoạch bảo trì',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Lịch 12 tháng · chạm tháng để xem chi tiết',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: nams.contains(nam)
                                    ? nam
                                    : (nams.isEmpty ? nam : nams.last),
                                icon: const Icon(
                                  Icons.expand_more_rounded,
                                  color: Color(0xFF0B6BCB),
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                items: nams
                                    .map(
                                      (n) => DropdownMenuItem(
                                    value: n,
                                    child: Text('$n'),
                                  ),
                                )
                                    .toList(),
                                onChanged: (n) {
                                  if (n != null) _controller.doiNam(n);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _StatChip(
                            label: 'Năm KH',
                            value: '${nams.length}',
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'Đang xem',
                            value: '$nam',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final thang = index + 1;
                      final mucs = _controller.mucTrongThang(thang);
                      final isCurrent = thang == DateTime.now().month &&
                          _controller.namDangChon == DateTime.now().year;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(
                          milliseconds: 260 + (index * 35).clamp(0, 280),
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, child) => Opacity(
                          opacity: v,
                          child: Transform.scale(
                            scale: 0.92 + 0.08 * v,
                            child: child,
                          ),
                        ),
                        child: _OThangLich(
                          thang: thang,
                          mucs: mucs,
                          isCurrent: isCurrent,
                          onTap: () => _moChiTietThang(thang),
                        ),
                      );
                    },
                    childCount: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}