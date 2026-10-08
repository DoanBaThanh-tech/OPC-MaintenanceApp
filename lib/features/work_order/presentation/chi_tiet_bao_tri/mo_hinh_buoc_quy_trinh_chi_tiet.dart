part of work_order_detail_screen;

class _BuocQtDetailView {
  final int soBuoc;
  final String moTa;
  final String trangThai;
  final String? tenNhanVien;
  final bool daThucHien;
  final bool daChon;
  final List<ChiTietVatTuSuDung> vatTu;
  _BuocQtDetailView({
    required this.soBuoc,
    required this.moTa,
    required this.trangThai,
    this.tenNhanVien,
    required this.daThucHien,
    required this.daChon,
    required this.vatTu,
  });
}