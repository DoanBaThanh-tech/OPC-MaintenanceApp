class QuyTrinhNvktRules {
  QuyTrinhNvktRules._();

  /// Được sửa số lượng / thêm / xóa vật tư trong bước.
  /// Khóa chỉ khi bước đã Xong (của mình hoặc người khác), trừ Xưởng từ chối.
  static bool coTheSuaVatTu({
    required bool daChon,
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    required bool dangXuLy,
  }) {
    if (dangXuLy) return false;
    // khoaBoiNguoiKhac chỉ true khi người khác đã Xong
    if (khoaBoiNguoiKhac) return false;
    if (daXong && !cheDoCapNhat) return false;
    return daChon;
  }

  /// Được tích checkbox — chỉ chặn khi người khác đã Xong bước đó.
  static bool coTheDoiCheckbox({
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    required bool dangXuLy,
  }) {
    if (dangXuLy) return false;
    if (khoaBoiNguoiKhac) return false; // người khác đã Xong
    if (daXong && !cheDoCapNhat) return false;
    return true;
  }

  static bool coTheBoTich({
    required bool daXong,
    required bool cheDoCapNhat,
  }) {
    if (daXong && !cheDoCapNhat) return false;
    return true;
  }

  static bool coTheBamXong({
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    required bool dangXuLy,
  }) {
    if (dangXuLy || khoaBoiNguoiKhac) return false;
    if (daXong && !cheDoCapNhat) return false;
    return true;
  }

  /// Bắt buộc có ≥1 vật tư hợp lệ trước khi Xong.
  /// Trả về null nếu OK, ngược lại chuỗi lỗi.
  static String? kiemTraTruocKhiXong({
    required int soDongVatTu,
    required List<String?> loiSoLuongTungDong,
  }) {
    if (soDongVatTu <= 0) {
      return 'Vui lòng chọn ít nhất 1 vật tư trước khi bấm Xong.';
    }
    for (final loi in loiSoLuongTungDong) {
      if (loi != null && loi.isNotEmpty) return loi;
    }
    return null;
  }

  /// Thành tiền 1 dòng = số lượng × đơn giá.
  static int thanhTienDong({required int soLuong, required int donGia}) {
    if (soLuong <= 0 || donGia < 0) return 0;
    return soLuong * donGia;
  }

  /// Tổng tiền mọi dòng vật tư đã chọn.
  static int tongTienVatTu(List<({int soLuong, int donGia})> dong) {
    var sum = 0;
    for (final d in dong) {
      sum += thanhTienDong(soLuong: d.soLuong, donGia: d.donGia);
    }
    return sum;
  }

  /// Gộp vật tư trùng (cùng mã/tên) — hồ sơ vật tư chỉ liệt kê VT, không theo bước.
  static List<({String ten, int soLuong, int donGia, int thanhTien})>
  gopVatTuKhongTheoBuoc(
      List<({int? maVatTu, String ten, int soLuong, int donGia})> dong,
      ) {
    final map = <String, ({String ten, int soLuong, int donGia})>{};
    for (final d in dong) {
      if (d.ten.isEmpty || d.soLuong <= 0) continue;
      final key = d.maVatTu != null ? 'id:${d.maVatTu}' : 'ten:${d.ten}';
      final cu = map[key];
      if (cu == null) {
        map[key] = (ten: d.ten, soLuong: d.soLuong, donGia: d.donGia);
      } else {
        map[key] = (
        ten: cu.ten,
        soLuong: cu.soLuong + d.soLuong,
        donGia: d.donGia > 0 ? d.donGia : cu.donGia,
        );
      }
    }
    return map.values
        .map((e) => (
    ten: e.ten,
    soLuong: e.soLuong,
    donGia: e.donGia,
    thanhTien: thanhTienDong(soLuong: e.soLuong, donGia: e.donGia),
    ))
        .toList();
  }

  static String nhanNutXong({
    required bool daXong,
    required bool cheDoCapNhat,
  }) {
    if (!daXong) return 'Xong';
    if (cheDoCapNhat) return 'Lưu lại bước';
    return 'Đã xong bước';
  }

  /// Tiêu đề: "Bước 2 · Đã xong · Trần Thị Mai"
  static String tieuDeBuoc({
    required int soBuoc,
    required bool daXong,
    required bool dangLam,
    String? tenNguoiThucHien,
  }) {
    final ten = (tenNguoiThucHien ?? '').trim();
    if (daXong) {
      if (ten.isNotEmpty) return 'Bước $soBuoc · Đã xong · $ten';
      return 'Bước $soBuoc · Đã xong';
    }
    return 'Bước $soBuoc';
  }

  static String? ghiChuBuocDaXong({
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    String? tenNguoiGiu,
  }) {
    if (!daXong || cheDoCapNhat) return null;
    final ten = (tenNguoiGiu ?? '').trim();
    if (ten.isNotEmpty) {
      return 'Do $ten thực hiện — chỉ xem, không chỉnh sửa (trừ khi Xưởng từ chối).';
    }
    return 'Đã xong bước — không chỉnh số lượng / thêm vật tư (trừ khi Xưởng từ chối).';
  }

  static String goiYChuaChonBuoc({
    required bool khoaBoiNguoiKhac,
    required bool daXong,
    String? tenNguoiGiu,
  }) {
    final ten = (tenNguoiGiu ?? '').trim();
    // Chỉ khóa khi đã Xong bởi người khác
    if (khoaBoiNguoiKhac && daXong) {
      return ten.isNotEmpty
          ? 'Bước này do $ten đã hoàn thành — chỉ xem (reload để cập nhật).'
          : 'Bước đã hoàn thành bởi người khác — chỉ xem.';
    }
    return 'Tích chọn bước → chọn vật tư → bấm Xong. '
        'Chỉ khi đã Xong, NV khác mới không sửa được bước đó.';
  }

  /// Áp tiến độ API:
  /// - DaXong của người khác → khóa
  /// - DangLam → không khóa (NV khác vẫn làm được; chỉ DaXong mới khóa)
  static ({
  bool daChon,
  bool daXong,
  bool khoaBoiNguoiKhac,
  bool moRong,
  String? tenHienThi,
  }) apDungTienDo({
    required String trangThai,
    required bool laCuaToi,
    String? tenNhanVien,
  }) {
    if (trangThai == 'DaXong') {
      return (
      daChon: true,
      daXong: true,
      khoaBoiNguoiKhac: !laCuaToi,
      moRong: true,
      tenHienThi: tenNhanVien,
      );
    }
    // DangLam: không khóa cho người khác
    if (trangThai == 'DangLam' && laCuaToi) {
      return (
      daChon: true,
      daXong: false,
      khoaBoiNguoiKhac: false,
      moRong: true,
      tenHienThi: tenNhanVien,
      );
    }
    return (
    daChon: false,
    daXong: false,
    khoaBoiNguoiKhac: false,
    moRong: false,
    tenHienThi: null,
    );
  }
}