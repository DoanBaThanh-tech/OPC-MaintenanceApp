import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

// ============ MODEL ============

/// Rút gọn — chỉ đủ field để chọn trong dropdown, chưa phải feature
/// "Danh sách thiết bị" đầy đủ (sẽ tách riêng khi làm tới)
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
        maThietBi: j['maThietBi'],
        tenThietBi: j['tenThietBi'],
        loaiThietBi: j['loaiThietBi'],
        maChuKy: j['maChuKy'],
      );
}

class ChuKyBaoTriModel {
  final int maChuKy;
  final String? loaiThietBi;
  final int soThangChuKyDeXuat;

  ChuKyBaoTriModel({required this.maChuKy, this.loaiThietBi, required this.soThangChuKyDeXuat});

  factory ChuKyBaoTriModel.fromJson(Map<String, dynamic> j) => ChuKyBaoTriModel(
      maChuKy: (j['maChuKy'] as num?)?.toInt() ?? 0,
        loaiThietBi: j['loaiThietBi'],
      soThangChuKyDeXuat: (j['soThangChuKyDeXuat'] as num?)?.toInt() ?? 0,
      );

  String get nhan => '${loaiThietBi ?? "Chưa rõ loại"} · $soThangChuKyDeXuat tháng/lần';
}

/// 1 dòng thiết bị trong kế hoạch — người dùng tự chọn ngày dự kiến bảo trì,
/// KHÁC với ngày lập kế hoạch (đúng lưu ý bạn nhấn mạnh)
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
  final int? maHoSoBaoTri; // null = chưa tạo hồ sơ, có giá trị = đã tạo

  ChiTietKeHoach({
    required this.maChiTietKeHoach,
    required this.maThietBi,
    required this.tenThietBi,
    required this.ngayDuKienBaoTri,
    this.maHoSoBaoTri,
  });

  bool get daTaoHoSo => maHoSoBaoTri != null;

  factory ChiTietKeHoach.fromJson(Map<String, dynamic> j) => ChiTietKeHoach(
        maChiTietKeHoach: j['maChiTietKeHoach'],
        maThietBi: j['maThietBi'],
        tenThietBi: j['tenThietBi'] ?? '',
        ngayDuKienBaoTri: DateTime.parse(j['ngayDuKienBaoTri']),
        maHoSoBaoTri: j['maHoSoBaoTri'],
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
  // BỎ: ngayBatDauKeHoach, ngayKetThucKeHoach — không có trong DB

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
        maKeHoach: j['maKeHoach'],
        maChuKy: j['maChuKy'],
        tenChuKy: j['tenChuKy'],
        nam: j['nam'],
        tenNhanVienLap: j['tenNhanVienLap'],
        ngayLapKeHoach: DateTime.parse(j['ngayLapKeHoach']),
        trangThai: j['trangThai'] ?? '',
        soThietBi: j['soThietBi'] ?? 0,
        tenThietBi: j['tenThietBi'],
      );
}

// ============ SERVICE ============

class MaintenancePlanService {
  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Future<List<ChuKyBaoTriModel>> layDanhSachChuKy() async {
    final data = await ApiClient.instance.get<List<dynamic>>(ApiConstants.chuKyBaoTri);
    return data.map((e) => ChuKyBaoTriModel.fromJson(e)).toList();
  }

  static Future<List<ThietBiRutGon>> layThietBiTheoChuKy(int maChuKy) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      ApiConstants.equipment,
      query: {'maChuKy': maChuKy},
    );
    return data.map((e) => ThietBiRutGon.fromJson(e)).toList();
  }

  static Future<List<ThietBiRutGon>> layDanhSachThietBi() async {
    final data = await ApiClient.instance.get<List<dynamic>>(ApiConstants.equipment);
    return data.map((e) => ThietBiRutGon.fromJson(e)).toList();
  }

  static Future<List<KeHoachBaoTri>> layDanhSachKeHoach() async {
    final data = await ApiClient.instance.get<List<dynamic>>(ApiConstants.maintenancePlan);
    return data.map((e) => KeHoachBaoTri.fromJson(e)).toList();
  }

  static Future<List<ChiTietKeHoach>> layChiTietKeHoach(int maKeHoach) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.maintenancePlan}/$maKeHoach/chi-tiet',
    );
    return data.map((e) => ChiTietKeHoach.fromJson(e)).toList();
  }

  /// Tạo kế hoạch cả năm + danh sách thiết bị kèm ngày dự kiến bảo trì riêng
  static Future<void> taoKeHoach({
  required int maChuKy,
  required int nam,
  required List<ChiTietKeHoachInput> danhSachThietBi,
}) async {
  await ApiClient.instance.post<Map<String, dynamic>>(ApiConstants.maintenancePlan, {
    'maChuKy': maChuKy,
    'nam': nam,
    'thietBiDuocChon': danhSachThietBi   // đổi tên key cho khớp DTO C#
        .map((e) => {
              'maThietBi': e.thietBi.maThietBi,
              'ngayDuKienBaoTri': _dateOnly(e.ngayDuKienBaoTri),
            })
        .toList(),
  });
}
}