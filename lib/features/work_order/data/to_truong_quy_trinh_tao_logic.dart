import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import 'models/material_usage_models.dart';
import 'services/material_usage_service.dart';

/// Một quy trình (TB × loại) trong combo khi tạo hồ sơ.
class QuyTrinhOption {
  final int maThietBi;
  final String tenThietBi;
  final String loaiCongViec;
  final int soBuoc;
  final String nhan;

  const QuyTrinhOption({
    required this.maThietBi,
    required this.tenThietBi,
    required this.loaiCongViec,
    required this.soBuoc,
    required this.nhan,
  });

  factory QuyTrinhOption.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    final ten = (j['tenThietBi'] ?? j['TenThietBi'])?.toString() ?? '';
    final loai = (j['loaiCongViec'] ?? j['LoaiCongViec'])?.toString() ?? '';
    final so = n(j['soBuoc'] ?? j['SoBuoc']);
    return QuyTrinhOption(
      maThietBi: n(j['maThietBi'] ?? j['MaThietBi']),
      tenThietBi: ten,
      loaiCongViec: loai,
      soBuoc: so,
      nhan: (j['nhan'] ?? j['Nhan'])?.toString() ??
          '$ten — $loai ($so bước)',
    );
  }
}

class ToTruongQuyTrinhTaoRules {
  ToTruongQuyTrinhTaoRules._();

  static String? kiemTraTruocKhiLuu(Set<int> daChon) {
    if (daChon.isEmpty) {
      return 'Vui lòng tích chọn ít nhất một bước quy trình.';
    }
    return null;
  }
}

/// Logic chọn quy trình + bước khi tạo hồ sơ (Tổ trưởng / Xưởng SC).
class ToTruongQuyTrinhTaoController extends ChangeNotifier {
  final String loaiCongViec;

  ToTruongQuyTrinhTaoController({required this.loaiCongViec});

  List<QuyTrinhOption> danhSach = [];
  QuyTrinhOption? dangChon;
  List<BuocQuyTrinh> buoc = [];
  final Set<int> daTich = {};
  /// Nội dung bước tổ trưởng chỉnh (soBuoc → mô tả).
  final Map<int, String> moTaSua = {};
  bool dangTaiDs = true;
  bool dangTaiBuoc = false;
  String? loi;

  Future<void> taiDanhSach() async {
    dangTaiDs = true;
    loi = null;
    notifyListeners();
    try {
      final data = await ApiClient.instance.get<List<dynamic>>(
        '${ApiConstants.inventory}/quy-trinh/danh-sach',
        query: {'loaiCongViec': loaiCongViec},
      );
      danhSach = data
          .whereType<Map>()
          .map((e) => QuyTrinhOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      loi = e.message;
    } catch (e) {
      loi = '$e';
    } finally {
      dangTaiDs = false;
      notifyListeners();
    }
  }

  Future<void> chonQuyTrinh(QuyTrinhOption? opt) async {
    dangChon = opt;
    buoc = [];
    daTich.clear();
    moTaSua.clear();
    if (opt == null) {
      notifyListeners();
      return;
    }
    dangTaiBuoc = true;
    loi = null;
    notifyListeners();
    try {
      buoc = await MaterialUsageService.layQuyTrinhThietBi(
        maThietBi: opt.maThietBi,
        loaiCongViec: opt.loaiCongViec,
      );
      // Mặc định tích hết — Tổ trưởng bỏ bớt / sửa nội dung nếu cần
      daTich
        ..clear()
        ..addAll(buoc.map((b) => b.soBuoc));
      moTaSua
        ..clear()
        ..addEntries(buoc.map((b) => MapEntry(b.soBuoc, b.moTa)));
    } on ApiException catch (e) {
      loi = e.message;
    } catch (e) {
      loi = '$e';
    } finally {
      dangTaiBuoc = false;
      notifyListeners();
    }
  }

  void doiTich(int soBuoc, bool? v) {
    if (v == true) {
      daTich.add(soBuoc);
      if (!moTaSua.containsKey(soBuoc)) {
        final goc = buoc.where((b) => b.soBuoc == soBuoc).map((b) => b.moTa);
        moTaSua[soBuoc] = goc.isEmpty ? '' : goc.first;
      }
    } else {
      daTich.remove(soBuoc);
    }
    notifyListeners();
  }

  void capNhatMoTaBuoc(int soBuoc, String moTa) {
    moTaSua[soBuoc] = moTa;
    // không notify mỗi ký tự — caller setState nếu cần
  }

  String moTaHienThi(int soBuoc) {
    if (moTaSua.containsKey(soBuoc)) return moTaSua[soBuoc] ?? '';
    for (final b in buoc) {
      if (b.soBuoc == soBuoc) return b.moTa;
    }
    return '';
  }

  /// Payload gửi kèm tạo hồ sơ (kèm nội dung bước đã chỉnh).
  List<Map<String, dynamic>>? payloadBuoc() {
    if (dangChon == null || daTich.isEmpty) return null;
    return buoc
        .where((b) => daTich.contains(b.soBuoc))
        .map((b) => {
      'soBuoc': b.soBuoc,
      'moTaBuoc': moTaHienThi(b.soBuoc).trim().isEmpty
          ? (b.moTa.isEmpty ? 'Bước ${b.soBuoc}' : b.moTa)
          : moTaHienThi(b.soBuoc).trim(),
    })
        .toList();
  }

  String? validate() {
    if (dangChon == null) {
      return 'Vui lòng chọn quy trình từ danh sách.';
    }
    return ToTruongQuyTrinhTaoRules.kiemTraTruocKhiLuu(daTich);
  }
}