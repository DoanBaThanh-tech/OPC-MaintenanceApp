part of xuong_quy_trinh_screen;

/// View model bước quy trình phía Xưởng (đủ bước: đã chọn / chưa chọn / đã làm).
class _BuocXuongView {
  final int soBuoc;
  final String moTa;
  final String trangThai;
  final String? tenNhanVien;
  final bool daThucHien;
  final bool daChon;
  final List<ChiTietVatTuSuDung> vatTu;

  const _BuocXuongView({
    required this.soBuoc,
    required this.moTa,
    required this.trangThai,
    this.tenNhanVien,
    required this.daThucHien,
    required this.daChon,
    this.vatTu = const [],
  });
}