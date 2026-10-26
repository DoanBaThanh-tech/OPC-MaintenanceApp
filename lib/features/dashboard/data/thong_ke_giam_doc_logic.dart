import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';

class ThongKeThang {
  final int thang;
  final int soBaoTri;
  final int soBaoTriHoanThanh;
  final int soSuaChua;
  final int soSuaChuaHoanThanh;
  final int soLuongVatTu;
  final int tongTienVatTu;

  const ThongKeThang({
    required this.thang,
    required this.soBaoTri,
    required this.soBaoTriHoanThanh,
    required this.soSuaChua,
    required this.soSuaChuaHoanThanh,
    required this.soLuongVatTu,
    required this.tongTienVatTu,
  });

  factory ThongKeThang.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => ((v as num?)?.round() ?? 0);
    return ThongKeThang(
      thang: n(j['thang'] ?? j['Thang']),
      soBaoTri: n(j['soBaoTri'] ?? j['SoBaoTri']),
      soBaoTriHoanThanh: n(j['soBaoTriHoanThanh'] ?? j['SoBaoTriHoanThanh']),
      soSuaChua: n(j['soSuaChua'] ?? j['SoSuaChua']),
      soSuaChuaHoanThanh: n(j['soSuaChuaHoanThanh'] ?? j['SoSuaChuaHoanThanh']),
      soLuongVatTu: n(j['soLuongVatTu'] ?? j['SoLuongVatTu']),
      tongTienVatTu: n(j['tongTienVatTu'] ?? j['TongTienVatTu']),
    );
  }
}

class ThongKeGiamDocData {
  final int nam;
  /// Năm được phép chọn: >= 2026 và có kế hoạch BT hoặc SC đã hoàn thành.
  final List<int> danhSachNam;
  final int tongBaoTri;
  final int tongBaoTriHoanThanh;
  final int tongSuaChua;
  final int tongSuaChuaHoanThanh;
  final int tongSoLuongVatTu;
  final int tongTienVatTu;
  final List<ThongKeThang> theoThang;

  const ThongKeGiamDocData({
    required this.nam,
    required this.danhSachNam,
    required this.tongBaoTri,
    required this.tongBaoTriHoanThanh,
    required this.tongSuaChua,
    required this.tongSuaChuaHoanThanh,
    required this.tongSoLuongVatTu,
    required this.tongTienVatTu,
    required this.theoThang,
  });

  factory ThongKeGiamDocData.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => ((v as num?)?.round() ?? 0);
    final rawNam = j['danhSachNam'] ?? j['DanhSachNam'];
    final dsNam = <int>[];
    if (rawNam is List) {
      for (final e in rawNam) {
        final y = n(e);
        if (y >= 2026) dsNam.add(y);
      }
    }
    dsNam.sort();
    final raw = j['theoThang'] ?? j['TheoThang'];
    final list = <ThongKeThang>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          list.add(ThongKeThang.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    final byM = {for (final t in list) t.thang: t};
    final full = List.generate(12, (i) {
      final m = i + 1;
      return byM[m] ??
          const ThongKeThang(
            thang: 0,
            soBaoTri: 0,
            soBaoTriHoanThanh: 0,
            soSuaChua: 0,
            soSuaChuaHoanThanh: 0,
            soLuongVatTu: 0,
            tongTienVatTu: 0,
          ).copyWithThang(m);
    });
    return ThongKeGiamDocData(
      nam: n(j['nam'] ?? j['Nam']).clamp(2026, 2100),
      danhSachNam: dsNam,
      tongBaoTri: n(j['tongBaoTri'] ?? j['TongBaoTri']),
      tongBaoTriHoanThanh:
      n(j['tongBaoTriHoanThanh'] ?? j['TongBaoTriHoanThanh']),
      tongSuaChua: n(j['tongSuaChua'] ?? j['TongSuaChua']),
      tongSuaChuaHoanThanh:
      n(j['tongSuaChuaHoanThanh'] ?? j['TongSuaChuaHoanThanh']),
      tongSoLuongVatTu: n(j['tongSoLuongVatTu'] ?? j['TongSoLuongVatTu']),
      tongTienVatTu: n(j['tongTienVatTu'] ?? j['TongTienVatTu']),
      theoThang: full,
    );
  }
}

extension on ThongKeThang {
  ThongKeThang copyWithThang(int m) => ThongKeThang(
    thang: m,
    soBaoTri: soBaoTri,
    soBaoTriHoanThanh: soBaoTriHoanThanh,
    soSuaChua: soSuaChua,
    soSuaChuaHoanThanh: soSuaChuaHoanThanh,
    soLuongVatTu: soLuongVatTu,
    tongTienVatTu: tongTienVatTu,
  );
}

class ThongKeGiamDocController extends ChangeNotifier {
  ThongKeGiamDocData? data;
  bool dangTai = true;
  String? loi;
  int nam = DateTime.now().year < 2026 ? 2026 : DateTime.now().year;
  /// Năm dropdown: chỉ >= 2026 và có dữ liệu đủ điều kiện.
  List<int> danhSachNam = [];

  Future<void> tai({int? namMoi}) async {
    if (namMoi != null) nam = namMoi;
    if (nam < 2026) nam = 2026;
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final raw = await ApiClient.instance.get<Map<String, dynamic>>(
        ApiConstants.thongKeGiamDoc,
        query: {'nam': nam},
      );
      data = ThongKeGiamDocData.fromJson(raw);
      if (data!.danhSachNam.isNotEmpty) {
        danhSachNam = List<int>.from(data!.danhSachNam);
        // Nếu năm đang chọn không còn trong list → chuyển sang năm mới nhất có dữ liệu
        if (!danhSachNam.contains(nam)) {
          nam = danhSachNam.last;
          if (data!.nam != nam) {
            final raw2 = await ApiClient.instance.get<Map<String, dynamic>>(
              ApiConstants.thongKeGiamDoc,
              query: {'nam': nam},
            );
            data = ThongKeGiamDocData.fromJson(raw2);
            if (data!.danhSachNam.isNotEmpty) {
              danhSachNam = List<int>.from(data!.danhSachNam);
            }
          }
        }
      } else {
        // Chưa có năm đủ điều kiện — chỉ hiện năm hiện tại nếu >= 2026 (trống số liệu)
        final y = DateTime.now().year < 2026 ? 2026 : DateTime.now().year;
        danhSachNam = [y];
        nam = y;
      }
    } on ApiException catch (e) {
      loi = e.message;
      data = null;
    } catch (e) {
      loi = '$e';
      data = null;
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void doiNam(int n) {
    if (n == nam) return;
    if (n < 2026) return;
    if (danhSachNam.isNotEmpty && !danhSachNam.contains(n)) return;
    tai(namMoi: n);
  }
}