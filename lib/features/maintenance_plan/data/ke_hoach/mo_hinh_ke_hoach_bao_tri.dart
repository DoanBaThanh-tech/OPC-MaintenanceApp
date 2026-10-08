part of maintenance_plan_logic;

class ThietBiRutGon {
  final int maThietBi;
  final String tenThietBi;
  final String? loaiThietBi;
  final int maChuKy;

  ThietBiRutGon({
    required this.maThietBi,
    required this.tenThietBi,
    this.loaiThietBi,
    required this.maChuKy,
  });

  factory ThietBiRutGon.fromJson(Map<String, dynamic> j) => ThietBiRutGon(
    maThietBi: (j['maThietBi'] as num?)?.toInt() ?? 0,
    tenThietBi: j['tenThietBi']?.toString() ?? '',
    loaiThietBi: j['loaiThietBi']?.toString(),
    maChuKy: (j['maChuKy'] as num?)?.toInt() ?? 0,
  );
}

class ChuKyBaoTriModel {
  final int maChuKy;
  final String? loaiThietBi;
  final int soThangChuKyDeXuat;

  ChuKyBaoTriModel({
    required this.maChuKy,
    this.loaiThietBi,
    required this.soThangChuKyDeXuat,
  });

  factory ChuKyBaoTriModel.fromJson(Map<String, dynamic> j) => ChuKyBaoTriModel(
    maChuKy: (j['maChuKy'] as num?)?.toInt() ?? 0,
    loaiThietBi: j['loaiThietBi']?.toString(),
    soThangChuKyDeXuat: (j['soThangChuKyDeXuat'] as num?)?.toInt() ?? 0,
  );

  String get nhan => '${loaiThietBi ?? "Chưa rõ loại"} · $soThangChuKyDeXuat tháng/lần';
}

/// Thiết bị trong hàng chờ đến hạn bảo trì (API hang-cho-den-han).
class HangChoDenHanItem {
  final int maThietBi;
  final String tenThietBi;
  final String? loaiThietBi;
  final int soThangChuKy;
  final DateTime? ngayBaoTriGanNhat;
  final DateTime ngayDenHan;
  final String trangThaiHan; // Đến hạn | Trễ hạn

  HangChoDenHanItem({
    required this.maThietBi,
    required this.tenThietBi,
    this.loaiThietBi,
    required this.soThangChuKy,
    this.ngayBaoTriGanNhat,
    required this.ngayDenHan,
    required this.trangThaiHan,
  });

  factory HangChoDenHanItem.fromJson(Map<String, dynamic> j) {
    DateTime? parseD(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return HangChoDenHanItem(
      maThietBi: (j['maThietBi'] as num?)?.toInt() ?? 0,
      tenThietBi: j['tenThietBi']?.toString() ?? '',
      loaiThietBi: j['loaiThietBi']?.toString(),
      soThangChuKy: (j['soThangChuKy'] as num?)?.toInt() ?? 1,
      ngayBaoTriGanNhat: parseD(j['ngayBaoTriGanNhat']),
      ngayDenHan: parseD(j['ngayDenHan']) ?? DateTime.now(),
      trangThaiHan: j['trangThaiHan']?.toString() ?? 'Đến hạn',
    );
  }

  bool get treHan => trangThaiHan == 'Trễ hạn';
}

class ChiTietKeHoachInput {
  final ThietBiRutGon thietBi;
  DateTime ngayDuKienBaoTri;

  ChiTietKeHoachInput({required this.thietBi, required this.ngayDuKienBaoTri});
}

class ChiTietKeHoach {
  final int maChiTietKeHoach;
  final int maThietBi;
  final String tenThietBi;
  final DateTime ngayDuKienBaoTri;
  final int? maHoSoBaoTri;
  /// Trạng thái hồ sơ bảo trì (null = chưa tạo hồ sơ). Ví dụ: Chờ duyệt, Đã duyệt, Từ chối...
  final String? trangThaiHoSo;

  ChiTietKeHoach({
    required this.maChiTietKeHoach,
    required this.maThietBi,
    required this.tenThietBi,
    required this.ngayDuKienBaoTri,
    this.maHoSoBaoTri,
    this.trangThaiHoSo,
  });

  bool get daTaoHoSo => maHoSoBaoTri != null;

  /// Nhãn hiển thị: ưu tiên trạng thái hồ sơ nếu đã tạo, ngược lại "Chưa tạo hồ sơ".
  String get nhanTrangThaiHienThi =>
      daTaoHoSo ? (trangThaiHoSo?.isNotEmpty == true ? trangThaiHoSo! : 'Đã tạo hồ sơ') : 'Chưa tạo hồ sơ';

  factory ChiTietKeHoach.fromJson(Map<String, dynamic> j) => ChiTietKeHoach(
    maChiTietKeHoach: (j['maChiTietKeHoach'] as num?)?.toInt() ?? 0,
    maThietBi: (j['maThietBi'] as num?)?.toInt() ?? 0,
    tenThietBi: j['tenThietBi']?.toString() ?? '',
    ngayDuKienBaoTri: DateTime.parse(j['ngayDuKienBaoTri'].toString()),
    maHoSoBaoTri: (j['maHoSoBaoTri'] as num?)?.toInt(),
    trangThaiHoSo: j['trangThaiHoSo']?.toString(),
  );
}

class KeHoachBaoTri {
  final int maKeHoach;
  final int maChuKy;
  final String? tenChuKy;
  final int nam;
  final String? tenNhanVienLap;
  final DateTime ngayLapKeHoach;
  final String trangThai;
  final int soThietBi;
  final String? tenThietBi;

  KeHoachBaoTri({
    required this.maKeHoach,
    required this.maChuKy,
    this.tenChuKy,
    required this.nam,
    this.tenNhanVienLap,
    required this.ngayLapKeHoach,
    required this.trangThai,
    required this.soThietBi,
    this.tenThietBi,
  });

  factory KeHoachBaoTri.fromJson(Map<String, dynamic> j) => KeHoachBaoTri(
    maKeHoach: (j['maKeHoach'] as num?)?.toInt() ?? 0,
    maChuKy: (j['maChuKy'] as num?)?.toInt() ?? 0,
    tenChuKy: j['tenChuKy']?.toString(),
    nam: (j['nam'] as num?)?.toInt() ?? 0,
    tenNhanVienLap: j['tenNhanVienLap']?.toString(),
    ngayLapKeHoach: DateTime.parse(j['ngayLapKeHoach'].toString()),
    trangThai: j['trangThai']?.toString() ?? '',
    soThietBi: (j['soThietBi'] as num?)?.toInt() ?? 0,
    tenThietBi: j['tenThietBi']?.toString(),
  );
}

/// Một dòng thiết bị trong một tháng trên lịch.
class MucThietBiTrongThang {
  final KeHoachBaoTri keHoach;
  final ChiTietKeHoach chiTiet;

  MucThietBiTrongThang({required this.keHoach, required this.chiTiet});
}

enum TrangThaiKeHoach {
  choDuyet, daDuyet, tuChoi, dangThucHien, daHoanThanh, choXuLy, chuaTao,
}

TrangThaiKeHoach phanLoaiTrangThai(String tt) {
  switch (tt) {
    case 'Chờ duyệt': return TrangThaiKeHoach.choDuyet;
    case 'Đã duyệt': return TrangThaiKeHoach.daDuyet;
    case 'Từ chối': return TrangThaiKeHoach.tuChoi;
    case 'Đang thực hiện': return TrangThaiKeHoach.dangThucHien;
    case 'Đã hoàn thành':
    case 'Hoàn thành': return TrangThaiKeHoach.daHoanThanh;
    case 'Chưa tạo hồ sơ': return TrangThaiKeHoach.chuaTao;
    default: return TrangThaiKeHoach.choXuLy;
  }
}

/// Lập bảo trì cho thiết bị (theo tháng xưởng chốt) | Lập theo năm
enum CheDoLapKeHoach { choThietBi, theoNam }