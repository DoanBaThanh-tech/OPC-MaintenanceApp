import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/to_truong_quy_trinh_tao_logic.dart';

/// Chọn quy trình gọn: ô tóm tắt → bottom sheet tìm kiếm + bước dạng chip.
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
  static const _sky = Color(0xFF38BDF8);

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

  Future<void> _moSheetChonQuyTrinh() async {
    if (_c.dangTaiDs) return;
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SheetChonQuyTrinh(
        controller: _c,
        loaiCongViec: widget.loaiCongViec,
      ),
    );
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_blue, _sky]),
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
              if (_c.dangChon != null)
                Text(
                  '${_c.daTich.length}/${_c.buoc.length} bước',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _blue.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Ô chọn — mở sheet, không xổ dài trên form
          Material(
            color: const Color(0xFFF0F7FC),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _c.dangTaiDs ? null : _moSheetChonQuyTrinh,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        size: 20, color: Colors.grey.shade500),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _c.dangTaiDs
                          ? Text('Đang tải danh sách...',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14))
                          : Text(
                        _c.dangChon?.nhan ??
                            'Chạm để chọn quy trình *',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _c.dangChon != null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _c.dangChon != null
                              ? const Color(0xFF0F172A)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
          ),
          if (_c.loi != null && _c.danhSach.isEmpty) ...[
            const SizedBox(height: 8),
            Text(_c.loi!,
                style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
          ],
          if (_c.dangTaiBuoc) ...[
            const SizedBox(height: 14),
            const Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          ] else if (_c.buoc.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Bước cần làm',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.grey.shade800),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    for (final b in _c.buoc) {
                      if (!_c.daTich.contains(b.soBuoc)) {
                        _c.doiTich(b.soBuoc, true);
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _blue,
                  ),
                  child: const Text('Chọn tất cả',
                      style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tích chọn bước và chỉnh nội dung nếu cần (không bắt buộc giữ nguyên mẫu).',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600, height: 1.3),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: _c.buoc.map((b) {
                    final chon = _c.daTich.contains(b.soBuoc);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
                      decoration: BoxDecoration(
                        color: chon
                            ? _blue.withValues(alpha: 0.06)
                            : const Color(0xFFF8FBFE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: chon
                              ? _blue.withValues(alpha: 0.35)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: chon,
                                activeColor: _blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  _c.doiTich(b.soBuoc, v);
                                },
                              ),
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: chon ? _blue : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${b.soBuoc}',
                                  style: TextStyle(
                                    color: chon
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  chon
                                      ? 'Đã chọn — có thể sửa nội dung bên dưới'
                                      : 'Chưa chọn',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: chon
                                        ? _blue
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (chon) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 4),
                              child: TextFormField(
                                key: ValueKey('moTa-${b.soBuoc}-${_c.dangChon?.maThietBi}'),
                                initialValue: _c.moTaHienThi(b.soBuoc),
                                onChanged: (v) =>
                                    _c.capNhatMoTaBuoc(b.soBuoc, v),
                                maxLines: 2,
                                style: const TextStyle(
                                    fontSize: 13.5, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: 'Nội dung bước ${b.soBuoc}',
                                  hintText: 'Chỉnh nội dung bảo trì/sửa chữa…',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ] else
                            Padding(
                              padding:
                              const EdgeInsets.only(left: 12, bottom: 4),
                              child: Text(
                                b.moTa.isEmpty ? 'Bước ${b.soBuoc}' : b.moTa,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet tìm & chọn quy trình (danh sách dài nhưng gọn, có search).
class _SheetChonQuyTrinh extends StatefulWidget {
  final ToTruongQuyTrinhTaoController controller;
  final String loaiCongViec;

  const _SheetChonQuyTrinh({
    required this.controller,
    required this.loaiCongViec,
  });

  @override
  State<_SheetChonQuyTrinh> createState() => _SheetChonQuyTrinhState();
}

class _SheetChonQuyTrinhState extends State<_SheetChonQuyTrinh> {
  static const _blue = Color(0xFF0B6BCB);
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<QuyTrinhOption> get _loc {
    final all = widget.controller.danhSach;
    if (_q.trim().isEmpty) return all;
    final k = _q.trim().toLowerCase();
    return all
        .where((e) => e.nhan.toLowerCase().contains(k))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.72;
    final ds = _loc;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chọn quy trình ${widget.loaiCongViec}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên thiết bị / quy trình...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF0F7FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${ds.length} quy trình',
                style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ds.isEmpty
                ? Center(
              child: Text('Không tìm thấy',
                  style: TextStyle(color: Colors.grey.shade500)),
            )
                : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: ds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final q = ds[i];
                final chon = widget.controller.dangChon != null &&
                    widget.controller.dangChon!.maThietBi ==
                        q.maThietBi &&
                    widget.controller.dangChon!.loaiCongViec ==
                        q.loaiCongViec;
                return Material(
                  color: chon
                      ? _blue.withValues(alpha: 0.08)
                      : const Color(0xFFF8FBFE),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.controller.chonQuyTrinh(q);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: chon
                                    ? [_blue, const Color(0xFF38BDF8)]
                                    : [
                                  Colors.grey.shade200,
                                  Colors.grey.shade100
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.precision_manufacturing_rounded,
                              size: 18,
                              color: chon
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              q.nhan,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: chon
                                    ? _blue
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (chon)
                            const Icon(Icons.check_circle_rounded,
                                color: _blue, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}