import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_exception.dart';
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
    List<Map<String, dynamic>>? danhSachBuoc,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>('${ApiConstants.workOrder}/bao-tri', {
      'maChiTietKeHoach': maChiTietKeHoach,
      'maThietBi': maThietBi,
      'noiDungCongViec': noiDungCongViec,
      'thoiGianDuKien': thoiGianDuKien,
      'guiDuyet': guiDuyet,
      if (danhSachBuoc != null) 'danhSachBuoc': danhSachBuoc,
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
    int? maNhanVienGhiChep,
    DateTime? ngayBatDau,
    DateTime? ngayKetThuc,
  }) async {
    final ds = <int>[];
    if (maNhanVienThucHiens != null) {
      ds.addAll(maNhanVienThucHiens.where((e) => e > 0));
    }
    if (ds.isEmpty && maNhanVienThucHien != null && maNhanVienThucHien > 0) {
      ds.add(maNhanVienThucHien);
    }
    if (ds.isEmpty) {
      throw ApiException(400, 'Vui lòng chọn ít nhất một nhân viên thực hiện.');
    }

    final body = <String, dynamic>{
      // Gửi cả camelCase để bind chắc chắn với API
      'maNhanVienThucHiens': ds,
      'MaNhanVienThucHiens': ds,
    };
    if (ngayBatDau != null) {
      body['ngayBatDauDuKien'] = ngayBatDau.toIso8601String();
    }
    if (ngayKetThuc != null) {
      body['ngayKetThucDuKien'] = ngayKetThuc.toIso8601String();
    }
    if (maNhanVienGhiChep != null && maNhanVienGhiChep > 0) {
      body['maNhanVienGhiChep'] = maNhanVienGhiChep;
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

  /// Xưởng lưu chỉnh sửa hồ sơ (Chờ duyệt).
  static Future<void> xuongLuuHoSo({
    required int maHoSoBaoTri,
    String? noiDungCongViec,
    String? thoiGianDuKien,
    String? gioBatDauDuKien,
    String? gioKetThucDuKien,
    DateTime? ngayDuKienBaoTri,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/xuong-luu',
      {
        if (noiDungCongViec != null) 'noiDungCongViec': noiDungCongViec,
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

  /// Tổ trưởng: Chờ gửi → Chờ duyệt (gửi xưởng).
  static Future<void> guiDenXuong({required int maHoSoBaoTri}) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/gui-den-xuong',
      {},
    );
  }

  /// Tổ trưởng sửa ngày/nội dung khi còn Chờ gửi.
  static Future<void> capNhatHoSoChoGui({
    required int maHoSoBaoTri,
    String? noiDungCongViec,
    DateTime? ngayDuKienBaoTri,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/cho-gui',
      {
        if (noiDungCongViec != null) 'noiDungCongViec': noiDungCongViec,
        if (ngayDuKienBaoTri != null)
          'ngayDuKienBaoTri':
          '${ngayDuKienBaoTri.year.toString().padLeft(4, '0')}-'
              '${ngayDuKienBaoTri.month.toString().padLeft(2, '0')}-'
              '${ngayDuKienBaoTri.day.toString().padLeft(2, '0')}',
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

  /// Xưởng sửa hồ sơ bị Giám đốc từ chối rồi gửi lại duyệt (Chờ GĐ duyệt).
  /// Tổ trưởng cơ điện không dùng endpoint này — chỉ phân công khi hồ sơ đã duyệt.
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

  // ===== HỒ SƠ SỬA CHỮA =====

  static Future<List<HoSoSuaChua>> layDanhSachHoSoSuaChua({String? trangThai}) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/sua-chua',
      query: trangThai != null && trangThai.isNotEmpty ? {'trangThai': trangThai} : null,
    );
    return data
        .map((e) => HoSoSuaChua.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<HoSoSuaChua> layChiTietHoSoSuaChua(int id) async {
    final data = await ApiClient.instance.get<dynamic>(
      '${ApiConstants.workOrder}/sua-chua/$id',
    );
    if (data is! Map) throw Exception('API không trả về object');
    return HoSoSuaChua.fromJson(Map<String, dynamic>.from(data));
  }

  /// Xưởng tạo hồ sơ SC — thiết bị chuyển Sửa chữa, gửi Tổ trưởng phân công.
  static Future<void> taoHoSoSuaChua({
    required int maThietBi,
    required String moTaHuHong,
    String? phuongAnSuaChua,
    String? thoiGianDuKien,
    String? gioBatDauDuKien,
    String? gioKetThucDuKien,
    bool guiDuyet = true,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/sua-chua',
      {
        'maThietBi': maThietBi,
        'moTaHuHong': moTaHuHong,
        if (phuongAnSuaChua != null) 'phuongAnSuaChua': phuongAnSuaChua,
        if (thoiGianDuKien != null) 'thoiGianDuKien': thoiGianDuKien,
        if (gioBatDauDuKien != null) 'gioBatDauDuKien': gioBatDauDuKien,
        if (gioKetThucDuKien != null) 'gioKetThucDuKien': gioKetThucDuKien,
        'guiDuyet': guiDuyet,
      },
    );
  }

  static Future<void> phanCongSuaChua({
    required int maHoSoSuaChua,
    List<int>? maNhanVienThucHiens,
    int? maNhanVienThucHien,
    int? maNhanVienGhiChep,
    DateTime? ngayBatDau,
    DateTime? ngayKetThuc,
  }) async {
    final body = <String, dynamic>{};
    if (ngayBatDau != null) {
      body['ngayBatDauDuKien'] = ngayBatDau.toIso8601String();
    }
    if (ngayKetThuc != null) {
      body['ngayKetThucDuKien'] = ngayKetThuc.toIso8601String();
    }
    if (maNhanVienThucHiens != null && maNhanVienThucHiens.isNotEmpty) {
      body['maNhanVienThucHiens'] = maNhanVienThucHiens;
    } else if (maNhanVienThucHien != null) {
      body['maNhanVienThucHien'] = maNhanVienThucHien;
    }
    if (maNhanVienGhiChep != null && maNhanVienGhiChep > 0) {
      body['maNhanVienGhiChep'] = maNhanVienGhiChep;
    }
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/sua-chua/$maHoSoSuaChua/phan-cong',
      body,
    );
  }

  /// NVKT bấm Tiến hành sửa chữa → HS + PC = Đang thực hiện (mọi vai trò).
  static Future<void> nhanVienTienHanhSuaChua(int maHoSoSuaChua) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/sua-chua/$maHoSoSuaChua/tien-hanh',
      {},
    );
  }

  /// NVKT bấm Tiến hành quy trình bảo trì — ghi nhận thời điểm bắt đầu thực tế.
  static Future<void> nhanVienTienHanhBaoTri(int maHoSoBaoTri) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/tien-hanh',
      {},
    );
  }

  /// Tiến độ bước quy trình (đồng bộ giữa các NVKT).
  static Future<List<Map<String, dynamic>>> layTienDoBuoc({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
  }) async {
    final data = await ApiClient.instance.get<dynamic>(
      '${ApiConstants.workOrder}/tien-do-buoc',
      query: {
        if (maHoSoBaoTri != null) 'maHoSoBaoTri': maHoSoBaoTri,
        if (maHoSoSuaChua != null) 'maHoSoSuaChua': maHoSoSuaChua,
      },
    );
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Nhận bước (DangLam) hoặc lưu đã xong (DaXong). Ném ApiException nếu bị người khác giữ.
  static Future<void> luuTienDoBuoc({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
    required int soBuoc,
    String? moTaBuoc,
    required String trangThai,
    String? jsonVatTu,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/tien-do-buoc',
      {
        if (maHoSoBaoTri != null) 'maHoSoBaoTri': maHoSoBaoTri,
        if (maHoSoSuaChua != null) 'maHoSoSuaChua': maHoSoSuaChua,
        'soBuoc': soBuoc,
        if (moTaBuoc != null) 'moTaBuoc': moTaBuoc,
        'trangThai': trangThai,
        if (jsonVatTu != null) 'jsonVatTu': jsonVatTu,
      },
    );
  }

  /// Tháng trong năm đã có hồ sơ BT của thiết bị.
  static Future<List<int>> layThangCoBaoTri(int maThietBi, {int? nam}) async {
    final y = nam ?? DateTime.now().year;
    final data = await ApiClient.instance.get<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/thiet-bi/$maThietBi/thang-co-bao-tri',
      query: {'nam': y},
    );
    final list = data['danhSachThang'] ?? data['DanhSachThang'];
    if (list is! List) return const [];
    return list
        .map((e) {
      if (e is Map) {
        final t = e['thang'] ?? e['Thang'];
        return (t as num?)?.toInt();
      }
      return int.tryParse(e.toString());
    })
        .whereType<int>()
        .toList();
  }

  /// Xưởng xác nhận / từ chối kết quả sau khi NVKT bấm Xong.
  static Future<void> xuongXacNhanKetQua({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
    required bool xacNhan,
    String? lyDo,
  }) async {
    await ApiClient.instance.put<dynamic>(
      '${ApiConstants.workOrder}/xuong-xac-nhan-ket-qua',
      {
        if (maHoSoBaoTri != null) 'maHoSoBaoTri': maHoSoBaoTri,
        if (maHoSoSuaChua != null) 'maHoSoSuaChua': maHoSoSuaChua,
        'xacNhan': xacNhan,
        if (lyDo != null) 'lyDo': lyDo,
      },
    );
  }

  static Future<void> nhanVienHoanThanhSuaChua(int maHoSoSuaChua) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/sua-chua/$maHoSoSuaChua/hoan-thanh',
      {},
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