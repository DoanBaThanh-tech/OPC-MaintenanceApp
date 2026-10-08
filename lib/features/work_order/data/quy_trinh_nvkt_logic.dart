class QuyTrinhNvktRules {
  QuyTrinhNvktRules._();

  /// Ưu tiên mô tả: tiến độ đã lưu → bước lúc tạo hồ sơ → mẫu thiết bị.
  static String moTaUuTien({
    String? moTaTienDo,
    String? moTaHoSo,
    String? moTaMau,
    required int soBuoc,
  }) {
    final td = (moTaTienDo ?? '').trim();
    if (td.isNotEmpty) return td;
    final hs = (moTaHoSo ?? '').trim();
    if (hs.isNotEmpty) return hs;
    final mau = (moTaMau ?? '').trim();
    if (mau.isNotEmpty) return mau;
    return 'Bước $soBuoc';
  }

  /// Được chỉnh nội dung bước (cùng điều kiện sửa vật tư).
  static bool coTheSuaMoTa({
    required bool daChon,
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    required bool dangXuLy,
    bool dangMoCapNhat = false,
  }) =>
      coTheSuaVatTu(
        daChon: daChon,
        daXong: daXong,
        khoaBoiNguoiKhac: khoaBoiNguoiKhac,
        cheDoCapNhat: cheDoCapNhat,
        dangXuLy: dangXuLy,
        dangMoCapNhat: dangMoCapNhat,
      );

  /// Được sửa số lượng / thêm / xóa vật tư trong bước.
  /// - Khóa khi người khác đã Xong
  /// - Sau Xong / sau từ chối: khóa đến khi bấm «Cập nhật» ([dangMoCapNhat])
  static bool coTheSuaVatTu({
    required bool daChon,
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    required bool dangXuLy,
    bool daLuuDieuChinh = false,
    bool dangMoCapNhat = false,
  }) {
    if (dangXuLy) return false;
    if (khoaBoiNguoiKhac) return false;
    if (!daChon) return false;
    // Đã Xong → chỉ sửa khi đang mở cập nhật (cả quy trình mới & sau từ chối)
    if (daXong && !dangMoCapNhat) return false;
    return true;
  }

  /// Checkbox: khóa khi người khác Xong / đã Xong chưa mở cập nhật.
  /// Khi đang mở cập nhật được bỏ tích để hủy bước.
  static bool coTheDoiCheckbox({
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    required bool dangXuLy,
    bool daLuuDieuChinh = false,
    bool dangMoCapNhat = false,
  }) {
    if (dangXuLy) return false;
    if (khoaBoiNguoiKhac) return false;
    if (daXong && !dangMoCapNhat) return false;
    return true;
  }

  static bool coTheBoTich({
    required bool daXong,
    required bool cheDoCapNhat,
    bool daLuuDieuChinh = false,
    bool dangMoCapNhat = false,
  }) {
    // Chỉ bỏ tích khi đang mở khóa cập nhật (hoặc chưa Xong)
    if (daXong && !dangMoCapNhat) return false;
    return true;
  }

  /// Nút: luôn bấm được trừ khóa người khác / đang xử lý.
  static bool coTheBamXong({
    required bool daXong,
    required bool khoaBoiNguoiKhac,
    required bool cheDoCapNhat,
    required bool dangXuLy,
    bool daLuuDieuChinh = false,
  }) {
    if (dangXuLy || khoaBoiNguoiKhac) return false;
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

  /// Nhãn nút (quy trình mới + sau Xưởng từ chối giống nhau):
  /// - Lần đầu: «Xong»
  /// - Đã xong (khóa): «Cập nhật» → mở khóa
  /// - Đang mở sửa: «Lưu cập nhật» → khóa lại (hoặc bỏ tích rồi lưu = hủy bước)
  static String nhanNutXong({
    required bool daXong,
    required bool cheDoCapNhat,
    bool daLuuDieuChinh = false,
    bool dangMoCapNhat = false,
  }) {
    if (daXong && dangMoCapNhat) return 'Lưu cập nhật';
    if (daXong) return 'Cập nhật';
    return 'Xong';
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
      if (ten.isNotEmpty) return 'Bước $soBuoc · Đã lưu · $ten';
      return 'Bước $soBuoc · Đã lưu';
    }
    if (dangLam) {
      if (ten.isNotEmpty) return 'Bước $soBuoc · Đang làm · $ten';
      return 'Bước $soBuoc · Đang làm';
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
    if (khoaBoiNguoiKhac) {
      final ten = (tenNguoiGiu ?? '').trim();
      if (ten.isNotEmpty) {
        return 'Do $ten thực hiện — chỉ xem.';
      }
      return 'Bước đã hoàn thành bởi người khác — chỉ xem.';
    }
    return 'Đã khóa bước — bấm «Cập nhật» để mở sửa, rồi «Lưu cập nhật» để khóa lại.';
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
        'Nháp được lưu tự động. Sau Xong bấm Cập nhật để sửa tiếp.';
  }

  /// Áp tiến độ API:
  /// - DuocChon: chỉ khi quy trình mới (screen bỏ qua khi cheDoCapNhat)
  /// - DaXong / DaCapNhat → đã xong, khóa đến khi bấm Cập nhật
  /// - DangLam của mình → đang làm
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
    bool boQuaDuocChon = false,
  }) {
    // Tổ trưởng chọn sẵn — bỏ qua khi cập nhật sau từ chối
    if (trangThai == 'DuocChon') {
      if (boQuaDuocChon) {
        return (
        daChon: false,
        daXong: false,
        khoaBoiNguoiKhac: false,
        moRong: false,
        daLuuDieuChinh: false,
        tenHienThi: null,
        );
      }
      return (
      daChon: true,
      daXong: false,
      khoaBoiNguoiKhac: false,
      moRong: true,
      daLuuDieuChinh: false,
      tenHienThi: null,
      );
    }
    // Đã lưu sau Xưởng từ chối — coi như đã Xong, khóa đến Cập nhật
    if (trangThai == 'DaCapNhat') {
      return (
      daChon: true,
      daXong: true,
      khoaBoiNguoiKhac: !laCuaToi,
      moRong: true,
      daLuuDieuChinh: false,
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
      // Chưa Xong → không hiện tên
      tenHienThi: null,
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