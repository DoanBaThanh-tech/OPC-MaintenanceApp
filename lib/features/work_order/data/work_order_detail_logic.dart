import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'models/work_order_models.dart';
import 'services/work_order_service.dart';
import 'work_order_validators.dart';

// Logic cho work_order_detail_screen.dart (chi tiết + sửa hồ sơ bị từ chối)

class WorkOrderBaoTriDetailController extends ChangeNotifier {
  final int maHoSoBaoTri;
  WorkOrderBaoTriDetailController(this.maHoSoBaoTri);

  HoSoBaoTri? hoSo;
  bool dangTai = true;
  String? loi;
  String? vaiTro;

  bool get laToTruong =>
      vaiTro == 'Tổ trưởng cơ điện' ||
          vaiTro == 'Tổ trưởng kỹ thuật' ||
          vaiTro == 'Tổ trưởng';
  bool get laNvkt => vaiTro == 'Nhân viên kỹ thuật';
  bool get laXuong =>
      vaiTro == 'Xưởng' || vaiTro == 'Tổ trưởng sản xuất';

  Future<void> taiChiTiet() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        WorkOrderService.layChiTietHoSoBaoTri(maHoSoBaoTri),
        TokenStorage.getVaiTro(),
      ]);
      hoSo = results[0] as HoSoBaoTri;
      vaiTro ??= results[1] as String?;
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  Future<bool> nhanVienHoanThanhBaoTri() async {
    try {
      await WorkOrderService.nhanVienHoanThanhBaoTri(maHoSoBaoTri);
      await taiChiTiet();
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<(bool ok, String? message)> xuongGuiGiamDoc({
    required String? noiDungCongViec,
    required String? thoiGianDuKien,
    required String? gioBatDauDuKien,
    required String? gioKetThucDuKien,
  }) async {
    try {
      await WorkOrderService.xuongGuiGiamDoc(
        maHoSoBaoTri: maHoSoBaoTri,
        noiDungCongViec: noiDungCongViec,
        thoiGianDuKien: thoiGianDuKien,
        gioBatDauDuKien: gioBatDauDuKien,
        gioKetThucDuKien: gioKetThucDuKien,
      );
      await taiChiTiet();
      return (true, null);
    } on ApiException catch (e) {
      return (false, e.message);
    }
  }
}

/// Form chỉnh sửa của Xưởng trên hồ sơ Chờ duyệt.
class XuongChinhSuaHoSoController extends ChangeNotifier {
  bool dangChinhSua = false;
  bool dangLuu = false;
  String? loi;
  String? loiThoiGian;

  TimeOfDay? gioBatDau;
  TimeOfDay? gioKetThuc;
  DateTime? ngayDuKien;
  int? soGioDuKien;

  bool get thoiGianHopLe =>
      loiThoiGian == null &&
          soGioDuKien != null &&
          soGioDuKien! > 0 &&
          soGioDuKien! <= 24;

  bool get choPhepChonGio => thoiGianHopLe;

  TimeOfDay? _parseGio(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final p = s.trim().split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? fmtGio(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void batDauChinhSua(HoSoBaoTri hs, {required String thoiGianText}) {
    ngayDuKien = hs.ngayDuKienBaoTri;
    gioBatDau = _parseGio(hs.gioBatDauDuKien);
    gioKetThuc = _parseGio(hs.gioKetThucDuKien);
    datThoiGianTuChuoi(thoiGianText);
    if (!thoiGianHopLe) {
      gioBatDau = null;
      gioKetThuc = null;
    }
    dangChinhSua = true;
    loi = null;
    notifyListeners();
  }

  void huyChinhSua() {
    dangChinhSua = false;
    loi = null;
    loiThoiGian = null;
    notifyListeners();
  }

  void datThoiGianTuChuoi(String raw) {
    final kq = validateSoGioDuKien(raw);
    loiThoiGian = kq.loi;
    soGioDuKien = kq.soGio;
    if (!thoiGianHopLe) {
      gioBatDau = null;
      gioKetThuc = null;
    } else if (gioBatDau != null) {
      _tinhGioKetThuc();
    }
    notifyListeners();
  }

  void datGioBatDau(TimeOfDay t) {
    if (!choPhepChonGio) {
      loi = 'Nhập đúng số giờ dự kiến trước khi chọn giờ bắt đầu';
      notifyListeners();
      return;
    }
    gioBatDau = t;
    loi = null;
    _tinhGioKetThuc();
    notifyListeners();
  }

  void datNgayDuKien(DateTime d) {
    ngayDuKien = d;
    notifyListeners();
  }

  void _tinhGioKetThuc() {
    if (!thoiGianHopLe || gioBatDau == null || soGioDuKien == null) {
      if (!thoiGianHopLe) gioKetThuc = null;
      return;
    }
    final tongPhut =
        gioBatDau!.hour * 60 + gioBatDau!.minute + soGioDuKien! * 60;
    gioKetThuc = TimeOfDay(hour: (tongPhut ~/ 60) % 24, minute: tongPhut % 60);
  }

  Future<bool> luu({
    required int maHoSoBaoTri,
    required String noiDungCongViec,
    required String thoiGianText,
  }) async {
    final noiDung = noiDungCongViec.trim();
    if (noiDung.isEmpty) {
      loi = 'Vui lòng nhập nội dung công việc';
      notifyListeners();
      return false;
    }
    datThoiGianTuChuoi(thoiGianText);
    if (loiThoiGian != null) {
      notifyListeners();
      return false;
    }
    if (gioBatDau == null) {
      loi = 'Vui lòng chọn giờ bắt đầu';
      notifyListeners();
      return false;
    }
    _tinhGioKetThuc();
    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.xuongLuuHoSo(
        maHoSoBaoTri: maHoSoBaoTri,
        noiDungCongViec: noiDung,
        thoiGianDuKien: thoiGianText.trim(),
        gioBatDauDuKien: fmtGio(gioBatDau),
        gioKetThucDuKien: fmtGio(gioKetThuc),
        ngayDuKienBaoTri: ngayDuKien,
      );
      dangChinhSua = false;
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

class SuaHoSoBiTuChoiController extends ChangeNotifier {
  bool dangLuu = false;
  String? loi;

  int? thoiGianDuKien;          // số giờ > 0
  String? loiThoiGianDuKien;    // lỗi đỏ dưới ô giờ
  TimeOfDay? gioBatDau;
  TimeOfDay? gioKetThuc;        // chỉ tự tính, không chọn tay
  DateTime? ngayDuKienBaoTri;

  /// true khi số giờ hợp lệ → mới cho chọn giờ bắt đầu
  bool get choPhepChonGioBatDau =>
      thoiGianDuKien != null &&
          thoiGianDuKien! > 0 &&
          thoiGianDuKien! <= 24 &&
          loiThoiGianDuKien == null;

  void khoiTaoTuHoSo({
    String? thoiGianDuKienStr,
    String? gioBatDauStr,   // "15:00"
    String? gioKetThucStr,
    DateTime? ngayDuKien,
  }) {
    ngayDuKienBaoTri = ngayDuKien;
    if (thoiGianDuKienStr != null && thoiGianDuKienStr.trim().isNotEmpty) {
      datThoiGianDuKienTuChuoi(thoiGianDuKienStr);
    }
    if (gioBatDauStr != null) {
      final p = gioBatDauStr.split(':');
      if (p.length >= 2) {
        final h = int.tryParse(p[0]);
        final m = int.tryParse(p[1]);
        if (h != null && m != null) {
          gioBatDau = TimeOfDay(hour: h, minute: m);
          _tinhGioKetThuc();
        }
      }
    }
    notifyListeners();
  }

  /// Số nguyên dương 1–24 — dùng validator chung.
  void datThoiGianDuKienTuChuoi(String raw) {
    final kq = validateSoGioDuKien(raw);
    thoiGianDuKien = kq.soGio;
    loiThoiGianDuKien = kq.loi;
    if (kq.loi != null) {
      gioKetThuc = null;
    } else {
      _tinhGioKetThuc();
    }
    notifyListeners();
  }

  void datGioBatDau(TimeOfDay t) {
    if (!choPhepChonGioBatDau) {
      loi = 'Nhập đúng số giờ dự kiến trước khi chọn giờ bắt đầu';
      notifyListeners();
      return;
    }
    gioBatDau = t;
    loi = null;
    _tinhGioKetThuc();
    notifyListeners();
  }

  void datNgayDuKien(DateTime d) {
    ngayDuKienBaoTri = d;
    notifyListeners();
  }

  void _tinhGioKetThuc() {
    if (gioBatDau == null || thoiGianDuKien == null) {
      gioKetThuc = null;
      return;
    }
    final tongPhut = gioBatDau!.hour * 60 + gioBatDau!.minute + thoiGianDuKien! * 60;
    gioKetThuc = TimeOfDay(hour: (tongPhut ~/ 60) % 24, minute: tongPhut % 60);
  }

  String? _fmtGio(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> luu({
    required int maHoSoBaoTri,
    required String noiDungCongViec,
    String? thoiGianDuKien,
    String? gioBatDauDuKien,
    String? gioKetThucDuKien,
    DateTime? ngayDuKienBaoTri,
  }) async {
    if (noiDungCongViec.trim().isEmpty) {
      loi = 'Vui lòng nhập nội dung công việc';
      notifyListeners();
      return false;
    }

    final soGio = thoiGianDuKien ?? this.thoiGianDuKien?.toString();
    final gbd = gioBatDauDuKien ?? _fmtGio(gioBatDau);
    final gkt = gioKetThucDuKien ?? _fmtGio(gioKetThuc);
    final ngay = ngayDuKienBaoTri ?? this.ngayDuKienBaoTri;

    if (soGio == null || soGio.isEmpty) {
      loi = 'Vui lòng nhập số giờ dự kiến hợp lệ';
      notifyListeners();
      return false;
    }
    final soGioInt = int.tryParse(soGio.trim());
    if (soGioInt == null || soGioInt <= 0) {
      loi = 'Giờ dự kiến phải là số dương lớn hơn 0';
      notifyListeners();
      return false;
    }
    if (soGioInt > 24) {
      loi = 'Bảo trì trong ngày — tối đa 24 giờ';
      notifyListeners();
      return false;
    }
    if (gbd == null) {
      loi = 'Vui lòng chọn giờ bắt đầu';
      notifyListeners();
      return false;
    }
    if (gkt == null) {
      loi = 'Chưa tính được giờ kết thúc';
      notifyListeners();
      return false;
    }

    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.suaHoSoBiTuChoi(
        maHoSoBaoTri: maHoSoBaoTri,
        noiDungCongViec: noiDungCongViec.trim(),
        thoiGianDuKien: soGio,
        gioBatDauDuKien: gbd,
        gioKetThucDuKien: gkt,
        ngayDuKienBaoTri: ngay,
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