import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_exception.dart';

// ============ MÀN 5: LỊCH SỬ PHÂN CÔNG ============

class LichSuPhanCongScreen extends StatefulWidget {
  const LichSuPhanCongScreen({super.key});

  @override
  State<LichSuPhanCongScreen> createState() => _LichSuPhanCongScreenState();
}

class _LichSuPhanCongScreenState extends State<LichSuPhanCongScreen>
    with SingleTickerProviderStateMixin {
  final _controller = LichSuPhanCongController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _controller.doiTab(_tabCtrl.index == 0 ? 'Bảo trì' : 'Sửa chữa');
      }
    });
    _controller.tai();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _fmtNgay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtGio(DateTime? d) {
    if (d == null) return '—';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _huyPhanCong(LichSuPhanCong item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy phân công?'),
        content: Text(
          'Phân công #${item.maPhanCong} sẽ bị hủy.\n'
              'Hồ sơ ${item.loai ?? "bảo trì/sửa chữa"} về trạng thái Đã duyệt và có thể phân công lại.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy phân công'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _controller.huyPhanCong(item.maPhanCong);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Đã hủy phân công. Có thể phân công lại trên hồ sơ.'
            : (_controller.loi ?? 'Lỗi')),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Color _mauTrangThai(String tt) {
    switch (tt) {
      case 'Hoàn thành':
      case 'Xác nhận':
        return AppColors.success;
      case 'Đã phân công':
      case 'Chờ xác nhận':
        return AppColors.warning;
      case 'Từ chối':
      case 'Đã hủy':
        return AppColors.danger;
      case 'Đang thực hiện':
        return const Color(0xFF7C3AED);
      default:
        return Colors.blueGrey;
    }
  }

  Color _mauLoai(String? loai) {
    if (loai == 'Sửa chữa') return const Color(0xFFEA580C);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.primary,
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Tab(
                  text: 'Bảo trì (${_controller.demTheoLoai('Bảo trì')})',
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Tab(
                  text: 'Sửa chữa (${_controller.demTheoLoai('Sửa chữa')})',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.dangTai) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_controller.loi != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text(_controller.loi!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _controller.tai,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final list = _controller.danhSach;
              if (list.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _controller.tai,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                      Icon(Icons.history_rounded, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có phân công ${_controller.tabLoai?.toLowerCase() ?? ''}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _controller.tai,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = list[i];
                    final mau = _mauTrangThai(item.trangThai);
                    final mauLoai = _mauLoai(item.loai);
                    final laBt = item.laBaoTri || item.loai == null;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [mau.withValues(alpha: 0.12), mau.withValues(alpha: 0.04)],
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: mauLoai.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    laBt ? Icons.build_circle_outlined : Icons.handyman_rounded,
                                    color: mauLoai,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Phân công #${item.maPhanCong}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ngày: ${_fmtNgay(item.ngayPhanCong)}',
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Chip loại BT / SC
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: mauLoai.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: mauLoai.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    item.loai ?? 'Bảo trì',
                                    style: TextStyle(
                                      color: mauLoai,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Chip trạng thái
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: mau.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.trangThai,
                                    style: TextStyle(
                                      color: mau,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            child: Column(
                              children: [
                                _HistoryRow(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Người phân công',
                                  value: item.tenNhanVienPhanCong ?? '—',
                                ),
                                const SizedBox(height: 10),
                                _HistoryRow(
                                  icon: Icons.engineering_rounded,
                                  label: 'Nhân viên thực hiện',
                                  value: item.tenNhanVienThucHien ?? '—',
                                ),
                                if (item.tenThietBi != null && item.tenThietBi!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _HistoryRow(
                                    icon: Icons.precision_manufacturing_outlined,
                                    label: 'Thiết bị',
                                    value: item.tenThietBi!,
                                  ),
                                ],
                                if (item.lyDoTuChoi != null && item.lyDoTuChoi!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _HistoryRow(
                                    icon: Icons.info_outline_rounded,
                                    label: 'Lý do từ chối',
                                    value: item.lyDoTuChoi!,
                                  ),
                                ],
                                const Divider(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _TimeChip(
                                        icon: Icons.play_circle_outline_rounded,
                                        label: 'Giờ bắt đầu',
                                        value: _fmtGio(item.gioBatDau),
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _TimeChip(
                                        icon: Icons.stop_circle_outlined,
                                        label: 'Giờ kết thúc',
                                        value: _fmtGio(item.gioKetThuc),
                                        color: const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HistoryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _TimeChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}