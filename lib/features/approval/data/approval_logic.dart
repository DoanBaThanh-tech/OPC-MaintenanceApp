import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';

// ============================================================
// MODEL
// ============================================================

class HoSoBaoTriDuyet {
  final int maHoSoBaoTri;
  final String tenThietBi;
  final String? tenNguoiLap;
  final String? noiDungCongViec;
  final String? thoiGianDuKien;
  final DateTime? ngayDuKienBaoTri;
  final DateTime ngayTao;
  final String trangThai;
  final String? lyDoTuChoi;
  final String? rowVersion;

  HoSoBaoTriDuyet({
    required this.maHoSoBaoTri,
    required this.tenThietBi,
    this.tenNguoiLap,
    this.noiDungCongViec,
    this.thoiGianDuKien,
    this.ngayDuKienBaoTri,
    required this.ngayTao,
    required this.trangThai,
    this.lyDoTuChoi,
    this.rowVersion,
  });

  bool get choDuyet => trangThai == 'Chờ duyệt';

  factory HoSoBaoTriDuyet.fromJson(Map<String, dynamic> j) => HoSoBaoTriDuyet(
        maHoSoBaoTri: (j['maHoSoBaoTri'] as num?)?.toInt() ?? 0,
        tenThietBi: j['tenThietBi']?.toString() ?? '',
        tenNguoiLap: j['tenNhanVienTao']?.toString(),
        noiDungCongViec: j['noiDungCongViec']?.toString(),
        thoiGianDuKien: j['thoiGianDuKien']?.toString(),
        ngayDuKienBaoTri: j['ngayDuKienBaoTri'] != null ? DateTime.tryParse(j['ngayDuKienBaoTri'].toString()) : null,
        ngayTao: DateTime.parse(j['ngayTao'].toString()),
        trangThai: j['trangThai']?.toString() ?? '',
        lyDoTuChoi: j['lyDoTuChoi']?.toString(),
        rowVersion: j['rowVersion']?.toString(),
      );
}

// ============================================================
// SERVICE
// ============================================================

class ApprovalService {
  static Future<List<HoSoBaoTriDuyet>> layDanhSachBaoTri({String? trangThai}) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/bao-tri',
      query: trangThai != null ? {'trangThai': trangThai} : null,
    );
    return data.map((e) => HoSoBaoTriDuyet.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<HoSoBaoTriDuyet> layChiTietBaoTri(int id) async {
    final data = await ApiClient.instance.get<Map<String, dynamic>>('${ApiConstants.workOrder}/bao-tri/$id');
    return HoSoBaoTriDuyet.fromJson(data);
  }

  /// MaNhanVienDuyet KHÔNG gửi lên — server tự lấy từ JWT (giám đốc đang đăng nhập).
  static Future<void> duyetBaoTri({
    required int maHoSoBaoTri,
    required String quyetDinh, // "Duyệt" | "Từ chối"
    String? lyDo,
    required String rowVersion,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>('${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/duyet', {
      'quyetDinh': quyetDinh,
      'lyDo': lyDo,
      'rowVersion': rowVersion,
    });
  }
}

// ============================================================
// CONTROLLERS
// ============================================================

class ApprovalBaoTriListController extends ChangeNotifier {
  List<HoSoBaoTriDuyet> danhSach = [];
  bool dangTai = true;
  String? loi;

  Future<void> taiDanhSachChoDuyet() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      danhSach = await ApprovalService.layDanhSachBaoTri(trangThai: 'Chờ duyệt');
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }
}

class ApprovalBaoTriDetailController extends ChangeNotifier {
  final int maHoSoBaoTri;
  ApprovalBaoTriDetailController(this.maHoSoBaoTri);

  HoSoBaoTriDuyet? hoSo;
  bool dangTai = true;
  bool dangXuLy = false;
  String? loi;

  Future<void> taiChiTiet() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      hoSo = await ApprovalService.layChiTietBaoTri(maHoSoBaoTri);
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  /// Trả về true nếu xử lý thành công.
  Future<bool> xuLy({required String quyetDinh, String? lyDo}) async {
    if (hoSo?.rowVersion == null) {
      loi = 'Thiếu dữ liệu đồng bộ, vui lòng tải lại hồ sơ.';
      notifyListeners();
      return false;
    }
    if (quyetDinh == 'Từ chối' && (lyDo == null || lyDo.trim().isEmpty)) {
      loi = 'Vui lòng nhập lý do từ chối.';
      notifyListeners();
      return false;
    }
    dangXuLy = true;
    loi = null;
    notifyListeners();
    try {
      await ApprovalService.duyetBaoTri(
        maHoSoBaoTri: maHoSoBaoTri,
        quyetDinh: quyetDinh,
        lyDo: lyDo,
        rowVersion: hoSo!.rowVersion!,
      );
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } finally {
      dangXuLy = false;
      notifyListeners();
    }
  }
}