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
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
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
  final int tongBaoTri;
  final int tongBaoTriHoanThanh;
  final int tongSuaChua;
  final int tongSuaChuaHoanThanh;
  final int tongSoLuongVatTu;
  final int tongTienVatTu;
  final List<ThongKeThang> theoThang;

  const ThongKeGiamDocData({
    required this.nam,
    required this.tongBaoTri,
    required this.tongBaoTriHoanThanh,
    required this.tongSuaChua,
    required this.tongSuaChuaHoanThanh,
    required this.tongSoLuongVatTu,
    required this.tongTienVatTu,
    required this.theoThang,
  });

  factory ThongKeGiamDocData.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
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
      nam: n(j['nam'] ?? j['Nam']).clamp(2000, 2100),
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
  int nam = DateTime.now().year;

  Future<void> tai({int? namMoi}) async {
    if (namMoi != null) nam = namMoi;
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final raw = await ApiClient.instance.get<Map<String, dynamic>>(
        ApiConstants.thongKeGiamDoc,
        query: {'nam': nam},
      );
      data = ThongKeGiamDocData.fromJson(raw);
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
    tai(namMoi: n);
  }
}