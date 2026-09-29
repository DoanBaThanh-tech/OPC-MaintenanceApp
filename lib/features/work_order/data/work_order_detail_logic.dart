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
  /// Tháng/năm kế hoạch ban đầu — không được đổi khi sửa.
  DateTime? ngayDuKienGoc;
  DateTime? ngayTaoHoSo;
  int? soGioDuKien;
  int? soPhutDuKien;
  bool nhapPhut = false;

  bool get thoiGianHopLe {
    if (loiThoiGian != null) return false;
    if (nhapPhut) return soPhutDuKien != null && soPhutDuKien! > 0;
    return soGioDuKien != null && soGioDuKien! > 0 && soGioDuKien! <= 24;
  }

  bool get choPhepChonGio => thoiGianHopLe;

  String get chuoiThoiGianLuu {
    if (nhapPhut && soPhutDuKien != null) return '${soPhutDuKien}p';
    return '${soGioDuKien ?? ''}';
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

  String? fmtGio(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void batDauChinhSua(HoSoBaoTri hs, {required String thoiGianText}) {
    ngayDuKien = hs.ngayDuKienBaoTri;
    ngayDuKienGoc = hs.ngayDuKienBaoTri;
    ngayTaoHoSo = hs.ngayTao;
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

  void datDonViThoiGian({required bool laPhut}) {
    nhapPhut = laPhut;
    notifyListeners();
  }

  void datThoiGianTuChuoi(String raw) {
    // Tự nhận "15p" từ dữ liệu cũ
    final rawLower = raw.trim().toLowerCase();
    if (rawLower.endsWith('p') || rawLower.contains('phút')) {
      nhapPhut = true;
    }
    final kq = validateThoiGianDuKien(raw, laPhut: nhapPhut);
    loiThoiGian = kq.loi;
    if (kq.laPhut) {
      soPhutDuKien = kq.soPhut;
      soGioDuKien = null;
      nhapPhut = true;
    } else {
      soGioDuKien = kq.soGio;
      soPhutDuKien = null;
      if (kq.hopLe) nhapPhut = false;
    }
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
      loi = 'Nhập đúng thời gian dự kiến trước khi chọn giờ bắt đầu';
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
    loi = _kiemTraNgayDuKien(d);
    notifyListeners();
  }

  /// Khóa đúng tháng kế hoạch; ngày dự kiến > ngày tạo.
  String? _kiemTraNgayDuKien(DateTime? ngayMoi) {
    if (ngayMoi == null) return null;
    final goc = ngayDuKienGoc;
    final tao = ngayTaoHoSo;
    if (tao != null) {
      final taoOnly = DateTime(tao.year, tao.month, tao.day);
      final moiOnly = DateTime(ngayMoi.year, ngayMoi.month, ngayMoi.day);
      if (!moiOnly.isAfter(taoOnly)) {
        return 'Ngày dự kiến phải lớn hơn ngày tạo '
            '(${taoOnly.day.toString().padLeft(2, '0')}/'
            '${taoOnly.month.toString().padLeft(2, '0')}/${taoOnly.year}). '
            'Không được đặt trùng hoặc trước ngày tạo.';
      }
    }
    if (goc != null &&
        (ngayMoi.month != goc.month || ngayMoi.year != goc.year)) {
      return 'Hồ sơ đang lập bảo trì cho tháng ${goc.month}/${goc.year}. '
          'Không được chuyển sang tháng ${ngayMoi.month}/${ngayMoi.year} '
          '(ví dụ không được sửa về ngày tạo thuộc tháng khác). '
          'Chỉ được chọn ngày trong đúng tháng kế hoạch.';
    }
    return null;
  }

  void _tinhGioKetThuc() {
    final phutThem = nhapPhut ? (soPhutDuKien ?? 0) : (soGioDuKien ?? 0) * 60;
    if (!thoiGianHopLe || gioBatDau == null || phutThem <= 0) {
      if (!thoiGianHopLe) gioKetThuc = null;
      return;
    }
    final tongPhut = gioBatDau!.hour * 60 + gioBatDau!.minute + phutThem;
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
    final loiNgay = _kiemTraNgayDuKien(ngayDuKien);
    if (loiNgay != null) {
      loi = loiNgay;
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
        thoiGianDuKien: chuoiThoiGianLuu,
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

  int? thoiGianDuKien; // số giờ (khi !nhapPhut)
  int? thoiGianPhut; // số phút (khi nhapPhut)
  bool nhapPhut = false;
  String? loiThoiGianDuKien;
  TimeOfDay? gioBatDau;
  TimeOfDay? gioKetThuc; // tự tính từ bắt đầu + thời lượng
  DateTime? ngayDuKienBaoTri;

  /// true khi thời lượng hợp lệ → mới cho chọn giờ bắt đầu
  bool get choPhepChonGioBatDau {
    if (loiThoiGianDuKien != null) return false;
    if (nhapPhut) return thoiGianPhut != null && thoiGianPhut! > 0;
    return thoiGianDuKien != null &&
        thoiGianDuKien! > 0 &&
        thoiGianDuKien! <= 24;
  }

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

  void datDonViThoiGian({required bool laPhut}) {
    nhapPhut = laPhut;
    notifyListeners();
  }

  /// Số nguyên dương — giờ (1–24) hoặc phút (1–1440).
  void datThoiGianDuKienTuChuoi(String raw) {
    final kq = validateThoiGianDuKien(raw, laPhut: nhapPhut);
    loiThoiGianDuKien = kq.loi;
    if (kq.loi != null) {
      thoiGianDuKien = null;
      thoiGianPhut = null;
      gioKetThuc = null;
    } else if (kq.laPhut) {
      thoiGianPhut = kq.soPhut;
      thoiGianDuKien = null;
      nhapPhut = true;
      _tinhGioKetThuc();
    } else {
      thoiGianDuKien = kq.soGio;
      thoiGianPhut = null;
      nhapPhut = false;
      _tinhGioKetThuc();
    }
    notifyListeners();
  }

  void datGioBatDau(TimeOfDay t) {
    if (!choPhepChonGioBatDau) {
      loi = 'Nhập đúng thời gian dự kiến (giờ hoặc phút) trước khi chọn giờ bắt đầu';
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
    final phutThem = nhapPhut
        ? (thoiGianPhut ?? 0)
        : (thoiGianDuKien ?? 0) * 60;
    if (gioBatDau == null || phutThem <= 0) {
      gioKetThuc = null;
      return;
    }
    final tongPhut =
        gioBatDau!.hour * 60 + gioBatDau!.minute + phutThem;
    gioKetThuc =
        TimeOfDay(hour: (tongPhut ~/ 60) % 24, minute: tongPhut % 60);
  }

  /// Chuỗi lưu API: "4" hoặc "15p"
  String? get chuoiThoiGianLuu {
    if (nhapPhut && thoiGianPhut != null) return '${thoiGianPhut}p';
    if (thoiGianDuKien != null) return '$thoiGianDuKien';
    return null;
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
    DateTime? ngayDuKienGoc,
    DateTime? ngayTao,
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
    final goc = ngayDuKienGoc ?? this.ngayDuKienBaoTri;
    if (ngay != null && ngayTao != null) {
      final taoOnly = DateTime(ngayTao.year, ngayTao.month, ngayTao.day);
      final moiOnly = DateTime(ngay.year, ngay.month, ngay.day);
      if (!moiOnly.isAfter(taoOnly)) {
        loi =
        'Ngày dự kiến phải lớn hơn ngày tạo — không được đặt trùng ngày tạo.';
        notifyListeners();
        return false;
      }
    }
    if (ngay != null &&
        goc != null &&
        (ngay.month != goc.month || ngay.year != goc.year)) {
      loi =
      'Hồ sơ lập cho tháng ${goc.month}/${goc.year} — không được chuyển sang tháng ${ngay.month}/${ngay.year}.';
      notifyListeners();
      return false;
    }

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