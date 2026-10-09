class ThongBaoItem {
  final int maThongBao;
  final String tieuDe;
  final String noiDung;
  final String loai;
  final int? maHoSoBaoTri;
  final int? maHoSoSuaChua;
  final bool daDoc;
  final DateTime ngayTao;

  ThongBaoItem({
    required this.maThongBao,
    required this.tieuDe,
    required this.noiDung,
    required this.loai,
    this.maHoSoBaoTri,
    this.maHoSoSuaChua,
    required this.daDoc,
    required this.ngayTao,
  });

  factory ThongBaoItem.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    return ThongBaoItem(
      maThongBao: n(j['maThongBao'] ?? j['MaThongBao']),
      tieuDe: (j['tieuDe'] ?? j['TieuDe'] ?? '').toString(),
      noiDung: (j['noiDung'] ?? j['NoiDung'] ?? '').toString(),
      loai: (j['loai'] ?? j['Loai'] ?? '').toString(),
      maHoSoBaoTri: (j['maHoSoBaoTri'] as num?)?.toInt() ??
          (j['MaHoSoBaoTri'] as num?)?.toInt(),
      maHoSoSuaChua: (j['maHoSoSuaChua'] as num?)?.toInt() ??
          (j['MaHoSoSuaChua'] as num?)?.toInt(),
      daDoc: j['daDoc'] == true || j['DaDoc'] == true,
      ngayTao: DateTime.tryParse(
          (j['ngayTao'] ?? j['NgayTao'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  bool get isBaoTri => loai == 'PhanCongBT';
  bool get isSuaChua => loai == 'PhanCongSC';
}