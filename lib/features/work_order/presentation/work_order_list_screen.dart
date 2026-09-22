import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_exception.dart';
import 'work_order_detail_screen.dart';

// ============ MÀN 2: DANH SÁCH HỒ SƠ BẢO TRÌ (có tab lọc trạng thái) ============

class WorkOrderBaoTriListScreen extends StatefulWidget {
  /// Nếu truyền, mở tab tương ứng (vd: 'Chờ xưởng' cho vai trò Xưởng).
  final String? trangThaiMacDinh;
  const WorkOrderBaoTriListScreen({super.key, this.trangThaiMacDinh});
  @override
  State<WorkOrderBaoTriListScreen> createState() => _WorkOrderBaoTriListScreenState();
}

class _WorkOrderBaoTriListScreenState extends State<WorkOrderBaoTriListScreen> with SingleTickerProviderStateMixin {
  final _controller = WorkOrderBaoTriListController();
  late TabController _tab;

  final _tabs = const ['Tất cả', 'Chờ xưởng', 'Chờ duyệt', 'Đã duyệt', 'Đang thực hiện', 'Đã hoàn thành', 'Từ chối'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    if (widget.trangThaiMacDinh != null) {
      final idx = _tabs.indexOf(widget.trangThaiMacDinh!);
      if (idx >= 0) _tab.index = idx;
    }
    _controller.taiDanhSach();
  }

  @override
  void dispose() {
    _tab.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _moBoLocNam(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final nams = _controller.cacNamCoKeHoach;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Text('Lọc theo năm kế hoạch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Chỉ hiển thị những năm đã có kế hoạch bảo trì được lập',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  if (nams.isEmpty)
                    const Text('Chưa có kế hoạch bảo trì nào được lập', style: TextStyle(color: Colors.grey))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chipNam(context, nhan: 'Tất cả', giaTri: null),
                        for (final n in nams) _chipNam(context, nhan: 'Năm $n', giaTri: n),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _chipNam(BuildContext context, {required String nhan, required int? giaTri}) {
    final dangChon = _controller.namLoc == giaTri;
    return ChoiceChip(
      label: Text(nhan),
      selected: dangChon,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: dangChon ? Colors.white : Colors.black87,
        fontWeight: dangChon ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: dangChon ? AppColors.primary : Colors.grey.shade300),
      ),
      onSelected: (_) {
        _controller.datNamLoc(giaTri);
        Navigator.pop(context);
      },
    );
  }

  Color _mau(TrangThaiHoSoBaoTri tt) {
    switch (tt) {
      case TrangThaiHoSoBaoTri.daDuyet:
        return const Color(0xFF0068A9);
      case TrangThaiHoSoBaoTri.dangThucHien:
        return const Color(0xFF1D4ED8);
      case TrangThaiHoSoBaoTri.daHoanThanh:
        return AppColors.success;
      case TrangThaiHoSoBaoTri.tuChoi:
        return AppColors.danger;
      case TrangThaiHoSoBaoTri.choDuyet:
      case TrangThaiHoSoBaoTri.khac:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => IconButton(
              icon: Badge(
                isLabelVisible: _controller.namLoc != null,
                label: Text('${_controller.namLoc}', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.filter_alt_rounded),
              ),
              onPressed: () => _moBoLocNam(context),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: _tabs.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) return const Center(child: CircularProgressIndicator());
          if (_controller.loi != null) return Center(child: Text(_controller.loi!));

          return TabBarView(
            controller: _tab,
            children: _tabs.map((tab) {
              final list = _controller.locTheoTab(tab);
              if (list.isEmpty) return const Center(child: Text('Không có hồ sơ nào'));
              return RefreshIndicator(
                onRefresh: _controller.taiDanhSach,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final hs = list[i];
                    final mau = _mau(phanLoaiTrangThaiHoSo(hs.trangThai));
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: mau, width: 3, style: BorderStyle.solid),
                      ),
                      child: ListTile(
                        title: Text(
                          hs.tenThietBi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '#${hs.maHoSoBaoTri} · ${hs.ngayTao.day}/${hs.ngayTao.month}/${hs.ngayTao.year}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'KH ${hs.nam}${hs.namTuKeHoach ? '' : ' (đột xuất)'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: mau.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              hs.trangThai,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: mau, fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => WorkOrderBaoTriDetailScreen(maHoSoBaoTri: hs.maHoSoBaoTri)),
                          );
                          if (changed == true) _controller.taiDanhSach();
                        },
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}