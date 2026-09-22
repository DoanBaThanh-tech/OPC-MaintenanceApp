import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../core/network/api_exception.dart';
import 'models/work_order_models.dart';
import 'services/work_order_service.dart';

// Logic cho work_order_detail_screen.dart (chi tiết + sửa hồ sơ bị từ chối)

class WorkOrderBaoTriDetailController extends ChangeNotifier {
  final int maHoSoBaoTri;
  WorkOrderBaoTriDetailController(this.maHoSoBaoTri);

  HoSoBaoTri? hoSo;
  bool dangTai = true;
  String? loi;

  Future<void> taiChiTiet() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      hoSo = await WorkOrderService.layChiTietHoSoBaoTri(maHoSoBaoTri);
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
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

  /// Số dương, không ký tự đặc biệt, tối đa 24 giờ trong ngày
  void datThoiGianDuKienTuChuoi(String raw) {
    final v = raw.trim();
    if (v.isEmpty) {
      thoiGianDuKien = null;
      loiThoiGianDuKien = 'Vui lòng nhập số giờ dự kiến';
      gioKetThuc = null;
      notifyListeners();
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(v)) {
      thoiGianDuKien = null;
      loiThoiGianDuKien = 'Chỉ được nhập số dương (không chữ, không ký tự đặc biệt)';
      gioKetThuc = null;
      notifyListeners();
      return;
    }
    final so = int.tryParse(v);
    if (so == null || so <= 0) {
      thoiGianDuKien = null;
      loiThoiGianDuKien = 'Giờ dự kiến phải lớn hơn 0';
      gioKetThuc = null;
      notifyListeners();
      return;
    }
    if (so > 24) {
      thoiGianDuKien = null;
      loiThoiGianDuKien = 'Bảo trì trong ngày — tối đa 24 giờ';
      gioKetThuc = null;
      notifyListeners();
      return;
    }
    thoiGianDuKien = so;
    loiThoiGianDuKien = null;
    _tinhGioKetThuc();
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