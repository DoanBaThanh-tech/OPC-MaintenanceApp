import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/approval_logic.dart';
import '../../work_order/data/services/work_order_service.dart';
import '../../work_order/data/models/work_order_models.dart';
import '../../work_order/presentation/work_order_repair_screens.dart';

// ============ MÀN 1: DANH SÁCH HỒ SƠ BẢO TRÌ CHỜ DUYỆT ============

class ApprovalBaoTriListScreen extends StatefulWidget {
  const ApprovalBaoTriListScreen({super.key});
  @override
  State<ApprovalBaoTriListScreen> createState() => _ApprovalBaoTriListScreenState();
}

class _ApprovalBaoTriListScreenState extends State<ApprovalBaoTriListScreen> {
  final _controller = ApprovalBaoTriListController();

  @override
  void initState() {
    super.initState();
    _controller.taiDanhSachChoDuyet();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt hồ sơ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0068A9), Color(0xFF0284C7), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final namHienTai = _controller.namLoc;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PopupMenuButton<int>(
                  tooltip: 'Lọc theo năm',
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    // -1 = Tất cả năm
                    _controller.datNamLoc(value == -1 ? null : value);
                  },
                  itemBuilder: (context) {
                    final nams = _controller.cacNamCoDuLieu;
                    return [
                      // ===== Tất cả năm =====
                      PopupMenuItem<int>(
                        value: -1,
                        child: Row(
                          children: [
                            Icon(
                              Icons.all_inclusive_rounded,
                              size: 18,
                              color: namHienTai == null ? AppColors.primary : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Tất cả năm',
                              style: TextStyle(
                                fontWeight: namHienTai == null ? FontWeight.w700 : FontWeight.w500,
                                color: namHienTai == null ? AppColors.primary : null,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ===== Các năm thực sự có dữ liệu =====
                      if (nams.isEmpty)
                        const PopupMenuItem(
                          enabled: false,
                          child: Text('Chưa có hồ sơ nào', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ...nams.map((n) {
                          final dangChon = namHienTai == n;
                          return PopupMenuItem<int>(
                            value: n,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: dangChon ? AppColors.primary : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Năm $n',
                                  style: TextStyle(
                                    fontWeight: dangChon ? FontWeight.w700 : FontWeight.w500,
                                    color: dangChon ? AppColors.primary : null,
                                  ),
                                ),
                                if (dangChon) ...[
                                  const Spacer(),
                                  Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
                                ],
                              ],
                            ),
                          );
                        }),
                    ];
                  },
                  // Nút lọc đẹp
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          namHienTai == null ? 'Tất cả năm' : 'Năm $namHienTai',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (namHienTai != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) return const Center(child: CircularProgressIndicator());
          if (_controller.loi != null) return Center(child: Text(_controller.loi!));
          final list = _controller.danhSach;
          if (list.isEmpty) {
            return Center(
              child: Text(
                _controller.namLoc == null
                    ? 'Không có hồ sơ nào đang chờ duyệt'
                    : 'Không có hồ sơ nào đang chờ duyệt trong năm ${_controller.namLoc}',
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _controller.taiDanhSachChoDuyet,
            child: Responsive(
              builder: (context, info) {
                final soCot = info.isDesktop ? 2 : 1;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: soCot,
                    mainAxisExtent: 130,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final hs = list[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ApprovalBaoTriDetailScreen(maHoSoBaoTri: hs.maHoSoBaoTri)),
                          );
                          if (changed == true) _controller.taiDanhSachChoDuyet();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: const Border(left: BorderSide(color: AppColors.warning, width: 4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(hs.tenThietBi,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'KH ${hs.nam}${hs.namTuKeHoach ? '' : ' (đột xuất)'}',
                                    style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ]),
                              Text('Người lập: ${hs.tenNguoiLap ?? '—'}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
                              Row(children: [
                                Icon(Icons.event_note, size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text('Tạo ngày ${_fmt(hs.ngayTao)}',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============ MÀN 2: CHI TIẾT + PHÊ DUYỆT / TỪ CHỐI ============

class ApprovalBaoTriDetailScreen extends StatefulWidget {
  final int maHoSoBaoTri;
  const ApprovalBaoTriDetailScreen({super.key, required this.maHoSoBaoTri});
  @override
  State<ApprovalBaoTriDetailScreen> createState() => _ApprovalBaoTriDetailScreenState();
}

class _ApprovalBaoTriDetailScreenState extends State<ApprovalBaoTriDetailScreen> {
  late final ApprovalBaoTriDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ApprovalBaoTriDetailController(widget.maHoSoBaoTri);
    _controller.taiChiTiet();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) => d == null ? '—' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _duyet() async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận phê duyệt'),
        content: const Text('Bạn chắc chắn muốn phê duyệt hồ sơ bảo trì này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Phê duyệt')),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hồ sơ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) return const Center(child: CircularProgressIndicator());
          if (_controller.hoSo == null) return Center(child: Text(_controller.loi ?? 'Không tải được hồ sơ'));
          final hs = _controller.hoSo!;

          return ResponsiveCenteredContent(
            maxContentWidth: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hs.tenThietBi,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Chờ duyệt',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dong(
                            'Người lập',
                            hs.tenNguoiLap ?? '—',
                          ),
                          const Divider(height: 20),
                          _dong(
                            'Ngày tạo hồ sơ',
                            _fmt(hs.ngayTao),
                          ),
                          const Divider(height: 20),
                          _dong(
                            'Ngày dự kiến bảo trì',
                            _fmt(hs.ngayDuKienBaoTri),
                          ),
                          const Divider(height: 20),
                          _dong(
                            'Thời gian dự kiến',
                            '${hs.thoiGianDuKien ?? '—'} giờ',
                          ),
                          const Divider(height: 20),
                          _dong(
                            'Giờ bắt đầu',
                            hs.gioBatDauDuKien ?? '—',
                          ),
                          const Divider(height: 20),
                          _dong(
                            'Giờ kết thúc',
                            hs.gioKetThucDuKien ?? '—',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nội dung công việc',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(hs.noiDungCongViec ?? '—'),
                        ],
                      ),
                    ),
                  ),

                  if (_controller.loi != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _controller.loi!,
                      style: const TextStyle(
                        color: AppColors.danger,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (_controller.dangXuLy)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(
                                color: AppColors.danger,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Từ chối'),
                            onPressed: _tuChoi,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Phê duyệt'),
                            onPressed: _duyet,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dong(String nhan, String giaTri) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(nhan, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
        Flexible(
          child: Text(giaTri, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }
}
// ============ LỊCH SỬ PHÊ DUYỆT (Giám đốc) ============

class LichSuPheDuyetScreen extends StatefulWidget {
  const LichSuPheDuyetScreen({super.key});

  @override
  State<LichSuPheDuyetScreen> createState() => _LichSuPheDuyetScreenState();
}

class _LichSuPheDuyetScreenState extends State<LichSuPheDuyetScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = LichSuPheDuyetController();
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

  String _fmtNgay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtGio(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử phê duyệt'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0068A9), Color(0xFF0284C7), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Bảo trì'),
            Tab(text: 'Sửa chữa'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildYearFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildYearFilter() {
    final years = _ctrl.cacNam;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lọc theo năm',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _yearChip('Tất cả', null),
                ...years.map((y) => _yearChip('$y', y)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _yearChip(String label, int? value) {
    final selected = _ctrl.namLoc == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _ctrl.datNam(value),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_ctrl.dangTai) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ctrl.loi != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.danger.withValues(alpha: 0.7)),
              const SizedBox(height: 12),
              Text(_ctrl.loi!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _ctrl.tai, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_ctrl.danhSach.isEmpty) {
      return RefreshIndicator(
        onRefresh: _ctrl.tai,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Chưa có lịch sử phê duyệt\n${_ctrl.tabLoai.toLowerCase()}'
                  '${_ctrl.namLoc != null ? ' năm ${_ctrl.namLoc}' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _ctrl.tai,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _ctrl.danhSach.length,
        itemBuilder: (context, i) {
          final item = _ctrl.danhSach[i];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 280 + (i % 6) * 40),
            curve: Curves.easeOutCubic,
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
            ),
            child: _LichSuCard(
              item: item,
              fmtNgay: _fmtNgay,
              fmtGio: _fmtGio,
            ),
          );
        },
      ),
    );
  }
}

class _LichSuCard extends StatelessWidget {
  final LichSuPheDuyetItem item;
  final String Function(DateTime) fmtNgay;
  final String Function(DateTime) fmtGio;

  const _LichSuCard({
    required this.item,
    required this.fmtNgay,
    required this.fmtGio,
  });

  @override
  Widget build(BuildContext context) {
    final daDuyet = item.daDuyet;
    final mau = daDuyet ? AppColors.success : AppColors.danger;
    final nhanTrangThai = daDuyet ? 'Đã duyệt' : 'Từ chối';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [mau.withValues(alpha: 0.12), mau.withValues(alpha: 0.03)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: mau.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        daDuyet ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: mau,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.tenThietBi ?? 'Hồ sơ #${item.maHoSo ?? '—'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.loai} · HS #${item.maHoSo ?? '—'} · ${fmtNgay(item.ngayDuyet)} ${fmtGio(item.ngayDuyet)}',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: mau.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        nhanTrangThai,
                        style: TextStyle(color: mau, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.person_outline, 'Người lập', item.tenNguoiLap ?? '—'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.verified_user_outlined, 'Người duyệt', item.tenNguoiDuyet ?? '—'),
                    if (item.noiDung != null && item.noiDung!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow(Icons.notes_rounded, 'Nội dung', item.noiDung!),
                    ],
                    if (item.tuChoi && item.lyDo != null && item.lyDo!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.danger.withValues(alpha: 0.9)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lý do từ chối: ${item.lyDo}',
                                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.35),
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
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ============ DUYỆT HỒ SƠ SỬA CHỮA (Giám đốc xem sau khi NVKT Hoàn thành) ============

class ApprovalSuaChuaListScreen extends StatefulWidget {
  const ApprovalSuaChuaListScreen({super.key});

  @override
  State<ApprovalSuaChuaListScreen> createState() =>
      _ApprovalSuaChuaListScreenState();
}

class _ApprovalSuaChuaListScreenState extends State<ApprovalSuaChuaListScreen> {
  List<HoSoSuaChua> _list = [];
  bool _dangTai = true;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      // Hồ sơ SC đã hoàn thành → tự "gửi" GĐ xem (không cần Tổ trưởng gửi thủ công)
      final done =
      await WorkOrderService.layDanhSachHoSoSuaChua(trangThai: 'Đã hoàn thành');
      // Kèm hồ sơ đang thực hiện để GĐ theo dõi
      final dang =
      await WorkOrderService.layDanhSachHoSoSuaChua(trangThai: 'Đang thực hiện');
      final map = <int, HoSoSuaChua>{};
      for (final h in [...dang, ...done]) {
        map[h.maHoSoSuaChua] = h;
      }
      final list = map.values.toList()
        ..sort((a, b) => b.ngayTao.compareTo(a.ngayTao));
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

  Color _mau(String tt) {
    switch (tt) {
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Đang thực hiện':
        return AppColors.primary;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      appBar: AppBar(
        title: const Text('Duyệt hồ sơ sửa chữa'),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0068A9), Color(0xFF0284C7), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _tai,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: _dangTai
          ? const Center(child: CircularProgressIndicator())
          : _loi != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loi!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _tai, child: const Text('Thử lại')),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _tai,
        color: AppColors.primary,
        child: _list.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(Icons.handyman_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Chưa có hồ sơ sửa chữa để xem',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: _list.length,
          itemBuilder: (_, i) {
            final hs = _list[i];
            final mau = _mau(hs.trangThai);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChiTietHoSoSuaChuaScreen(
                          maHoSo: hs.maHoSoSuaChua,
                        ),
                      ),
                    );
                    _tai();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                hs.tenThietBi,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5),
                              ),
                            ),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4),
                              decoration: BoxDecoration(
                                color: mau.withValues(
                                    alpha: 0.12),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                hs.trangThai,
                                style: TextStyle(
                                  color: mau,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'HS SC #${hs.maHoSoSuaChua} · ${_fmt(hs.ngayTao)}',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5),
                        ),
                        if (hs.moTaHuHong != null &&
                            hs.moTaHuHong!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            hs.moTaHuHong!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                height: 1.35, fontSize: 13.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}