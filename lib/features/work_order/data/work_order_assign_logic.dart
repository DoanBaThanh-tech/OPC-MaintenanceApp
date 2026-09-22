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
  /// NV vừa từ chối đúng hồ sơ này (không áp dụng thiết bị khác)
  int? maNhanVienBiTuChoi;
  String? tenNhanVienBiLoai;

  // Lấy từ hồ sơ bảo trì — chỉ đọc, không cho sửa
  HoSoBaoTri? hoSo;
  TimeOfDay? gioBatDau;
  TimeOfDay? gioKetThuc;
  DateTime? ngayDuKien; // ngày bảo trì dự kiến trên hồ sơ

  bool dangTai = true;
  bool dangLuu = false;
  String? loi;

  TimeOfDay? _parseGio(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final p = s.trim().split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> khoiTao(int maHoSoBaoTri) async {
    dangTai = true;
    loi = null;
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

      // 2) Danh sách NVKT đầy đủ — người vừa từ chối hồ sơ NÀY vẫn hiện nhưng không chọn được
      dsNhanVien = await WorkOrderService.layDanhSachNhanVienKyThuat();
      if (hoSo?.phanCongBiTuChoi == true && hoSo?.maNhanVienThucHien != null) {
        maNhanVienBiTuChoi = hoSo!.maNhanVienThucHien;
        tenNhanVienBiLoai = hoSo?.tenNhanVienThucHien;
      } else {
        maNhanVienBiTuChoi = null;
        tenNhanVienBiLoai = null;
      }
      tenNguoiPhanCong = 'Tổ trưởng đang đăng nhập'; // TODO: lấy từ TokenStorage
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

  bool laNhanVienBiTuChoi(int maNhanVien) =>
      maNhanVienBiTuChoi != null && maNhanVien == maNhanVienBiTuChoi;

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