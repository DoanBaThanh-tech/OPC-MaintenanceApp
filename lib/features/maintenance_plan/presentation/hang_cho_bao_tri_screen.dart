import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../data/maintenance_plan_logic.dart';
import '../../work_order/data/to_truong_quy_trinh_tao_logic.dart';
import '../../work_order/presentation/widgets/to_truong_chon_quy_trinh_tao.dart';
import '../../dashboard/data/dashboard_logic.dart';

/// Lập bảo trì nhanh — thiết bị đến hạn / trễ hạn, tạo HS hàng loạt.
class HangChoBaoTriScreen extends StatefulWidget {
  final int? namBanDau;
  const HangChoBaoTriScreen({super.key, this.namBanDau});

  @override
  State<HangChoBaoTriScreen> createState() => _HangChoBaoTriScreenState();
}

class _HangChoBaoTriScreenState extends State<HangChoBaoTriScreen>
    with TickerProviderStateMixin {
  static const _blue = Color(0xFF0B6BCB);
  static const _sky = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF0F7FC);

  final _controller = HangChoDenHanController();
  final _qtCtrl = ToTruongQuyTrinhTaoController(loaiCongViec: 'Bảo trì');
  final _noiDungCtrl = TextEditingController(
    text: 'Bảo trì định kỳ theo chu kỳ đề xuất',
  );
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  bool _moCauHinh = true;

  static const _tenThang = [
    '',
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.namBanDau != null) _controller.nam = widget.namBanDau!;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _controller.tai().then((_) {
      if (mounted) _fadeCtrl.forward();
    });
    _qtCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _noiDungCtrl.dispose();
    _qtCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _taoHangLoat() async {
    final errQt = _qtCtrl.validate();
    if (errQt != null) {
      setState(() => _moCauHinh = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errQt),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_noiDungCtrl.text.trim().isEmpty) {
      setState(() => _moCauHinh = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Vui lòng nhập nội dung công việc'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final ok = await _controller.taoHangLoat(
      _noiDungCtrl.text,
      danhSachBuoc: _qtCtrl.payloadBuoc(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.thongBao ??
                'Đã tạo hồ sơ bảo trì và gửi xưởng (Chờ duyệt).',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Về Dashboard (còn slide menu) rồi mở mục Hồ sơ bảo trì
      Navigator.of(context).popUntil((route) => route.isFirst);
      DashboardLogic.moMenuTheoNhan('Hồ sơ bảo trì');
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
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final soChon = _controller.daChon.length;
          return Column(
            children: [
              // ===== Header gọn =====
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(8, top + 4, 12, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004E80), _blue, _sky],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(22)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x400B6BCB),
                      blurRadius: 16,
                      offset: Offset(0, 6),
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
                            'Lập bảo trì nhanh',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _fadeCtrl.reset();
                              _controller.tai().then((_) {
                                if (mounted) _fadeCtrl.forward();
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Text(
                        'Chọn tháng · cấu hình quy trình · tích thiết bị · tạo hồ sơ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(child: _pillThang()),
                          const SizedBox(width: 10),
                          Expanded(child: _pillNam()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ===== Nội dung cuộn chung (form + danh sách) =====
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      if (_controller.loi != null && !_controller.dangTao)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            child: _LoiBanner(text: _controller.loi!),
                          ),
                        ),

                      // Card cấu hình (có thể thu gọn)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                          child: _buildCardCauHinh(),
                        ),
                      ),

                      // Tiêu đề danh sách
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Chọn thiết bị',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              if (!_controller.dangTai &&
                                  _controller.danhSach.isNotEmpty) ...[
                                Text(
                                  '${_controller.danhSach.length} máy',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    _controller.chonTatCa();
                                  },
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: _blue,
                                  ),
                                  child: Text(
                                    soChon == _controller.danhSach.length
                                        ? 'Bỏ chọn'
                                        : 'Chọn tất cả',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Danh sách thiết bị
                      ..._sliverDanhSach(),

                      // Đệm dưới cho thanh tạo
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ),

              // ===== Thanh tạo cố định =====
              _buildThanhTao(soChon),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardCauHinh() {
    final daChonQt = _qtCtrl.dangChon != null;
    final soBuoc = _qtCtrl.daTich.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _blue.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header thu/mở
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _moCauHinh = !_moCauHinh);
              },
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient:
                        const LinearGradient(colors: [_blue, _sky]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cấu hình tạo hồ sơ',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 14.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            daChonQt
                                ? '${_qtCtrl.dangChon!.nhan} · $soBuoc bước'
                                : 'Chưa chọn quy trình',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: daChonQt
                                  ? _blue
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _moCauHinh ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.expand_more_rounded,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ToTruongChonQuyTrinhTao(
                    loaiCongViec: 'Bảo trì',
                    controller: _qtCtrl,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noiDungCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Nội dung công việc',
                      hintText: 'Mô tả bảo trì định kỳ...',
                      prefixIcon:
                      const Icon(Icons.notes_rounded, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FBFE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                        const BorderSide(color: _blue, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _moCauHinh
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  List<Widget> _sliverDanhSach() {
    if (_controller.dangTai) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: _blue),
          ),
        ),
      ];
    }
    final list = _controller.danhSach;
    if (list.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _blue.withValues(alpha: 0.15),
                          _sky.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.event_available_rounded,
                        size: 36, color: _blue),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Không có thiết bị đến hạn',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Trong ${_tenThang[_controller.thang].toLowerCase()}/${_controller.nam}\n'
                        'chỉ hiện máy đến hạn / trễ hạn chưa có hồ sơ BT.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final item = list[index];
              final chon = _controller.daChon.contains(item.maThietBi);
              final tre = item.trangThaiHan == 'Trễ hạn';
              final mau = tre ? const Color(0xFFDC2626) : const Color(0xFFD97706);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 280 + (index % 8) * 40),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - t)),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: chon ? 2 : 0,
                    shadowColor: _blue.withValues(alpha: 0.2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _controller.daoChon(item.maThietBi);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: chon
                                ? _blue.withValues(alpha: 0.5)
                                : Colors.grey.shade200,
                            width: chon ? 1.6 : 1,
                          ),
                          color: chon
                              ? _blue.withValues(alpha: 0.04)
                              : Colors.white,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: chon ? _blue : Colors.transparent,
                                border: Border.all(
                                  color: chon ? _blue : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: chon
                                  ? const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.tenThietBi,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.loaiThietBi ?? "—"} · Chu kỳ ${item.soThangChuKy} tháng',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Hạn: ${_fmt(item.ngayDenHan)}'
                                        '${item.ngayBaoTriGanNhat != null ? ' · Gần nhất: ${_fmt(item.ngayBaoTriGanNhat)}' : ''}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: mau.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.trangThaiHan,
                                style: TextStyle(
                                  color: mau,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: list.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildThanhTao(int soChon) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: soChon == 0 || _controller.dangTao
                  ? null
                  : const LinearGradient(colors: [_blue, Color(0xFF0284C7)]),
              color: soChon == 0 || _controller.dangTao
                  ? Colors.grey.shade300
                  : null,
              boxShadow: soChon == 0
                  ? null
                  : [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _controller.dangTao || soChon == 0 ? null : _taoHangLoat,
                child: Center(
                  child: _controller.dangTao
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_add_check_rounded,
                        color: soChon == 0
                            ? Colors.grey.shade600
                            : Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        soChon == 0
                            ? 'Chọn thiết bị để tạo hồ sơ'
                            : 'Tạo $soChon hồ sơ bảo trì',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: soChon == 0
                              ? Colors.grey.shade600
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillThang() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _controller.thang,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: _blue),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          items: List.generate(
            12,
                (i) =>
                DropdownMenuItem(value: i + 1, child: Text(_tenThang[i + 1])),
          ),
          onChanged: (v) {
            if (v != null) {
              _fadeCtrl.reset();
              _controller.doiThangNam(_controller.nam, v);
              _fadeCtrl.forward();
            }
          },
        ),
      ),
    );
  }

  Widget _pillNam() {
    final nams = _controller.danhSachNam.isEmpty
        ? <int>[_controller.nam]
        : _controller.danhSachNam;
    final value = nams.contains(_controller.nam) ? _controller.nam : nams.last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: _blue),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          items: nams
              .map((y) => DropdownMenuItem(value: y, child: Text('Năm $y')))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              _fadeCtrl.reset();
              _controller.doiThangNam(v, _controller.thang);
              _fadeCtrl.forward();
            }
          },
        ),
      ),
    );
  }
}

class _LoiBanner extends StatelessWidget {
  final String text;
  const _LoiBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB91C1C),
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }
}