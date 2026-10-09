import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/token_storage.dart';
import 'profile_logic.dart' show ProfileVault;

// ============ MODEL ============

class DangNhapRequest {
  final String email;
  final String matKhau;
  DangNhapRequest({required this.email, required this.matKhau});
  Map<String, dynamic> toJson() => {'email': email, 'matKhau': matKhau};
}

class DangNhapResponse {
  final int maNguoiDung;
  final String email;
  final String? hoTen;
  final String vaiTro;
  final int maVaiTro;
  final String token;

  DangNhapResponse({
    required this.maNguoiDung,
    required this.email,
    this.hoTen,
    required this.vaiTro,
    required this.maVaiTro,
    required this.token,
  });

  factory DangNhapResponse.fromJson(Map<String, dynamic> json) => DangNhapResponse(
    maNguoiDung: json['maNguoiDung'] ?? json['MaNguoiDung'],
    email: (json['email'] ?? json['Email'])?.toString() ?? '',
    hoTen: (json['hoTen'] ?? json['HoTen'])?.toString(),
    vaiTro: (json['vaiTro'] ?? json['VaiTro'])?.toString() ?? '',
    maVaiTro: json['maVaiTro'] ?? json['MaVaiTro'] ?? 0,
    token: (json['token'] ?? json['Token'])?.toString() ?? '',
  );
}

// ============ SERVICE (gọi API) ============

class AuthService {
  static Future<DangNhapResponse> dangNhap(String email, String matKhau) async {
    final data = await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.auth}/dang-nhap',
      DangNhapRequest(email: email, matKhau: matKhau).toJson(),
      auth: false,
    );
    final result = DangNhapResponse.fromJson(data);
    await TokenStorage.luuPhienDangNhap(
      token: result.token,
      maNguoiDung: result.maNguoiDung,
      email: result.email,
      hoTen: result.hoTen,
      vaiTro: result.vaiTro,
      maVaiTro: result.maVaiTro,
    );
    // Lưu MK trên máy để xem trong hồ sơ (sau khi nhập PIN 4 số)
    await ProfileVault.luuMatKhau(result.maNguoiDung, matKhau);
    return result;
  }

  /// [email]: email đăng nhập công ty. [emailNhanOtp]: Gmail cá nhân nhận mã.
  static Future<void> quenMatKhau(String email, {String? emailNhanOtp}) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.auth}/quen-mat-khau/yeu-cau',
      {
        'email': email,
        if (emailNhanOtp != null && emailNhanOtp.trim().isNotEmpty)
          'emailNhanOtp': emailNhanOtp.trim(),
      },
      auth: false,
    );
  }

  static Future<void> xacNhanOtp(String email, String maOtp) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.auth}/quen-mat-khau/xac-nhan',
      {'email': email, 'maOTP': maOtp},
      auth: false,
    );
  }

  static Future<void> datLaiMatKhau(String email, String matKhauMoi) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.auth}/quen-mat-khau/dat-lai',
      {'email': email, 'matKhauMoi': matKhauMoi},
      auth: false,
    );
    final ma = await TokenStorage.getMaNguoiDung();
    if (ma != null) {
      await ProfileVault.luuMatKhau(ma, matKhauMoi);
    }
  }

  static Future<void> dangXuat() async => TokenStorage.xoaPhienDangNhap();
}

// ============ VALIDATOR (chỉ riêng cho luồng Auth) ============

class AuthValidators {
  AuthValidators._();

  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');

  // Khớp CHÍNH XÁC quy tắc trong QuanLyNguoiDungService.cs backend
  // ≥8 ký tự, có số + ký tự đặc biệt (khớp AuthService API)
  static final _matKhauRegex =
  RegExp(r'^(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>_\-]).{8,}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
    if (!_emailRegex.hasMatch(value.trim())) return 'Email không hợp lệ';
    return null;
  }

  static String? matKhauDangNhap(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    return null;
  }

  static String? matKhauMoi(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (!_matKhauRegex.hasMatch(value)) {
      return 'Mật khẩu tối thiểu 8 ký tự, có 1 chữ số và 1 ký tự đặc biệt';
    }
    return null;
  }

  static String? xacNhanMatKhau(String? value, String matKhauMoi) {
    if (value != matKhauMoi) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().length != 6) return 'Mã OTP gồm 6 số';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) return 'Mã OTP gồm 6 số';
    return null;
  }

  /// Độ mạnh mật khẩu 0–100 (thanh trạng thái UI).
  static int doManhMatKhau(String? value) {
    if (value == null || value.isEmpty) return 0;
    var diem = 0;
    if (value.length >= 8) diem += 30;
    if (value.length >= 12) diem += 10;
    if (RegExp(r'[0-9]').hasMatch(value)) diem += 25;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value)) diem += 25;
    if (RegExp(r'[A-Z]').hasMatch(value)) diem += 5;
    if (RegExp(r'[a-z]').hasMatch(value)) diem += 5;
    if (diem > 100) diem = 100;
    return diem;
  }
}