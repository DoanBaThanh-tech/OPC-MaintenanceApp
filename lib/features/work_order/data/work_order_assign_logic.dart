import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../core/network/api_exception.dart';
import 'models/work_order_models.dart';
import 'services/work_order_service.dart';

// Logic cho work_order_assign_screen.dart — hỗ trợ cả Bảo trì và Sửa chữa

class PhanCongBaoTriController extends ChangeNotifier {
  List<NhanVienRutGon> dsNhanVien = [];
  /// Chọn nhiều nhân viên (tích / bỏ tích).
  final Set<int> maNhanVienDaChon = {};

  String? tenNguoiPhanCong;
  int? maNguoiPhanCong;

  // Hồ sơ bảo trì (khi !isSuaChua)
  HoSoBaoTri? hoSo;
  // Hồ sơ sửa chữa (khi isSuaChua)
  HoSoSuaChua? hoSoSc;

  TimeOfDay? gioBatDau;
  TimeOfDay? gioKetThuc;
  DateTime? ngayDuKien;

  bool dangTai = true;
  bool dangLuu = false;
  String? loi;
  bool isCapNhat = false;
  bool isSuaChua = false;

  String get tenThietBiHienThi {
    if (isSuaChua) return hoSoSc?.tenThietBi ?? '—';
    return hoSo?.tenThietBi ?? '—';
  }

  String get maHoSoHienThi {
    if (isSuaChua) return '#${hoSoSc?.maHoSoSuaChua ?? ''}';
    return '#${hoSo?.maHoSoBaoTri ?? ''}';
  }

  TimeOfDay? _parseGio(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final p = s.trim().split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> khoiTao(
      int maHoSo, {
        bool capNhat = false,
        bool suaChua = false,
      }) async {
    isCapNhat = capNhat;
    isSuaChua = suaChua;
    dangTai = true;
    loi = null;
    maNhanVienDaChon.clear();
    notifyListeners();
    try {
      if (isSuaChua) {
        hoSoSc = await WorkOrderService.layChiTietHoSoSuaChua(maHoSo);
        // SC không có giờ cố định trên hồ sơ → mặc định hôm nay 08:00–17:00
        ngayDuKien = DateTime.now();
        gioBatDau = const TimeOfDay(hour: 8, minute: 0);
        gioKetThuc = const TimeOfDay(hour: 17, minute: 0);

        if (isCapNhat && hoSoSc != null && hoSoSc!.maNhanVienThucHiens.isNotEmpty) {
          maNhanVienDaChon.addAll(hoSoSc!.maNhanVienThucHiens);
        }
      } else {
        hoSo = await WorkOrderService.layChiTietHoSoBaoTri(maHoSo);
        gioBatDau = _parseGio(hoSo!.gioBatDauDuKien);
        gioKetThuc = _parseGio(hoSo!.gioKetThucDuKien);
        ngayDuKien = hoSo!.ngayDuKienBaoTri ?? DateTime.now();

        if (gioBatDau == null || gioKetThuc == null) {
          loi =
          'Hồ sơ chưa có giờ bắt đầu/kết thúc. Vui lòng sửa hồ sơ trước khi phân công.';
        }

        if (isCapNhat && hoSo != null) {
          if (hoSo!.maNhanVienThucHiens.isNotEmpty) {
            maNhanVienDaChon.addAll(hoSo!.maNhanVienThucHiens);
          } else if (hoSo!.maNhanVienThucHien != null) {
            maNhanVienDaChon.add(hoSo!.maNhanVienThucHien!);
          }
        }
      }

      dsNhanVien = await WorkOrderService.layDanhSachNhanVienKyThuat();
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

  /// Cho phép chọn ngày khi phân công SC (BT lấy từ hồ sơ).
  void datNgayDuKien(DateTime d) {
    if (!isSuaChua) return;
    ngayDuKien = d;
    notifyListeners();
  }

  void datGioBatDau(TimeOfDay t) {
    if (!isSuaChua) return;
    gioBatDau = t;
    notifyListeners();
  }

  void datGioKetThuc(TimeOfDay t) {
    if (!isSuaChua) return;
    gioKetThuc = t;
    notifyListeners();
  }

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

  Future<bool> xacNhan(int maHoSo) async {
    if (maNhanVienDaChon.isEmpty) {
      loi = 'Vui lòng chọn ít nhất một nhân viên thực hiện';
      notifyListeners();
      return false;
    }
    if (gioBatDau == null || gioKetThuc == null) {
      loi = 'Thiếu giờ bắt đầu/kết thúc — không thể phân công';
      notifyListeners();
      return false;
    }
    if (thoiDiemKetThuc.isBefore(thoiDiemBatDau)) {
      loi = 'Giờ kết thúc phải sau giờ bắt đầu';
      notifyListeners();
      return false;
    }

    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      if (isSuaChua) {
        await WorkOrderService.phanCongSuaChua(
          maHoSoSuaChua: maHoSo,
          maNhanVienThucHiens: maNhanVienDaChon.toList(),
          ngayBatDau: thoiDiemBatDau,
          ngayKetThuc: thoiDiemKetThuc,
        );
      } else {
        await WorkOrderService.phanCongBaoTri(
          maHoSoBaoTri: maHoSo,
          maNhanVienThucHiens: maNhanVienDaChon.toList(),
          ngayBatDau: thoiDiemBatDau,
          ngayKetThuc: thoiDiemKetThuc,
        );
      }
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