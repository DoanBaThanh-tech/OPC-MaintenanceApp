class QuyTrinhNvktRules {
  QuyTrinhNvktRules._();

  /// Được sửa số lượng / thêm / xóa vật tư trong bước.
  /// - Khóa khi người khác đã Xong
  /// - Khóa khi đã Xong (trừ đang chờ điều chỉnh sau Xưởng từ chối)
  /// - Khóa ngay sau khi đã bấm "Lưu lại bước" ([daLuuDieuChinh])
  static bool coTheSuaVatTu({
    required bool daChon,
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    required bool dangXuLy,
    bool daLuuDieuChinh = false,
  }) {
    if (dangXuLy) return false;
    if (khoaBoiNguoiKhac) return false;
    if (daLuuDieuChinh) return false;
    if (daXong && !cheDoCapNhat) return false;
    return daChon;
  }

  /// Được tích checkbox — chặn khi người khác đã Xong hoặc đã lưu điều chỉnh.
  static bool coTheDoiCheckbox({
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    required bool dangXuLy,
    bool daLuuDieuChinh = false,
  }) {
    if (dangXuLy) return false;
    if (khoaBoiNguoiKhac) return false;
    if (daLuuDieuChinh) return false;
    if (daXong && !cheDoCapNhat) return false;
    return true;
  }

  static bool coTheBoTich({
    required bool daXong,
    required bool cheDoCapNhat,
    bool daLuuDieuChinh = false,
  }) {
    if (daLuuDieuChinh) return false;
    if (daXong && !cheDoCapNhat) return false;
    return true;
  }

  static bool coTheBamXong({
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    required bool dangXuLy,
    bool daLuuDieuChinh = false,
  }) {
    if (dangXuLy || khoaBoiNguoiKhac) return false;
    if (daLuuDieuChinh) return false;
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

  /// Nhãn nút theo đúng hoàn cảnh:
  /// - Quy trình mới: «Xong» → sau khi bấm: «Đã xong bước»
  /// - Xưởng từ chối (cheDoCapNhat): «Lưu lại bước» → sau khi lưu: «Cập nhật thành công»
  static String nhanNutXong({
    required bool daXong,
    required bool cheDoCapNhat,
    bool daLuuDieuChinh = false,
  }) {
    // Chỉ dùng «Cập nhật thành công» khi đang điều chỉnh sau từ chối và đã lưu
    if (cheDoCapNhat && daLuuDieuChinh) return 'Cập nhật thành công';
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
  /// - DaXong / DaCapNhat của người khác → khóa (không sửa bước người khác)
  /// - DaCapNhat của mình → đã lưu sau từ chối → khóa, nút «Cập nhật thành công»
  /// - DaXong của mình + chế độ từ chối → còn được «Lưu lại bước»
  /// - DangLam → không khóa cho người khác
  static ({
  bool daChon,
  bool daXong,
  bool khoaBoiNguoiKhac,
  bool moRong,
  bool daLuuDieuChinh,
  String? tenHienThi,
  }) apDungTienDo({
    required String trangThai,
    required bool laCuaToi,
    String? tenNhanVien,
  }) {
    // Đã lưu điều chỉnh sau Xưởng từ chối
    if (trangThai == 'DaCapNhat') {
      return (
      daChon: true,
      daXong: true,
      khoaBoiNguoiKhac: !laCuaToi,
      moRong: true,
      daLuuDieuChinh: true,
      tenHienThi: tenNhanVien,
      );
    }
    if (trangThai == 'DaXong') {
      return (
      daChon: true,
      daXong: true,
      khoaBoiNguoiKhac: !laCuaToi,
      moRong: true,
      daLuuDieuChinh: false,
      tenHienThi: tenNhanVien,
      );
    }
    if (trangThai == 'DangLam' && laCuaToi) {
      return (
      daChon: true,
      daXong: false,
      khoaBoiNguoiKhac: false,
      moRong: true,
      daLuuDieuChinh: false,
      tenHienThi: tenNhanVien,
      );
    }
    return (
    daChon: false,
    daXong: false,
    khoaBoiNguoiKhac: false,
    moRong: false,
    daLuuDieuChinh: false,
    tenHienThi: null,
    );
  }
}