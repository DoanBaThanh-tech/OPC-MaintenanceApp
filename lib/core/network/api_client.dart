import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';
import 'api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Gọi khi nhận 401 — feature/auth đăng ký callback này để tự động
  /// đưa người dùng về màn Đăng nhập, ApiClient không tự điều hướng
  /// (vì tầng network không nên biết gì về Navigator/UI)
  void Function()? onUnauthorized;

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (auth) {
      final token = await TokenStorage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  /// Xử lý response chung cho mọi method — tự parse JSON,
  /// tự ném ApiException đúng message backend trả về (dạng { "Message": "..." })
  ///
  /// Lưu ý: nhiều endpoint ASP.NET trả `Ok()` không body → body = null.
  /// Caller dùng `post` / `put` / `delete` không ép kiểu Map khi không cần body.
  dynamic _xuLyResponse(http.Response res) {
    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } on FormatException {
        // Body không phải JSON (hiếm) — vẫn coi thành công nếu 2xx
        body = res.body;
      }
    } else {
      body = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    if (res.statusCode == 401) {
      onUnauthorized?.call();
    }

    String message = 'Đã có lỗi xảy ra (${res.statusCode})';
    if (body is Map && body['Message'] != null) {
      message = body['Message'].toString();
    } else if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is Map && body['loi'] != null) {
      message = body['loi'].toString();
    } else if (body is Map && body['errors'] != null) {
      message = body['errors'].toString();
    }

    throw ApiException(res.statusCode, message);
  }

  Future<T> _thucHien<T>(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(ApiConstants.connectTimeout);
      final parsed = _xuLyResponse(res);

      // Body rỗng (Ok() không nội dung) — trả về null an toàn, không ép Map
      if (parsed == null) {
        // Caller expect Map → trả {}
        if (<String, dynamic>{} is T) {
          return <String, dynamic>{} as T;
        }
        // Caller expect List → trả []
        if (<dynamic>[] is T) {
          return <dynamic>[] as T;
        }
        // dynamic / Object? / nullable → null
        return null as T;
      }

      return parsed as T;
    } on SocketException {
      throw NetworkException('Không thể kết nối tới máy chủ. Kiểm tra mạng Wi‑Fi/4G hoặc địa chỉ API (ngrok).');
    } on HttpException {
      throw NetworkException('Lỗi kết nối HTTP.');
    } on FormatException {
      throw NetworkException('Phản hồi từ máy chủ không hợp lệ.');
    } on TimeoutException {
      throw NetworkException('Hết thời gian chờ máy chủ. Thử lại hoặc kiểm tra ngrok còn online.');
    }
    // ApiException tự ném lên
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query, bool auth = true}) {
    return _thucHien<T>(() async {
      final headers = await _headers(auth: auth);
      return http.get(_uri(path, query), headers: headers);
    });
  }

  Future<T> post<T>(String path, Map<String, dynamic> body, {bool auth = true}) {
    return _thucHien<T>(() async {
      final headers = await _headers(auth: auth);
      return http.post(_uri(path), headers: headers, body: jsonEncode(body));
    });
  }

  Future<T> put<T>(String path, Map<String, dynamic> body, {bool auth = true}) {
    return _thucHien<T>(() async {
      final headers = await _headers(auth: auth);
      return http.put(_uri(path), headers: headers, body: jsonEncode(body));
    });
  }

  Future<T> delete<T>(String path, {bool auth = true}) {
    return _thucHien<T>(() async {
      final headers = await _headers(auth: auth);
      return http.delete(_uri(path), headers: headers);
    });
  }
}