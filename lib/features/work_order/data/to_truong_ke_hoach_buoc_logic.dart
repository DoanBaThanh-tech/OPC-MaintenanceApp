import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import 'models/material_usage_models.dart';
import 'services/material_usage_service.dart';

/// Ràng buộc: Tổ trưởng phải chọn ≥1 bước và Lưu trước khi phân công.
class ToTruongKeHoachBuocRules {
  ToTruongKeHoachBuocRules._();

  static String? kiemTraTruocKhiLuu(List<int> soBuocDaChon) {
    if (soBuocDaChon.isEmpty) {
      return 'Vui lòng tích chọn ít nhất một bước quy trình trước khi Lưu.';
    }
    return null;
  }

  static String? kiemTraTruocKhiPhanCong({required bool daLuuKeHoach}) {
    if (!daLuuKeHoach) {
      return 'Vui lòng chọn và Lưu các bước quy trình trước khi phân công nhân viên.';
    }
    return null;
  }
}

class ToTruongKeHoachBuocService {
  static Future<List<BuocQuyTrinh>> layMau({
    required int maThietBi,
    required String loaiCongViec,
  }) =>
      MaterialUsageService.layQuyTrinhThietBi(
        maThietBi: maThietBi,
        loaiCongViec: loaiCongViec,
      );

  /// Các bước đã chọn + cờ NVKT đã tiến hành (có tiến độ thật).
  static Future<({Set<int> soBuoc, bool nvktDaTienHanh})> layTienDoKeHoach({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
  }) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/tien-do-buoc',
      query: {
        if (maHoSoBaoTri != null) 'maHoSoBaoTri': maHoSoBaoTri,
        if (maHoSoSuaChua != null) 'maHoSoSuaChua': maHoSoSuaChua,
      },
    );
    final set = <int>{};
    var nvktDaTienHanh = false;
    for (final e in data) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final tt = (m['trangThai'] ?? m['TrangThai'])?.toString() ?? '';
      final maNv = (m['maNhanVien'] as num?)?.toInt() ??
          (m['MaNhanVien'] as num?)?.toInt() ??
          0;
      if (tt == 'DuocChon' ||
          tt == 'DangLam' ||
          tt == 'DaXong' ||
          tt == 'DaCapNhat') {
        final so = (m['soBuoc'] as num?)?.toInt() ??
            (m['SoBuoc'] as num?)?.toInt() ??
            0;
        if (so > 0) set.add(so);
      }
      if (tt != 'DuocChon' && maNv > 0) {
        nvktDaTienHanh = true;
      }
    }
    return (soBuoc: set, nvktDaTienHanh: nvktDaTienHanh);
  }

  static Future<Set<int>> laySoBuocDaChon({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
  }) async {
    final r = await layTienDoKeHoach(
      maHoSoBaoTri: maHoSoBaoTri,
      maHoSoSuaChua: maHoSoSuaChua,
    );
    return r.soBuoc;
  }

  static Future<void> luu({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
    required List<({int soBuoc, String moTa})> danhSach,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/ke-hoach-buoc',
      {
        'maHoSoBaoTri': maHoSoBaoTri,
        'maHoSoSuaChua': maHoSoSuaChua,
        'danhSachBuoc': danhSach
            .map((e) => {
          'soBuoc': e.soBuoc,
          'moTaBuoc': e.moTa,
        })
            .toList(),
      },
    );
  }
}

class ToTruongKeHoachBuocController extends ChangeNotifier {
  final int? maHoSoBaoTri;
  final int? maHoSoSuaChua;
  final int maThietBi;
  final String loaiCongViec;
  final bool chiXem;
  /// true nếu hồ sơ đã có ThoiDiemBatDauThucTe (NVKT bấm Tiến hành).
  final bool forceNvktDaTienHanh;

  ToTruongKeHoachBuocController({
    this.maHoSoBaoTri,
    this.maHoSoSuaChua,
    required this.maThietBi,
    required this.loaiCongViec,
    this.chiXem = false,
    this.forceNvktDaTienHanh = false,
  });

  List<BuocQuyTrinh> mau = [];
  final Set<int> daChon = {};
  /// Đã lưu lên server ít nhất 1 lần (đủ điều kiện phân công).
  bool daLuuServer = false;
  /// Sau khi Lưu: khóa tích chọn. Chỉ mở khi bấm «Cập nhật bước quy trình».
  bool daKhoa = false;
  /// Đang mở khóa để chỉnh (sau khi bấm Cập nhật).
  bool cheDoCapNhat = false;
  /// NVKT đã tiến hành / có tiến độ thực tế → Tổ trưởng không được sửa nữa.
  bool nvktDaTienHanh = false;
  bool dangTai = true;
  bool dangLuu = false;
  String? loi;

  /// Chỉ được tích khi chưa khóa, hoặc đang ở chế độ cập nhật — và NVKT chưa làm.
  bool get coTheTich =>
      !chiXem &&
          !nvktDaTienHanh &&
          !dangLuu &&
          (!daKhoa || cheDoCapNhat);

  /// Nhãn nút chính theo trạng thái khóa.
  String get nhanNut {
    if (nvktDaTienHanh) return 'NVKT đã tiến hành — không sửa được';
    if (dangLuu) return 'Đang lưu…';
    if (!daLuuServer && !daKhoa) return 'Lưu bước quy trình';
    if (daKhoa && !cheDoCapNhat) return 'Cập nhật bước quy trình';
    return 'Lưu cập nhật bước';
  }

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        ToTruongKeHoachBuocService.layMau(
          maThietBi: maThietBi,
          loaiCongViec: loaiCongViec,
        ),
        ToTruongKeHoachBuocService.layTienDoKeHoach(
          maHoSoBaoTri: maHoSoBaoTri,
          maHoSoSuaChua: maHoSoSuaChua,
        ),
      ]);
      mau = results[0] as List<BuocQuyTrinh>;
      final tienDo = results[1] as ({Set<int> soBuoc, bool nvktDaTienHanh});
      daChon
        ..clear()
        ..addAll(tienDo.soBuoc);
      nvktDaTienHanh = tienDo.nvktDaTienHanh || forceNvktDaTienHanh;
      daLuuServer = daChon.isNotEmpty;
      // Đã có bước trên server → khóa; NVKT đã làm → khóa cứng
      daKhoa = daLuuServer || nvktDaTienHanh;
      cheDoCapNhat = false;
    } on ApiException catch (e) {
      loi = e.message;
    } catch (e) {
      loi = '$e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void doiTich(int soBuoc, bool? value) {
    if (!coTheTich) return;
    if (value == true) {
      daChon.add(soBuoc);
    } else {
      daChon.remove(soBuoc);
    }
    notifyListeners();
  }

  /// Bấm «Cập nhật bước quy trình» khi đang khóa → mở khóa để tích/bỏ tích.
  void batDauCapNhat() {
    if (chiXem || dangLuu || nvktDaTienHanh) return;
    if (!daKhoa) return;
    cheDoCapNhat = true;
    notifyListeners();
  }

  /// Lưu (lần đầu hoặc sau khi mở khóa cập nhật) → khóa lại.
  Future<String?> luu() async {
    final err = ToTruongKeHoachBuocRules.kiemTraTruocKhiLuu(daChon.toList());
    if (err != null) return err;
    dangLuu = true;
    notifyListeners();
    try {
      final ds = mau
          .where((b) => daChon.contains(b.soBuoc))
          .map((b) => (soBuoc: b.soBuoc, moTa: b.moTa))
          .toList();
      if (ds.isEmpty) {
        for (final s in daChon) {
          ds.add((soBuoc: s, moTa: 'Bước $s'));
        }
      }
      await ToTruongKeHoachBuocService.luu(
        maHoSoBaoTri: maHoSoBaoTri,
        maHoSoSuaChua: maHoSoSuaChua,
        danhSach: ds,
      );
      daLuuServer = true;
      daKhoa = true;
      cheDoCapNhat = false;
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    } finally {
      dangLuu = false;
      notifyListeners();
    }
  }

  /// Xử lý bấm nút chính: khóa → mở cập nhật; còn lại → lưu.
  Future<String?> xuLyNutChinh() async {
    if (nvktDaTienHanh) {
      return 'Nhân viên kỹ thuật đã tiến hành quy trình — không thể chỉnh sửa bước.';
    }
    if (daKhoa && !cheDoCapNhat) {
      batDauCapNhat();
      return null;
    }
    return luu();
  }
}