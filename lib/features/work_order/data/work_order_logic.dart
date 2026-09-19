import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';

// ============================================================
// MODEL
// ============================================================

class NhanVienRutGon {
  final int maNhanVien;
  final String hoTen;
  final String? email;
  final String? soDienThoai;
  final String? chucVu;
  final String? tenVaiTro;
  /// Số thiết bị đang BT/SC (Đang thực hiện)
  final int soCongViecDangLam;

  NhanVienRutGon({
    required this.maNhanVien,
    required this.hoTen,
    this.email,
    this.soDienThoai,
    this.chucVu,
    this.tenVaiTro,
    this.soCongViecDangLam = 0,
  });

  factory NhanVienRutGon.fromJson(Map<String, dynamic> j) => NhanVienRutGon(
    maNhanVien: (j['maNhanVien'] as num?)?.toInt() ?? 0,
    hoTen: j['hoTen']?.toString() ?? '',
    email: j['email']?.toString(),
    soDienThoai: j['soDienThoai']?.toString(),
    chucVu: j['chucVu']?.toString(),
    tenVaiTro: j['tenVaiTro']?.toString(),
    soCongViecDangLam: (j['soCongViecDangLam'] as num?)?.toInt() ?? 0,
  );
}



class HoSoBaoTri {
  final int maHoSoBaoTri;
  final int maThietBi;
  final String tenThietBi;
  final String? tenNhanVienTao;
  final String? noiDungCongViec;
  final String? thoiGianDuKien;
  final String? gioBatDauDuKien;
  final String? gioKetThucDuKien;
  final DateTime? ngayDuKienBaoTri;
  final DateTime ngayTao;
  final DateTime? ngayDuyet;
  final String trangThai;
  final String? lyDoTuChoi;
  final int? maPhanCong;
  final int nam;
  final bool namTuKeHoach;
  final String? rowVersion;

  HoSoBaoTri({
    required this.maHoSoBaoTri,
    required this.maThietBi,
    required this.tenThietBi,
    this.tenNhanVienTao,
    this.noiDungCongViec,
    this.thoiGianDuKien,
    this.gioBatDauDuKien,
    this.gioKetThucDuKien,
    this.ngayDuKienBaoTri,
    required this.ngayTao,
    this.ngayDuyet,
    required this.trangThai,
    this.lyDoTuChoi,
    this.maPhanCong,
    required this.nam,
    required this.namTuKeHoach,
    this.rowVersion,
  });

  bool get choDuyet => trangThai == 'Chờ duyệt';
  bool get daDuyetChuaPhanCong => trangThai == 'Đã duyệt' && maPhanCong == null;
  bool get daDuyetChoXacNhan => trangThai == 'Đã duyệt' && maPhanCong != null;
  bool get dangThucHien => trangThai == 'Đang thực hiện';
  bool get biTuChoi => trangThai == 'Từ chối';
  bool get daHoanThanh => trangThai == 'Đã hoàn thành';

  factory HoSoBaoTri.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
    int? asIntN(dynamic v) => (v as num?)?.toInt();
    DateTime? asDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final ngayTao = asDate(j['ngayTao'] ?? j['NgayTao']) ?? DateTime.now();

    return HoSoBaoTri(
      maHoSoBaoTri: asInt(j['maHoSoBaoTri'] ?? j['MaHoSoBaoTri']),
      maThietBi: asInt(j['maThietBi'] ?? j['MaThietBi'] ?? j['maThieBi'] ?? j['MaThieBi']),
      tenThietBi: (j['tenThietBi'] ?? j['TenThietBi'])?.toString() ?? '',
      tenNhanVienTao: (j['tenNhanVienTao'] ?? j['TenNhanVienTao'])?.toString(),
      noiDungCongViec: (j['noiDungCongViec'] ?? j['NoiDungCongViec'])?.toString(),
      thoiGianDuKien: (j['thoiGianDuKien'] ?? j['ThoiGianDuKien'])?.toString(),
      gioBatDauDuKien: (j['gioBatDauDuKien'] ?? j['GioBatDauDuKien'])?.toString(),
      gioKetThucDuKien: (j['gioKetThucDuKien'] ?? j['GioKetThucDuKien'])?.toString(),
      ngayDuKienBaoTri: asDate(j['ngayDuKienBaoTri'] ?? j['NgayDuKienBaoTri']),
      ngayTao: ngayTao,
      ngayDuyet: asDate(j['ngayDuyet'] ?? j['NgayDuyet']),
      trangThai: (j['trangThai'] ?? j['TrangThai'])?.toString() ?? '',
      lyDoTuChoi: (j['lyDoTuChoi'] ?? j['LyDoTuChoi'])?.toString(),
      maPhanCong: asIntN(j['maPhanCong'] ?? j['MaPhanCong']),
      nam: asInt(j['nam'] ?? j['Nam'] ?? ngayTao.year),
      namTuKeHoach: (j['namTuKeHoach'] ?? j['NamTuKeHoach']) == true,
      rowVersion: (j['rowVersion'] ?? j['RowVersion'])?.toString(),
    );
  }
}

/// Phân loại trạng thái thành nhóm cố định — presentation tự map ra màu,
/// logic không phụ thuộc Material theme để giữ file này chủ yếu là dữ liệu.
enum TrangThaiHoSoBaoTri { choDuyet, daDuyet, dangThucHien, daHoanThanh, tuChoi, khac }

TrangThaiHoSoBaoTri phanLoaiTrangThaiHoSo(String tt) {
  switch (tt) {
    case 'Chờ duyệt':
      return TrangThaiHoSoBaoTri.choDuyet;
    case 'Đã duyệt':
      return TrangThaiHoSoBaoTri.daDuyet;
    case 'Đang thực hiện':
      return TrangThaiHoSoBaoTri.dangThucHien;
    case 'Đã hoàn thành':
      return TrangThaiHoSoBaoTri.daHoanThanh;
    case 'Từ chối':
      return TrangThaiHoSoBaoTri.tuChoi;
    default:
      return TrangThaiHoSoBaoTri.khac;
  }
}

// ============================================================
// SERVICE (gọi API thuần, không giữ state)
// ============================================================

class WorkOrderService {
  static Future<List<HoSoBaoTri>> layDanhSachHoSoBaoTri({int? nam}) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/bao-tri',
      query: nam != null ? {'nam': nam} : null,
    );
    return data.map((e) => HoSoBaoTri.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<HoSoBaoTri> layChiTietHoSoBaoTri(int id) async {
    final data = await ApiClient.instance.get<dynamic>(
      '${ApiConstants.workOrder}/bao-tri/$id',
    );
    if (data is! Map) {
      throw Exception('API không trả về object');
    }
    return HoSoBaoTri.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<List<int>> layDanhSachNamCoKeHoach() async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.maintenancePlan}/nam-da-lap',
    );
    return data.map((e) => (e as num).toInt()).toList();
  }

  /// MaNhanVienTao KHÔNG gửi lên — server tự lấy từ JWT Claims.
  static Future<void> taoHoSoBaoTri({
    required int maChiTietKeHoach,
    required int maThietBi,
    required String noiDungCongViec,
    required String? thoiGianDuKien,
    required bool guiDuyet,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>('${ApiConstants.workOrder}/bao-tri', {
      'maChiTietKeHoach': maChiTietKeHoach,
      'maThietBi': maThietBi,
      'noiDungCongViec': noiDungCongViec,
      'thoiGianDuKien': thoiGianDuKien,
      'guiDuyet': guiDuyet,
    });
  }

  static Future<List<NhanVienRutGon>> layDanhSachNhanVienKyThuat() async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      ApiConstants.nhanVien,
      query: {'vaiTro': 'Nhân viên kỹ thuật'},
    );
    return data.map((e) => NhanVienRutGon.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// MaNhanVienPhanCong KHÔNG gửi lên — server tự lấy từ JWT (tổ trưởng đang đăng nhập).
  static Future<void> phanCongBaoTri({
    required int maHoSoBaoTri,
    required int maNhanVienThucHien,
    required DateTime ngayBatDau,
    required DateTime ngayKetThuc,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/phan-cong',
      {
        'maNhanVienThucHien': maNhanVienThucHien,
        'ngayBatDauDuKien': ngayBatDau.toIso8601String(),
        'ngayKetThucDuKien': ngayKetThuc.toIso8601String(),
      },
    );
  }
  /// NVKT xác nhận nhận việc → backend: Đã duyệt → Đang thực hiện
  static Future<void> nhanVienXacNhanBaoTri(int maHoSoBaoTri) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/nhan-viec',
      {},
    );
  }

  /// Tổ trưởng sửa hồ sơ bị từ chối rồi gửi lại duyệt
  static Future<void> suaHoSoBiTuChoi({
    required int maHoSoBaoTri,
    required String noiDungCongViec,
    String? thoiGianDuKien,
    String? gioBatDauDuKien,
    String? gioKetThucDuKien,
    DateTime? ngayDuKienBaoTri,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/sua-tu-choi',
      {
        'noiDungCongViec': noiDungCongViec,
        if (thoiGianDuKien != null) 'thoiGianDuKien': thoiGianDuKien,
        if (gioBatDauDuKien != null) 'gioBatDauDuKien': gioBatDauDuKien,
        if (gioKetThucDuKien != null) 'gioKetThucDuKien': gioKetThucDuKien,
        if (ngayDuKienBaoTri != null)
          'ngayDuKienBaoTri':
          '${ngayDuKienBaoTri.year.toString().padLeft(4, '0')}-'
              '${ngayDuKienBaoTri.month.toString().padLeft(2, '0')}-'
              '${ngayDuKienBaoTri.day.toString().padLeft(2, '0')}',
      },
    );
  }
  static Future<List<LichSuPhanCong>> layLichSuPhanCong() async {
    final data = await ApiClient.instance.get<List<dynamic>>('${ApiConstants.workOrder}/phan-cong');
    return data.map((e) => LichSuPhanCong.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Tổ trưởng hủy phân công đang Chờ xác nhận / Từ chối
  static Future<void> huyPhanCong(int maPhanCong) async {
    await ApiClient.instance.delete('${ApiConstants.workOrder}/phan-cong/$maPhanCong');
  }

  /// Yêu cầu được phân công cho NVKT đang đăng nhập
  static Future<List<YeuCauPhanCong>> layYeuCauCuaToi({String? loai, String? trangThai}) async {
    final query = <String, dynamic>{};
    if (loai != null) query['loai'] = loai;
    if (trangThai != null) query['trangThai'] = trangThai;
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/yeu-cau-cua-toi',
      query: query.isEmpty ? null : query,
    );
    return data.map((e) => YeuCauPhanCong.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<YeuCauPhanCong>> layYeuCauDaXacNhan({String? loai}) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/yeu-cau-da-xac-nhan',
      query: loai != null ? {'loai': loai} : null,
    );
    return data.map((e) => YeuCauPhanCong.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> nhanVienTuChoiBaoTri({required int maHoSo, required String lyDo}) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSo/tu-choi-nhan-viec',
      {'lyDo': lyDo},
    );
  }

  static Future<void> nhanVienXacNhanSuaChua(int maHoSo) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/sua-chua/$maHoSo/nhan-viec',
      {},
    );
  }

  static Future<void> nhanVienTuChoiSuaChua({required int maHoSo, required String lyDo}) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/sua-chua/$maHoSo/tu-choi-nhan-viec',
      {'lyDo': lyDo},
    );
  }

  static Future<void> ghiNhanKetQua({
    required int maPhanCong,
    required int maNhanVienGhiNhan,
    String? ghiChu,
    DateTime? ngayGhiNhan,
    String? soLieuGhiNhan,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/phan-cong/$maPhanCong/ket-qua',
      {
        'maNhanVienGhiNhan': maNhanVienGhiNhan,
        if (ghiChu != null) 'ghiChu': ghiChu,
        if (soLieuGhiNhan != null) 'soLieuGhiNhan': soLieuGhiNhan,
        if (ngayGhiNhan != null) 'ngayGhiNhan': ngayGhiNhan.toIso8601String(),
      },
    );
  }
}

class LichSuPhanCong {
  final int maPhanCong;
  final String? tenNhanVienPhanCong;
  final String? tenNhanVienThucHien;
  final String trangThai;
  final String? lyDoTuChoi;
  final DateTime ngayPhanCong;
  final DateTime? gioBatDau;
  final DateTime? gioKetThuc;
  final String? tenThietBi;
  final String? loai;

  LichSuPhanCong({
    required this.maPhanCong,
    this.tenNhanVienPhanCong,
    this.tenNhanVienThucHien,
    required this.trangThai,
    this.lyDoTuChoi,
    required this.ngayPhanCong,
    this.gioBatDau,
    this.gioKetThuc,
    this.tenThietBi,
    this.loai,
  });

  factory LichSuPhanCong.fromJson(Map<String, dynamic> j) => LichSuPhanCong(
    maPhanCong: (j['maPhanCong'] as num?)?.toInt() ?? 0,
    tenNhanVienPhanCong: j['tenNhanVienPhanCong']?.toString(),
    tenNhanVienThucHien: j['tenNhanVienThucHien']?.toString(),
    trangThai: j['trangThai']?.toString() ?? '',
    lyDoTuChoi: j['lyDoTuChoi']?.toString(),
    ngayPhanCong: DateTime.tryParse(j['ngayPhanCong']?.toString() ?? '') ?? DateTime.now(),
    gioBatDau: j['gioBatDau'] != null ? DateTime.tryParse(j['gioBatDau'].toString()) : null,
    gioKetThuc: j['gioKetThuc'] != null ? DateTime.tryParse(j['gioKetThuc'].toString()) : null,
    tenThietBi: j['tenThietBi']?.toString(),
    loai: j['loai']?.toString(),
  );
}

/// Yêu cầu phân công gửi tới NVKT
class YeuCauPhanCong {
  final int maPhanCong;
  final String trangThaiPhanCong;
  final String? lyDoTuChoi;
  final DateTime ngayPhanCong;
  final DateTime? ngayBatDauDuKien;
  final DateTime? ngayKetThucDuKien;
  final String? tenNhanVienPhanCong;
  final String loai; // Bảo trì | Sửa chữa
  final int? maHoSo;
  final int? maThietBi;
  final String? tenThietBi;
  final String? noiDung;
  final String? thoiGianDuKien;
  final String? trangThaiHoSo;
  final DateTime? ngayDuKienBaoTri;
  final DateTime? ngayTaoHoSo;

  YeuCauPhanCong({
    required this.maPhanCong,
    required this.trangThaiPhanCong,
    this.lyDoTuChoi,
    required this.ngayPhanCong,
    this.ngayBatDauDuKien,
    this.ngayKetThucDuKien,
    this.tenNhanVienPhanCong,
    required this.loai,
    this.maHoSo,
    this.maThietBi,
    this.tenThietBi,
    this.noiDung,
    this.thoiGianDuKien,
    this.trangThaiHoSo,
    this.ngayDuKienBaoTri,
    this.ngayTaoHoSo,
  });

  bool get choXacNhan =>
      trangThaiPhanCong == 'Chờ xác nhận' || trangThaiPhanCong == 'Đã phân công';
  bool get daXacNhan => trangThaiPhanCong == 'Xác nhận';
  bool get biTuChoi => trangThaiPhanCong == 'Từ chối';
  bool get daHuy => trangThaiPhanCong == 'Đã hủy';
  bool get laBaoTri => loai == 'Bảo trì';

  factory YeuCauPhanCong.fromJson(Map<String, dynamic> j) {
    DateTime? asDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return YeuCauPhanCong(
      maPhanCong: (j['maPhanCong'] as num?)?.toInt() ?? 0,
      trangThaiPhanCong: j['trangThaiPhanCong']?.toString() ?? '',
      lyDoTuChoi: j['lyDoTuChoi']?.toString(),
      ngayPhanCong: asDate(j['ngayPhanCong']) ?? DateTime.now(),
      ngayBatDauDuKien: asDate(j['ngayBatDauDuKien']),
      ngayKetThucDuKien: asDate(j['ngayKetThucDuKien']),
      tenNhanVienPhanCong: j['tenNhanVienPhanCong']?.toString(),
      loai: j['loai']?.toString() ?? 'Bảo trì',
      maHoSo: (j['maHoSo'] as num?)?.toInt(),
      maThietBi: (j['maThietBi'] as num?)?.toInt(),
      tenThietBi: j['tenThietBi']?.toString(),
      noiDung: j['noiDung']?.toString(),
      thoiGianDuKien: j['thoiGianDuKien']?.toString(),
      trangThaiHoSo: j['trangThaiHoSo']?.toString(),
      ngayDuKienBaoTri: asDate(j['ngayDuKienBaoTri']),
      ngayTaoHoSo: asDate(j['ngayTaoHoSo']),
    );
  }
}

// ============================================================
// CONTROLLERS (toàn bộ state + nghiệp vụ — presentation chỉ gọi & lắng nghe)
// ============================================================

class WorkOrderBaoTriListController extends ChangeNotifier {
  List<HoSoBaoTri> danhSach = [];
  List<int> cacNamCoKeHoach = [];
  bool dangTai = true;
  String? loi;
  int? namLoc;

  Future<void> taiDanhSach() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        WorkOrderService.layDanhSachHoSoBaoTri(nam: namLoc),
        WorkOrderService.layDanhSachNamCoKeHoach(),
      ]);
      danhSach = results[0] as List<HoSoBaoTri>;
      cacNamCoKeHoach = results[1] as List<int>;
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void datNamLoc(int? nam) {
    namLoc = nam;
    taiDanhSach();
  }


  List<HoSoBaoTri> locTheoTab(String tab) =>
      tab == 'Tất cả' ? danhSach : danhSach.where((h) => h.trangThai == tab).toList();
}

class CreateWorkOrderBaoTriController extends ChangeNotifier {
  bool dangLuu = false;
  String? loi;

  /// Trả về true nếu tạo thành công — presentation chỉ cần pop(context, true) khi true.
  Future<bool> luu({
    required int maChiTietKeHoach,
    required int maThietBi,
    required String noiDungCongViec,
    required String thoiGianDuKien,
    required bool guiDuyet,
  }) async {
    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.taoHoSoBaoTri(
        maChiTietKeHoach: maChiTietKeHoach,
        maThietBi: maThietBi,
        noiDungCongViec: noiDungCongViec,
        thoiGianDuKien: thoiGianDuKien,
        guiDuyet: guiDuyet,
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

class PhanCongBaoTriController extends ChangeNotifier {
  List<NhanVienRutGon> dsNhanVien = [];
  NhanVienRutGon? chon;

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

      // 2) Danh sách NVKT
      dsNhanVien = await WorkOrderService.layDanhSachNhanVienKyThuat();
      tenNguoiPhanCong = 'Tổ trưởng đang đăng nhập'; // TODO: lấy từ TokenStorage
    } catch (e) {
      loi = 'Không tải được dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void chonNhanVien(NhanVienRutGon nv) {
    // Bỏ ràng buộc max 3 / dangBan — luôn cho chọn
    chon = nv;
    loi = null;
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

  Future<bool> xacNhan(int maHoSoBaoTri) async {
    if (chon == null) {
      loi = 'Vui lòng chọn nhân viên thực hiện';
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
        maNhanVienThucHien: chon!.maNhanVien,
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

class LichSuPhanCongController extends ChangeNotifier {
  List<LichSuPhanCong> danhSach = [];
  bool dangTai = true;
  bool dangHuy = false;
  String? loi;

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      danhSach = await WorkOrderService.layLichSuPhanCong();
    } catch (e) {
      loi = 'Không tải được lịch sử: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  Future<bool> huyPhanCong(int maPhanCong) async {
    dangHuy = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.huyPhanCong(maPhanCong);
      await tai();
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } catch (e) {
      loi = '$e';
      return false;
    } finally {
      dangHuy = false;
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
      thoiGianDuKien != null && thoiGianDuKien! > 0 && loiThoiGianDuKien == null;

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

  /// Chỉ chấp nhận chuỗi toàn chữ số dương
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
class QuanLyYeuCauController extends ChangeNotifier {
  List<YeuCauPhanCong> danhSach = [];
  bool dangTai = true;
  String? loi;
  String tabLoai = 'Bảo trì'; // Bảo trì | Sửa chữa

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      danhSach = await WorkOrderService.layYeuCauCuaToi(loai: tabLoai);
    } catch (e) {
      loi = 'Không tải được yêu cầu: $e';
      danhSach = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void doiTab(String loai) {
    if (tabLoai == loai) return;
    tabLoai = loai;
    tai();
  }

  List<YeuCauPhanCong> get choXacNhan =>
      danhSach.where((e) => e.choXacNhan).toList();
  List<YeuCauPhanCong> get khac =>
      danhSach.where((e) => !e.choXacNhan).toList();
}

class KetQuaThucHienController extends ChangeNotifier {
  List<YeuCauPhanCong> dsXacNhan = [];
  YeuCauPhanCong? chon;
  DateTime? ngayGhiNhan;
  String ghiChu = '';
  bool dangTai = true;
  bool dangLuu = false;
  String? loi;
  String? loiNgay; // chữ đỏ dưới ngày

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      dsXacNhan = await WorkOrderService.layYeuCauDaXacNhan();
    } catch (e) {
      loi = 'Không tải danh sách: $e';
      dsXacNhan = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void chonYeuCau(YeuCauPhanCong? y) {
    chon = y;
    ngayGhiNhan = null;
    loiNgay = null;
    loi = null;
    notifyListeners();
  }

  void datNgayGhiNhan(DateTime d) {
    ngayGhiNhan = d;
    loiNgay = null;
    if (chon?.ngayDuKienBaoTri != null) {
      final dk = chon!.ngayDuKienBaoTri!;
      if (d.year != dk.year || d.month != dk.month) {
        loiNgay =
        'Ngày ghi nhận phải nằm trong tháng ${dk.month}/${dk.year} (tháng dự kiến bảo trì).';
      }
    }
    notifyListeners();
  }

  Future<bool> xacNhanHoanThanh({required int maNhanVienGhiNhan}) async {
    if (chon == null) {
      loi = 'Vui lòng chọn hồ sơ bảo trì';
      notifyListeners();
      return false;
    }
    if (ngayGhiNhan == null) {
      loi = 'Vui lòng chọn ngày ghi nhận';
      notifyListeners();
      return false;
    }
    if (loiNgay != null) {
      loi = loiNgay;
      notifyListeners();
      return false;
    }

    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.ghiNhanKetQua(
        maPhanCong: chon!.maPhanCong,
        maNhanVienGhiNhan: maNhanVienGhiNhan,
        ghiChu: ghiChu.trim().isEmpty ? null : ghiChu.trim(),
        ngayGhiNhan: ngayGhiNhan,
        soLieuGhiNhan: 'Hoàn thành',
      );
      // Làm mới danh sách
      await tai();
      chon = null;
      ngayGhiNhan = null;
      ghiChu = '';
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } catch (e) {
      loi = '$e';
      return false;
    } finally {
      dangLuu = false;
      notifyListeners();
    }
  }
}