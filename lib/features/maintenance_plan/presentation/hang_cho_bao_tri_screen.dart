import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/maintenance_plan_logic.dart';

/// Hàng chờ thiết bị đến hạn / trễ hạn bảo trì — tạo HS hàng loạt (chỉ BT).
class HangChoBaoTriScreen extends StatefulWidget {
  const HangChoBaoTriScreen({super.key});

  @override
  State<HangChoBaoTriScreen> createState() => _HangChoBaoTriScreenState();
}

class _HangChoBaoTriScreenState extends State<HangChoBaoTriScreen> {
  final _controller = HangChoDenHanController();
  final _noiDungCtrl = TextEditingController(
    text: 'Bảo trì định kỳ theo chu kỳ đề xuất',
  );

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
    _controller.tai();
  }

  @override
  void dispose() {
    _noiDungCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _taoHangLoat() async {
    final ok = await _controller.taoHangLoat(_noiDungCtrl.text);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_controller.thongBao ?? 'Đã tạo hồ sơ bảo trì.'} '
                'Hồ sơ ở Chờ gửi — vào chi tiết bấm Gửi đến xưởng khi sẵn sàng.',
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hàng chờ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.tai(),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              _buildBoLoc(),
              if (_controller.loi != null && !_controller.dangTao)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _controller.loi!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              Expanded(child: _buildDanhSach()),
              _buildThanhTao(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBoLoc() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _controller.thang,
              decoration: InputDecoration(
                labelText: 'Tháng',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: List.generate(
                12,
                    (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(_tenThang[i + 1]),
                ),
              ),
              onChanged: (v) {
                if (v != null) {
                  _controller.doiThangNam(_controller.nam, v);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _controller.nam,
              decoration: InputDecoration(
                labelText: 'Năm',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                for (var y = 2026; y <= 2026; y++)
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (v) {
                if (v != null) {
                  _controller.doiThangNam(v, _controller.thang);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDanhSach() {
    if (_controller.dangTai) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = _controller.danhSach;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Không có thiết bị đến hạn trong '
                  '${_tenThang[_controller.thang].toLowerCase()}/${_controller.nam}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              'Chỉ hiển thị máy đến hạn / trễ hạn và chưa có hồ sơ BT tháng này.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(
                '${list.length} thiết bị',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
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
                ),
                label: Text(
                  _controller.daChon.length == list.length
                      ? 'Bỏ chọn'
                      : 'Chọn tất cả',
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
              final mau = item.treHan ? AppColors.danger : AppColors.warning;
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 0.6,
                shadowColor: Colors.black26,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _controller.daoChon(item.maThietBi),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(color: mau, width: 4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: chon,
                          onChanged: (_) =>
                              _controller.daoChon(item.maThietBi),
                          activeColor: AppColors.primary,
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
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: mau.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.trangThaiHan,
                            style: TextStyle(
                              color: mau,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noiDungCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Nội dung công việc (chung)',
                hintText: 'Mô tả bảo trì định kỳ...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _controller.dangTao || soChon == 0
                    ? null
                    : _taoHangLoat,
                icon: _controller.dangTao
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.playlist_add_check_rounded),
                label: Text(
                  soChon == 0
                      ? 'Chọn thiết bị để tạo hồ sơ'
                      : 'Tạo $soChon hồ sơ bảo trì',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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