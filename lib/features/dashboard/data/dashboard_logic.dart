import 'package:flutter/material.dart';
import '../../../core/storage/token_storage.dart';
import '../../maintenance_plan/presentation/maintenance_plan_screens.dart';
import '../../work_order/presentation/work_order_screens.dart';
import '../../approval/presentation/approval_screens.dart';
// ============ MODEL ============

/// 1 mục trong slide menu
class MenuItemData {
  final IconData icon;
  final String label;
  final Widget Function() screenBuilder;
  const MenuItemData({
    required this.icon,
    required this.label,
    required this.screenBuilder,
  });
}

/// 1 nhóm mục trong slide menu (VD: "Tài khoản", "Hệ thống")
class MenuGroup {
  final String tieuDe;
  final List<MenuItemData> muc;
  const MenuGroup({required this.tieuDe, required this.muc});
}

/// Thông tin phiên đăng nhập hiện tại, dùng để hiển thị ở header slide menu
class PhienDangNhap {
  final String email;
  final String vaiTro;
  const PhienDangNhap({required this.email, required this.vaiTro});
}

// ============ LOGIC PHỨC TẠP: xác định menu theo vai trò ============

class DashboardLogic {
  DashboardLogic._();

  /// Đọc thông tin phiên đăng nhập đã lưu — dùng cho header slide menu
  static Future<PhienDangNhap> layPhienDangNhap() async {
    final email = await TokenStorage.getToken() != null
        ? (await TokenStorage.getVaiTro() ?? '')
        : '';
    // Lấy đúng 2 giá trị cần thiết cho header
    final vaiTro = await TokenStorage.getVaiTro() ?? 'Người dùng';
    return PhienDangNhap(email: email, vaiTro: vaiTro);
  }

  /// Trung tâm điều phối: mỗi vai trò thấy nhóm chức năng khác nhau.
  /// Đây là nơi DUY NHẤT quyết định "vai trò nào thấy gì" — khi thêm
  /// tính năng mới, chỉ sửa đúng hàm này, không sửa rải rác ở UI.
  static List<MenuGroup> layMenuTheoVaiTro(String vaiTro) {
    switch (vaiTro) {
      case 'Admin hệ thống':
        return [
          MenuGroup(tieuDe: 'Tài khoản', muc: [
            MenuItemData(icon: Icons.people_alt_rounded, label: 'Quản lý người dùng', screenBuilder: () => const _ChuaLamScreen(ten: 'Quản lý người dùng')),
            MenuItemData(icon: Icons.admin_panel_settings_rounded, label: 'Quản lý vai trò', screenBuilder: () => const _ChuaLamScreen(ten: 'Quản lý vai trò')),
          ]),
          MenuGroup(tieuDe: 'Hệ thống', muc: [
            MenuItemData(icon: Icons.grid_view_rounded, label: 'Danh mục chức năng', screenBuilder: () => const _ChuaLamScreen(ten: 'Danh mục chức năng')),
            MenuItemData(icon: Icons.tune_rounded, label: 'Cấu hình hệ thống', screenBuilder: () => const _ChuaLamScreen(ten: 'Cấu hình hệ thống')),
            MenuItemData(icon: Icons.receipt_long_rounded, label: 'Nhật ký hệ thống', screenBuilder: () => const _ChuaLamScreen(ten: 'Nhật ký hệ thống')),
          ]),
        ];

      case 'Tổ trưởng kỹ thuật':
        return [
          MenuGroup(tieuDe: 'Thiết bị', muc: [
            MenuItemData(icon: Icons.precision_manufacturing_rounded, label: 'Danh sách thiết bị', screenBuilder: () => const _ChuaLamScreen(ten: 'Danh sách thiết bị')),
            MenuItemData(icon: Icons.event_note_rounded, label: 'Kế hoạch bảo trì', screenBuilder: () => const MaintenancePlanListScreen()),
          ]),
          MenuGroup(tieuDe: 'Công việc', muc: [
            MenuItemData(icon: Icons.build_rounded, label: 'Hồ sơ bảo trì', screenBuilder: () => const WorkOrderBaoTriListScreen()),
            MenuItemData(icon: Icons.handyman_rounded, label: 'Hồ sơ sửa chữa', screenBuilder: () => const _ChuaLamScreen(ten: 'Hồ sơ sửa chữa')),
            MenuItemData(icon: Icons.groups_rounded, label: 'Phân công nhân viên', screenBuilder: () => const _ChuaLamScreen(ten: 'Phân công nhân viên')),
          ]),
        ];

      case 'Nhân viên kỹ thuật':
        return [
          MenuGroup(tieuDe: 'Công việc của tôi', muc: [
            MenuItemData(icon: Icons.assignment_rounded, label: 'Công việc được giao', screenBuilder: () => const _ChuaLamScreen(ten: 'Công việc được giao')),
            MenuItemData(icon: Icons.build_rounded, label: 'Tạo hồ sơ bảo trì', screenBuilder: () => const _ChuaLamScreen(ten: 'Tạo hồ sơ bảo trì')),
            MenuItemData(icon: Icons.handyman_rounded, label: 'Tạo hồ sơ sửa chữa', screenBuilder: () => const _ChuaLamScreen(ten: 'Tạo hồ sơ sửa chữa')),
            MenuItemData(icon: Icons.inventory_2_rounded, label: 'Yêu cầu vật tư', screenBuilder: () => const _ChuaLamScreen(ten: 'Yêu cầu vật tư')),
          ]),
        ];

      case 'Giám đốc':
      case 'Phó giám đốc':
      return [
        MenuGroup(tieuDe: 'Phê duyệt', muc: [
          MenuItemData(icon: Icons.fact_check_rounded, label: 'Duyệt hồ sơ bảo trì', screenBuilder: () => const ApprovalBaoTriListScreen()),
          MenuItemData(icon: Icons.fact_check_outlined, label: 'Duyệt hồ sơ sửa chữa', screenBuilder: () => const _ChuaLamScreen(ten: 'Duyệt hồ sơ sửa chữa')),
          MenuItemData(icon: Icons.inventory_rounded, label: 'Duyệt yêu cầu vật tư', screenBuilder: () => const _ChuaLamScreen(ten: 'Duyệt yêu cầu vật tư')),
          MenuItemData(icon: Icons.history_rounded, label: 'Lịch sử phê duyệt', screenBuilder: () => const _ChuaLamScreen(ten: 'Lịch sử phê duyệt')),
        ]),
      ];

      case 'Nhân viên quản lý vật tư':
        return [
          MenuGroup(tieuDe: 'Kho vật tư', muc: [
            MenuItemData(icon: Icons.warehouse_rounded, label: 'Danh sách vật tư', screenBuilder: () => const _ChuaLamScreen(ten: 'Danh sách vật tư')),
            MenuItemData(icon: Icons.swap_vert_rounded, label: 'Nhập / Xuất vật tư', screenBuilder: () => const _ChuaLamScreen(ten: 'Nhập / Xuất vật tư')),
            MenuItemData(icon: Icons.assignment_turned_in_rounded, label: 'Yêu cầu vật tư', screenBuilder: () => const _ChuaLamScreen(ten: 'Yêu cầu vật tư')),
          ]),
        ];

      default:
        return const [];
    }
  }
}

/// Màn tạm — bạn thay bằng screen thật của từng feature khi làm tới
class _ChuaLamScreen extends StatelessWidget {
  final String ten;
  const _ChuaLamScreen({required this.ten});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$ten — sẽ làm chi tiết sau', style: const TextStyle(color: Colors.grey)),
    );
  }
}