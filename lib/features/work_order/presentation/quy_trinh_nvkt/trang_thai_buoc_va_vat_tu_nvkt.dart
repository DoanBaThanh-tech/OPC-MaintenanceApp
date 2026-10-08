part of quy_trinh_nvkt_screen;

class _BuocState {
  int soBuoc;
  final TextEditingController moTaCtrl;
  final List<_VatTuDongState> vatTu;
  /// NVKT tích chọn bước sẽ thực hiện
  bool daChon;
  /// Đã bấm Xong trong bước
  bool daXong;
  /// Mở rộng chọn vật tư
  bool moRong;
  /// Người khác đang giữ / đã xong bước này
  bool khoaBoiNguoiKhac;
  String? tenNguoiGiu;
  /// Đã bấm Lưu lại bước / Xong thành công → khóa nút & không sửa nữa
  bool daLuuDieuChinh;
  /// Đang mở chế độ sửa sau khi bấm «Cập nhật» (chưa Lưu cập nhật).
  bool dangMoCapNhat;

  _BuocState({required this.soBuoc, required String moTa})
      : moTaCtrl = TextEditingController(text: moTa),
        vatTu = [],
        daChon = false,
        daXong = false,
        moRong = false,
        khoaBoiNguoiKhac = false,
        daLuuDieuChinh = false,
        dangMoCapNhat = false;

  void dispose() {
    moTaCtrl.dispose();
    for (final v in vatTu) {
      v.dispose();
    }
  }
}

class _VatTuDongState {
  final int? maVatTu;
  final String tenVatTu;
  int soLuong;
  final int donGia;
  final TextEditingController slCtrl;

  _VatTuDongState({
    this.maVatTu,
    required this.tenVatTu,
    required this.soLuong,
    required this.donGia,
  }) : slCtrl = TextEditingController(text: soLuong.toString());

  void dispose() => slCtrl.dispose();
}