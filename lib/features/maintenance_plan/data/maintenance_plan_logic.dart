import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../work_order/data/work_order_validators.dart';

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

  /// Đã lập kế hoạch (hoặc đã có hồ sơ) cho thiết bị trong tháng: key = "maThietBi|thang|nam"
  final Set<String> _daLapKeHoachKeys = {};

  String _keyTbThang(int maThietBi, int thang, int nam) => '$maThietBi|$thang|$nam';

  /// Mỗi thiết bị chỉ được lập bảo trì 1 lần trong một tháng.
  bool daLapKeHoachThang(int maThietBi, int thang, int nam) =>
      _daLapKeHoachKeys.contains(_keyTbThang(maThietBi, thang, nam));

  /// Tất cả 12 tháng được chọn bình thường (không phụ thuộc yêu cầu cũ).
  List<int> get thangChoPhep => List.generate(12, (i) => i + 1);

  Future<void> taiDuLieuBanDau() async {
    dangTai = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        MaintenancePlanService.layDanhSachThietBi(),
        MaintenancePlanService.layDanhSachChuKy(),
        MaintenancePlanService.layDanhSachKeHoach(),
      ]);
      dsThietBi = results[0] as List<ThietBiRutGon>;
      dsChuKy = results[1] as List<ChuKyBaoTriModel>;
      final dsKeHoach = results[2] as List<KeHoachBaoTri>;

      _daLapKeHoachKeys.clear();
      final khNam = dsKeHoach.where((k) => k.nam == nam).toList();
      if (khNam.isNotEmpty) {
        khNam.sort((a, b) => a.ngayLapKeHoach.compareTo(b.ngayLapKeHoach));
        ngayLapKeHoach = DateTime(
          khNam.first.ngayLapKeHoach.year,
          khNam.first.ngayLapKeHoach.month,
          khNam.first.ngayLapKeHoach.day,
        );
        // Tải chi tiết để biết thiết bị nào đã lập KH trong tháng nào
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
      loi = null;
    } catch (e) {
      loi = 'Không tải được danh sách thiết bị / kế hoạch';
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

    // Cảnh báo nếu thiết bị đã có bảo trì trong tháng đang chọn (vẫn cho chọn để user đổi tháng)
    if (daLapKeHoachThang(tb.maThietBi, thang, nam)) {
      loi =
      'Thiết bị "${tb.tenThietBi}" đã được lập bảo trì trong tháng $thang/$nam. '
          'Mỗi thiết bị chỉ được lập bảo trì 1 lần trong một tháng. Vui lòng chọn tháng khác.';
    } else {
      loi = null;
    }

    var macDinh = ngayDuKienToiThieu;
    if (macDinh.isAfter(ngayKetThuc)) macDinh = ngayKetThuc;
    chiTietChon = ChiTietKeHoachInput(thietBi: tb, ngayDuKienBaoTri: macDinh);
    notifyListeners();
  }

  void doiThang(int t) {
    thang = t;
    if (chiTietChon != null && thietBiChon != null) {
      var macDinh = ngayDuKienToiThieu;
      if (macDinh.isAfter(ngayKetThuc)) macDinh = ngayKetThuc;
      chiTietChon!.ngayDuKienBaoTri = macDinh;

      if (daLapKeHoachThang(thietBiChon!.maThietBi, thang, nam)) {
        loi =
        'Thiết bị "${thietBiChon!.tenThietBi}" đã được lập bảo trì trong tháng $thang/$nam. '
            'Mỗi thiết bị chỉ được lập bảo trì 1 lần trong một tháng.';
      } else {
        loi = null;
      }
    } else {
      loi = null;
    }
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
  /// Số giờ (khi !nhapPhut) — giữ int để tương thích API plan đang nhận int giờ.
  int? thoiGianDuKien;
  int? thoiGianPhut;
  bool nhapPhut = false;
  TimeOfDay? gioBatDau;

  TimeOfDay? get gioKetThucTuTinh {
    final phut = nhapPhut
        ? (thoiGianPhut ?? 0)
        : (thoiGianDuKien ?? 0) * 60;
    if (gioBatDau == null || phut <= 0) return null;
    return tinhGioKetThuc(gioBatDau: gioBatDau!, tongPhut: phut);
  }

  /// Giá trị số gửi API kế hoạch (hiện schema dùng giờ số nguyên).
  /// Phút quy đổi: làm tròn lên tối thiểu 1 giờ nếu < 60, hoặc gửi phút dạng metadata qua nội dung — giữ int giờ ceil.
  int get thoiGianDuKienGuiApi {
    if (nhapPhut && thoiGianPhut != null) {
      // API plan dùng int giờ — lưu ceil giờ tối thiểu 1, đồng thời có thể lưu "Xp" nếu API hỗ trợ string
      final g = (thoiGianPhut! / 60).ceil();
      return g < 1 ? 1 : g;
    }
    return thoiGianDuKien ?? 0;
  }

  void datDonViThoiGian({required bool laPhut}) {
    nhapPhut = laPhut;
    notifyListeners();
  }

  void datThoiGianDuKienTuChuoi(String raw) {
    final kq = validateThoiGianDuKien(
      raw,
      laPhut: nhapPhut,
      gioBatDau: gioBatDau,
    );
    loiThoiGianDuKien = kq.loi;
    if (!kq.hopLe) {
      thoiGianDuKien = null;
      thoiGianPhut = null;
    } else if (kq.laPhut) {
      thoiGianPhut = kq.soPhut;
      thoiGianDuKien = null;
      nhapPhut = true;
    } else {
      thoiGianDuKien = kq.soGio;
      thoiGianPhut = null;
      nhapPhut = false;
    }
    notifyListeners();
  }

  void datThoiGianDuKien(int? gio) {
    nhapPhut = false;
    thoiGianDuKien = gio;
    thoiGianPhut = null;
    if (gio == null || gio <= 0) {
      loiThoiGianDuKien = 'Vui lòng nhập giờ dự kiến bảo trì (số dương)';
    } else {
      final kq = validateThoiGianDuKien(
        '$gio',
        laPhut: false,
        gioBatDau: gioBatDau,
      );
      loiThoiGianDuKien = kq.loi;
      if (!kq.hopLe) thoiGianDuKien = null;
    }
    notifyListeners();
  }

  void datGioBatDau(TimeOfDay t) {
    gioBatDau = t;
    // Re-validate thời lượng với giờ bắt đầu mới
    final raw = nhapPhut
        ? (thoiGianPhut?.toString() ?? '')
        : (thoiGianDuKien?.toString() ?? '');
    if (raw.isNotEmpty) {
      datThoiGianDuKienTuChuoi(raw);
    } else {
      notifyListeners();
    }
  }

  String? kiemTraGio() {
    if (loiThoiGianDuKien != null) return loiThoiGianDuKien;
    final phut = nhapPhut ? thoiGianPhut : (thoiGianDuKien != null ? thoiGianDuKien! * 60 : null);
    if (phut == null || phut <= 0) {
      return nhapPhut
          ? 'Vui lòng nhập số phút dự kiến (số dương)'
          : 'Vui lòng nhập giờ dự kiến bảo trì (số dương)';
    }
    if (gioBatDau == null) return 'Vui lòng chọn giờ bắt đầu';
    if (gioKetThucTuTinh == null) {
      return 'Thời lượng + giờ bắt đầu vượt quá 24:00 — không được lấn sang ngày khác';
    }
    if (gioKetThucTuTinh == gioBatDau) {
      return 'Giờ bắt đầu và kết thúc không được trùng nhau';
    }
    return null;
  }

  Future<bool> luuKeHoach() async {
    if (chiTietChon == null || thietBiChon == null) {
      loi = 'Vui lòng chọn thiết bị';
      notifyListeners();
      return false;
    }

    // Ràng buộc: mỗi thiết bị chỉ lập bảo trì 1 lần trong tháng
    if (daLapKeHoachThang(thietBiChon!.maThietBi, thang, nam)) {
      loi =
      'Thiết bị "${thietBiChon!.tenThietBi}" đã được lập bảo trì trong tháng $thang/$nam. '
          'Không thể tạo thêm. Mỗi thiết bị chỉ được lập bảo trì 1 lần trong một tháng.';
      notifyListeners();
      return false;
    }

    final ngay = DateTime(
      chiTietChon!.ngayDuKienBaoTri.year,
      chiTietChon!.ngayDuKienBaoTri.month,
      chiTietChon!.ngayDuKienBaoTri.day,
    );
    if (ngay.year != nam || ngay.month != thang) {
      loi = 'Ngày dự kiến bảo trì phải nằm trong tháng $thang/$nam.';
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
        thoiGianDuKien: thoiGianDuKienGuiApi,
        gioBatDau: gioBatDau!,
        gioKetThuc: gioKetThucTuTinh!,
      );
      // Đánh dấu đã lập để chặn tạo trùng ngay trên client
      _daLapKeHoachKeys.add(_keyTbThang(thietBiChon!.maThietBi, thang, nam));
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

  /// Bỏ dấu tiếng Việt để tìm "lo" vẫn ra "Lò", "auto" ra "Autoclave", ...
  static String _boDau(String input) {
    const map = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
    };
    final sb = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }

  /// Khớp nếu từ khóa (đã bỏ dấu) nằm trong tên / loại thiết bị (cũng bỏ dấu).
  /// Chỉ cần 1–2 ký tự là ra kết quả chứa — không bắt buộc gõ đúng cả tên.
  static bool _khopTen(String haystack, String needle) {
    if (needle.isEmpty) return true;
    final h = _boDau(haystack.trim());
    final n = _boDau(needle.trim());
    if (n.isEmpty) return true;
    if (h.contains(n)) return true;
    // Tách từ: "lo hap" khớp "Lò hấp tiệt trùng Autoclave..."
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.every((p) => h.contains(p));
  }

  List<ThietBiRutGon> get dsThietBiDaLoc {
    return dsThietBi.where((tb) {
      final khopDanhMuc =
          danhMucChon == null || (tb.loaiThietBi ?? 'Chưa phân loại') == danhMucChon;
      final khopTuKhoa = tuKhoaTimKiem.trim().isEmpty ||
          _khopTen(tb.tenThietBi, tuKhoaTimKiem) ||
          _khopTen(tb.loaiThietBi ?? '', tuKhoaTimKiem);
      return khopDanhMuc && khopTuKhoa;
    }).toList();
  }

  void datTuKhoaTimKiem(String tk) {
    tuKhoaTimKiem = tk;
    // Nếu đang chọn thiết bị nhưng không còn khớp từ khóa → bỏ chọn để dropdown không lỗi
    if (thietBiChon != null &&
        tk.trim().isNotEmpty &&
        !_khopTen(thietBiChon!.tenThietBi, tk) &&
        !_khopTen(thietBiChon!.loaiThietBi ?? '', tk)) {
      thietBiChon = null;
      chiTietChon = null;
      loi = null;
    }
    notifyListeners();
  }

  void chonDanhMuc(String? dm) {
    danhMucChon = dm;
    thietBiChon = null;
    chiTietChon = null;
    loi = null;
    notifyListeners();
  }

  void xoaTuKhoaTimKiem() {
    tuKhoaTimKiem = '';
    notifyListeners();
  }
}