/// Đại diện lỗi từ API, tách riêng theo statusCode để tầng trên
/// (feature/auth, feature/equipment...) dễ xử lý từng trường hợp
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isBadRequest => statusCode == 400;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => message;
}

/// Lỗi mạng (mất kết nối, timeout) — khác lỗi từ API trả về có statusCode
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}