import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/equipment_logic.dart';

String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ============================================================
// MÀN 1: DANH SÁCH THIẾT BỊ
// ============================================================

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _controller = EquipmentListController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.taiDanhSach();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _HeaderThongKe(thongKe: _controller.thongKe),
              _ThanhTimKiemVaLoc(
                searchController: _searchController,
                locTrangThai: _controller.locTrangThai,
                onSearch: _controller.datTuKhoa,
                onLoc: _controller.datLocTrangThai,
              ),
              Expanded(child: _buildNoiDung()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoiDung() {
    if (_controller.dangTai) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_controller.loi != null) {
      return _EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Không tải được dữ liệu',
        subtitle: _controller.loi!,
        actionLabel: 'Thử lại',
        onAction: _controller.taiDanhSach,
      );
    }
    if (_controller.nhom.isEmpty) {
      return const _EmptyState(
        icon: Icons.precision_manufacturing_outlined,
        title: 'Không có thiết bị phù hợp',
        subtitle: 'Thử đổi bộ lọc hoặc từ khóa tìm kiếm',
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.taiDanhSach,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        itemCount: _controller.nhom.length,
        itemBuilder: (context, index) {
          final nhom = _controller.nhom[index];
          return _NhomCard(
            nhom: nhom,
            onTapThietBi: (tb) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EquipmentDetailScreen(maThietBi: tb.maThietBi),
                ),
              );
              if (mounted) _controller.taiDanhSach();
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// MÀN 2: CHI TIẾT THIẾT BỊ
// ============================================================

class EquipmentDetailScreen extends StatefulWidget {
  final int maThietBi;
  const EquipmentDetailScreen({super.key, required this.maThietBi});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final _controller = EquipmentDetailController();

  @override
  void initState() {
    super.initState();
    _controller.taiChiTiet(widget.maThietBi);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Chi tiết thiết bị'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _controller.taiChiTiet(widget.maThietBi),
              ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.dangTai) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_controller.loi != null || _controller.thietBi == null) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Không tải được chi tiết',
        subtitle: _controller.loi ?? 'Không tìm thấy thiết bị',
        actionLabel: 'Thử lại',
        onAction: () => _controller.taiChiTiet(widget.maThietBi),
      );
    }

    final tb = _controller.thietBi!;
    final statusColor = _statusColor(tb.tinhTrangHienTai);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.precision_manufacturing_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(tb.tinhTrangHienTai), size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            tb.tinhTrangHienTai,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  tb.tenThietBi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã TB · ${tb.maThietBi}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'Thông tin chung',
            icon: Icons.info_outline_rounded,
            rows: [
              _InfoItem('Danh mục', tb.danhMuc),
              _InfoItem('Vị trí lắp đặt', tb.viTriLapDat ?? '—'),
              _InfoItem('Ngày lắp đặt', _fmtDate(tb.ngayLapDat)),
              _InfoItem(
                'Chu kỳ bảo trì',
                tb.soThangDeXuat != null ? '${tb.soThangDeXuat} tháng/lần' : '—',
              ),
              if (tb.moTaChuKy != null && tb.moTaChuKy!.isNotEmpty)
                _InfoItem('Mô tả chu kỳ', tb.moTaChuKy!),
              if (tb.ghiChu != null && tb.ghiChu!.trim().isNotEmpty)
                _InfoItem('Ghi chú', tb.ghiChu!),
            ],
          ),
          const SizedBox(height: 12),
          _InfoSection(
            title: 'Lịch bảo trì',
            icon: Icons.event_available_rounded,
            rows: [
              _InfoItem(
                'Bảo trì gần nhất',
                tb.ngayBaoTriGanNhat != null ? _fmtDate(tb.ngayBaoTriGanNhat) : 'Chưa có',
              ),
              _InfoItem(
                'Bảo trì tiếp theo',
                tb.ngayBaoTriTiepTheo != null ? _fmtDate(tb.ngayBaoTriTiepTheo) : 'Chưa lên lịch',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_statusIcon(tb.tinhTrangHienTai), color: statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusHint(tb.tinhTrangHienTai),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: statusColor.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String tt) {
    if (tt == TrangThaiThietBi.baoTri) return AppColors.warning;
    if (tt == TrangThaiThietBi.suaChua) return AppColors.danger;
    return AppColors.success;
  }

  IconData _statusIcon(String tt) {
    if (tt == TrangThaiThietBi.baoTri) return Icons.build_circle_outlined;
    if (tt == TrangThaiThietBi.suaChua) return Icons.handyman_rounded;
    return Icons.play_circle_outline_rounded;
  }

  String _statusHint(String tt) {
    if (tt == TrangThaiThietBi.baoTri) {
      return 'Thiết bị đang được phân công bảo trì. Sau khi hoàn thành, trạng thái sẽ trở về Sản xuất.';
    }
    if (tt == TrangThaiThietBi.suaChua) {
      return 'Thiết bị đang được phân công sửa chữa. Sau khi hoàn thành, trạng thái sẽ trở về Sản xuất.';
    }
    return 'Thiết bị đang ở trạng thái Sản xuất — chưa được phân công bảo trì hoặc sửa chữa.';
  }
}

// ============================================================
// WIDGETS
// ============================================================

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