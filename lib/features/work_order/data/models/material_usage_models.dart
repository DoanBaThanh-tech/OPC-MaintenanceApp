class VatTuOption {
  final int maVatTu;
  final String tenVatTu;
  final String? donViTinh;
  final int soLuongTonKho;
  final int donGia;

  const VatTuOption({
    required this.maVatTu,
    required this.tenVatTu,
    this.donViTinh,
    this.soLuongTonKho = 0,
    this.donGia = 0,
  });

  factory VatTuOption.fromJson(Map<String, dynamic> j) => VatTuOption(
    maVatTu: (j['maVatTu'] as num?)?.toInt() ?? 0,
    tenVatTu: j['tenVatTu']?.toString() ?? '',
    donViTinh: j['donViTinh']?.toString(),
    soLuongTonKho: (j['soLuongTonKho'] as num?)?.toInt() ?? 0,
    donGia: (j['donGia'] as num?)?.toInt() ?? 0,
  );
}

/// Một bước trong quy trình (tối đa 4) — mô tả lấy theo thiết bị từ DB.
class BuocQuyTrinh {
  final int soBuoc;
  final String moTa;
  int? maVatTu;
  String tenVatTu;
  int soLuong;
  int donGia;
  String ketQuaThucHien;

  BuocQuyTrinh({
    required this.soBuoc,
    required this.moTa,
    this.maVatTu,
    this.tenVatTu = '',
    this.soLuong = 0,
    this.donGia = 0,
    this.ketQuaThucHien = '',
  });

  int get thanhTien => soLuong * donGia;

  factory BuocQuyTrinh.fromJson(Map<String, dynamic> j) => BuocQuyTrinh(
    soBuoc: (j['soBuoc'] as num?)?.toInt() ?? 0,
    moTa: (j['moTaBuoc'] ?? j['moTa'])?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'soBuoc': soBuoc,
    'moTaBuoc': moTa,
    if (maVatTu != null) 'maVatTu': maVatTu,
    'tenVatTu': tenVatTu,
    'soLuong': soLuong,
    'donGia': donGia,
  };

  BuocQuyTrinh copy() => BuocQuyTrinh(
    soBuoc: soBuoc,
    moTa: moTa,
    maVatTu: maVatTu,
    tenVatTu: tenVatTu,
    soLuong: soLuong,
    donGia: donGia,
    ketQuaThucHien: ketQuaThucHien,
  );
}

class HoSoVatTuItem {
  final int maHoSoVatTu;
  final int? maHoSoBaoTri;
  final int? maHoSoSuaChua;
  final int maThietBi;
  final String tenThietBi;
  final String loaiCongViec;
  final DateTime ngayThucHien;
  final String? tenNhanVien;
  final int tongTien;
  final String trangThai;
  final DateTime? ngayGuiGiamDoc;
  final List<ChiTietVatTuSuDung> chiTiet;

  HoSoVatTuItem({
    required this.maHoSoVatTu,
    this.maHoSoBaoTri,
    this.maHoSoSuaChua,
    required this.maThietBi,
    required this.tenThietBi,
    required this.loaiCongViec,
    required this.ngayThucHien,
    this.tenNhanVien,
    required this.tongTien,
    required this.trangThai,
    this.ngayGuiGiamDoc,
    this.chiTiet = const [],
  });

  bool get daGuiGiamDoc =>
      trangThai == 'Đã gửi GĐ' || trangThai == 'Đã xem';

  factory HoSoVatTuItem.fromJson(Map<String, dynamic> j) {
    final ct = j['chiTiet'] ?? j['ChiTiet'];
    List<ChiTietVatTuSuDung> list = [];
    if (ct is List) {
      list = ct
          .whereType<Map>()
          .map((e) => ChiTietVatTuSuDung.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    DateTime parseDt(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return HoSoVatTuItem(
      maHoSoVatTu: (j['maHoSoVatTu'] as num?)?.toInt() ?? 0,
      maHoSoBaoTri: (j['maHoSoBaoTri'] as num?)?.toInt(),
      maHoSoSuaChua: (j['maHoSoSuaChua'] as num?)?.toInt(),
      maThietBi: (j['maThietBi'] as num?)?.toInt() ?? 0,
      tenThietBi: j['tenThietBi']?.toString() ?? '',
      loaiCongViec: j['loaiCongViec']?.toString() ?? '',
      ngayThucHien: parseDt(j['ngayThucHien']),
      tenNhanVien: j['tenNhanVien']?.toString(),
      tongTien: (j['tongTien'] as num?)?.toInt() ?? 0,
      trangThai: j['trangThai']?.toString() ?? 'Chờ gửi',
      ngayGuiGiamDoc: j['ngayGuiGiamDoc'] != null
          ? parseDt(j['ngayGuiGiamDoc'])
          : null,
      chiTiet: list,
    );
  }
}

class ChiTietVatTuSuDung {
  final int soBuoc;
  final String moTaBuoc;
  final int? maVatTu;
  final String tenVatTu;
  final int soLuong;
  final int donGia;
  final int thanhTien;

  ChiTietVatTuSuDung({
    required this.soBuoc,
    required this.moTaBuoc,
    this.maVatTu,
    required this.tenVatTu,
    required this.soLuong,
    required this.donGia,
    required this.thanhTien,
  });

  factory ChiTietVatTuSuDung.fromJson(Map<String, dynamic> j) =>
      ChiTietVatTuSuDung(
        soBuoc: (j['soBuoc'] as num?)?.toInt() ?? 0,
        moTaBuoc: j['moTaBuoc']?.toString() ?? '',
        maVatTu: (j['maVatTu'] as num?)?.toInt(),
        tenVatTu: j['tenVatTu']?.toString() ?? '',
        soLuong: (j['soLuong'] as num?)?.toInt() ?? 0,
        donGia: (j['donGia'] as num?)?.toInt() ?? 0,
        thanhTien: (j['thanhTien'] as num?)?.toInt() ??
            ((j['soLuong'] as num?)?.toInt() ?? 0) *
                ((j['donGia'] as num?)?.toInt() ?? 0),
      );
}