import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';

// ============================================================
// MODEL
// ============================================================

class ThietBiRutGon {
  final int maThietBi;
  final String tenThietBi;
  final String? loaiThietBi;
  final int maChuKy;

  ThietBiRutGon({
    required this.maThietBi,
    required this.tenThietBi,
    this.loaiThietBi,
    required this.maChuKy,
  });

  factory ThietBiRutGon.fromJson(Map<String, dynamic> j) => ThietBiRutGon(
    maThietBi: (j['maThietBi'] as num?)?.toInt() ?? 0,
    tenThietBi: j['tenThietBi']?.toString() ?? '',
    loaiThietBi: j['loaiThietBi']?.toString(),
    maChuKy: (j['maChuKy'] as num?)?.toInt() ?? 0,
  );
}

class ChuKyBaoTriModel {
  final int maChuKy;
  final String? loaiThietBi;
  final int soThangChuKyDeXuat;

  ChuKyBaoTriModel({
    required this.maChuKy,
    this.loaiThietBi,
    required this.soThangChuKyDeXuat,
  });

  factory ChuKyBaoTriModel.fromJson(Map<String, dynamic> j) => ChuKyBaoTriModel(
    maChuKy: (j['maChuKy'] as num?)?.toInt() ?? 0,
    loaiThietBi: j['loaiThietBi']?.toString(),
    soThangChuKyDeXuat: (j['soThangChuKyDeXuat'] as num?)?.toInt() ?? 0,
  );

  String get nhan => '${loaiThietBi ?? "Chưa rõ loại"} · $soThangChuKyDeXuat tháng/lần';
}

class ChiTietKeHoachInput {
  final ThietBiRutGon thietBi;
  DateTime ngayDuKienBaoTri;

  ChiTietKeHoachInput({required this.thietBi, required this.ngayDuKienBaoTri});
}

class ChiTietKeHoach {
  final int maChiTietKeHoach;
  final int maThietBi;
  final String tenThietBi;
  final DateTime ngayDuKienBaoTri;
  final int? maHoSoBaoTri;

  ChiTietKeHoach({
    required this.maChiTietKeHoach,
    required this.maThietBi,
    required this.tenThietBi,
    required this.ngayDuKienBaoTri,
    this.maHoSoBaoTri,
  });

  bool get daTaoHoSo => maHoSoBaoTri != null;

  factory ChiTietKeHoach.fromJson(Map<String, dynamic> j) => ChiTietKeHoach(
    maChiTietKeHoach: (j['maChiTietKeHoach'] as num?)?.toInt() ?? 0,
    maThietBi: (j['maThietBi'] as num?)?.toInt() ?? 0,
    tenThietBi: j['tenThietBi']?.toString() ?? '',
    ngayDuKienBaoTri: DateTime.parse(j['ngayDuKienBaoTri'].toString()),
    maHoSoBaoTri: (j['maHoSoBaoTri'] as num?)?.toInt(),
  );
}

class KeHoachBaoTri {
  final int maKeHoach;
  final int maChuKy;
  final String? tenChuKy;
  final int nam;
  final String? tenNhanVienLap;
  final DateTime ngayLapKeHoach;
  final String trangThai;
  final int soThietBi;
  final String? tenThietBi;

  KeHoachBaoTri({
    required this.maKeHoach,
    required this.maChuKy,
    this.tenChuKy,
    required this.nam,
    this.tenNhanVienLap,
    required this.ngayLapKeHoach,
    required this.trangThai,
    required this.soThietBi,
    this.tenThietBi,
  });

  factory KeHoachBaoTri.fromJson(Map<String, dynamic> j) => KeHoachBaoTri(
    maKeHoach: (j['maKeHoach'] as num?)?.toInt() ?? 0,
    maChuKy: (j['maChuKy'] as num?)?.toInt() ?? 0,
    tenChuKy: j['tenChuKy']?.toString(),
    nam: (j['nam'] as num?)?.toInt() ?? 0,
    tenNhanVienLap: j['tenNhanVienLap']?.toString(),
    ngayLapKeHoach: DateTime.parse(j['ngayLapKeHoach'].toString()),
    trangThai: j['trangThai']?.toString() ?? '',
    soThietBi: (j['soThietBi'] as num?)?.toInt() ?? 0,
    tenThietBi: j['tenThietBi']?.toString(),
  );
}

/// Một dòng thiết bị trong một tháng trên lịch.
class MucThietBiTrongThang {
  final KeHoachBaoTri keHoach;
  final ChiTietKeHoach chiTiet;

  MucThietBiTrongThang({required this.keHoach, required this.chiTiet});
}

enum TrangThaiKeHoach { daDuyet, tuChoi, choXuLy }

TrangThaiKeHoach phanLoaiTrangThai(String tt) {
  switch (tt) {
    case 'Đã duyệt':
      return TrangThaiKeHoach.daDuyet;
    case 'Từ chối':
      return TrangThaiKeHoach.tuChoi;
    default:
      return TrangThaiKeHoach.choXuLy;
  }
}

/// Lập bảo trì cho thiết bị (theo tháng xưởng chốt) | Lập theo năm
enum CheDoLapKeHoach { choThietBi, theoNam }

// ============================================================
// SERVICE
// ============================================================

class MaintenancePlanService {
  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Future<List<ChuKyBaoTriModel>> layDanhSachChuKy() async {
    final data = await ApiClient.instance.get<List<dynamic>>(ApiConstants.chuKyBaoTri);
    return data.map((e) => ChuKyBaoTriModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<ThietBiRutGon>> layDanhSachThietBi() async {
    final data = await ApiClient.instance.get<List<dynamic>>(ApiConstants.equipment);
    return data.map((e) => ThietBiRutGon.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<KeHoachBaoTri>> layDanhSachKeHoach() async {
    final data = await ApiClient.instance.get<List<dynamic>>(ApiConstants.maintenancePlan);
    return data.map((e) => KeHoachBaoTri.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<ChiTietKeHoach>> layChiTietKeHoach(int maKeHoach) async {
    final data = await ApiClient.instance.get<List<dynamic>>('${ApiConstants.maintenancePlan}/$maKeHoach/chi-tiet');
    return data.map((e) => ChiTietKeHoach.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> taoKeHoach({
    required int maChuKy,
    required int nam,
    required List<ChiTietKeHoachInput> danhSachThietBi,
  }) async {
    if (maChuKy <= 0) throw Exception('Mã chu kỳ không hợp lệ: $maChuKy');
    if (nam < 2000 || nam > 2100) throw Exception('Năm không hợp lệ: $nam');
    if (danhSachThietBi.isEmpty) throw Exception('Chưa có thiết bị nào được chọn');

    // API có thể trả Ok() không body → dùng dynamic, không ép Map
    await ApiClient.instance.post<dynamic>(ApiConstants.maintenancePlan, {
      'maChuKy': maChuKy,
      'nam': nam,
      'thietBiDuocChon': danhSachThietBi
          .map((e) => {
        'maThietBi': e.thietBi.maThietBi,
        'ngayDuKienBaoTri': _dateOnly(e.ngayDuKienBaoTri),
      })
          .toList(),
    });
  }

  static Future<void> taoNamMoi(int nam) async {
    await ApiClient.instance.post<dynamic>(ApiConstants.namMoi, {'nam': nam});
  }

  static Future<void> themThietBiVaoNam({
    required int nam,
    required int maThietBi,
    required DateTime ngay,
  }) async {
    await ApiClient.instance.post<dynamic>(ApiConstants.themThietBiVaoNam, {
      'nam': nam,
      'maThietBi': maThietBi,
      'ngayDuKienBaoTri': _dateOnly(ngay),
    });
  }
}


// ============================================================
// CONTROLLERS
// ============================================================

class MaintenancePlanListController extends ChangeNotifier {
  List<KeHoachBaoTri> _tatCa = [];
  final Map<int, List<ChiTietKeHoach>> _chiTietTheoKeHoach = {};

  int namDangChon = DateTime.now().year;
  bool dangTai = true;
  String? loi;

  List<int> get danhSachNam {
    final set = <int>{DateTime.now().year, DateTime.now().year + 1};
    for (final k in _tatCa) {
      set.add(k.nam);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<KeHoachBaoTri> get keHoachTheoNam =>
      _tatCa.where((k) => k.nam == namDangChon).toList();

  List<MucThietBiTrongThang> mucTrongThang(int thang) {
    final ketQua = <MucThietBiTrongThang>[];
    for (final kh in keHoachTheoNam) {
      final cts = _chiTietTheoKeHoach[kh.maKeHoach] ?? const [];
      for (final ct in cts) {
        if (ct.ngayDuKienBaoTri.year == namDangChon && ct.ngayDuKienBaoTri.month == thang) {
          ketQua.add(MucThietBiTrongThang(keHoach: kh, chiTiet: ct));
        }
      }
    }
    ketQua.sort((a, b) => a.chiTiet.ngayDuKienBaoTri.compareTo(b.chiTiet.ngayDuKienBaoTri));
    return ketQua;
  }

  int soMucTrongThang(int thang) => mucTrongThang(thang).length;

  Future<void> taiDanhSach() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      _tatCa = await MaintenancePlanService.layDanhSachKeHoach();
      _chiTietTheoKeHoach.clear();

      final theoNam = _tatCa.where((k) => k.nam == namDangChon).toList();
      if (theoNam.isNotEmpty) {
        final results = await Future.wait(
          theoNam.map((k) => MaintenancePlanService.layChiTietKeHoach(k.maKeHoach)),
        );
        for (var i = 0; i < theoNam.length; i++) {
          _chiTietTheoKeHoach[theoNam[i].maKeHoach] = results[i];
        }
      }

      if (!danhSachNam.contains(namDangChon) && danhSachNam.isNotEmpty) {
        namDangChon = danhSachNam.last;
      }
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  Future<void> doiNam(int nam) async {
    if (nam == namDangChon) return;
    namDangChon = nam;
    await taiDanhSach();
  }
}

class CreateYearPlanController extends ChangeNotifier {
  final List<int> namDaCo;
  CreateYearPlanController(this.namDaCo);

  int? nam;
  bool dangLuu = false;
  String? loi;

  void datNam(String value) {
    nam = int.tryParse(value);
    loi = null;
    notifyListeners();
  }

  Future<bool> luu() async {
    if (nam == null || nam.toString().length > 4 || nam! < 2000) {
      loi = 'Vui lòng nhập năm hợp lệ (tối đa 4 số)';
      notifyListeners();
      return false;
    }
    if (namDaCo.contains(nam)) {
      loi = 'Năm $nam đã có kế hoạch, vui lòng chọn năm khác';
      notifyListeners();
      return false;
    }
    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await MaintenancePlanService.taoNamMoi(nam!);
      return true;
    } catch (e) {
      loi = 'Lỗi: $e';
      return false;
    } finally {
      dangLuu = false;
      notifyListeners();
    }
  }
}
/// Chi tiết theo tháng: chỉ hiện thiết bị đúng tháng (không lẫn dữ liệu cũ).
class MaintenancePlanMonthDetailController extends ChangeNotifier {
  final int nam;
  final int thang;
  final List<MucThietBiTrongThang> mucBanDau;

  MaintenancePlanMonthDetailController({
    required this.nam,
    required this.thang,
    required this.mucBanDau,
  });

  List<MucThietBiTrongThang> danhSach = [];
  bool dangTai = false;
  String? loi;

  void khoiTao() {
    danhSach = List.from(mucBanDau);
    notifyListeners();
  }

  Future<void> taiLai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final keHoachIds = mucBanDau.map((m) => m.keHoach.maKeHoach).toSet();
      final ketQua = <MucThietBiTrongThang>[];
      for (final maKh in keHoachIds) {
        final kh = mucBanDau.firstWhere((m) => m.keHoach.maKeHoach == maKh).keHoach;
        final cts = await MaintenancePlanService.layChiTietKeHoach(maKh);
        for (final ct in cts) {
          if (ct.ngayDuKienBaoTri.year == nam && ct.ngayDuKienBaoTri.month == thang) {
            ketQua.add(MucThietBiTrongThang(keHoach: kh, chiTiet: ct));
          }
        }
      }
      ketQua.sort((a, b) => a.chiTiet.ngayDuKienBaoTri.compareTo(b.chiTiet.ngayDuKienBaoTri));
      danhSach = ketQua;
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }
}

class CreateMaintenancePlanController extends ChangeNotifier {
  final int nam;   // ← truyền vào từ màn danh sách (năm đang xem trên lịch), KHÔNG cho sửa
  CreateMaintenancePlanController({required this.nam});

  List<ThietBiRutGon> dsThietBi = [];
  List<ChuKyBaoTriModel> dsChuKy = [];
  ThietBiRutGon? thietBiChon;
  ChiTietKeHoachInput? chiTietChon;
  int thang = DateTime.now().month;

  bool dangTai = true;
  bool dangLuu = false;
  String? loi;

  DateTime get ngayBatDau => DateTime(nam, thang, 1);
  DateTime get ngayKetThuc => DateTime(nam, thang + 1, 0);

  Future<void> taiDuLieuBanDau() async {
    dangTai = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        MaintenancePlanService.layDanhSachThietBi(),
        MaintenancePlanService.layDanhSachChuKy(),
      ]);
      dsThietBi = results[0] as List<ThietBiRutGon>;
      dsChuKy = results[1] as List<ChuKyBaoTriModel>;
    } catch (e) {
      loi = 'Không tải được danh sách thiết bị';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  ChuKyBaoTriModel? get chuKyCoDinh {
    if (thietBiChon == null) return null;
    try {
      return dsChuKy.firstWhere((c) => c.maChuKy == thietBiChon!.maChuKy);
    } catch (_) {
      return null;
    }
  }

  void chonThietBi(ThietBiRutGon? tb) {
    if (tb == null) return;
    thietBiChon = tb;
    chiTietChon = ChiTietKeHoachInput(thietBi: tb, ngayDuKienBaoTri: ngayBatDau);
    loi = null;
    notifyListeners();
  }

  void doiThang(int t) {
    thang = t;
    if (chiTietChon != null) chiTietChon!.ngayDuKienBaoTri = ngayBatDau;
    notifyListeners();
  }

  void datNgayDuKien(DateTime ngay) {
    if (chiTietChon == null) return;
    if (ngay.isBefore(ngayBatDau) || ngay.isAfter(ngayKetThuc)) {
      loi = 'Ngày dự kiến phải nằm trong tháng $thang';
      notifyListeners();
      return;
    }
    chiTietChon!.ngayDuKienBaoTri = ngay;
    loi = null;
    notifyListeners();
  }

  Future<bool> luuKeHoach() async {
    if (chiTietChon == null || thietBiChon == null) {
      loi = 'Vui lòng chọn thiết bị';
      notifyListeners();
      return false;
    }
    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await MaintenancePlanService.themThietBiVaoNam(
        nam: nam,
        maThietBi: thietBiChon!.maThietBi,
        ngay: chiTietChon!.ngayDuKienBaoTri,
      );
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } on NetworkException catch (e) {
      loi = e.message;
      return false;
    } catch (e) {
      loi = 'Đã có lỗi xảy ra: $e';
      return false;
    } finally {
      dangLuu = false;
      notifyListeners();
    }
  }
}