import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../core/network/api_exception.dart';
import 'models/work_order_models.dart';
import 'services/material_usage_service.dart';
import 'services/work_order_service.dart';

// Logic cho work_order_assign_screen.dart — hỗ trợ cả Bảo trì và Sửa chữa

class PhanCongBaoTriController extends ChangeNotifier {
  List<NhanVienRutGon> dsNhanVien = [];
  /// Chọn nhiều nhân viên (tích / bỏ tích).
  final Set<int> maNhanVienDaChon = {};

  /// Người ghi chép quy trình (tối đa 1, phải nằm trong maNhanVienDaChon).
  int? maNhanVienGhiChep;

  /// Người ghi chép hiện tại khi mở chế độ cập nhật (để khóa).
  int? maNhanVienGhiChepGoc;

  /// true = người ghi chép đã tiến hành quy trình → không đổi / không bỏ.
  bool khoaNguoiGhiChep = false;

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

  static const _msgKhoaGhiChep =
      'Người ghi chép đã tiến hành quy trình — không được đổi / bỏ người ghi chép. Chỉ được cập nhật trước khi tiến hành quy trình.';

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
    maNhanVienGhiChep = null;
    maNhanVienGhiChepGoc = null;
    khoaNguoiGhiChep = false;
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
          maNhanVienGhiChep = maNhanVienDaChon.isNotEmpty
              ? maNhanVienDaChon.first
              : null;
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
          maNhanVienGhiChep =
          maNhanVienDaChon.isNotEmpty ? maNhanVienDaChon.first : null;
        }
      }

      dsNhanVien = await WorkOrderService.layDanhSachNhanVienKyThuat();
      tenNguoiPhanCong = 'Tổ trưởng đang đăng nhập';

      // Cập nhật: khóa người ghi chép nếu đã có hồ sơ vật tư (đã tiến hành quy trình)
      if (isCapNhat) {
        maNhanVienGhiChepGoc = maNhanVienGhiChep;
        try {
          final hsVt = await MaterialUsageService.layHoSoTheoCongViec(
            maHoSoBaoTri: isSuaChua ? null : maHoSo,
            maHoSoSuaChua: isSuaChua ? maHoSo : null,
          );
          if (hsVt != null) {
            khoaNguoiGhiChep = true;
          }
        } catch (_) {
          // Không chặn nếu API lỗi — server vẫn validate
        }
        // Hồ sơ SC/BT đang chờ Xưởng cũng khóa
        final ttPc = isSuaChua
            ? (hoSoSc?.trangThaiPhanCong ?? hoSoSc?.trangThai)
            : (hoSo?.trangThaiPhanCong ?? hoSo?.trangThai);
        if (ttPc == 'Chờ xác nhận' || ttPc == 'Đang thực hiện') {
          // Đang thực hiện + đã có phân công: chỉ khóa khi đã có HS vật tư
          // hoặc chờ xác nhận (đã gửi quy trình)
          if (ttPc == 'Chờ xác nhận') khoaNguoiGhiChep = true;
        }
      }
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
    // Không cho bỏ người ghi chép đã khóa khỏi danh sách phân công
    if (khoaNguoiGhiChep &&
        maNhanVienGhiChepGoc != null &&
        nv.maNhanVien == maNhanVienGhiChepGoc &&
        maNhanVienDaChon.contains(nv.maNhanVien)) {
      loi = _msgKhoaGhiChep;
      notifyListeners();
      return;
    }
    if (maNhanVienDaChon.contains(nv.maNhanVien)) {
      maNhanVienDaChon.remove(nv.maNhanVien);
      if (maNhanVienGhiChep == nv.maNhanVien) {
        maNhanVienGhiChep =
        maNhanVienDaChon.isEmpty ? null : maNhanVienDaChon.first;
      }
    } else {
      maNhanVienDaChon.add(nv.maNhanVien);
      // 1 người → auto ghi chép
      if (maNhanVienDaChon.length == 1) {
        maNhanVienGhiChep = nv.maNhanVien;
      }
    }
    loi = null;
    notifyListeners();
  }

  bool daChon(int maNhanVien) => maNhanVienDaChon.contains(maNhanVien);

  /// Chọn người ghi chép (phải đã được tick phân công).
  void chonNguoiGhiChep(int maNhanVien) {
    if (!maNhanVienDaChon.contains(maNhanVien)) return;
    if (khoaNguoiGhiChep &&
        maNhanVienGhiChepGoc != null &&
        maNhanVien != maNhanVienGhiChepGoc) {
      loi = _msgKhoaGhiChep;
      notifyListeners();
      return;
    }
    maNhanVienGhiChep = maNhanVien;
    loi = null;
    notifyListeners();
  }

  bool laNguoiGhiChep(int maNhanVien) => maNhanVienGhiChep == maNhanVien;

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
    // Không còn chọn người ghi chép — mọi NV phân công đều làm quy trình
    maNhanVienGhiChep =
    maNhanVienDaChon.isNotEmpty ? maNhanVienDaChon.first : null;
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
          maNhanVienGhiChep: maNhanVienGhiChep,
          ngayBatDau: thoiDiemBatDau,
          ngayKetThuc: thoiDiemKetThuc,
        );
      } else {
        await WorkOrderService.phanCongBaoTri(
          maHoSoBaoTri: maHoSo,
          maNhanVienThucHiens: maNhanVienDaChon.toList(),
          maNhanVienGhiChep: maNhanVienGhiChep,
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