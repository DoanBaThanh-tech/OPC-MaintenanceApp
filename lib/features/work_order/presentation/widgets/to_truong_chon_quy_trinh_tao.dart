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
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final isTablet = w >= 560;
                final daChon = _c.daTich.length;
                final tong = _c.buoc.length;
                final cols = w >= 840 ? 3 : (isTablet ? 2 : 1);
                final listH = isTablet
                    ? (tong <= cols * 2 ? null : 360.0)
                    : (tong <= 3 ? null : 310.0);

                Widget stepCard(dynamic b) {
                  final chon = _c.daTich.contains(b.soBuoc);
                  final moTa = _c.moTaHienThi(b);
                  return Material(
                    color: Colors.transparent,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.all(isTablet ? 12 : 10),
                      decoration: BoxDecoration(
                        color: chon
                            ? _blue.withValues(alpha: 0.07)
                            : const Color(0xFFF8FBFE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: chon
                              ? _blue.withValues(alpha: 0.4)
                              : Colors.grey.shade200,
                          width: chon ? 1.3 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: Checkbox(
                                  value: chon,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                  activeColor: _blue,
                                  onChanged: (v) {
                                    HapticFeedback.selectionClick();
                                    _c.doiTich(b.soBuoc, v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                  chon ? _blue : _blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Bước ${b.soBuoc}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 12.5 : 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: chon ? Colors.white : _blue,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (chon)
                                Icon(Icons.check_circle_rounded,
                                    size: 18,
                                    color: _blue.withValues(alpha: 0.9)),
                            ],
                          ),
                          SizedBox(height: isTablet ? 10 : 8),
                          TextFormField(
                            key: ValueKey('buoc-mota-${b.soBuoc}'),
                            initialValue: moTa,
                            maxLines: isTablet ? 3 : 2,
                            minLines: 1,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 12 : 10,
                                vertical: isTablet ? 12 : 10,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Nội dung bước ${b.soBuoc}',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                                fontSize: isTablet ? 13.5 : 12.5,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: _blue, width: 1.5),
                              ),
                            ),
                            onChanged: (v) => _c.capNhatMoTa(b.soBuoc, v),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final Widget body = cols > 1
                    ? GridView.builder(
                  shrinkWrap: true,
                  physics: listH == null
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: cols >= 3 ? 1.5 : 1.42,
                  ),
                  itemCount: tong,
                  itemBuilder: (context, i) => stepCard(_c.buoc[i]),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: listH == null
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  itemCount: tong,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => stepCard(_c.buoc[i]),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bước cần làm',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: isTablet ? 15 : 13.5,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sửa nội dung ngay trên ô · bỏ tích nếu không làm',
                                style: TextStyle(
                                  fontSize: isTablet ? 12.5 : 11.5,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$daChon/$tong',
                            style: const TextStyle(
                              color: _blue,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            for (final b in _c.buoc) {
                              _c.doiTich(b.soBuoc, true);
                            }
                          },
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: _blue,
                          ),
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label: const Text('Chọn tất cả',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        TextButton(
                          onPressed: () {
                            for (final b in _c.buoc.toList()) {
                              _c.doiTich(b.soBuoc, false);
                            }
                          },
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: Colors.grey.shade700,
                          ),
                          child: const Text('Bỏ chọn',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (listH != null)
                      SizedBox(height: listH, child: body)
                    else
                      body,
                  ],
                );
              },
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