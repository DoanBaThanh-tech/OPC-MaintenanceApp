import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';

/// Hồ sơ cá nhân — logic + validate (không nhét vào UI).
class HoSoCaNhan {
  final int maNguoiDung;
  final String email;
  final String? tenVaiTro;
  final String hoTen;
  final String? soDienThoai;
  final String? chucVu;
  final DateTime? ngayVaoLam;

  const HoSoCaNhan({
    required this.maNguoiDung,
    required this.email,
    this.tenVaiTro,
    required this.hoTen,
    this.soDienThoai,
    this.chucVu,
    this.ngayVaoLam,
  });

  factory HoSoCaNhan.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    DateTime? d(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      // DateOnly từ API: "2024-01-15" hoặc full ISO
      return DateTime.tryParse(s.length == 10 ? '${s}T00:00:00' : s);
    }

    return HoSoCaNhan(
      maNguoiDung: n(j['maNguoiDung'] ?? j['MaNguoiDung']),
      email: (j['email'] ?? j['Email'])?.toString() ?? '',
      tenVaiTro: (j['tenVaiTro'] ?? j['TenVaiTro'])?.toString(),
      hoTen: (j['hoTen'] ?? j['HoTen'])?.toString() ?? '',
      soDienThoai: (j['soDienThoai'] ?? j['SoDienThoai'])?.toString(),
      chucVu: (j['chucVu'] ?? j['ChucVu'])?.toString(),
      ngayVaoLam: d(j['ngayVaoLam'] ?? j['NgayVaoLam']),
    );
  }
}

class ProfileRules {
  ProfileRules._();

  static String? kiemTraHoTen(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return 'Vui lòng nhập họ tên.';
    if (t.contains('@') || t.toLowerCase().contains('opc.com')) {
      return 'Họ tên không được điền email.';
    }
    final ok = RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(t);
    if (!ok) {
      return 'Họ tên chỉ gồm chữ cái và khoảng trắng.';
    }
    return null;
  }

  static String? kiemTraSdt(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    if (!RegExp(r'^[0-9+\-\s]{8,15}$').hasMatch(t)) {
      return 'Số điện thoại không hợp lệ (8–15 số).';
    }
    return null;
  }
}

class ProfileService {
  static Future<HoSoCaNhan> layHoSo() async {
    final data = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.hoSoCaNhan);
    return HoSoCaNhan.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<HoSoCaNhan> capNhat({
    required String hoTen,
    String? soDienThoai,
    String? chucVu,
    DateTime? ngayVaoLam,
  }) async {
    final body = <String, dynamic>{
      'hoTen': hoTen.trim(),
      'soDienThoai': soDienThoai?.trim(),
      'chucVu': chucVu?.trim(),
    };
    if (ngayVaoLam != null) {
      body['ngayVaoLam'] =
      '${ngayVaoLam.year.toString().padLeft(4, '0')}-'
          '${ngayVaoLam.month.toString().padLeft(2, '0')}-'
          '${ngayVaoLam.day.toString().padLeft(2, '0')}';
    }
    final res = await ApiClient.instance
        .put<Map<String, dynamic>>(ApiConstants.hoSoCaNhan, body);
    final data = res['data'] ?? res['Data'] ?? res;
    final hs = HoSoCaNhan.fromJson(Map<String, dynamic>.from(data as Map));
    await TokenStorage.capNhatHoTen(hs.hoTen);
    return hs;
  }
}