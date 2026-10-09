import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/material_usage_models.dart';

class MaterialUsageService {
  MaterialUsageService._();

  /// Danh sách vật tư từ database (API). Không hardcode trên app.
  static Future<List<VatTuOption>> layDanhSachVatTu() async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.inventory}/vat-tu',
    );
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => VatTuOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Quy trình theo từng thiết bị + loại công việc từ DB.
  static Future<List<BuocQuyTrinh>> layQuyTrinhThietBi({
    required int maThietBi,
    required String loaiCongViec,
  }) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.inventory}/quy-trinh',
      query: {
        'maThietBi': maThietBi,
        'loaiCongViec': loaiCongViec,
      },
    );
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => BuocQuyTrinh.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Cập nhật nội dung các bước quy trình mẫu của thiết bị.
  static Future<void> capNhatQuyTrinhThietBi({
    required int maThietBi,
    required String loaiCongViec,
    required List<BuocQuyTrinh> buoc,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.inventory}/quy-trinh',
      {
        'maThietBi': maThietBi,
        'loaiCongViec': loaiCongViec,
        'danhSachBuoc': buoc
            .map((b) => {
          'soBuoc': b.soBuoc,
          'moTaBuoc': b.moTa,
        })
            .toList(),
      },
    );
  }

  static Future<HoSoVatTuItem?> taoHoSoVatTu({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
    required int maThietBi,
    required String tenThietBi,
    required String loaiCongViec,
    required List<BuocQuyTrinh> buoc,
  }) async {
    final chiTiet = <Map<String, dynamic>>[];
    for (final b in buoc) {
      chiTiet.addAll(b.toChiTietJsonList());
    }
    if (chiTiet.isEmpty) return null;

    final data = await ApiClient.instance.post<dynamic>(
      '${ApiConstants.inventory}/ho-so-vat-tu',
      {
        if (maHoSoBaoTri != null) 'maHoSoBaoTri': maHoSoBaoTri,
        if (maHoSoSuaChua != null) 'maHoSoSuaChua': maHoSoSuaChua,
        'maThietBi': maThietBi,
        'tenThietBi': tenThietBi,
        'loaiCongViec': loaiCongViec,
        'ngayThucHien': DateTime.now().toIso8601String(),
        'chiTiet': chiTiet,
      },
    );
    if (data is Map) {
      return HoSoVatTuItem.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// Cập nhật hồ sơ vật tư (chỉ khi còn Chờ gửi).
  static Future<HoSoVatTuItem> capNhatHoSoVatTu({
    required int maHoSoVatTu,
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
    required int maThietBi,
    required String tenThietBi,
    required String loaiCongViec,
    required List<BuocQuyTrinh> buoc,
  }) async {
    final chiTiet = <Map<String, dynamic>>[];
    for (final b in buoc) {
      chiTiet.addAll(b.toChiTietJsonList());
    }
    final data = await ApiClient.instance.put<dynamic>(
      '${ApiConstants.inventory}/ho-so-vat-tu/$maHoSoVatTu',
      {
        if (maHoSoBaoTri != null) 'maHoSoBaoTri': maHoSoBaoTri,
        if (maHoSoSuaChua != null) 'maHoSoSuaChua': maHoSoSuaChua,
        'maThietBi': maThietBi,
        'tenThietBi': tenThietBi,
        'loaiCongViec': loaiCongViec,
        'ngayThucHien': DateTime.now().toIso8601String(),
        'chiTiet': chiTiet,
      },
    );
    return HoSoVatTuItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Lấy hồ sơ vật tư theo mã hồ sơ BT/SC (mới nhất).
  static Future<HoSoVatTuItem?> layHoSoTheoCongViec({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
  }) async {
    try {
      final data = await ApiClient.instance.get<dynamic>(
        '${ApiConstants.inventory}/ho-so-vat-tu/theo-cong-viec',
        query: {
          if (maHoSoBaoTri != null) 'maHoSoBaoTri': maHoSoBaoTri,
          if (maHoSoSuaChua != null) 'maHoSoSuaChua': maHoSoSuaChua,
        },
      );
      if (data is Map) {
        return HoSoVatTuItem.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      // 404 → chưa có hồ sơ
    }
    return null;
  }

  static Future<List<HoSoVatTuItem>> layDanhSachHoSoVatTu(
      {String? trangThai}) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.inventory}/ho-so-vat-tu',
      query: trangThai != null ? {'trangThai': trangThai} : null,
    );
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => HoSoVatTuItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<HoSoVatTuItem> layChiTiet(int id) async {
    final data = await ApiClient.instance.get<dynamic>(
      '${ApiConstants.inventory}/ho-so-vat-tu/$id',
    );
    return HoSoVatTuItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<void> guiGiamDoc(int id) async {
    await ApiClient.instance.put<dynamic>(
      '${ApiConstants.inventory}/ho-so-vat-tu/$id/gui-giam-doc',
      {},
    );
  }

  /// Giám đốc xác nhận hồ sơ vật tư.
  static Future<void> xacNhan(int id) async {
    await ApiClient.instance.put<dynamic>(
      '${ApiConstants.inventory}/ho-so-vat-tu/$id/xac-nhan',
      {},
    );
  }
}