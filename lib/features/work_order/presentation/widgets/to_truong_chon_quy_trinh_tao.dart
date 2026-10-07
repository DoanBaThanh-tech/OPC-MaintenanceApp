import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/to_truong_quy_trinh_tao_logic.dart';

/// Chọn quy trình (combo mọi TB) + tích bước khi tạo hồ sơ.
class ToTruongChonQuyTrinhTao extends StatefulWidget {
  final String loaiCongViec;
  final ToTruongQuyTrinhTaoController controller;

  const ToTruongChonQuyTrinhTao({
    super.key,
    required this.loaiCongViec,
    required this.controller,
  });

  @override
  State<ToTruongChonQuyTrinhTao> createState() =>
      _ToTruongChonQuyTrinhTaoState();
}

class _ToTruongChonQuyTrinhTaoState extends State<ToTruongChonQuyTrinhTao> {
  static const _blue = Color(0xFF0B6BCB);

  ToTruongQuyTrinhTaoController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_on);
    _c.taiDanhSach();
  }

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_on);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _blue.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_blue, Color(0xFF38BDF8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_tree_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Quy trình thực hiện',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Có thể chọn quy trình của thiết bị khác. Tích các bước cần làm.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          if (_c.dangTaiDs)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_c.loi != null && _c.danhSach.isEmpty)
            Text(_c.loi!,
                style: const TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700))
          else
            DropdownButtonFormField<QuyTrinhOption>(
              value: _c.dangChon,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Chọn quy trình *',
                filled: true,
                fillColor: const Color(0xFFF0F7FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _c.danhSach
                  .map((q) => DropdownMenuItem(
                value: q,
                child: Text(q.nhan,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: (v) => _c.chonQuyTrinh(v),
            ),
          if (_c.dangTaiBuoc) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ] else if (_c.buoc.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Các bước (${_c.daTich.length}/${_c.buoc.length} đã chọn)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ..._c.buoc.map((b) {
              final chon = _c.daTich.contains(b.soBuoc);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: chon
                      ? _blue.withValues(alpha: 0.06)
                      : const Color(0xFFF8FBFE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: chon
                        ? _blue.withValues(alpha: 0.35)
                        : Colors.grey.shade200,
                  ),
                ),
                child: CheckboxListTile(
                  value: chon,
                  onChanged: (v) => _c.doiTich(b.soBuoc, v),
                  activeColor: _blue,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('Bước ${b.soBuoc}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    b.moTa.isEmpty ? '—' : b.moTa,
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.grey.shade700, height: 1.3),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}