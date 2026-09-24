import 'package:flutter/material.dart';
import '../../../core/storage/token_storage.dart';
import '../../maintenance_plan/presentation/maintenance_plan_screens.dart';
import '../../work_order/presentation/work_order_screens.dart';
import '../../work_order/presentation/technician_screens.dart';
import '../../work_order/presentation/work_order_repair_screens.dart';
import '../../approval/presentation/approval_screens.dart';
import '../../equipment/presentation/equipment_screens.dart';
import '../../work_order/presentation/work_order_assign_history_screen.dart';
import '../../work_order/presentation/ho_so_vat_tu_screens.dart';
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
  final String hoTen;
  final String vaiTro;
  const PhienDangNhap({
    required this.email,
    required this.hoTen,
    required this.vaiTro,
  });
}

// ============ LOGIC PHỨC TẠP: xác định menu theo vai trò ============

class DashboardLogic {
  DashboardLogic._();

  /// Đọc thông tin phiên đăng nhập đã lưu — dùng cho header slide menu
  static Future<PhienDangNhap> layPhienDangNhap() async {
    final email = await TokenStorage.getEmail() ?? '';
    final hoTen = await TokenStorage.getHoTen();
    final vaiTro = await TokenStorage.getVaiTro() ?? 'Người dùng';
    // Ưu tiên họ tên; nếu chưa có (session cũ) thì dùng email
    final tenHienThi =
    (hoTen != null && hoTen.trim().isNotEmpty) ? hoTen.trim() : email;
    return PhienDangNhap(email: email, hoTen: tenHienThi, vaiTro: vaiTro);
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

    // Xưởng: xem hồ sơ Chờ duyệt, điều chỉnh ngày, xác nhận lịch trước khi GĐ duyệt + tạo hồ sơ sửa chữa
      case 'Xưởng':
      case 'Tổ trưởng sản xuất': // tương thích JWT/DB cũ
        return [
          MenuGroup(tieuDe: 'Hồ sơ bảo trì', muc: [
            MenuItemData(
              icon: Icons.fact_check_rounded,
              label: 'Hồ sơ bảo trì',
              screenBuilder: () => const WorkOrderBaoTriListScreen(trangThaiMacDinh: 'Chờ duyệt'),
            ),
          ]),
          MenuGroup(tieuDe: 'Sửa chữa', muc: [
            MenuItemData(
              icon: Icons.handyman_rounded,
              label: 'Hồ sơ sửa chữa',
              screenBuilder: () =>
              const WorkOrderSuaChuaListScreen(hienFabTao: true),
            ),
          ]),
        ];

    // Tổ trưởng cơ điện: kế hoạch + tạo hồ sơ gửi xưởng + phân công sau khi GĐ duyệt
      case 'Tổ trưởng cơ điện':
      case 'Tổ trưởng kỹ thuật': // tương thích tên cũ trước khi chạy SQL rename
        return [
          MenuGroup(tieuDe: 'Thiết bị', muc: [
            MenuItemData(icon: Icons.precision_manufacturing_rounded, label: 'Danh sách thiết bị', screenBuilder: () => const EquipmentListScreen()),
            MenuItemData(icon: Icons.event_note_rounded, label: 'Kế hoạch bảo trì', screenBuilder: () => const MaintenancePlanListScreen()),
          ]),
          MenuGroup(tieuDe: 'Công việc', muc: [
            MenuItemData(icon: Icons.build_rounded, label: 'Hồ sơ bảo trì', screenBuilder: () => const WorkOrderBaoTriListScreen()),
            MenuItemData(
              icon: Icons.handyman_rounded,
              label: 'Hồ sơ sửa chữa',
              screenBuilder: () => const WorkOrderSuaChuaListScreen(
                trangThaiMacDinh: 'Chờ phân công',
              ),
            ),
            MenuItemData(
              icon: Icons.inventory_2_rounded,
              label: 'Hồ sơ vật tư',
              screenBuilder: () => const HoSoVatTuListScreen(),
            ),
            MenuItemData(icon: Icons.history_rounded, label: 'Lịch sử phân công', screenBuilder: () => const LichSuPhanCongScreen()),
          ]),
        ];

      case 'Nhân viên kỹ thuật':
        return [
          MenuGroup(tieuDe: 'Công việc của tôi', muc: [
            MenuItemData(
              icon: Icons.assignment_rounded,
              label: 'Yêu cầu bảo trì của tôi',
              screenBuilder: () => const QuanLyYeuCauScreen(),
            ),
          ]),
        ];

      case 'Giám đốc':
      case 'Phó giám đốc':
        return [
          MenuGroup(tieuDe: 'Phê duyệt', muc: [
            MenuItemData(icon: Icons.fact_check_rounded, label: 'Duyệt hồ sơ bảo trì', screenBuilder: () => const ApprovalBaoTriListScreen()),
            MenuItemData(icon: Icons.handyman_rounded, label: 'Duyệt hồ sơ sửa chữa', screenBuilder: () => const ApprovalSuaChuaListScreen()),
            MenuItemData(
              icon: Icons.inventory_2_rounded,
              label: 'Duyệt hồ sơ vật tư',
              screenBuilder: () => const HoSoVatTuListScreen(chiXemDaGui: true),
            ),
            MenuItemData(icon: Icons.history_rounded, label: 'Lịch sử phê duyệt', screenBuilder: () => const LichSuPheDuyetScreen()),
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