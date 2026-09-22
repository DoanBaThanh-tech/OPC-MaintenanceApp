import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/work_order_models.dart';

// Service gọi API — không giữ state UI

class WorkOrderService {
  static Future<List<HoSoBaoTri>> layDanhSachHoSoBaoTri({int? nam}) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/bao-tri',
      query: nam != null ? {'nam': nam} : null,
    );
    return data.map((e) => HoSoBaoTri.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<HoSoBaoTri> layChiTietHoSoBaoTri(int id) async {
    final data = await ApiClient.instance.get<dynamic>(
      '${ApiConstants.workOrder}/bao-tri/$id',
    );
    if (data is! Map) {
      throw Exception('API không trả về object');
    }
    return HoSoBaoTri.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<List<int>> layDanhSachNamCoKeHoach() async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.maintenancePlan}/nam-da-lap',
    );
    return data.map((e) => (e as num).toInt()).toList();
  }

  /// MaNhanVienTao KHÔNG gửi lên — server tự lấy từ JWT Claims.
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
    return data.map((e) => NhanVienRutGon.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// MaNhanVienPhanCong KHÔNG gửi lên — server tự lấy từ JWT (tổ trưởng đang đăng nhập).
  /// Hỗ trợ chọn nhiều nhân viên (maNhanVienThucHiens).
  static Future<void> phanCongBaoTri({
    required int maHoSoBaoTri,
    int? maNhanVienThucHien,
    List<int>? maNhanVienThucHiens,
    required DateTime ngayBatDau,
    required DateTime ngayKetThuc,
  }) async {
    final body = <String, dynamic>{
      'ngayBatDauDuKien': ngayBatDau.toIso8601String(),
      'ngayKetThucDuKien': ngayKetThuc.toIso8601String(),
    };
    if (maNhanVienThucHiens != null && maNhanVienThucHiens.isNotEmpty) {
      body['maNhanVienThucHiens'] = maNhanVienThucHiens;
    } else if (maNhanVienThucHien != null) {
      body['maNhanVienThucHien'] = maNhanVienThucHien;
    }
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/phan-cong',
      body,
    );
  }

  /// NVKT bấm Hoàn thành bảo trì — đồng bộ tất cả phân công cùng hồ sơ.
  static Future<void> nhanVienHoanThanhBaoTri(int maHoSoBaoTri) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/nhan-vien-hoan-thanh',
      {},
    );
  }

  /// Xưởng lưu chỉnh sửa hồ sơ (vẫn Chờ xưởng).
  static Future<void> xuongLuuHoSo({
    required int maHoSoBaoTri,
    String? noiDungCongViec,
    String? thoiGianDuKien,
    String? gioBatDauDuKien,
    String? gioKetThucDuKien,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/xuong-luu',
      {
        if (noiDungCongViec != null) 'noiDungCongViec': noiDungCongViec,
        if (thoiGianDuKien != null) 'thoiGianDuKien': thoiGianDuKien,
        if (gioBatDauDuKien != null) 'gioBatDauDuKien': gioBatDauDuKien,
        if (gioKetThucDuKien != null) 'gioKetThucDuKien': gioKetThucDuKien,
      },
    );
  }

  /// Xưởng gửi Giám đốc duyệt.
  static Future<void> xuongGuiGiamDoc({
    required int maHoSoBaoTri,
    String? noiDungCongViec,
    String? thoiGianDuKien,
    String? gioBatDauDuKien,
    String? gioKetThucDuKien,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/xuong-gui-giam-doc',
      {
        if (noiDungCongViec != null) 'noiDungCongViec': noiDungCongViec,
        if (thoiGianDuKien != null) 'thoiGianDuKien': thoiGianDuKien,
        if (gioBatDauDuKien != null) 'gioBatDauDuKien': gioBatDauDuKien,
        if (gioKetThucDuKien != null) 'gioKetThucDuKien': gioKetThucDuKien,
      },
    );
  }
  /// NVKT xác nhận nhận việc → backend: Đã duyệt → Đang thực hiện
  static Future<void> nhanVienXacNhanBaoTri(int maHoSoBaoTri) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/nhan-viec',
      {},
    );
  }

  /// Tổ trưởng sửa hồ sơ bị từ chối rồi gửi lại duyệt
  static Future<void> suaHoSoBiTuChoi({
    required int maHoSoBaoTri,
    required String noiDungCongViec,
    String? thoiGianDuKien,
    String? gioBatDauDuKien,
    String? gioKetThucDuKien,
    DateTime? ngayDuKienBaoTri,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/sua-tu-choi',
      {
        'noiDungCongViec': noiDungCongViec,
        if (thoiGianDuKien != null) 'thoiGianDuKien': thoiGianDuKien,
        if (gioBatDauDuKien != null) 'gioBatDauDuKien': gioBatDauDuKien,
        if (gioKetThucDuKien != null) 'gioKetThucDuKien': gioKetThucDuKien,
        if (ngayDuKienBaoTri != null)
          'ngayDuKienBaoTri':
          '${ngayDuKienBaoTri.year.toString().padLeft(4, '0')}-'
              '${ngayDuKienBaoTri.month.toString().padLeft(2, '0')}-'
              '${ngayDuKienBaoTri.day.toString().padLeft(2, '0')}',
      },
    );
  }
  static Future<List<LichSuPhanCong>> layLichSuPhanCong() async {
    final data = await ApiClient.instance.get<List<dynamic>>('${ApiConstants.workOrder}/phan-cong');
    return data.map((e) => LichSuPhanCong.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Tổ trưởng hủy phân công đang Chờ xác nhận / Từ chối
  static Future<void> huyPhanCong(int maPhanCong) async {
    await ApiClient.instance.delete('${ApiConstants.workOrder}/phan-cong/$maPhanCong');
  }

  /// Yêu cầu được phân công cho NVKT đang đăng nhập
  static Future<List<YeuCauPhanCong>> layYeuCauCuaToi({String? loai, String? trangThai}) async {
    final query = <String, dynamic>{};
    if (loai != null) query['loai'] = loai;
    if (trangThai != null) query['trangThai'] = trangThai;
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/yeu-cau-cua-toi',
      query: query.isEmpty ? null : query,
    );
    return data.map((e) => YeuCauPhanCong.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<YeuCauPhanCong>> layYeuCauDaXacNhan({String? loai}) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/yeu-cau-da-xac-nhan',
      query: loai != null ? {'loai': loai} : null,
    );
    return data.map((e) => YeuCauPhanCong.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> nhanVienTuChoiBaoTri({required int maHoSo, required String lyDo}) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSo/tu-choi-nhan-viec',
      {'lyDo': lyDo},
    );
  }

  static Future<void> nhanVienXacNhanSuaChua(int maHoSo) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/sua-chua/$maHoSo/nhan-viec',
      {},
    );
  }

  static Future<void> nhanVienTuChoiSuaChua({required int maHoSo, required String lyDo}) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/sua-chua/$maHoSo/tu-choi-nhan-viec',
      {'lyDo': lyDo},
    );
  }

  static Future<void> ghiNhanKetQua({
    required int maPhanCong,
    required int maNhanVienGhiNhan,
    String? ghiChu,
    DateTime? ngayGhiNhan,
    String? soLieuGhiNhan,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/phan-cong/$maPhanCong/ket-qua',
      {
        'maNhanVienGhiNhan': maNhanVienGhiNhan,
        if (ghiChu != null) 'ghiChu': ghiChu,
        if (soLieuGhiNhan != null) 'soLieuGhiNhan': soLieuGhiNhan,
        if (ngayGhiNhan != null) 'ngayGhiNhan': ngayGhiNhan.toIso8601String(),
      },
    );
  }
}