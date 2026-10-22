part of equipment_screens;

class _HeaderThongKe extends StatelessWidget {
  final ThongKeThietBi thongKe;
  const _HeaderThongKe({required this.thongKe});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý thiết bị',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 2),
          Text(
            'Phân theo danh mục · Theo dõi bảo trì & sửa chữa',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Tổng',
                  value: '${thongKe.tongSo}',
                  color: AppColors.primary,
                  icon: Icons.precision_manufacturing_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Sản xuất',
                  value: '${thongKe.soSanXuat}',
                  color: AppColors.success,
                  icon: Icons.play_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Bảo trì',
                  value: '${thongKe.soBaoTri}',
                  color: AppColors.warning,
                  icon: Icons.build_circle_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Sửa chữa',
                  value: '${thongKe.soSuaChua}',
                  color: AppColors.danger,
                  icon: Icons.handyman_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThanhTimKiemVaLoc extends StatelessWidget {
  final TextEditingController searchController;
  final String? locTrangThai;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onLoc;

  const _ThanhTimKiemVaLoc({
    required this.searchController,
    required this.locTrangThai,
    required this.onSearch,
    required this.onLoc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Tìm tên, vị trí, mã thiết bị…',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: () {
                  searchController.clear();
                  onSearch('');
                },
              )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(label: 'Tất cả', selected: locTrangThai == null, onTap: () => onLoc(null)),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Sản xuất',
                  color: AppColors.success,
                  selected: locTrangThai == TrangThaiThietBi.sanXuat,
                  onTap: () => onLoc(TrangThaiThietBi.sanXuat),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Bảo trì',
                  color: AppColors.warning,
                  selected: locTrangThai == TrangThaiThietBi.baoTri,
                  onTap: () => onLoc(TrangThaiThietBi.baoTri),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Sửa chữa',
                  color: AppColors.danger,
                  selected: locTrangThai == TrangThaiThietBi.suaChua,
                  onTap: () => onLoc(TrangThaiThietBi.suaChua),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Material(
      color: selected ? c.withValues(alpha: 0.14) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? c : Colors.grey.shade300, width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? c : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NhomCard extends StatelessWidget {
  final NhomThietBiTheoDanhMuc nhom;
  final void Function(ThietBiModel) onTapThietBi;

  const _NhomCard({required this.nhom, required this.onTapThietBi});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.category_rounded, color: AppColors.primary, size: 22),
          ),
          title: Text(
            nhom.tenDanhMuc,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${nhom.soLuong} thiết bị'
                  '${nhom.soThangChuKy != null ? ' · Chu kỳ ${nhom.soThangChuKy} tháng' : ''}'
                  ' · SX ${nhom.soSanXuat} · BT ${nhom.soBaoTri} · SC ${nhom.soSuaChua}',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
            ),
          ),
          children: nhom.danhSach
              .map((tb) => _ThietBiRow(thietBi: tb, onTap: () => onTapThietBi(tb)))
              .toList(),
        ),
      ),
    );
  }
}

class _ThietBiRow extends StatelessWidget {
  final ThietBiModel thietBi;
  final VoidCallback onTap;

  const _ThietBiRow({required this.thietBi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = thietBi.tinhTrangHienTai == TrangThaiThietBi.baoTri
        ? AppColors.warning
        : thietBi.tinhTrangHienTai == TrangThaiThietBi.suaChua
        ? AppColors.danger
        : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thietBi.tenThietBi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      if (thietBi.viTriLapDat != null && thietBi.viTriLapDat!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                thietBi.viTriLapDat!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    thietBi.tinhTrangHienTai,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoItem> rows;

  const _InfoSection({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(r.label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ),
                  Expanded(
                    child: Text(
                      r.value,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gom quy trình BT + SC trong một khung «Quy trình thực hiện».
/// - Mobile: tab Bảo trì | Sửa chữa (gọn, dễ chạm).
/// - Màn rộng (≥ 640): hai cột cạnh nhau.
class _QuyTrinhThucHienGom extends StatefulWidget {
  final int maThietBi;
  final List<BuocQuyTrinh> buocBaoTri;
  final List<BuocQuyTrinh> buocSuaChua;
  final VoidCallback? onSaved;

  const _QuyTrinhThucHienGom({
    required this.maThietBi,
    required this.buocBaoTri,
    required this.buocSuaChua,
    this.onSaved,
  });

  @override
  State<_QuyTrinhThucHienGom> createState() => _QuyTrinhThucHienGomState();
}

class _QuyTrinhThucHienGomState extends State<_QuyTrinhThucHienGom> {
  /// 0 = Bảo trì, 1 = Sửa chữa (dùng khi layout tab)
  int _tab = 0;
  late List<TextEditingController> _ctrlsBt;
  late List<TextEditingController> _ctrlsSc;
  bool _dangLuuBt = false;
  bool _dangLuuSc = false;

  static const _blue = Color(0xFF0068A9);
  static const _amber = Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    _ctrlsBt = _makeCtrls(widget.buocBaoTri);
    _ctrlsSc = _makeCtrls(widget.buocSuaChua);
  }

  @override
  void didUpdateWidget(covariant _QuyTrinhThucHienGom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buocBaoTri != widget.buocBaoTri) {
      for (final c in _ctrlsBt) {
        c.dispose();
      }
      _ctrlsBt = _makeCtrls(widget.buocBaoTri);
    }
    if (oldWidget.buocSuaChua != widget.buocSuaChua) {
      for (final c in _ctrlsSc) {
        c.dispose();
      }
      _ctrlsSc = _makeCtrls(widget.buocSuaChua);
    }
  }

  List<TextEditingController> _makeCtrls(List<BuocQuyTrinh> buoc) =>
      buoc.map((b) => TextEditingController(text: b.moTa)).toList();

  @override
  void dispose() {
    for (final c in _ctrlsBt) {
      c.dispose();
    }
    for (final c in _ctrlsSc) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _luu({
    required bool laBaoTri,
    required List<BuocQuyTrinh> buoc,
    required List<TextEditingController> ctrls,
  }) async {
    if (buoc.isEmpty) return;
    setState(() {
      if (laBaoTri) {
        _dangLuuBt = true;
      } else {
        _dangLuuSc = true;
      }
    });
    try {
      final payload = <BuocQuyTrinh>[];
      for (var i = 0; i < buoc.length; i++) {
        final b = buoc[i];
        final moTa = i < ctrls.length ? ctrls[i].text.trim() : b.moTa;
        payload.add(BuocQuyTrinh(
          soBuoc: b.soBuoc,
          moTa: moTa.isEmpty ? 'Bước ${b.soBuoc}' : moTa,
        ));
      }
      await MaterialUsageService.capNhatQuyTrinhThietBi(
        maThietBi: widget.maThietBi,
        loaiCongViec: laBaoTri ? 'Bảo trì' : 'Sửa chữa',
        buoc: payload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đã lưu quy trình ${laBaoTri ? 'bảo trì' : 'sửa chữa'}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSaved?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (laBaoTri) {
            _dangLuuBt = false;
          } else {
            _dangLuuSc = false;
          }
        });
      }
    }
  }

  Widget _tabChip({
    required String label,
    required IconData icon,
    required Color accent,
    required int soBuoc,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: selected ? Colors.white : accent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: selected ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$soBuoc',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: selected ? Colors.white : accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cotNoiDung({
    required String loai,
    required Color accent,
    required List<BuocQuyTrinh> buoc,
    required List<TextEditingController> ctrls,
    required bool dangLuu,
    required VoidCallback onLuu,
    bool compactHeader = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compactHeader) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  loai == 'Bảo trì'
                      ? Icons.build_circle_outlined
                      : Icons.handyman_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loai,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
              Text(
                '${buoc.length} bước',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'Chỉnh nội dung từng bước rồi bấm Lưu — dùng khi tạo hồ sơ ${loai.toLowerCase()}.',
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (buoc.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Chưa có quy trình $loai trong hệ thống cho thiết bị này.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
          )
        else
          ...List.generate(buoc.length, (i) {
            final b = buoc[i];
            final ctrl = i < ctrls.length ? ctrls[i] : null;
            return Container(
              margin: EdgeInsets.only(bottom: i == buoc.length - 1 ? 0 : 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${b.soBuoc}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ctrl == null
                        ? Text(b.moTa)
                        : TextField(
                      controller: ctrl,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Bước ${b.soBuoc}',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        if (buoc.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: dangLuu ? null : onLuu,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: dangLuu
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                dangLuu ? 'Đang lưu…' : 'Lưu $loai',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final haiCot = constraints.maxWidth >= 640;
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tiêu đề khung chung
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0068A9), Color(0xFF0EA5E9)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_tree_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Quy trình thực hiện',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Text(
                    '${widget.buocBaoTri.length + widget.buocSuaChua.length} bước',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (haiCot)
              // Màn rộng: 2 cột Bảo trì | Sửa chữa
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _blue.withValues(alpha: 0.2)),
                        ),
                        child: _cotNoiDung(
                          loai: 'Bảo trì',
                          accent: _blue,
                          buoc: widget.buocBaoTri,
                          ctrls: _ctrlsBt,
                          dangLuu: _dangLuuBt,
                          compactHeader: true,
                          onLuu: () => _luu(
                            laBaoTri: true,
                            buoc: widget.buocBaoTri,
                            ctrls: _ctrlsBt,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _amber.withValues(alpha: 0.25)),
                        ),
                        child: _cotNoiDung(
                          loai: 'Sửa chữa',
                          accent: _amber,
                          buoc: widget.buocSuaChua,
                          ctrls: _ctrlsSc,
                          dangLuu: _dangLuuSc,
                          compactHeader: true,
                          onLuu: () => _luu(
                            laBaoTri: false,
                            buoc: widget.buocSuaChua,
                            ctrls: _ctrlsSc,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                // Mobile: tab gọn
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _tabChip(
                        label: 'Bảo trì',
                        icon: Icons.build_circle_outlined,
                        accent: _blue,
                        soBuoc: widget.buocBaoTri.length,
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      const SizedBox(width: 4),
                      _tabChip(
                        label: 'Sửa chữa',
                        icon: Icons.handyman_rounded,
                        accent: _amber,
                        soBuoc: widget.buocSuaChua.length,
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _tab == 0
                      ? KeyedSubtree(
                    key: const ValueKey('bt'),
                    child: _cotNoiDung(
                      loai: 'Bảo trì',
                      accent: _blue,
                      buoc: widget.buocBaoTri,
                      ctrls: _ctrlsBt,
                      dangLuu: _dangLuuBt,
                      onLuu: () => _luu(
                        laBaoTri: true,
                        buoc: widget.buocBaoTri,
                        ctrls: _ctrlsBt,
                      ),
                    ),
                  )
                      : KeyedSubtree(
                    key: const ValueKey('sc'),
                    child: _cotNoiDung(
                      loai: 'Sửa chữa',
                      accent: _amber,
                      buoc: widget.buocSuaChua,
                      ctrls: _ctrlsSc,
                      dangLuu: _dangLuuSc,
                      onLuu: () => _luu(
                        laBaoTri: false,
                        buoc: widget.buocSuaChua,
                        ctrls: _ctrlsSc,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Định dạng ngày dd/MM/yyyy — dùng chung danh sách/chi tiết thiết bị.
String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}