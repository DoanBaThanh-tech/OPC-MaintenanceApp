part of maintenance_plan_logic;

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

  /// Các năm đã có khung kế hoạch (sau khi lập kế hoạch năm).
  static Future<List<int>> layDanhSachNamDaLap() async {
    final data = await ApiClient.instance.get<List<dynamic>>(ApiConstants.namDaLap);
    final nams = data
        .map((e) => (e as num).toInt())
        .where((n) => n >= 2000 && n <= 9999)
        .toSet()
        .toList()
      ..sort();
    return nams;
  }

  static Future<void> themThietBiVaoNam({
    required int nam,
    required int maThietBi,
    required DateTime ngay,
    required String noiDungCongViec,
    int? thoiGianDuKien,
    TimeOfDay? gioBatDau,
    TimeOfDay? gioKetThuc,
    List<Map<String, dynamic>>? danhSachBuoc,
  }) async {
    String fmtGio(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

    await ApiClient.instance.post<dynamic>(ApiConstants.themThietBiVaoNam, {
      'nam': nam,
      'maThietBi': maThietBi,
      'ngayDuKienBaoTri': _dateOnly(ngay),
      'noiDungCongViec': noiDungCongViec,
      if (thoiGianDuKien != null && thoiGianDuKien > 0)
        'thoiGianDuKien': thoiGianDuKien,
      if (gioBatDau != null) 'gioBatDauDuKien': fmtGio(gioBatDau),
      if (gioKetThuc != null) 'gioKetThucDuKien': fmtGio(gioKetThuc),
      if (danhSachBuoc != null) 'danhSachBuoc': danhSachBuoc,
    });
  }

  static Future<List<HangChoDenHanItem>> layHangChoDenHan({
    required int nam,
    required int thang,
  }) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      ApiConstants.hangChoDenHan,
      query: {'nam': nam, 'thang': thang},
    );
    return data
        .map((e) => HangChoDenHanItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Trả về message thành công từ API.
  static Future<String> taoHangLoatBaoTri({
    required int nam,
    required int thang,
    required List<int> danhSachMaThietBi,
    required String noiDungCongViec,
    List<Map<String, dynamic>>? danhSachBuoc,
  }) async {
    final res = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.taoHangLoatBaoTri,
      {
        'nam': nam,
        'thang': thang,
        'danhSachMaThietBi': danhSachMaThietBi,
        'noiDungCongViec': noiDungCongViec,
        if (danhSachBuoc != null) 'danhSachBuoc': danhSachBuoc,
      },
    );
    return res['message']?.toString() ??
        res['Message']?.toString() ??
        'Đã tạo hồ sơ bảo trì hàng loạt.';
  }
}
