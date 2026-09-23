import 'package:flutter/foundation.dart';

// Models dùng chung cho feature work_order

class NhanVienRutGon {
  final int maNhanVien;
  final String hoTen;
  final String? email;
  final String? soDienThoai;
  final String? chucVu;
  final String? tenVaiTro;
  /// Số thiết bị đang BT/SC (Đang thực hiện)
  final int soCongViecDangLam;

  NhanVienRutGon({
    required this.maNhanVien,
    required this.hoTen,
    this.email,
    this.soDienThoai,
    this.chucVu,
    this.tenVaiTro,
    this.soCongViecDangLam = 0,
  });

  factory NhanVienRutGon.fromJson(Map<String, dynamic> j) => NhanVienRutGon(
    maNhanVien: (j['maNhanVien'] as num?)?.toInt() ?? 0,
    hoTen: j['hoTen']?.toString() ?? '',
    email: j['email']?.toString(),
    soDienThoai: j['soDienThoai']?.toString(),
    chucVu: j['chucVu']?.toString(),
    tenVaiTro: j['tenVaiTro']?.toString(),
    soCongViecDangLam: (j['soCongViecDangLam'] as num?)?.toInt() ?? 0,
  );
}



class HoSoBaoTri {
  final int maHoSoBaoTri;
  final int maThietBi;
  final String tenThietBi;
  final String? tenNhanVienTao;
  final String? noiDungCongViec;
  final String? thoiGianDuKien;
  final String? gioBatDauDuKien;
  final String? gioKetThucDuKien;
  final DateTime? ngayDuKienBaoTri;
  final DateTime ngayTao;
  final DateTime? ngayDuyet;
  final String trangThai;
  final String? lyDoTuChoi;
  final int? maPhanCong;
  /// Trạng thái phân công: Chờ xác nhận | Xác nhận | Từ chối | …
  final String? trangThaiPhanCong;
  final String? lyDoTuChoiPhanCong;
  final int? maNhanVienThucHien;
  final String? tenNhanVienThucHien;
  /// Nhiều NV đang được phân công (cập nhật phân công / hiển thị).
  final List<int> maNhanVienThucHiens;
  final String? tenNhanVienThucHiens;
  final DateTime? ngayPhanCong;
  final int nam;
  final bool namTuKeHoach;
  final String? rowVersion;

  HoSoBaoTri({
    required this.maHoSoBaoTri,
    required this.maThietBi,
    required this.tenThietBi,
    this.tenNhanVienTao,
    this.noiDungCongViec,
    this.thoiGianDuKien,
    this.gioBatDauDuKien,
    this.gioKetThucDuKien,
    this.ngayDuKienBaoTri,
    required this.ngayTao,
    this.ngayDuyet,
    required this.trangThai,
    this.lyDoTuChoi,
    this.maPhanCong,
    this.trangThaiPhanCong,
    this.lyDoTuChoiPhanCong,
    this.maNhanVienThucHien,
    this.tenNhanVienThucHien,
    this.maNhanVienThucHiens = const [],
    this.tenNhanVienThucHiens,
    this.ngayPhanCong,
    required this.nam,
    required this.namTuKeHoach,
    this.rowVersion,
  });

  /// Xưởng còn được chỉnh sửa / gửi GĐ (chưa gửi Giám đốc).
  bool get choXuong => trangThai == 'Chờ duyệt' || trangThai == 'Chờ xưởng';
  /// Đã gửi Giám đốc — Xưởng chỉ xem, không còn nút chỉnh sửa/gửi.
  bool get daGuiGiamDoc => trangThai == 'Chờ GĐ duyệt';
  /// Đang chờ Giám đốc (gồm trước/sau khi Xưởng gửi).
  bool get choDuyet =>
      trangThai == 'Chờ duyệt' ||
          trangThai == 'Chờ xưởng' ||
          trangThai == 'Chờ GĐ duyệt';
  bool get daDuyetChuaPhanCong =>
      trangThai == 'Đã duyệt' &&
          (maPhanCong == null || trangThaiPhanCong == null || trangThaiPhanCong == 'Đã hủy');
  /// NVKT đã từ chối nhận việc — tổ trưởng thấy lý do và phân công lại
  bool get phanCongBiTuChoi =>
      trangThai == 'Đã duyệt' && trangThaiPhanCong == 'Từ chối';
  bool get daDuyetChoXacNhan =>
      trangThai == 'Đã duyệt' &&
          maPhanCong != null &&
          (trangThaiPhanCong == 'Chờ xác nhận' ||
              trangThaiPhanCong == 'Đã phân công' ||
              trangThaiPhanCong == null);
  bool get dangThucHien => trangThai == 'Đang thực hiện';
  /// Đã phân công, tổ trưởng có thể cập nhật lại danh sách NV.
  bool get coTheCapNhatPhanCong =>
      dangThucHien &&
          (maPhanCong != null || maNhanVienThucHiens.isNotEmpty) &&
          trangThaiPhanCong != 'Hoàn thành';
  bool get biTuChoi => trangThai == 'Từ chối';
  bool get daHoanThanh => trangThai == 'Đã hoàn thành';

  factory HoSoBaoTri.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
    int? asIntN(dynamic v) => (v as num?)?.toInt();
    DateTime? asDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final ngayTao = asDate(j['ngayTao'] ?? j['NgayTao']) ?? DateTime.now();

    List<int> parseMaNvList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) {
        if (e is num) return e.toInt();
        if (e is Map) {
          final v = e['maNhanVien'] ?? e['MaNhanVien'];
          return (v as num?)?.toInt();
        }
        return int.tryParse(e.toString());
      })
          .whereType<int>()
          .toList();
    }

    final maList = parseMaNvList(j['maNhanVienThucHiens'] ?? j['MaNhanVienThucHiens']);
    final fromDs = parseMaNvList(j['danhSachNhanVienPhanCong'] ?? j['DanhSachNhanVienPhanCong']);
    final maNvs = maList.isNotEmpty ? maList : fromDs;

    return HoSoBaoTri(
      maHoSoBaoTri: asInt(j['maHoSoBaoTri'] ?? j['MaHoSoBaoTri']),
      maThietBi: asInt(j['maThietBi'] ?? j['MaThietBi'] ?? j['maThieBi'] ?? j['MaThieBi']),
      tenThietBi: (j['tenThietBi'] ?? j['TenThietBi'])?.toString() ?? '',
      tenNhanVienTao: (j['tenNhanVienTao'] ?? j['TenNhanVienTao'])?.toString(),
      noiDungCongViec: (j['noiDungCongViec'] ?? j['NoiDungCongViec'])?.toString(),
      thoiGianDuKien: (j['thoiGianDuKien'] ?? j['ThoiGianDuKien'])?.toString(),
      gioBatDauDuKien: (j['gioBatDauDuKien'] ?? j['GioBatDauDuKien'])?.toString(),
      gioKetThucDuKien: (j['gioKetThucDuKien'] ?? j['GioKetThucDuKien'])?.toString(),
      ngayDuKienBaoTri: asDate(j['ngayDuKienBaoTri'] ?? j['NgayDuKienBaoTri']),
      ngayTao: ngayTao,
      ngayDuyet: asDate(j['ngayDuyet'] ?? j['NgayDuyet']),
      trangThai: (j['trangThai'] ?? j['TrangThai'])?.toString() ?? '',
      lyDoTuChoi: (j['lyDoTuChoi'] ?? j['LyDoTuChoi'])?.toString(),
      maPhanCong: asIntN(j['maPhanCong'] ?? j['MaPhanCong']),
      trangThaiPhanCong: (j['trangThaiPhanCong'] ?? j['TrangThaiPhanCong'])?.toString(),
      lyDoTuChoiPhanCong: (j['lyDoTuChoiPhanCong'] ?? j['LyDoTuChoiPhanCong'])?.toString(),
      maNhanVienThucHien: asIntN(j['maNhanVienThucHien'] ?? j['MaNhanVienThucHien']),
      tenNhanVienThucHien: (j['tenNhanVienThucHien'] ?? j['TenNhanVienThucHien'])?.toString(),
      maNhanVienThucHiens: maNvs,
      tenNhanVienThucHiens: (j['tenNhanVienThucHiens'] ?? j['TenNhanVienThucHiens'])?.toString(),
      ngayPhanCong: asDate(j['ngayPhanCong'] ?? j['NgayPhanCong']),
      nam: asInt(j['nam'] ?? j['Nam'] ?? ngayTao.year),
      namTuKeHoach: (j['namTuKeHoach'] ?? j['NamTuKeHoach']) == true,
      rowVersion: (j['rowVersion'] ?? j['RowVersion'])?.toString(),
    );
  }
}

/// Phân loại trạng thái thành nhóm cố định — presentation tự map ra màu,
/// logic không phụ thuộc Material theme để giữ file này chủ yếu là dữ liệu.
enum TrangThaiHoSoBaoTri { choDuyet, daDuyet, dangThucHien, daHoanThanh, tuChoi, khac }

TrangThaiHoSoBaoTri phanLoaiTrangThaiHoSo(String tt) {
  switch (tt) {
    case 'Chờ duyệt':
    case 'Chờ GĐ duyệt':
    case 'Chờ xưởng':
      return TrangThaiHoSoBaoTri.choDuyet;
    case 'Đã duyệt':
      return TrangThaiHoSoBaoTri.daDuyet;
    case 'Đang thực hiện':
      return TrangThaiHoSoBaoTri.dangThucHien;
    case 'Đã hoàn thành':
      return TrangThaiHoSoBaoTri.daHoanThanh;
    case 'Từ chối':
      return TrangThaiHoSoBaoTri.tuChoi;
    default:
      return TrangThaiHoSoBaoTri.khac;
  }
}

class LichSuPhanCong {
  final int maPhanCong;
  final String? tenNhanVienPhanCong;
  final String? tenNhanVienThucHien;
  final String trangThai;
  final String? lyDoTuChoi;
  final DateTime ngayPhanCong;
  final DateTime? gioBatDau;
  final DateTime? gioKetThuc;
  final String? tenThietBi;
  final String? loai;

  LichSuPhanCong({
    required this.maPhanCong,
    this.tenNhanVienPhanCong,
    this.tenNhanVienThucHien,
    required this.trangThai,
    this.lyDoTuChoi,
    required this.ngayPhanCong,
    this.gioBatDau,
    this.gioKetThuc,
    this.tenThietBi,
    this.loai,
  });

  bool get laBaoTri => loai == 'Bảo trì';
  bool get laSuaChua => loai == 'Sửa chữa';

  factory LichSuPhanCong.fromJson(Map<String, dynamic> j) => LichSuPhanCong(
    maPhanCong: (j['maPhanCong'] as num?)?.toInt() ?? 0,
    tenNhanVienPhanCong: j['tenNhanVienPhanCong']?.toString(),
    tenNhanVienThucHien: j['tenNhanVienThucHien']?.toString(),
    trangThai: j['trangThai']?.toString() ?? '',
    lyDoTuChoi: j['lyDoTuChoi']?.toString(),
    ngayPhanCong: DateTime.tryParse(j['ngayPhanCong']?.toString() ?? '') ?? DateTime.now(),
    gioBatDau: j['gioBatDau'] != null ? DateTime.tryParse(j['gioBatDau'].toString()) : null,
    gioKetThuc: j['gioKetThuc'] != null ? DateTime.tryParse(j['gioKetThuc'].toString()) : null,
    tenThietBi: j['tenThietBi']?.toString(),
    loai: j['loai']?.toString(),
  );
}

/// Yêu cầu phân công gửi tới NVKT
class YeuCauPhanCong {
  final int maPhanCong;
  final String trangThaiPhanCong;
  final String? lyDoTuChoi;
  final DateTime ngayPhanCong;
  final DateTime? ngayBatDauDuKien;
  final DateTime? ngayKetThucDuKien;
  final String? tenNhanVienPhanCong;
  final String loai; // Bảo trì | Sửa chữa
  final int? maHoSo;
  final int? maThietBi;
  final String? tenThietBi;
  final String? noiDung;
  final String? thoiGianDuKien;
  final String? trangThaiHoSo;
  final DateTime? ngayDuKienBaoTri;
  final DateTime? ngayTaoHoSo;

  YeuCauPhanCong({
    required this.maPhanCong,
    required this.trangThaiPhanCong,
    this.lyDoTuChoi,
    required this.ngayPhanCong,
    this.ngayBatDauDuKien,
    this.ngayKetThucDuKien,
    this.tenNhanVienPhanCong,
    required this.loai,
    this.maHoSo,
    this.maThietBi,
    this.tenThietBi,
    this.noiDung,
    this.thoiGianDuKien,
    this.trangThaiHoSo,
    this.ngayDuKienBaoTri,
    this.ngayTaoHoSo,
  });

  /// Cần thực hiện (không còn bước xác nhận nhận việc).
  bool get canThucHien =>
      trangThaiPhanCong == 'Chờ xác nhận' ||
          trangThaiPhanCong == 'Đã phân công' ||
          trangThaiPhanCong == 'Xác nhận' ||
          trangThaiPhanCong == 'Đang thực hiện' ||
          trangThaiHoSo == 'Đang thực hiện';
  bool get choXacNhan => canThucHien; // giữ alias cũ
  bool get daXacNhan => trangThaiPhanCong == 'Xác nhận';
  bool get biTuChoi => trangThaiPhanCong == 'Từ chối';
  bool get daHuy => trangThaiPhanCong == 'Đã hủy';
  bool get daHoanThanhPc =>
      trangThaiPhanCong == 'Hoàn thành' || trangThaiHoSo == 'Đã hoàn thành';
  bool get laBaoTri => loai == 'Bảo trì';

  factory YeuCauPhanCong.fromJson(Map<String, dynamic> j) {
    DateTime? asDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return YeuCauPhanCong(
      maPhanCong: (j['maPhanCong'] as num?)?.toInt() ?? 0,
      trangThaiPhanCong: j['trangThaiPhanCong']?.toString() ?? '',
      lyDoTuChoi: j['lyDoTuChoi']?.toString(),
      ngayPhanCong: asDate(j['ngayPhanCong']) ?? DateTime.now(),
      ngayBatDauDuKien: asDate(j['ngayBatDauDuKien']),
      ngayKetThucDuKien: asDate(j['ngayKetThucDuKien']),
      tenNhanVienPhanCong: j['tenNhanVienPhanCong']?.toString(),
      loai: j['loai']?.toString() ?? 'Bảo trì',
      maHoSo: (j['maHoSo'] as num?)?.toInt(),
      maThietBi: (j['maThietBi'] as num?)?.toInt(),
      tenThietBi: j['tenThietBi']?.toString(),
      noiDung: j['noiDung']?.toString(),
      thoiGianDuKien: j['thoiGianDuKien']?.toString(),
      trangThaiHoSo: j['trangThaiHoSo']?.toString(),
      ngayDuKienBaoTri: asDate(j['ngayDuKienBaoTri']),
      ngayTaoHoSo: asDate(j['ngayTaoHoSo']),
    );
  }
}