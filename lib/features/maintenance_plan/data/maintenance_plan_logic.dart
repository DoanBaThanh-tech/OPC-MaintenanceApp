import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../maintenance_request/data/maintenance_request_logic.dart';

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
  /// Trạng thái hồ sơ bảo trì (null = chưa tạo hồ sơ). Ví dụ: Chờ duyệt, Đã duyệt, Từ chối...
  final String? trangThaiHoSo;

  ChiTietKeHoach({
    required this.maChiTietKeHoach,
    required this.maThietBi,
    required this.tenThietBi,
    required this.ngayDuKienBaoTri,
    this.maHoSoBaoTri,
    this.trangThaiHoSo,
  });

  bool get daTaoHoSo => maHoSoBaoTri != null;

  /// Nhãn hiển thị: ưu tiên trạng thái hồ sơ nếu đã tạo, ngược lại "Chưa tạo hồ sơ".
  String get nhanTrangThaiHienThi =>
      daTaoHoSo ? (trangThaiHoSo?.isNotEmpty == true ? trangThaiHoSo! : 'Đã tạo hồ sơ') : 'Chưa tạo hồ sơ';

  factory ChiTietKeHoach.fromJson(Map<String, dynamic> j) => ChiTietKeHoach(
    maChiTietKeHoach: (j['maChiTietKeHoach'] as num?)?.toInt() ?? 0,
    maThietBi: (j['maThietBi'] as num?)?.toInt() ?? 0,
    tenThietBi: j['tenThietBi']?.toString() ?? '',
    ngayDuKienBaoTri: DateTime.parse(j['ngayDuKienBaoTri'].toString()),
    maHoSoBaoTri: (j['maHoSoBaoTri'] as num?)?.toInt(),
    trangThaiHoSo: j['trangThaiHoSo']?.toString(),
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

enum TrangThaiKeHoach {
  choDuyet, daDuyet, tuChoi, dangThucHien, daHoanThanh, choXuLy, chuaTao,
}

TrangThaiKeHoach phanLoaiTrangThai(String tt) {
  switch (tt) {
    case 'Chờ duyệt': return TrangThaiKeHoach.choDuyet;
    case 'Đã duyệt': return TrangThaiKeHoach.daDuyet;
    case 'Từ chối': return TrangThaiKeHoach.tuChoi;
    case 'Đang thực hiện': return TrangThaiKeHoach.dangThucHien;
    case 'Đã hoàn thành':
    case 'Hoàn thành': return TrangThaiKeHoach.daHoanThanh;
    case 'Chưa tạo hồ sơ': return TrangThaiKeHoach.chuaTao;
    default: return TrangThaiKeHoach.choXuLy;
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
    required String noiDungCongViec,
    required int thoiGianDuKien,
    required TimeOfDay gioBatDau,
    required TimeOfDay gioKetThuc,
  }) async {
    String fmtGio(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

    await ApiClient.instance.post<dynamic>(ApiConstants.themThietBiVaoNam, {
      'nam': nam,
      'maThietBi': maThietBi,
      'ngayDuKienBaoTri': _dateOnly(ngay),
      'noiDungCongViec': noiDungCongViec,
      'thoiGianDuKien': thoiGianDuKien,
      'gioBatDauDuKien': fmtGio(gioBatDau),
      'gioKetThucDuKien': fmtGio(gioKetThuc),
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
  final int nam;
  CreateMaintenancePlanController({required this.nam});

  List<ThietBiRutGon> dsThietBi = [];
  List<ChuKyBaoTriModel> dsChuKy = [];
  ThietBiRutGon? thietBiChon;
  ChiTietKeHoachInput? chiTietChon;
  int thang = DateTime.now().month;
  DateTime? ngayLapKeHoach;

  bool dangTai = true;
  bool dangLuu = false;
  String? loi;
  /// Lỗi đỏ ngay dưới ô "Giờ dự kiến bảo trì"
  String? loiThoiGianDuKien;

  DateTime get ngayBatDau => DateTime(nam, thang, 1);
  DateTime get ngayKetThuc => DateTime(nam, thang + 1, 0);

  /// Ngày tối thiểu: phải SAU ngày hiện tại (không chọn hôm nay / quá khứ),
  /// và vẫn trong tháng đã chọn; đồng thời sau ngày lập kế hoạch nếu có.
  DateTime get ngayDuKienToiThieu {
    final now = DateTime.now();
    final ngayMai = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    var min = ngayMai;
    // Không sớm hơn đầu tháng đã chọn
    if (ngayBatDau.isAfter(min)) min = ngayBatDau;
    // Phải sau ngày lập kế hoạch
    if (ngayLapKeHoach != null) {
      final sauNgayLap = DateTime(
        ngayLapKeHoach!.year,
        ngayLapKeHoach!.month,
        ngayLapKeHoach!.day,
      ).add(const Duration(days: 1));
      if (sauNgayLap.isAfter(min)) min = sauNgayLap;
    }
    return min;
  }

  /// Yêu cầu đã xác nhận (theo tháng/năm) — dùng để gắn nhãn trên danh mục & thiết bị
  List<YeuCauBaoTriItem> yeuCauDaXacNhan = [];

  /// Đã lập kế hoạch (hoặc đã có hồ sơ) cho thiết bị trong tháng: key = "maThietBi|thang|nam"
  final Set<String> _daLapKeHoachKeys = {};

  String _keyTbThang(int maThietBi, int thang, int nam) => '$maThietBi|$thang|$nam';

  bool daLapKeHoachThang(int maThietBi, int thang, int nam) =>
      _daLapKeHoachKeys.contains(_keyTbThang(maThietBi, thang, nam));

  /// Map maThietBi → danh sách yêu cầu đã xác nhận (có thể nhiều tháng)
  Map<int, List<YeuCauBaoTriItem>> get mapYeuCauTheoThietBi {
    final m = <int, List<YeuCauBaoTriItem>>{};
    for (final y in yeuCauDaXacNhan) {
      m.putIfAbsent(y.maThietBi, () => []).add(y);
    }
    return m;
  }

  /// YC còn hiệu lực: đã xác nhận + chưa lập KH/hồ sơ cho đúng tháng đó
  List<YeuCauBaoTriItem> yeuCauConChoThietBi(int maThietBi) {
    final list = mapYeuCauTheoThietBi[maThietBi];
    if (list == null) return [];
    return list
        .where((y) => !daLapKeHoachThang(maThietBi, y.thangBaoTri, y.namBaoTri))
        .toList();
  }

  /// Danh mục có YC còn chờ lập KH (chưa bảo trì trong tháng đó)
  bool danhMucCoYeuCau(String dm) {
    return dsThietBi.any((tb) {
      final loai = tb.loaiThietBi ?? 'Chưa phân loại';
      if (loai != dm) return false;
      return yeuCauConChoThietBi(tb.maThietBi).isNotEmpty;
    });
  }

  /// Nhãn "YC Ttháng/năm" — chỉ các tháng còn YC chưa lập KH
  String? nhanYeuCauThietBi(int maThietBi) {
    final list = yeuCauConChoThietBi(maThietBi);
    if (list.isEmpty) return null;
    // Ưu tiên nhãn khớp tháng đang chọn trên form
    final matchThang =
    list.where((y) => y.thangBaoTri == thang && y.namBaoTri == nam).toList();
    final src = matchThang.isNotEmpty ? matchThang : list;
    return src.map((y) => 'YC T${y.thangBaoTri}/${y.namBaoTri}').toSet().join(', ');
  }

  bool thietBiCoYeuCauThangNay(int maThietBi) {
    return yeuCauConChoThietBi(maThietBi)
        .any((y) => y.thangBaoTri == thang && y.namBaoTri == nam);
  }

  /// Chỉ khớp đúng thiết bị + tháng/năm form — không lấy nhầm tháng khác
  YeuCauBaoTriItem? yeuCauKhopThietBi(int maThietBi) {
    for (final y in yeuCauConChoThietBi(maThietBi)) {
      if (y.thangBaoTri == thang && y.namBaoTri == nam) return y;
    }
    return null;
  }

  /// Tháng được phép chọn: chỉ tháng có YC còn hiệu lực của thiết bị đang chọn
  List<int> get thangChoPhep {
    if (thietBiChon == null) {
      return List.generate(12, (i) => i + 1);
    }
    final s = yeuCauConChoThietBi(thietBiChon!.maThietBi)
        .where((y) => y.namBaoTri == nam)
        .map((y) => y.thangBaoTri)
        .toSet()
        .toList()
      ..sort();
    return s.isEmpty ? List.generate(12, (i) => i + 1) : s;
  }

  Future<void> taiDuLieuBanDau() async {
    dangTai = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        MaintenancePlanService.layDanhSachThietBi(),
        MaintenancePlanService.layDanhSachChuKy(),
        MaintenancePlanService.layDanhSachKeHoach(),
        MaintenanceRequestService.layDeTaoHoSo(nam: nam),
      ]);
      dsThietBi = results[0] as List<ThietBiRutGon>;
      dsChuKy = results[1] as List<ChuKyBaoTriModel>;
      final dsKeHoach = results[2] as List<KeHoachBaoTri>;
      yeuCauDaXacNhan = results[3] as List<YeuCauBaoTriItem>;

      _daLapKeHoachKeys.clear();
      final khNam = dsKeHoach.where((k) => k.nam == nam).toList();
      if (khNam.isNotEmpty) {
        khNam.sort((a, b) => a.ngayLapKeHoach.compareTo(b.ngayLapKeHoach));
        ngayLapKeHoach = DateTime(
          khNam.first.ngayLapKeHoach.year,
          khNam.first.ngayLapKeHoach.month,
          khNam.first.ngayLapKeHoach.day,
        );
        // Tải chi tiết để biết tháng nào đã lập KH/hồ sơ
        final chiTietLists = await Future.wait(
          khNam.map((k) => MaintenancePlanService.layChiTietKeHoach(k.maKeHoach)),
        );
        for (final cts in chiTietLists) {
          for (final c in cts) {
            _daLapKeHoachKeys.add(_keyTbThang(
              c.maThietBi,
              c.ngayDuKienBaoTri.month,
              c.ngayDuKienBaoTri.year,
            ));
          }
        }
      }
    } catch (e) {
      loi = 'Không tải được danh sách thiết bị / yêu cầu đã xác nhận';
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

    final con = yeuCauConChoThietBi(tb.maThietBi);
    if (con.isEmpty) {
      loi = 'Thiết bị này không còn yêu cầu đã xác nhận chưa lập kế hoạch.';
      chiTietChon = null;
      notifyListeners();
      return;
    }

    // Khớp đúng tháng form; nếu tháng hiện tại không có YC còn lại → chuyển sang tháng YC gần nhất
    final khopThang = con.where((y) => y.thangBaoTri == thang && y.namBaoTri == nam).toList();
    if (khopThang.isEmpty) {
      con.sort((a, b) {
        final ca = a.namBaoTri * 12 + a.thangBaoTri;
        final cb = b.namBaoTri * 12 + b.thangBaoTri;
        return ca.compareTo(cb);
      });
      thang = con.first.thangBaoTri;
    }

    var macDinh = ngayDuKienToiThieu;
    if (macDinh.isAfter(ngayKetThuc)) macDinh = ngayKetThuc;
    chiTietChon = ChiTietKeHoachInput(thietBi: tb, ngayDuKienBaoTri: macDinh);
    // Chỉ điền từ YC đúng tháng (sau khi đã khóa tháng)
    _autoFillTuYeuCau(tb.maThietBi);
    loi = null;
    notifyListeners();
  }

  /// Điền ngày / giờ / thời gian / nội dung — chỉ từ YC khớp đúng tháng/năm form
  void _autoFillTuYeuCau(int maThietBi) {
    final yc = yeuCauKhopThietBi(maThietBi);
    if (yc == null) {
      // Không lấy nhầm tháng khác: xóa dữ liệu auto-fill cũ
      thoiGianDuKien = null;
      thoiGianTextController.clear();
      gioBatDau = null;
      loiThoiGianDuKien = null;
      return;
    }
    // Khóa tháng = tháng trên YC
    thang = yc.thangBaoTri;

    final ngayYc = DateTime(yc.ngayBaoTri.year, yc.ngayBaoTri.month, yc.ngayBaoTri.day);
    chiTietChon?.ngayDuKienBaoTri = ngayYc;

    final tg = yc.thoiGianDuKien.round();
    if (tg > 0) {
      thoiGianDuKien = tg;
      thoiGianTextController.text = '$tg';
      loiThoiGianDuKien = null;
    }
    if (yc.gioBatDau != null && yc.gioBatDau!.isNotEmpty) {
      final parts = yc.gioBatDau!.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) gioBatDau = TimeOfDay(hour: h, minute: m);
      }
    }
    if (yc.ghiChu != null && yc.ghiChu!.trim().isNotEmpty) {
      noiDungCongViecController.text = yc.ghiChu!.trim();
    }
  }

  void doiThang(int t) {
    // Khi đã chọn thiết bị: chỉ cho chọn tháng có YC còn hiệu lực
    if (thietBiChon != null) {
      final allowed = thangChoPhep;
      if (!allowed.contains(t)) {
        loi =
        'Tháng $t không có yêu cầu bảo trì đã xác nhận (còn trống) cho thiết bị này. '
            'Tháng phải trùng với yêu cầu đã được xưởng Đồng ý.';
        notifyListeners();
        return;
      }
    }
    thang = t;
    if (chiTietChon != null && thietBiChon != null) {
      var macDinh = ngayDuKienToiThieu;
      if (macDinh.isAfter(ngayKetThuc)) macDinh = ngayKetThuc;
      chiTietChon!.ngayDuKienBaoTri = macDinh;
      _autoFillTuYeuCau(thietBiChon!.maThietBi);
    }
    loi = null;
    notifyListeners();
  }

  void datNgayDuKien(DateTime ngay) {
    if (chiTietChon == null) return;
    final ngayChon = DateTime(ngay.year, ngay.month, ngay.day);
    final homNay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (ngayChon.month != thang || ngayChon.year != nam ||
        ngayChon.isBefore(ngayBatDau) || ngayChon.isAfter(ngayKetThuc)) {
      loi = 'Ngày dự kiến bảo trì phải nằm trong tháng $thang/$nam';
      notifyListeners();
      return;
    }
    // Không được chọn hôm nay hoặc ngày trong quá khứ
    if (!ngayChon.isAfter(homNay)) {
      loi = 'Ngày dự kiến bảo trì phải lớn hơn ngày hiện tại (không chọn hôm nay hoặc ngày trước).';
      notifyListeners();
      return;
    }
    if (ngayLapKeHoach != null) {
      final lap = DateTime(
        ngayLapKeHoach!.year,
        ngayLapKeHoach!.month,
        ngayLapKeHoach!.day,
      );
      if (!ngayChon.isAfter(lap)) {
        loi =
        'Ngày dự kiến bảo trì phải lớn hơn ngày lập kế hoạch (${lap.day.toString().padLeft(2, '0')}/${lap.month.toString().padLeft(2, '0')}/${lap.year}).';
        notifyListeners();
        return;
      }
    }
    chiTietChon!.ngayDuKienBaoTri = ngayChon;
    loi = null;
    notifyListeners();
  }

  final noiDungCongViecController = TextEditingController();
  final thoiGianTextController = TextEditingController();
  int? thoiGianDuKien;
  TimeOfDay? gioBatDau;

  TimeOfDay? get gioKetThucTuTinh {
    if (gioBatDau == null || thoiGianDuKien == null) return null;
    final tongPhut = gioBatDau!.hour * 60 + gioBatDau!.minute + thoiGianDuKien! * 60;
    return TimeOfDay(hour: (tongPhut ~/ 60) % 24, minute: tongPhut % 60);
  }

  /// Validate realtime: số dương, không ký tự đặc biệt, tối đa 24 giờ trong ngày
  static const int maxGioTrongNgay = 24;

  void datThoiGianDuKienTuChuoi(String raw) {
    final v = raw.trim();
    if (v.isEmpty) {
      thoiGianDuKien = null;
      loiThoiGianDuKien = 'Vui lòng nhập giờ dự kiến bảo trì';
      notifyListeners();
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(v)) {
      thoiGianDuKien = null;
      loiThoiGianDuKien = 'Chỉ được nhập số dương (không chữ, không ký tự đặc biệt)';
      notifyListeners();
      return;
    }
    final so = int.tryParse(v);
    if (so == null || so <= 0) {
      thoiGianDuKien = null;
      loiThoiGianDuKien = 'Giờ dự kiến phải là số dương lớn hơn 0';
      notifyListeners();
      return;
    }
    if (so > maxGioTrongNgay) {
      thoiGianDuKien = null;
      loiThoiGianDuKien = 'Bảo trì trong ngày — tối đa $maxGioTrongNgay giờ';
      notifyListeners();
      return;
    }
    thoiGianDuKien = so;
    loiThoiGianDuKien = null;
    notifyListeners();
  }

  void datThoiGianDuKien(int? gio) {
    thoiGianDuKien = gio;
    if (gio == null || gio <= 0) {
      loiThoiGianDuKien = 'Vui lòng nhập giờ dự kiến bảo trì (số dương)';
    } else if (gio > maxGioTrongNgay) {
      loiThoiGianDuKien = 'Bảo trì trong ngày — tối đa $maxGioTrongNgay giờ';
      thoiGianDuKien = null;
    } else {
      loiThoiGianDuKien = null;
    }
    notifyListeners();
  }

  void datGioBatDau(TimeOfDay t) {
    gioBatDau = t;
    notifyListeners();
  }

  String? kiemTraGio() {
    if (loiThoiGianDuKien != null) return loiThoiGianDuKien;
    if (thoiGianDuKien == null || thoiGianDuKien! <= 0) {
      return 'Vui lòng nhập giờ dự kiến bảo trì (số dương)';
    }
    if (thoiGianDuKien! > maxGioTrongNgay) {
      return 'Bảo trì trong ngày — tối đa $maxGioTrongNgay giờ';
    }
    if (gioBatDau == null) return 'Vui lòng chọn giờ bắt đầu';
    if (gioKetThucTuTinh == gioBatDau) return 'Giờ bắt đầu và kết thúc không được trùng nhau';
    return null;
  }

  Future<bool> luuKeHoach() async {
    if (chiTietChon == null || thietBiChon == null) {
      loi = 'Vui lòng chọn thiết bị';
      notifyListeners();
      return false;
    }
    // Bắt buộc có YC đã xác nhận đúng tháng và chưa lập KH
    final yc = yeuCauKhopThietBi(thietBiChon!.maThietBi);
    if (yc == null) {
      loi =
      'Thiết bị này chưa có yêu cầu bảo trì đã được xưởng xác nhận cho tháng $thang/$nam '
          '(hoặc tháng đó đã lập kế hoạch rồi). Tháng trên form phải trùng tháng trên yêu cầu.';
      notifyListeners();
      return false;
    }
    final ngay = DateTime(
      chiTietChon!.ngayDuKienBaoTri.year,
      chiTietChon!.ngayDuKienBaoTri.month,
      chiTietChon!.ngayDuKienBaoTri.day,
    );
    if (ngay.year != nam || ngay.month != thang) {
      loi = 'Ngày dự kiến bảo trì phải nằm trong tháng $thang/$nam (theo yêu cầu đã xác nhận).';
      notifyListeners();
      return false;
    }
    // Ngày phải thuộc đúng tháng YC
    if (ngay.month != yc.thangBaoTri || ngay.year != yc.namBaoTri) {
      loi =
      'Ngày/tháng phải khớp yêu cầu đã xác nhận (YC T${yc.thangBaoTri}/${yc.namBaoTri}).';
      notifyListeners();
      return false;
    }
    final homNay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (!ngay.isAfter(homNay)) {
      loi = 'Ngày dự kiến bảo trì phải lớn hơn ngày hiện tại (không chọn hôm nay hoặc ngày trước).';
      notifyListeners();
      return false;
    }
    if (noiDungCongViecController.text.trim().isEmpty) {
      loi = 'Vui lòng nhập nội dung công việc';
      notifyListeners();
      return false;
    }
    final loiGio = kiemTraGio();
    if (loiGio != null) {
      loi = loiGio;
      notifyListeners();
      return false;
    }
    if (ngayLapKeHoach != null) {
      final lap = DateTime(ngayLapKeHoach!.year, ngayLapKeHoach!.month, ngayLapKeHoach!.day);
      if (!ngay.isAfter(lap)) {
        loi =
        'Ngày dự kiến bảo trì phải lớn hơn ngày lập kế hoạch (${lap.day.toString().padLeft(2, '0')}/${lap.month.toString().padLeft(2, '0')}/${lap.year}).';
        notifyListeners();
        return false;
      }
    }
    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await MaintenancePlanService.themThietBiVaoNam(
        nam: nam,
        maThietBi: thietBiChon!.maThietBi,
        ngay: chiTietChon!.ngayDuKienBaoTri,
        noiDungCongViec: noiDungCongViecController.text.trim(),
        thoiGianDuKien: thoiGianDuKien!,
        gioBatDau: gioBatDau!,
        gioKetThuc: gioKetThucTuTinh!,
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

  String tuKhoaTimKiem = '';
  String? danhMucChon;

  List<String> get danhSachDanhMuc =>
      dsThietBi.map((t) => t.loaiThietBi ?? 'Chưa phân loại').toSet().toList()..sort();

  List<ThietBiRutGon> get dsThietBiDaLoc {
    return dsThietBi.where((tb) {
      final khopDanhMuc = danhMucChon == null || (tb.loaiThietBi ?? 'Chưa phân loại') == danhMucChon;
      final khopTuKhoa = tuKhoaTimKiem.isEmpty ||
          tb.tenThietBi.toLowerCase().contains(tuKhoaTimKiem.toLowerCase()) ||
          (tb.loaiThietBi ?? '').toLowerCase().contains(tuKhoaTimKiem.toLowerCase());
      return khopDanhMuc && khopTuKhoa;
    }).toList();
  }

  void datTuKhoaTimKiem(String tk) {
    tuKhoaTimKiem = tk;
    notifyListeners();
  }

  void chonDanhMuc(String? dm) {
    danhMucChon = dm;
    thietBiChon = null;
    chiTietChon = null;
    notifyListeners();
  }
}