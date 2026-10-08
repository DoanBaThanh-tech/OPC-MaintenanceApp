part of technician_screens;

/// View model bước quy trình trên chi tiết NVKT (đủ mẫu + tiến độ + vật tư).
class _BuocQtNvktView {
  final int soBuoc;
  final String moTa;
  final String trangThai;
  final String? tenNhanVien;
  final bool daThucHien;
  final bool daChon;
  final List<ChiTietVatTuSuDung> vatTu;

  const _BuocQtNvktView({
    required this.soBuoc,
    required this.moTa,
    required this.trangThai,
    this.tenNhanVien,
    required this.daThucHien,
    required this.daChon,
    this.vatTu = const [],
  });
}