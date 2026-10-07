import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/maintenance_plan_logic.dart';
import '../../work_order/data/to_truong_quy_trinh_tao_logic.dart';
import '../../work_order/presentation/widgets/to_truong_chon_quy_trinh_tao.dart';

/// Lập kế hoạch — thiết bị đến hạn / trễ hạn, tạo HS hàng loạt gửi xưởng.
class HangChoBaoTriScreen extends StatefulWidget {
  /// Năm đang xem trên màn kế hoạch (đồng bộ dropdown).
  final int? namBanDau;
  const HangChoBaoTriScreen({super.key, this.namBanDau});

  @override
  State<HangChoBaoTriScreen> createState() => _HangChoBaoTriScreenState();
}

class _HangChoBaoTriScreenState extends State<HangChoBaoTriScreen>
    with SingleTickerProviderStateMixin {
  final _controller = HangChoDenHanController();
  final _qtCtrl = ToTruongQuyTrinhTaoController(loaiCongViec: 'Bảo trì');
  final _noiDungCtrl = TextEditingController(
    text: 'Bảo trì định kỳ theo chu kỳ đề xuất',
  );
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

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
    if (widget.namBanDau != null) {
      _controller.nam = widget.namBanDau!;
    }
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _controller.tai().then((_) {
      if (mounted) _fadeCtrl.forward();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errQt),
        backgroundColor: Colors.red.shade700,
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
        ),
      );
    } else if (_controller.loi != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.loi!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FC),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              _buildHeroHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      if (_controller.loi != null && !_controller.dangTao)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: _LoiBanner(text: _controller.loi!),
                        ),
                      // Quy trình + nội dung — dưới tháng/năm, tách khỏi nút tạo
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                prefixIcon: const Icon(
                                    Icons.notes_rounded,
                                    size: 20),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF0B6BCB), width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _buildDanhSach()),
                      _buildThanhTao(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B6BCB), Color(0xFF0284C7), Color(0xFF0EA5E9)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x400B6BCB),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 18),
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
                      'Lập kế hoạch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _fadeCtrl.reset();
                        _controller.tai().then((_) {
                          if (mounted) _fadeCtrl.forward();
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Thiết bị đến hạn / trễ hạn — chọn máy và tạo hồ sơ gửi xưởng',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: _pillDropdownThang()),
                    const SizedBox(width: 10),
                    Expanded(child: _pillDropdownNam()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillDropdownThang() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _controller.thang,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF0B6BCB)),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          items: List.generate(
            12,
                (i) => DropdownMenuItem(value: i + 1, child: Text(_tenThang[i + 1])),
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

  Widget _pillDropdownNam() {
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF0B6BCB)),
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

  Widget _buildDanhSach() {
    if (_controller.dangTai) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0B6BCB)),
      );
    }
    final list = _controller.danhSach;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0B6BCB).withValues(alpha: 0.15),
                      const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: const Icon(Icons.event_available_rounded,
                    size: 40, color: Color(0xFF0B6BCB)),
              ),
              const SizedBox(height: 16),
              Text(
                'Không có thiết bị đến hạn',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trong ${_tenThang[_controller.thang].toLowerCase()}/${_controller.nam}\n'
                    'chỉ hiện máy đến hạn / trễ hạn và chưa có hồ sơ BT.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B6BCB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${list.length} thiết bị',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: Color(0xFF0B6BCB),
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _controller.chonTatCa,
                icon: Icon(
                  _controller.daChon.length == list.length
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 20,
                  color: const Color(0xFF0B6BCB),
                ),
                label: Text(
                  _controller.daChon.length == list.length
                      ? 'Bỏ chọn'
                      : 'Chọn tất cả',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B6BCB),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = list[i];
              final chon = _controller.daChon.contains(item.maThietBi);
              final mau =
              item.treHan ? const Color(0xFFDC2626) : const Color(0xFFD97706);
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 280 + (i * 40).clamp(0, 240)),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - v)),
                    child: child,
                  ),
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: chon ? 2.5 : 0.8,
                  shadowColor: chon
                      ? const Color(0xFF0B6BCB).withValues(alpha: 0.25)
                      : Colors.black26,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _controller.daoChon(item.maThietBi),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: chon
                              ? const Color(0xFF0B6BCB).withValues(alpha: 0.45)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: chon,
                            onChanged: (_) =>
                                _controller.daoChon(item.maThietBi),
                            activeColor: const Color(0xFF0B6BCB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
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
                                const SizedBox(height: 4),
                                Text(
                                  '${item.loaiThietBi ?? "—"} · Chu kỳ ${item.soThangChuKy} tháng',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hạn: ${_fmt(item.ngayDenHan)}'
                                      '${item.ngayBaoTriGanNhat != null ? ' · Gần nhất: ${_fmt(item.ngayBaoTriGanNhat)}' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThanhTao() {
    final soChon = _controller.daChon.length;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (soChon > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Đã chọn $soChon thiết bị',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: soChon == 0 || _controller.dangTao
                      ? null
                      : const LinearGradient(
                    colors: [Color(0xFF0B6BCB), Color(0xFF0284C7)],
                  ),
                  color: soChon == 0 || _controller.dangTao
                      ? Colors.grey.shade300
                      : null,
                  boxShadow: soChon == 0
                      ? null
                      : [
                    BoxShadow(
                      color: const Color(0xFF0B6BCB)
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _controller.dangTao || soChon == 0
                        ? null
                        : _taoHangLoat,
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
          ],
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