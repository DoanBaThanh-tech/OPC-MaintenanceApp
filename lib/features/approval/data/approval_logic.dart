import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';

// ============================================================
// MODEL (giữ nguyên)
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
  final int nam;
  final bool namTuKeHoach;

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
    required this.nam,
    required this.namTuKeHoach,
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
        nam: (j['nam'] as num?)?.toInt() ?? DateTime.now().year,
        namTuKeHoach: j['namTuKeHoach'] == true,
      );
}

// ============================================================
// SERVICE
// ============================================================

class ApprovalService {
  /// Luôn tải TOÀN BỘ hồ sơ chờ duyệt (không lọc năm ở API) - lọc năm làm ở client
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

  static Future<void> duyetBaoTri({
    required int maHoSoBaoTri,
    required String quyetDinh,
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
// CONTROLLER: danh sách + lọc năm (LỌC PHÍA CLIENT)
// ============================================================

class ApprovalBaoTriListController extends ChangeNotifier {
  List<HoSoBaoTriDuyet> _tatCa = []; // toàn bộ dữ liệu tải về, KHÔNG lọc năm
  bool dangTai = true;
  String? loi;
  int? namLoc; // null = "Tất cả năm"

  /// Danh sách hiện ra màn hình - luôn lọc từ _tatCa, không gọi mạng lại
  List<HoSoBaoTriDuyet> get danhSach =>
      namLoc == null ? _tatCa : _tatCa.where((h) => h.nam == namLoc).toList();

  /// Chỉ những năm THỰC SỰ có hồ sơ - lấy trực tiếp từ dữ liệu vừa tải,
  /// không đoán/hardcode -> luôn khớp đúng dữ liệu thật, tự thêm năm mới khi có hồ sơ năm đó
  List<int> get cacNamCoDuLieu {
    final nams = _tatCa.map((h) => h.nam).toSet().toList();
    nams.sort((a, b) => b.compareTo(a)); // mới nhất trước
    return nams;
  }

  Future<void> taiDanhSachChoDuyet() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      _tatCa = await ApprovalService.layDanhSachBaoTri(trangThai: 'Chờ duyệt');
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  /// Chỉ đổi bộ lọc hiển thị - KHÔNG gọi mạng, nên không có độ trễ/lỗi thời điểm
  void datNamLoc(int? nam) {
    namLoc = nam;
    notifyListeners();
  }
}

// ============================================================
// CONTROLLER: chi tiết + duyệt (giữ nguyên, không đổi)
// ============================================================

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