import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../core/network/api_exception.dart';
import 'models/work_order_models.dart';
import 'services/work_order_service.dart';

// Logic cho work_order_assign_screen.dart

class PhanCongBaoTriController extends ChangeNotifier {
  List<NhanVienRutGon> dsNhanVien = [];
  /// Chọn nhiều nhân viên (tích / bỏ tích).
  final Set<int> maNhanVienDaChon = {};

  String? tenNguoiPhanCong;
  int? maNguoiPhanCong;

  // Lấy từ hồ sơ bảo trì — chỉ đọc, không cho sửa
  HoSoBaoTri? hoSo;
  TimeOfDay? gioBatDau;
  TimeOfDay? gioKetThuc;
  DateTime? ngayDuKien; // ngày bảo trì dự kiến trên hồ sơ

  bool dangTai = true;
  bool dangLuu = false;
  String? loi;
  bool isCapNhat = false;

  TimeOfDay? _parseGio(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final p = s.trim().split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> khoiTao(int maHoSoBaoTri, {bool capNhat = false}) async {
    isCapNhat = capNhat;
    dangTai = true;
    loi = null;
    maNhanVienDaChon.clear();
    notifyListeners();
    try {
      // 1) Lấy hồ sơ → giờ bắt đầu / kết thúc cố định
      hoSo = await WorkOrderService.layChiTietHoSoBaoTri(maHoSoBaoTri);
      gioBatDau = _parseGio(hoSo!.gioBatDauDuKien);
      gioKetThuc = _parseGio(hoSo!.gioKetThucDuKien);
      ngayDuKien = hoSo!.ngayDuKienBaoTri ?? DateTime.now();

      if (gioBatDau == null || gioKetThuc == null) {
        loi = 'Hồ sơ chưa có giờ bắt đầu/kết thúc. Vui lòng sửa hồ sơ trước khi phân công.';
      }

      // 2) Danh sách NVKT — có thể phân công cùng người cho nhiều thiết bị khác nhau
      dsNhanVien = await WorkOrderService.layDanhSachNhanVienKyThuat();

      // 3) Cập nhật: pre-select những NV đang được phân công trên hồ sơ này
      if (isCapNhat && hoSo != null) {
        if (hoSo!.maNhanVienThucHiens.isNotEmpty) {
          maNhanVienDaChon.addAll(hoSo!.maNhanVienThucHiens);
        } else if (hoSo!.maNhanVienThucHien != null) {
          maNhanVienDaChon.add(hoSo!.maNhanVienThucHien!);
        }
      }

      tenNguoiPhanCong = 'Tổ trưởng đang đăng nhập';
    } catch (e) {
      loi = 'Không tải được dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void chonNhanVien(NhanVienRutGon nv) {
    toggleNhanVien(nv);
  }

  /// Tích / bỏ tích nhân viên (hỗ trợ chọn nhiều).
  void toggleNhanVien(NhanVienRutGon nv) {
    if (maNhanVienDaChon.contains(nv.maNhanVien)) {
      maNhanVienDaChon.remove(nv.maNhanVien);
    } else {
      maNhanVienDaChon.add(nv.maNhanVien);
    }
    loi = null;
    notifyListeners();
  }

  bool daChon(int maNhanVien) => maNhanVienDaChon.contains(maNhanVien);

  DateTime get thoiDiemBatDau {
    final d = ngayDuKien ?? DateTime.now();
    final g = gioBatDau ?? const TimeOfDay(hour: 8, minute: 0);
    return DateTime(d.year, d.month, d.day, g.hour, g.minute);
  }

  DateTime get thoiDiemKetThuc {
    final d = ngayDuKien ?? DateTime.now();
    final g = gioKetThuc ?? const TimeOfDay(hour: 17, minute: 0);
    return DateTime(d.year, d.month, d.day, g.hour, g.minute);
  }

  Future<bool> xacNhan(int maHoSoBaoTri) async {
    if (maNhanVienDaChon.isEmpty) {
      loi = 'Vui lòng chọn ít nhất một nhân viên thực hiện';
      notifyListeners();
      return false;
    }
    if (gioBatDau == null || gioKetThuc == null) {
      loi = 'Hồ sơ thiếu giờ bắt đầu/kết thúc — không thể phân công';
      notifyListeners();
      return false;
    }
    if (thoiDiemKetThuc.isBefore(thoiDiemBatDau)) {
      loi = 'Giờ kết thúc phải sau giờ bắt đầu (theo hồ sơ)';
      notifyListeners();
      return false;
    }

    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.phanCongBaoTri(
        maHoSoBaoTri: maHoSoBaoTri,
        maNhanVienThucHiens: maNhanVienDaChon.toList(),
        ngayBatDau: thoiDiemBatDau,
        ngayKetThuc: thoiDiemKetThuc,
      );
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } finally {
      dangLuu = false;
      notifyListeners();
    }
  }
}