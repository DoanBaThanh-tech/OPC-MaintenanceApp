import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

// ============ MODEL ============

class NhanVienRutGon {
  final int maNhanVien;
  final String hoTen;
  NhanVienRutGon({required this.maNhanVien, required this.hoTen});
  factory NhanVienRutGon.fromJson(Map<String, dynamic> j) =>
      NhanVienRutGon(maNhanVien: j['maNhanVien'], hoTen: j['hoTen']);
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

  factory HoSoBaoTri.fromJson(Map<String, dynamic> j) => HoSoBaoTri(
        maHoSoBaoTri: j['maHoSoBaoTri'],
        maThietBi: j['maThietBi'] ?? j['maThieBi'],
        tenThietBi: j['tenThietBi'] ?? '',
        noiDungCongViec: j['noiDungCongViec'],
        thoiGianDuKien: j['thoiGianDuKien'],
        ngayTao: DateTime.parse(j['ngayTao']),
        trangThai: j['trangThai'] ?? '',
        lyDoTuChoi: j['lyDoTuChoi'],
        maPhanCong: j['maPhanCong'],
      );
}

// ============ SERVICE ============

class WorkOrderService {
  static Future<List<HoSoBaoTri>> layDanhSachHoSoBaoTri() async {
    final data = await ApiClient.instance.get<List<dynamic>>('${ApiConstants.workOrder}/bao-tri');
    return data.map((e) => HoSoBaoTri.fromJson(e)).toList();
  }

  static Future<HoSoBaoTri> layChiTietHoSoBaoTri(int id) async {
    final data = await ApiClient.instance.get<Map<String, dynamic>>('${ApiConstants.workOrder}/bao-tri/$id');
    return HoSoBaoTri.fromJson(data);
  }

  /// MaNhanVienTao KHÔNG gửi lên — server tự lấy từ JWT Claims (đúng lưu ý bảo mật đã thống nhất)
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
    return data.map((e) => NhanVienRutGon.fromJson(e)).toList();
  }

  /// MaNhanVienPhanCong KHÔNG gửi lên — server tự lấy từ JWT (người tổ trưởng đang đăng nhập)
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