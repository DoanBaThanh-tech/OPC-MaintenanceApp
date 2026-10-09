import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/storage/token_storage.dart';

/// Hồ sơ cá nhân — logic + validate (không nhét vào UI).
class HoSoCaNhan {
  final int maNguoiDung;
  final String email;
  final String? tenVaiTro;
  final String hoTen;
  final String? soDienThoai;
  /// Email thật nhận OTP (Gmail…) — khác email đăng nhập @opc.com.
  final String? emailLienHe;
  final DateTime? ngayVaoLam;

  const HoSoCaNhan({
    required this.maNguoiDung,
    required this.email,
    this.tenVaiTro,
    required this.hoTen,
    this.soDienThoai,
    this.emailLienHe,
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
      emailLienHe: (j['emailLienHe'] ?? j['EmailLienHe'])?.toString(),
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

  /// Chỉ chữ số 0–9, tối đa 10 số; không chữ, ký tự đặc biệt, thập phân, số âm.
  static String? kiemTraSdt(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(t)) {
      return 'Số điện thoại chỉ được nhập số (không chữ, không ký tự đặc biệt).';
    }
    if (t.length > 10) {
      return 'Số điện thoại tối đa 10 số.';
    }
    return null;
  }

  /// Email nhận OTP — bỏ trống được; nếu nhập phải là hộp thư thật (không @opc.com).
  static String? kiemTraEmailLienHe(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    if (!RegExp(r'^[\w.\-]+@[\w.\-]+\.\w+$').hasMatch(t)) {
      return 'Email liên hệ không hợp lệ.';
    }
    if (t.toLowerCase().endsWith('@opc.com')) {
      return 'Email liên hệ phải là hộp thư thật (Gmail/Outlook…), không dùng @opc.com.';
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
    String? emailLienHe,
    DateTime? ngayVaoLam,
  }) async {
    final body = <String, dynamic>{
      'hoTen': hoTen.trim(),
      'soDienThoai': soDienThoai?.trim(),
      'emailLienHe': emailLienHe?.trim(),
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

  static Future<void> doiMatKhau({
    required String matKhauCu,
    required String matKhauMoi,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.hoSoCaNhan}/doi-mat-khau',
      {
        'matKhauCu': matKhauCu,
        'matKhauMoi': matKhauMoi,
      },
    );
  }
}



/// Lưu PIN 4 số + mật khẩu xem được trên thiết bị (sau đăng nhập / đổi MK).
/// Server chỉ lưu hash — không trả lại mật khẩu gốc.
class ProfileVault {
  ProfileVault._();
  static const _s = FlutterSecureStorage();

  static String _kPin(int maNd) => 'profile_pin_$maNd';
  static String _kPwd(int maNd) => 'profile_pwd_$maNd';

  static Future<bool> daCoPin(int maNd) async {
    final v = await _s.read(key: _kPin(maNd));
    return v != null && v.length == 4;
  }

  static Future<void> luuPin(int maNd, String pin4) async {
    await _s.write(key: _kPin(maNd), value: pin4);
  }

  static Future<bool> kiemTraPin(int maNd, String pin4) async {
    final v = await _s.read(key: _kPin(maNd));
    return v != null && v == pin4;
  }

  static Future<void> luuMatKhau(int maNd, String matKhau) async {
    await _s.write(key: _kPwd(maNd), value: matKhau);
  }

  static Future<String?> layMatKhau(int maNd) => _s.read(key: _kPwd(maNd));

  static Future<void> xoaMatKhau(int maNd) async {
    await _s.delete(key: _kPwd(maNd));
  }
}