import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Bọc riêng việc lưu token — nếu sau này đổi cách lưu (VD: Hive),
/// chỉ sửa đúng file này, không ảnh hưởng ApiClient hay các feature khác
class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'jwt_token';
  static const _keyMaNguoiDung = 'ma_nguoi_dung';
  static const _keyEmail = 'email';
  static const _keyVaiTro = 'vai_tro';
  static const _keyMaVaiTro = 'ma_vai_tro';

  static Future<void> luuPhienDangNhap({
    required String token,
    required int maNguoiDung,
    required String email,
    required String vaiTro,
    required int maVaiTro,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyMaNguoiDung, value: maNguoiDung.toString()),
      _storage.write(key: _keyEmail, value: email),
      _storage.write(key: _keyVaiTro, value: vaiTro),
      _storage.write(key: _keyMaVaiTro, value: maVaiTro.toString()),
    ]);
  }

  static Future<String?> getToken() => _storage.read(key: _keyToken);
  static Future<String?> getVaiTro() => _storage.read(key: _keyVaiTro);
  static Future<int?> getMaVaiTro() async {
    final v = await _storage.read(key: _keyMaVaiTro);
    return v == null ? null : int.tryParse(v);
  }

  static Future<bool> daDangNhap() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> xoaPhienDangNhap() => _storage.deleteAll();
}