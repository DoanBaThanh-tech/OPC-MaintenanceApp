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

/// Một dòng vật tư trong một bước quy trình (mỗi bước có thể nhiều dòng).
class VatTuDong {
  int? maVatTu;
  String tenVatTu;
  int soLuong;
  int donGia;
  String? donViTinh;

  VatTuDong({
    this.maVatTu,
    this.tenVatTu = '',
    this.soLuong = 1,
    this.donGia = 0,
    this.donViTinh,
  });

  int get thanhTien => soLuong * donGia;

  Map<String, dynamic> toChiTietJson(int soBuoc, String moTaBuoc) => {
    'soBuoc': soBuoc,
    'moTaBuoc': moTaBuoc,
    if (maVatTu != null) 'maVatTu': maVatTu,
    'tenVatTu': tenVatTu,
    'soLuong': soLuong,
    'donGia': donGia,
  };

  VatTuDong copy() => VatTuDong(
    maVatTu: maVatTu,
    tenVatTu: tenVatTu,
    soLuong: soLuong,
    donGia: donGia,
    donViTinh: donViTinh,
  );
}

/// Một bước trong quy trình — mô tả lấy theo thiết bị từ DB; mỗi bước có list vật tư.
class BuocQuyTrinh {
  final int soBuoc;
  final String moTa;
  /// Nhiều vật tư cho cùng một bước.
  List<VatTuDong> vatTuList;
  String ketQuaThucHien;

  // Giữ tương thích cũ (1 vật tư) — lấy phần tử đầu nếu có
  int? get maVatTu => vatTuList.isEmpty ? null : vatTuList.first.maVatTu;
  set maVatTu(int? v) {
    if (vatTuList.isEmpty) {
      vatTuList.add(VatTuDong(maVatTu: v));
    } else {
      vatTuList.first.maVatTu = v;
    }
  }

  String get tenVatTu => vatTuList.isEmpty ? '' : vatTuList.first.tenVatTu;
  set tenVatTu(String v) {
    if (vatTuList.isEmpty) {
      vatTuList.add(VatTuDong(tenVatTu: v));
    } else {
      vatTuList.first.tenVatTu = v;
    }
  }

  int get soLuong => vatTuList.isEmpty ? 0 : vatTuList.first.soLuong;
  set soLuong(int v) {
    if (vatTuList.isEmpty) {
      vatTuList.add(VatTuDong(soLuong: v));
    } else {
      vatTuList.first.soLuong = v;
    }
  }

  int get donGia => vatTuList.isEmpty ? 0 : vatTuList.first.donGia;
  set donGia(int v) {
    if (vatTuList.isEmpty) {
      vatTuList.add(VatTuDong(donGia: v));
    } else {
      vatTuList.first.donGia = v;
    }
  }

  BuocQuyTrinh({
    required this.soBuoc,
    required this.moTa,
    List<VatTuDong>? vatTuList,
    this.ketQuaThucHien = '',
  }) : vatTuList = vatTuList ?? [];

  int get thanhTien => vatTuList.fold(0, (s, d) => s + d.thanhTien);

  factory BuocQuyTrinh.fromJson(Map<String, dynamic> j) => BuocQuyTrinh(
    soBuoc: (j['soBuoc'] as num?)?.toInt() ?? 0,
    moTa: (j['moTaBuoc'] ?? j['moTa'])?.toString() ?? '',
  );

  /// Xuất tất cả dòng vật tư của bước (mỗi dòng 1 chi tiết API).
  List<Map<String, dynamic>> toChiTietJsonList() {
    final out = <Map<String, dynamic>>[];
    for (final d in vatTuList) {
      if (d.tenVatTu.isEmpty || d.soLuong <= 0) continue;
      out.add(d.toChiTietJson(soBuoc, moTa));
    }
    return out;
  }

  /// Tương thích cũ — 1 dòng.
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
    vatTuList: vatTuList.map((e) => e.copy()).toList(),
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
      trangThai == 'Chờ duyệt' ||
          trangThai == 'Xác nhận' ||
          trangThai == 'Đã gửi GĐ' ||
          trangThai == 'Đã xem';

  bool get choGui => trangThai == 'Chờ gửi';
  bool get choDuyet =>
      trangThai == 'Chờ duyệt' || trangThai == 'Đã gửi GĐ';
  bool get daXacNhan =>
      trangThai == 'Xác nhận' || trangThai == 'Đã xem';

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