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

  NhanVienRutGon({
    required this.maNhanVien,
    required this.hoTen,
    this.email,
    this.soDienThoai,
    this.chucVu,
    this.tenVaiTro,
  });

  factory NhanVienRutGon.fromJson(Map<String, dynamic> j) => NhanVienRutGon(
        maNhanVien: (j['maNhanVien'] as num?)?.toInt() ?? 0,
        hoTen: j['hoTen']?.toString() ?? '',
        email: j['email']?.toString(),
        soDienThoai: j['soDienThoai']?.toString(),
        chucVu: j['chucVu']?.toString(),
        tenVaiTro: j['tenVaiTro']?.toString(),
      );
}

class HoSoBaoTri {
  final int maHoSoBaoTri;
  final int maThietBi;
  final String tenThietBi;
  final String? tenNhanVienTao;
  final String? noiDungCongViec;
  final String? thoiGianDuKien;
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
  bool get dangThucHien => trangThai == 'Đang thực hiện';
  bool get biTuChoi => trangThai == 'Từ chối';

  factory HoSoBaoTri.fromJson(Map<String, dynamic> j) => HoSoBaoTri(
        maHoSoBaoTri: (j['maHoSoBaoTri'] as num?)?.toInt() ?? 0,
        maThietBi: (j['maThietBi'] as num?)?.toInt() ?? (j['maThieBi'] as num?)?.toInt() ?? 0,
        tenThietBi: j['tenThietBi']?.toString() ?? '',
        tenNhanVienTao: j['tenNhanVienTao']?.toString(),
        noiDungCongViec: j['noiDungCongViec']?.toString(),
        thoiGianDuKien: j['thoiGianDuKien']?.toString(),
        ngayDuKienBaoTri: j['ngayDuKienBaoTri'] != null
            ? DateTime.tryParse(j['ngayDuKienBaoTri'].toString())
            : null,
        ngayTao: DateTime.parse(j['ngayTao'].toString()),
        ngayDuyet: j['ngayDuyet'] != null ? DateTime.tryParse(j['ngayDuyet'].toString()) : null,
        trangThai: j['trangThai']?.toString() ?? '',
        lyDoTuChoi: j['lyDoTuChoi']?.toString(),
        maPhanCong: (j['maPhanCong'] as num?)?.toInt(),
        nam: (j['nam'] as num?)?.toInt() ?? DateTime.now().year,
        namTuKeHoach: j['namTuKeHoach'] == true,
        rowVersion: j['rowVersion']?.toString(),
      );
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
    final data = await ApiClient.instance.get<Map<String, dynamic>>('${ApiConstants.workOrder}/bao-tri/$id');
    return HoSoBaoTri.fromJson(data);
  }

  static Future<List<int>> layDanhSachNamCoKeHoach() async {
    final data = await ApiClient.instance.get<List<dynamic>>('${ApiConstants.maintenancePlan}/nam-da-lap');
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

  // Người phân công (lấy từ user đang đăng nhập)
  String? tenNguoiPhanCong;
  int? maNguoiPhanCong;

  DateTime ngayBatDau = DateTime.now();
  TimeOfDay gioBatDau = const TimeOfDay(hour: 8, minute: 0);

  DateTime ngayKetThuc = DateTime.now();
  TimeOfDay gioKetThuc = const TimeOfDay(hour: 17, minute: 0);

  bool dangTai = true;
  bool dangLuu = false;
  String? loi;

  Future<void> taiNhanVien() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      dsNhanVien = await WorkOrderService.layDanhSachNhanVienKyThuat();

      // TODO: Lấy thông tin người đang đăng nhập từ AuthService / SharedPreferences
      tenNguoiPhanCong = 'Tổ trưởng đang đăng nhập'; // tạm thời
    } catch (e) {
      loi = 'Không tải được danh sách nhân viên: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void chonNhanVien(NhanVienRutGon nv) {
    chon = nv;
    notifyListeners();
  }

  void datNgayBatDau(DateTime d) {
    ngayBatDau = d;
    notifyListeners();
  }

  void datGioBatDau(TimeOfDay t) {
    gioBatDau = t;
    notifyListeners();
  }

  void datNgayKetThuc(DateTime d) {
    ngayKetThuc = d;
    notifyListeners();
  }

  void datGioKetThuc(TimeOfDay t) {
    gioKetThuc = t;
    notifyListeners();
  }

  DateTime get thoiDiemBatDau => DateTime(
        ngayBatDau.year,
        ngayBatDau.month,
        ngayBatDau.day,
        gioBatDau.hour,
        gioBatDau.minute,
      );

  DateTime get thoiDiemKetThuc => DateTime(
        ngayKetThuc.year,
        ngayKetThuc.month,
        ngayKetThuc.day,
        gioKetThuc.hour,
        gioKetThuc.minute,
      );

  Future<bool> xacNhan(int maHoSoBaoTri) async {
    if (chon == null) {
      loi = 'Vui lòng chọn nhân viên thực hiện';
      notifyListeners();
      return false;
    }
    if (thoiDiemKetThuc.isBefore(thoiDiemBatDau)) {
      loi = 'Thời điểm kết thúc phải sau thời điểm bắt đầu';
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