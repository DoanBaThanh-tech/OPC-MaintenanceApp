import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../data/approval_logic.dart';

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
        title: const Text('Hồ sơ bảo trì chờ duyệt'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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