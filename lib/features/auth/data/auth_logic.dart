import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/token_storage.dart';

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
  final String vaiTro;
  final int maVaiTro;
  final String token;

  DangNhapResponse({
    required this.maNguoiDung,
    required this.email,
    required this.vaiTro,
    required this.maVaiTro,
    required this.token,
  });

  factory DangNhapResponse.fromJson(Map<String, dynamic> json) => DangNhapResponse(
        maNguoiDung: json['maNguoiDung'] ?? json['MaNguoiDung'],
        email: json['email'] ?? json['Email'],
        vaiTro: json['vaiTro'] ?? json['VaiTro'],
        maVaiTro: json['maVaiTro'] ?? json['MaVaiTro'],
        token: json['token'] ?? json['Token'],
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
      vaiTro: result.vaiTro,
      maVaiTro: result.maVaiTro,
    );
    return result;
  }

  static Future<void> quenMatKhau(String email) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.auth}/quen-mat-khau',
      {'email': email},
      auth: false,
    );
  }

  static Future<void> xacNhanOtp(String email, String maOtp) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.auth}/xac-nhan-otp',
      {'email': email, 'maOTP': maOtp},
      auth: false,
    );
  }

  static Future<void> datLaiMatKhau(String email, String matKhauMoi) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      '${ApiConstants.auth}/dat-lai-mat-khau',
      {'email': email, 'matKhauMoi': matKhauMoi},
      auth: false,
    );
  }

  static Future<void> dangXuat() async => TokenStorage.xoaPhienDangNhap();
}

// ============ VALIDATOR (chỉ riêng cho luồng Auth) ============

class AuthValidators {
  AuthValidators._();

  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');

  // Khớp CHÍNH XÁC quy tắc trong QuanLyNguoiDungService.cs backend
  static final _matKhauRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*[!@#$%^&*(),.?":{}|<>_\-]).{8,}$');

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
      return 'Mật khẩu tối thiểu 8 ký tự, có 1 chữ hoa và 1 ký tự đặc biệt';
    }
    return null;
  }

  static String? xacNhanMatKhau(String? value, String matKhauMoi) {
    if (value != matKhauMoi) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.length != 4) return 'Mã OTP gồm 4 số';
    return null;
  }
}