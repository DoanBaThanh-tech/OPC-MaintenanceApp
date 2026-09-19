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
  final String? gioBatDauDuKien;
  final String? gioKetThucDuKien;
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
    this.gioBatDauDuKien,
    this.gioKetThucDuKien,
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
    gioBatDauDuKien: j['gioBatDauDuKien']?.toString(),
    gioKetThucDuKien: j['gioKetThucDuKien']?.toString(),
    ngayDuKienBaoTri: j['ngayDuKienBaoTri'] != null
        ? DateTime.tryParse(j['ngayDuKienBaoTri'].toString())
        : null,
    ngayTao: DateTime.parse(j['ngayTao'].toString()),
    trangThai: j['trangThai']?.toString() ?? '',
    lyDoTuChoi: j['lyDoTuChoi']?.toString(),
    rowVersion: j['rowVersion']?.toString(),
    nam: (j['nam'] as num?)?.toInt() ?? DateTime.now().year,
    namTuKeHoach: j['namTuKeHoach'] == true,
  );
}

class LichSuPheDuyetItem {
  final int maPheDuyet;
  final String loai;
  final int? maHoSo;
  final String? tenThietBi;
  final String? tenNguoiLap;
  final String? noiDung;
  final String? tenNguoiDuyet;
  final String quyetDinh;
  final String trangThaiHoSo;
  final String? lyDo;
  final DateTime ngayDuyet;
  final int nam;

  LichSuPheDuyetItem({
    required this.maPheDuyet,
    required this.loai,
    this.maHoSo,
    this.tenThietBi,
    this.tenNguoiLap,
    this.noiDung,
    this.tenNguoiDuyet,
    required this.quyetDinh,
    required this.trangThaiHoSo,
    this.lyDo,
    required this.ngayDuyet,
    required this.nam,
  });

  bool get daDuyet => trangThaiHoSo == 'Đã duyệt' || quyetDinh == 'Duyệt';
  bool get tuChoi => trangThaiHoSo == 'Từ chối' || quyetDinh == 'Từ chối';

  factory LichSuPheDuyetItem.fromJson(Map<String, dynamic> j) {
    DateTime? asDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    final ngay = asDate(j['ngayDuyet']) ?? DateTime.now();
    return LichSuPheDuyetItem(
      maPheDuyet: (j['maPheDuyet'] as num?)?.toInt() ?? 0,
      loai: j['loai']?.toString() ?? 'Bảo trì',
      maHoSo: (j['maHoSo'] as num?)?.toInt(),
      tenThietBi: j['tenThietBi']?.toString(),
      tenNguoiLap: j['tenNguoiLap']?.toString(),
      noiDung: j['noiDung']?.toString(),
      tenNguoiDuyet: j['tenNguoiDuyet']?.toString(),
      quyetDinh: j['quyetDinh']?.toString() ?? '',
      trangThaiHoSo: j['trangThaiHoSo']?.toString() ?? '',
      lyDo: j['lyDo']?.toString(),
      ngayDuyet: ngay,
      nam: (j['nam'] as num?)?.toInt() ?? ngay.year,
    );
  }
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
    return data
        .map((e) => HoSoBaoTriDuyet.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<HoSoBaoTriDuyet> layChiTietBaoTri(int id) async {
    final data = await ApiClient.instance
        .get<Map<String, dynamic>>('${ApiConstants.workOrder}/bao-tri/$id');
    return HoSoBaoTriDuyet.fromJson(data);
  }

  static Future<void> duyetBaoTri({
    required int maHoSoBaoTri,
    required String quyetDinh,
    String? lyDo,
    required String rowVersion,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/duyet',
      {
        'quyetDinh': quyetDinh,
        'lyDo': lyDo,
        'rowVersion': rowVersion,
      },
    );
  }

  static Future<List<LichSuPheDuyetItem>> layLichSuPheDuyet({
    String? loai,
    int? nam,
  }) async {
    final query = <String, dynamic>{};
    if (loai != null) query['loai'] = loai;
    if (nam != null) query['nam'] = nam;
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/lich-su-phe-duyet',
      query: query.isEmpty ? null : query,
    );
    return data
        .map((e) =>
        LichSuPheDuyetItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<int>> layNamCoLichSu({String? loai}) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/lich-su-phe-duyet/nam',
      query: loai != null ? {'loai': loai} : null,
    );
    return data.map((e) => (e as num).toInt()).toList();
  }
}

// ============================================================
// CONTROLLERS
// ============================================================

class ApprovalBaoTriListController extends ChangeNotifier {
  List<HoSoBaoTriDuyet> _tatCa = [];
  bool dangTai = true;
  String? loi;
  int? namLoc;

  List<HoSoBaoTriDuyet> get danhSach =>
      namLoc == null ? _tatCa : _tatCa.where((h) => h.nam == namLoc).toList();

  List<int> get cacNamCoDuLieu {
    final nams = _tatCa.map((h) => h.nam).toSet().toList();
    nams.sort((a, b) => b.compareTo(a));
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

  void datNamLoc(int? nam) {
    namLoc = nam;
    notifyListeners();
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

class LichSuPheDuyetController extends ChangeNotifier {
  List<LichSuPheDuyetItem> danhSach = [];
  List<int> cacNam = [];
  bool dangTai = true;
  String? loi;
  String tabLoai = 'Bảo trì';
  int? namLoc;

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        ApprovalService.layLichSuPheDuyet(loai: tabLoai, nam: namLoc),
        ApprovalService.layNamCoLichSu(loai: tabLoai),
      ]);
      danhSach = results[0] as List<LichSuPheDuyetItem>;
      cacNam = results[1] as List<int>;
    } catch (e) {
      loi = 'Không tải được lịch sử: $e';
      danhSach = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void doiTab(String loai) {
    if (tabLoai == loai) return;
    tabLoai = loai;
    namLoc = null;
    tai();
  }

  void datNam(int? nam) {
    namLoc = nam;
    tai();
  }
}