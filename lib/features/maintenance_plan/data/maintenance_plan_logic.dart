import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

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

/// Phân loại trạng thái thành nhóm cố định — presentation tự map ra màu,
/// logic không phụ thuộc vào Flutter Material (Color) để giữ file này thuần dữ liệu.
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

// ============================================================
// SERVICE (gọi API thuần, không giữ state)
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

  static Future<void> themLanBaoTri({
  required int maKeHoach,
  required int maThietBi,
  required DateTime ngayDuKienBaoTri,
}) async {
  await ApiClient.instance.post<Map<String, dynamic>>(
    '${ApiConstants.maintenancePlan}/$maKeHoach/them-lan-bao-tri',
    {
      'maThietBi': maThietBi,
      'ngayDuKienBaoTri': _dateOnly(ngayDuKienBaoTri),
    },
  );
}

  static Future<void> taoKeHoach({
    required int maChuKy,
    required int nam,
    required List<ChiTietKeHoachInput> danhSachThietBi,
  }) async {
    if (maChuKy <= 0) throw Exception('Mã chu kỳ không hợp lệ: $maChuKy');
    if (nam < 2000 || nam > 2100) throw Exception('Năm không hợp lệ: $nam');
    if (danhSachThietBi.isEmpty) throw Exception('Chưa có thiết bị nào được chọn');

    final requestBody = {
      'maChuKy': maChuKy,
      'nam': nam,
      'thietBiDuocChon': danhSachThietBi
          .map((e) => {
                'maThietBi': e.thietBi.maThietBi,
                'ngayDuKienBaoTri': _dateOnly(e.ngayDuKienBaoTri),
              })
          .toList(),
    };

    await ApiClient.instance.post<Map<String, dynamic>>(ApiConstants.maintenancePlan, requestBody);
  }
}

// ============================================================
// CONTROLLERS (toàn bộ state + nghiệp vụ — presentation chỉ gọi & lắng nghe)
// ============================================================

class MaintenancePlanListController extends ChangeNotifier {
  List<KeHoachBaoTri> danhSach = [];
  bool dangTai = true;
  String? loi;

  Future<void> taiDanhSach() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      danhSach = await MaintenancePlanService.layDanhSachKeHoach();
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }
}

class MaintenancePlanDetailController extends ChangeNotifier {
  final int maKeHoach;
  final int maChuKy;
  final int nam;
  MaintenancePlanDetailController(this.maKeHoach, this.maChuKy, this.nam);

  List<ChiTietKeHoach> danhSach = [];
  bool dangTai = true;
  bool dangThem = false;
  String? loi;
  int? _soThangChuKy;

  DateTime get ngayDauNam => DateTime(nam, 1, 1);
  DateTime get ngayCuoiNam => DateTime(nam, 12, 31);

  Future<void> taiChiTiet() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        MaintenancePlanService.layChiTietKeHoach(maKeHoach),
        MaintenancePlanService.layDanhSachChuKy(),
      ]);
      danhSach = results[0] as List<ChiTietKeHoach>;
      final dsChuKy = results[1] as List<ChuKyBaoTriModel>;
      final trung = dsChuKy.where((c) => c.maChuKy == maChuKy);
      _soThangChuKy = trung.isEmpty ? null : trung.first.soThangChuKyDeXuat;
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  int? get maThietBiCuaKeHoach => danhSach.isEmpty ? null : danhSach.first.maThietBi;
  String? get tenThietBiCuaKeHoach => danhSach.isEmpty ? null : danhSach.first.tenThietBi;

  /// Ngày gợi ý cho lần bảo trì tiếp theo = ngày gần nhất hiện có + số tháng chu kỳ.
  /// Trả về null nếu chưa đủ dữ liệu (chưa có chu kỳ hoặc chưa có lần bảo trì nào).
  DateTime? get ngayGoiYLanTiepTheo {
    if (danhSach.isEmpty || _soThangChuKy == null) return null;
    final ganNhat = danhSach.map((c) => c.ngayDuKienBaoTri).reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime(ganNhat.year, ganNhat.month + _soThangChuKy!, ganNhat.day);
  }

  /// Rule mới: nếu ngày gợi ý cho lần tiếp theo đã lấn qua năm sau (ví dụ kế hoạch
  /// 2027 nhưng gợi ý ra 2028) thì KHÔNG cho thêm nữa — phải lập kế hoạch năm sau.
  /// Nếu chưa tính được ngày gợi ý (thiếu chu kỳ), vẫn cho phép chọn thủ công
  /// trong phạm vi năm hiện tại.
  bool get coTheThemLanBaoTri {
    final goiY = ngayGoiYLanTiepTheo;
    if (goiY == null) return true;
    return !goiY.isAfter(ngayCuoiNam);
  }

  /// Trả về true nếu thêm thành công
  Future<bool> themLanBaoTri(DateTime ngay) async {
    final maThietBi = maThietBiCuaKeHoach;
    if (maThietBi == null) {
      loi = 'Kế hoạch chưa có thiết bị nào để thêm lần bảo trì';
      notifyListeners();
      return false;
    }
    // Điều kiện chặn tại client trước khi gọi API — đối chiếu đúng năm kế hoạch
    if (ngay.year != nam) {
      loi = 'Ngày bảo trì phải thuộc năm $nam. Muốn bảo trì sang năm ${ngay.year}, '
          'vui lòng lập kế hoạch bảo trì mới cho năm ${ngay.year}.';
      notifyListeners();
      return false;
    }
    dangThem = true;
    loi = null;
    notifyListeners();
    try {
      await MaintenancePlanService.themLanBaoTri(maKeHoach: maKeHoach, maThietBi: maThietBi, ngayDuKienBaoTri: ngay);
      await taiChiTiet();
      return true;
    } catch (e) {
      loi = 'Không thêm được lần bảo trì: $e';
      notifyListeners();
      return false;
    } finally {
      dangThem = false;
      notifyListeners();
    }
  }
}

class CreateMaintenancePlanController extends ChangeNotifier {
  List<ChuKyBaoTriModel> dsChuKy = [];
  List<ThietBiRutGon> dsThietBi = [];
  ThietBiRutGon? thietBiChon;
  ChiTietKeHoachInput? chiTietChon;

  int nam = DateTime.now().year;
  DateTime ngayBatDau = DateTime(DateTime.now().year, 1, 1);
  DateTime ngayKetThuc = DateTime(DateTime.now().year, 12, 31);

  bool dangTai = true;
  bool dangLuu = false;
  String? loi;

  Future<void> taiDuLieuBanDau() async {
    dangTai = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        MaintenancePlanService.layDanhSachChuKy(),
        MaintenancePlanService.layDanhSachThietBi(),
      ]);
      dsChuKy = results[0] as List<ChuKyBaoTriModel>;
      dsThietBi = results[1] as List<ThietBiRutGon>;
    } catch (e) {
      loi = 'Không tải được danh sách chu kỳ';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  /// Chu kỳ được xác định CỐ ĐỊNH theo đúng ThietBi.MaChuKy trong DB —
  /// không cho người dùng tự chọn/sửa qua lại ở bước lập kế hoạch,
  /// tránh 1 thiết bị bị đổi chu kỳ lung tung giữa các lần lập kế hoạch.
  ChuKyBaoTriModel? get chuKyCoDinh {
    if (thietBiChon == null) return null;
    try {
      return dsChuKy.firstWhere((c) => c.maChuKy == thietBiChon!.maChuKy);
    } catch (_) {
      return null;
    }
  }

  void chonThietBi(ThietBiRutGon? thietBi) {
    if (thietBi == null) return;
    thietBiChon = thietBi;
    chiTietChon = ChiTietKeHoachInput(thietBi: thietBi, ngayDuKienBaoTri: DateTime(nam, 1, 1));
    loi = null;
    notifyListeners();
  }

  void doiNam(String value) {
    final n = int.tryParse(value);
    if (n == null || n < 2000 || n > 2100) return;
    nam = n;
    ngayBatDau = DateTime(n, 1, 1);
    ngayKetThuc = DateTime(n, 12, 31);
    chiTietChon?.ngayDuKienBaoTri = DateTime(n, 1, 1);
    notifyListeners();
  }

  DateTime ngayDuKienKhoiTao() {
    var d = chiTietChon?.ngayDuKienBaoTri ?? ngayBatDau;
    if (d.isBefore(ngayBatDau)) d = ngayBatDau;
    if (d.isAfter(ngayKetThuc)) d = ngayKetThuc;
    return d;
  }

  void datNgayDuKien(DateTime ngay) {
    if (chiTietChon == null) return;
    chiTietChon!.ngayDuKienBaoTri = ngay;
    notifyListeners();
  }

  void datNgayBatDau(DateTime ngay) {
    final ngayMoi = DateTime(nam, ngay.month, ngay.day);
    if (ngayMoi.isAfter(ngayKetThuc)) {
      loi = 'Ngày bắt đầu không được sau ngày kết thúc';
      notifyListeners();
      return;
    }
    ngayBatDau = ngayMoi;
    loi = null;
    if (chiTietChon != null && chiTietChon!.ngayDuKienBaoTri.isBefore(ngayBatDau)) {
      chiTietChon!.ngayDuKienBaoTri = ngayBatDau;
    }
    notifyListeners();
  }

  void datNgayKetThuc(DateTime ngay) {
    final ngayMoi = DateTime(nam, ngay.month, ngay.day);
    if (ngayMoi.isBefore(ngayBatDau)) {
      loi = 'Ngày kết thúc không được trước ngày bắt đầu';
      notifyListeners();
      return;
    }
    ngayKetThuc = ngayMoi;
    loi = null;
    if (chiTietChon != null && chiTietChon!.ngayDuKienBaoTri.isAfter(ngayKetThuc)) {
      chiTietChon!.ngayDuKienBaoTri = ngayKetThuc;
    }
    notifyListeners();
  }

  /// Trả về true nếu lưu thành công — presentation chỉ cần pop(context, true) khi true.
  Future<bool> luuKeHoach() async {
    if (chiTietChon == null || thietBiChon == null) {
      loi = 'Vui lòng chọn thiết bị';
      notifyListeners();
      return false;
    }
    if (chuKyCoDinh == null) {
      loi = 'Thiết bị này chưa được gán chu kỳ bảo trì trong hệ thống, liên hệ Admin để cập nhật';
      notifyListeners();
      return false;
    }
    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await MaintenancePlanService.taoKeHoach(
        maChuKy: thietBiChon!.maChuKy,
        nam: nam,
        danhSachThietBi: [chiTietChon!],
      );
      return true;
    } catch (e) {
      debugPrint('LỖI LƯU KẾ HOẠCH: $e');
      loi = 'Đã có lỗi xảy ra ở hệ thống, vui lòng thử lại sau hoặc liên hệ quản trị viên.';
      return false;
    } finally {
      dangLuu = false;
      notifyListeners();
    }
  }
}