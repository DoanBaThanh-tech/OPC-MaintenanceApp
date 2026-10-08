part of maintenance_request_screens;

// =============================================================================
// TTSX: Quản lý yêu cầu (Bảo trì / Sửa chữa) + nút +
// =============================================================================

class QuanLyYeuCauBaoTriScreen extends StatefulWidget {
  const QuanLyYeuCauBaoTriScreen({super.key});

  @override
  State<QuanLyYeuCauBaoTriScreen> createState() => _QuanLyYeuCauBaoTriScreenState();
}

class _QuanLyYeuCauBaoTriScreenState extends State<QuanLyYeuCauBaoTriScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _listCtrl = DanhSachYeuCauController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _listCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _listCtrl.tai();
  }

  @override
  void dispose() {
    _tab.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _moTaoYeuCau() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const TaoYeuCauBaoTriScreen(),
        fullscreenDialog: true,
      ),
    );
    if (created == true) {
      await _listCtrl.tai();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [
                Tab(text: 'Bảo trì'),
                Tab(text: 'Sửa chữa'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _DanhSachYeuCauBaoTriTab(controller: _listCtrl),
                const _PlaceholderSuaChuaTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton(
        onPressed: _moTaoYeuCau,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        child: const Icon(Icons.add_rounded, size: 28),
      )
          : null,
    );
  }
}

class _PlaceholderSuaChuaTab extends StatelessWidget {
  const _PlaceholderSuaChuaTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handyman_outlined, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Yêu cầu sửa chữa',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              'Chức năng đang được chuẩn bị.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DanhSachYeuCauBaoTriTab extends StatelessWidget {
  final DanhSachYeuCauController controller;
  const _DanhSachYeuCauBaoTriTab({required this.controller});

  Color _statusColor(String tt) {
    switch (tt) {
      case 'Chờ xác nhận':
        return AppColors.warning;
      case 'Đã xác nhận':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      case 'Đã tạo hồ sơ':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBoLoc() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('Bộ lọc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const Spacer(),
              if (controller.dangLoc)
                TextButton(
                  onPressed: controller.xoaLoc,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Xóa lọc', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Danh mục
          DropdownButtonFormField<String?>(
            value: controller.locDanhMuc,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Danh mục thiết bị',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Tất cả danh mục')),
              ...controller.cacDanhMuc.map(
                    (dm) => DropdownMenuItem(value: dm, child: Text(dm, overflow: TextOverflow.ellipsis)),
              ),
            ],
            onChanged: controller.datLocDanhMuc,
          ),
          const SizedBox(height: 10),
          // Thiết bị
          DropdownButtonFormField<int?>(
            value: controller.locMaThietBi,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Thiết bị',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Tất cả thiết bị')),
              ...controller.cacThietBi.map(
                    (t) => DropdownMenuItem(
                  value: t.ma,
                  child: Text(t.ten, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: controller.datLocThietBi,
          ),
          const SizedBox(height: 10),
          // Năm
          DropdownButtonFormField<int?>(
            value: controller.locNam,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Năm',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Tất cả năm')),
              ...controller.cacNam.map(
                    (n) => DropdownMenuItem(value: n, child: Text('$n')),
              ),
            ],
            onChanged: controller.datLocNam,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.dangTai) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.loi != null && controller.danhSachGoc.isEmpty) {
      return Center(child: Text(controller.loi!, style: const TextStyle(color: AppColors.danger)));
    }
    if (controller.danhSachGoc.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.tai,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Chưa có yêu cầu bảo trì',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Nhấn nút + để tạo yêu cầu mới',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final list = controller.danhSach;
    return RefreshIndicator(
      onRefresh: controller.tai,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
        itemCount: list.isEmpty ? 2 : list.length + 1, // +1 bộ lọc; +1 empty msg
        separatorBuilder: (context, i) {
          if (i == 0) return const SizedBox(height: 12);
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, i) {
          if (i == 0) return _buildBoLoc();
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'Không có yêu cầu khớp bộ lọc',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }
          final y = list[i - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCard(context, y),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, YeuCauBaoTriItem y) {
    final c = _statusColor(y.trangThai);
    final biTuChoi = y.trangThai == 'Từ chối';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  y.tenThietBi ?? 'Thiết bị #${y.maThietBi}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  y.trangThai,
                  style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'YC #${y.maYeuCauBaoTri} · ${y.danhMuc ?? '—'}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Ngày BT: ${y.ngayBaoTri.day.toString().padLeft(2, '0')}/'
                '${y.ngayBaoTri.month.toString().padLeft(2, '0')}/'
                '${y.ngayBaoTri.year}'
                ' · ${y.thoiGianDuKien}h'
                '${y.gioBatDau != null ? ' · ${y.gioBatDau}–${y.gioKetThuc}' : ''}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (y.ghiChu != null && y.ghiChu!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              y.ghiChu!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
          ],
          if (y.lyDoTuChoi != null && y.lyDoTuChoi!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Lý do từ chối: ${y.lyDoTuChoi}',
              style: const TextStyle(color: AppColors.danger, fontSize: 12.5),
            ),
          ],
          if (biTuChoi) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => TaoYeuCauBaoTriScreen(yeuCauSua: y),
                      fullscreenDialog: true,
                    ),
                  );
                  if (ok == true) await controller.tai();
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Chỉnh sửa & gửi lại xưởng',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}