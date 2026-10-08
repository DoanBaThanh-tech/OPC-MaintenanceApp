part of equipment_screens;

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