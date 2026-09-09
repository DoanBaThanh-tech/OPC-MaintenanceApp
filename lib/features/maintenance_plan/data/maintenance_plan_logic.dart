import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

class ThietBiRutGon {
  final int maThietBi; final String tenThietBi; final String? loaiThietBi; final int maChuKy;
  ThietBiRutGon({required this.maThietBi, required this.tenThietBi, this.loaiThietBi, required this.maChuKy});
  factory ThietBiRutGon.fromJson(Map<String,dynamic> j)=>ThietBiRutGon(maThietBi:(j['maThietBi'] as num?)?.toInt()??0,tenThietBi:j['tenThietBi']?.toString()??'',loaiThietBi:j['loaiThietBi']?.toString(),maChuKy:(j['maChuKy'] as num?)?.toInt()??0);
}

class ChuKyBaoTriModel {
  final int maChuKy; final String? loaiThietBi; final int soThangChuKyDeXuat;
  ChuKyBaoTriModel({required this.maChuKy,this.loaiThietBi,required this.soThangChuKyDeXuat});
  factory ChuKyBaoTriModel.fromJson(Map<String,dynamic> j)=>ChuKyBaoTriModel(maChuKy:(j['maChuKy'] as num?)?.toInt()??0,loaiThietBi:j['loaiThietBi']?.toString(),soThangChuKyDeXuat:(j['soThangChuKyDeXuat'] as num?)?.toInt()??0);
  String get nhan=>'${loaiThietBi??"Chưa rõ loại"} · $soThangChuKyDeXuat tháng/lần';
}

/// BƯỚC 1 trả về - 1 yêu cầu đăng ký ngày bảo trì đang "Chờ lập kế hoạch"
class YeuCauNgayBaoTri {
  final int maYeuCauNgayBaoTri;
  final String tenThietBi;
  final String? loaiThietBi;
  final int soThangChuKy;
  final int nam;
  final DateTime ngayBaoTri;
  final String trangThai;

  YeuCauNgayBaoTri({
    required this.maYeuCauNgayBaoTri, required this.tenThietBi, this.loaiThietBi,
    required this.soThangChuKy, required this.nam, required this.ngayBaoTri, required this.trangThai,
  });

  factory YeuCauNgayBaoTri.fromJson(Map<String,dynamic> j) => YeuCauNgayBaoTri(
    maYeuCauNgayBaoTri: (j['maYeuCauNgayBaoTri'] as num?)?.toInt() ?? 0,
    tenThietBi: j['tenThietBi']?.toString() ?? '',
    loaiThietBi: j['loaiThietBi']?.toString(),
    soThangChuKy: (j['soThangChuKy'] as num?)?.toInt() ?? 0,
    nam: (j['nam'] as num?)?.toInt() ?? 0,
    ngayBaoTri: DateTime.parse(j['ngayBaoTri'].toString()),
    trangThai: j['trangThai']?.toString() ?? '',
  );
}

class ChiTietKeHoach {
  final int maChiTietKeHoach, maThietBi; final String tenThietBi; final DateTime ngayDuKienBaoTri; final int? maHoSoBaoTri;
  ChiTietKeHoach({required this.maChiTietKeHoach,required this.maThietBi,required this.tenThietBi,required this.ngayDuKienBaoTri,this.maHoSoBaoTri});
  bool get daTaoHoSo=>maHoSoBaoTri!=null;
  factory ChiTietKeHoach.fromJson(Map<String,dynamic> j)=>ChiTietKeHoach(maChiTietKeHoach:(j['maChiTietKeHoach'] as num?)?.toInt()??0,maThietBi:(j['maThietBi'] as num?)?.toInt()??0,tenThietBi:j['tenThietBi']?.toString()??'',ngayDuKienBaoTri:DateTime.parse(j['ngayDuKienBaoTri'].toString()),maHoSoBaoTri:(j['maHoSoBaoTri'] as num?)?.toInt());
}

class KeHoachBaoTri {
  final int maKeHoach, maChuKy, nam, soThietBi; final String? tenChuKy, tenNhanVienLap, tenThietBi; final DateTime ngayLapKeHoach; final String trangThai;
  KeHoachBaoTri({required this.maKeHoach,required this.maChuKy,this.tenChuKy,required this.nam,this.tenNhanVienLap,required this.ngayLapKeHoach,required this.trangThai,required this.soThietBi,this.tenThietBi});
  factory KeHoachBaoTri.fromJson(Map<String,dynamic> j)=>KeHoachBaoTri(maKeHoach:(j['maKeHoach'] as num?)?.toInt()??0,maChuKy:(j['maChuKy'] as num?)?.toInt()??0,tenChuKy:j['tenChuKy']?.toString(),nam:(j['nam'] as num?)?.toInt()??0,tenNhanVienLap:j['tenNhanVienLap']?.toString(),ngayLapKeHoach:DateTime.parse(j['ngayLapKeHoach'].toString()),trangThai:j['trangThai']?.toString()??'',soThietBi:(j['soThietBi'] as num?)?.toInt()??0,tenThietBi:j['tenThietBi']?.toString());
}

class MaintenancePlanService {
  static String _dateOnly(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  static Future<List<ChuKyBaoTriModel>> layDanhSachChuKy() async {
    final data=await ApiClient.instance.get<List<dynamic>>(ApiConstants.chuKyBaoTri);
    return data.map((e)=>ChuKyBaoTriModel.fromJson(Map<String,dynamic>.from(e as Map))).toList();
  }

  static Future<List<ThietBiRutGon>> layDanhSachThietBi() async {
    final data=await ApiClient.instance.get<List<dynamic>>(ApiConstants.equipment);
    return data.map((e)=>ThietBiRutGon.fromJson(Map<String,dynamic>.from(e as Map))).toList();
  }

  /// BƯỚC 1: đăng ký ngày muốn bảo trì cho 1 thiết bị
  static Future<void> taoYeuCauNgayBaoTri({
    required int maThietBi,
    required int nam,
    required DateTime ngayBaoTri,
  }) async {
    await ApiClient.instance.post<Map<String,dynamic>>(ApiConstants.yeuCauNgayBaoTri, {
      'maThietBi': maThietBi,
      'nam': nam,
      'ngayBaoTri': _dateOnly(ngayBaoTri),
    });
  }

  /// Danh sách yêu cầu đang chờ lập kế hoạch - hiện ở màn BƯỚC 2 để chọn
  static Future<List<YeuCauNgayBaoTri>> layYeuCauChoLapKeHoach() async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.yeuCauNgayBaoTri}/cho-lap-ke-hoach',
    );
    return data.map((e) => YeuCauNgayBaoTri.fromJson(Map<String,dynamic>.from(e as Map))).toList();
  }

  /// BƯỚC 2: lập kế hoạch từ 1 yêu cầu đã chọn
  static Future<void> lapKeHoachTuYeuCau({
    required int maYeuCauNgayBaoTri,
    required int nam,
  }) async {
    await ApiClient.instance.post<Map<String,dynamic>>(ApiConstants.maintenancePlan, {
      'maYeuCauNgayBaoTri': maYeuCauNgayBaoTri,
      'nam': nam,
    });
  }

  static Future<List<KeHoachBaoTri>> layDanhSachKeHoach() async {
    final data=await ApiClient.instance.get<List<dynamic>>(ApiConstants.maintenancePlan);
    return data.map((e)=>KeHoachBaoTri.fromJson(Map<String,dynamic>.from(e as Map))).toList();
  }

  static Future<List<ChiTietKeHoach>> layChiTietKeHoach(int maKeHoach) async {
    final data=await ApiClient.instance.get<List<dynamic>>('${ApiConstants.maintenancePlan}/$maKeHoach/chi-tiet');
    return data.map((e)=>ChiTietKeHoach.fromJson(Map<String,dynamic>.from(e as Map))).toList();
  }
}