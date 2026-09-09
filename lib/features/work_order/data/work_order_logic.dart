import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';

// ============================================================
// MODEL
// ============================================================

class NhanVienRutGon {
  final int maNhanVien;
  final String hoTen;

  NhanVienRutGon({required this.maNhanVien, required this.hoTen});

  factory NhanVienRutGon.fromJson(Map<String, dynamic> j) => NhanVienRutGon(
        maNhanVien: (j['maNhanVien'] as num?)?.toInt() ?? 0,
        hoTen: j['hoTen']?.toString() ?? '',
      );
}

class HoSoBaoTri {
  final int maHoSoBaoTri;
  final int maThietBi;
  final String tenThietBi;
  final String? noiDungCongViec;
  final String? thoiGianDuKien;
  final DateTime ngayTao;
  final String trangThai;
  final String? lyDoTuChoi;
  final int? maPhanCong;

  HoSoBaoTri({
    required this.maHoSoBaoTri,
    required this.maThietBi,
    required this.tenThietBi,
    this.noiDungCongViec,
    this.thoiGianDuKien,
    required this.ngayTao,
    required this.trangThai,
    this.lyDoTuChoi,
    this.maPhanCong,
  });

  bool get choDuyet => trangThai == 'Chờ duyệt';
  bool get daDuyetChuaPhanCong => trangThai == 'Đã duyệt' && maPhanCong == null;
  bool get dangThucHien => trangThai == 'Đang thực hiện';

  // Giữ nguyên fallback maThieBi (thiếu chữ 't') vì tên cột FK gốc trong DB bị đặt vậy —
  // không đổi tên cột DB, chỉ dự phòng đọc đúng cả 2 khả năng JSON trả về.
  factory HoSoBaoTri.fromJson(Map<String, dynamic> j) => HoSoBaoTri(
        maHoSoBaoTri: (j['maHoSoBaoTri'] as num?)?.toInt() ?? 0,
        maThietBi: (j['maThietBi'] as num?)?.toInt() ?? (j['maThieBi'] as num?)?.toInt() ?? 0,
        tenThietBi: j['tenThietBi']?.toString() ?? '',
        noiDungCongViec: j['noiDungCongViec']?.toString(),
        thoiGianDuKien: j['thoiGianDuKien']?.toString(),
        ngayTao: DateTime.parse(j['ngayTao'].toString()),
        trangThai: j['trangThai']?.toString() ?? '',
        lyDoTuChoi: j['lyDoTuChoi']?.toString(),
        maPhanCong: (j['maPhanCong'] as num?)?.toInt(),
      );
}

/// Phân loại trạng thái thành nhóm cố định — presentation tự map ra màu,
/// logic không phụ thuộc Flutter Material để giữ file này thuần dữ liệu.
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
  static Future<List<HoSoBaoTri>> layDanhSachHoSoBaoTri() async {
    final data = await ApiClient.instance.get<List<dynamic>>('${ApiConstants.workOrder}/bao-tri');
    return data.map((e) => HoSoBaoTri.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<HoSoBaoTri> layChiTietHoSoBaoTri(int id) async {
    final data = await ApiClient.instance.get<Map<String, dynamic>>('${ApiConstants.workOrder}/bao-tri/$id');
    return HoSoBaoTri.fromJson(data);
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
    await ApiClient.instance.put<Map<String, dynamic>>('${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/phan-cong', {
      'maNhanVienThucHien': maNhanVienThucHien,
      'ngayBatDauDuKien': ngayBatDau.toIso8601String(),
      'ngayKetThucDuKien': ngayKetThuc.toIso8601String(),
    });
  }
}

// ============================================================
// CONTROLLERS (toàn bộ state + nghiệp vụ — presentation chỉ gọi & lắng nghe)
// ============================================================

class WorkOrderBaoTriListController extends ChangeNotifier {
  List<HoSoBaoTri> danhSach = [];
  bool dangTai = true;
  String? loi;

  Future<void> taiDanhSach() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      danhSach = await WorkOrderService.layDanhSachHoSoBaoTri();
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
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
  DateTime ngayBatDau = DateTime.now();
  DateTime ngayKetThuc = DateTime.now().add(const Duration(days: 1));
  bool dangTai = true;
  bool dangLuu = false;
  String? loi;

  Future<void> taiNhanVien() async {
    dangTai = true;
    notifyListeners();
    try {
      dsNhanVien = await WorkOrderService.layDanhSachNhanVienKyThuat();
    } catch (e) {
      loi = 'Không tải được danh sách nhân viên';
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

  void datNgayKetThuc(DateTime d) {
    ngayKetThuc = d;
    notifyListeners();
  }

  /// Trả về true nếu phân công thành công.
  Future<bool> xacNhan(int maHoSoBaoTri) async {
    if (chon == null) {
      loi = 'Vui lòng chọn nhân viên thực hiện';
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
        ngayBatDau: ngayBatDau,
        ngayKetThuc: ngayKetThuc,
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