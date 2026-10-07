import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';

// ============ MODELS ============

class TaiKhoanAdmin {
  final int maNguoiDung;
  final String email;
  final int maVaiTro;
  final String? tenVaiTro;
  final String hoTen;
  final String? soDienThoai;
  final String? chucVu;
  final String trangThai;
  final DateTime? lanDangNhapCuoi;
  final DateTime? ngayTao;

  const TaiKhoanAdmin({
    required this.maNguoiDung,
    required this.email,
    required this.maVaiTro,
    this.tenVaiTro,
    required this.hoTen,
    this.soDienThoai,
    this.chucVu,
    required this.trangThai,
    this.lanDangNhapCuoi,
    this.ngayTao,
  });

  bool get dangHoatDong => trangThai == 'Đang hoạt động';
  bool get daKhoa => trangThai == 'Đã khóa';
  bool get chuaKichHoat => trangThai == 'Chưa kích hoạt';

  factory TaiKhoanAdmin.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    DateTime? d(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return TaiKhoanAdmin(
      maNguoiDung: n(j['maNguoiDung'] ?? j['MaNguoiDung']),
      email: (j['email'] ?? j['Email'])?.toString() ?? '',
      maVaiTro: n(j['maVaiTro'] ?? j['MaVaiTro']),
      tenVaiTro: (j['tenVaiTro'] ?? j['TenVaiTro'])?.toString(),
      hoTen: (j['hoTen'] ?? j['HoTen'])?.toString() ??
          (j['email'] ?? j['Email'])?.toString() ??
          '',
      soDienThoai: (j['soDienThoai'] ?? j['SoDienThoai'])?.toString(),
      chucVu: (j['chucVu'] ?? j['ChucVu'])?.toString(),
      trangThai: (j['trangThai'] ?? j['TrangThai'])?.toString() ?? '',
      lanDangNhapCuoi: d(j['lanDangNhapCuoi'] ?? j['LanDangNhapCuoi']),
      ngayTao: d(j['ngayTao'] ?? j['NgayTao']),
    );
  }
}

class VaiTroThongKe {
  final int maVaiTro;
  final String tenVaiTro;
  final int? capDoQuyen;
  final int soNguoiDung;

  const VaiTroThongKe({
    required this.maVaiTro,
    required this.tenVaiTro,
    this.capDoQuyen,
    required this.soNguoiDung,
  });

  factory VaiTroThongKe.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    return VaiTroThongKe(
      maVaiTro: n(j['maVaiTro'] ?? j['MaVaiTro']),
      tenVaiTro: (j['tenVaiTro'] ?? j['TenVaiTro'])?.toString() ?? '',
      capDoQuyen: (j['capDoQuyen'] ?? j['CapDoQuyen']) as int?,
      soNguoiDung: n(j['soNguoiDung'] ?? j['SoNguoiDung']),
    );
  }
}

class NhatKyItem {
  final int maNhatKy;
  final int maNhanVien;
  final String tenNhanVien;
  final String tenApi;
  final String phuongThucHttp;
  final DateTime thoiGian;
  final String? diaChiIp;
  final String moTa;
  final int? statusCode;
  final String? queryString;
  final String loaiHanhDong; // Read / Create / Update / Delete
  final String? chiTiet;

  const NhatKyItem({
    required this.maNhatKy,
    required this.maNhanVien,
    required this.tenNhanVien,
    required this.tenApi,
    required this.phuongThucHttp,
    required this.thoiGian,
    this.diaChiIp,
    required this.moTa,
    this.statusCode,
    this.queryString,
    required this.loaiHanhDong,
    this.chiTiet,
  });

  String get loaiLabel {
    switch (loaiHanhDong.toUpperCase()) {
      case 'READ':
      case 'GET':
        return 'Read';
      case 'CREATE':
      case 'POST':
        return 'Create';
      case 'UPDATE':
      case 'PUT':
      case 'PATCH':
        return 'Update';
      case 'DELETE':
        return 'Delete';
      default:
        return loaiHanhDong.isEmpty ? phuongThucHttp : loaiHanhDong;
    }
  }

  factory NhatKyItem.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    int? nN(dynamic v) => (v as num?)?.toInt();
    final method =
        (j['phuongThucHttp'] ?? j['PhuongThucHttp'])?.toString() ?? '';
    final loaiRaw =
        (j['loaiHanhDong'] ?? j['LoaiHanhDong'])?.toString() ?? '';
    String loai;
    if (loaiRaw.isNotEmpty) {
      loai = loaiRaw;
    } else {
      switch (method.toUpperCase()) {
        case 'GET':
          loai = 'Read';
          break;
        case 'POST':
          loai = 'Create';
          break;
        case 'PUT':
        case 'PATCH':
          loai = 'Update';
          break;
        case 'DELETE':
          loai = 'Delete';
          break;
        default:
          loai = method;
      }
    }
    return NhatKyItem(
      maNhatKy: n(j['maNhatKy'] ?? j['MaNhatKy']),
      maNhanVien: n(j['maNhanVien'] ?? j['MaNhanVien']),
      tenNhanVien:
      (j['tenNhanVien'] ?? j['TenNhanVien'])?.toString() ?? '—',
      tenApi: (j['tenApi'] ?? j['TenApi'])?.toString() ?? '',
      phuongThucHttp: method,
      thoiGian: DateTime.tryParse(
          (j['thoiGianTruyCap'] ?? j['ThoiGianTruyCap'])?.toString() ??
              '') ??
          DateTime.now(),
      diaChiIp: (j['diaChiIp'] ?? j['DiaChiIp'])?.toString(),
      moTa: (j['moTa'] ?? j['MoTa'])?.toString() ?? '',
      statusCode: nN(j['statusCode'] ?? j['StatusCode']),
      queryString: (j['queryString'] ?? j['QueryString'])?.toString(),
      loaiHanhDong: loai,
      chiTiet: (j['chiTiet'] ?? j['ChiTiet'])?.toString(),
    );
  }
}

// ============ RULES (logic — không nhét vào screen) ============

class AdminNguoiDungRules {
  AdminNguoiDungRules._();

  static const vaiTroChoPhep = {
    'Tổ trưởng cơ điện',
    'Xưởng',
    'Giám đốc',
    'Nhân viên kỹ thuật',
  };

  /// Họ tên: để trống OK; nếu có thì chỉ chữ + khoảng trắng (không số/ký tự đặc biệt/email).
  static String? kiemTraHoTen(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    if (t.contains('@') || t.toLowerCase().contains('opc.com')) {
      return 'Họ tên không được điền email công ty.';
    }
    // Chữ Unicode (có dấu) + khoảng trắng
    final ok = RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(t);
    if (!ok) {
      return 'Họ tên chỉ gồm chữ cái và khoảng trắng (không số, không ký tự đặc biệt).';
    }
    return null;
  }

  static String? kiemTraEmailCongTy(String? raw) {
    final e = (raw ?? '').trim();
    if (e.isEmpty) return 'Vui lòng nhập email công ty.';
    if (!e.toLowerCase().endsWith('@opc.com')) {
      return 'Email công ty phải có đuôi @opc.com.';
    }
    if (!e.contains('@') || e.startsWith('@')) {
      return 'Email không hợp lệ.';
    }
    return null;
  }

}

// ============ SERVICE ============

class AdminService {
  static Future<List<TaiKhoanAdmin>> layDanhSachTaiKhoan() async {
    final data =
    await ApiClient.instance.get<List<dynamic>>(ApiConstants.adminUsers);
    return data
        .map((e) => TaiKhoanAdmin.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<VaiTroThongKe>> layThongKeVaiTro() async {
    final data =
    await ApiClient.instance.get<List<dynamic>>(ApiConstants.adminVaiTro);
    return data
        .map((e) => VaiTroThongKe.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((v) => AdminNguoiDungRules.vaiTroChoPhep.contains(v.tenVaiTro))
        .toList();
  }

  static Future<void> taoTaiKhoan({
    required String email,
    required String matKhau,
    required int maVaiTro,
    required String hoTen,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.adminTaoTaiKhoan,
      {
        'email': email,
        'matKhau': matKhau,
        'maVaiTro': maVaiTro,
        'hoTen': hoTen,
      },
    );
  }

  /// Admin chỉ đổi vai trò.
  static Future<void> capNhatTaiKhoan({
    required int maNguoiDung,
    required int maVaiTro,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.adminUsers}/$maNguoiDung',
      {
        'maVaiTro': maVaiTro,
      },
    );
  }

  static Future<void> kichHoat(int maNguoiDung) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.adminUsers}/$maNguoiDung/kich-hoat',
      {},
    );
  }

  static Future<void> khoa(int maNguoiDung) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.adminUsers}/$maNguoiDung/khoa',
      {},
    );
  }

  static Future<List<NhatKyItem>> layNhatKy({
    String? tuKhoa,
    String? phuongThuc,
  }) async {
    final q = <String, dynamic>{};
    if (tuKhoa != null && tuKhoa.trim().isNotEmpty) q['tuKhoa'] = tuKhoa.trim();
    if (phuongThuc != null && phuongThuc.isNotEmpty) {
      q['phuongThucHTTP'] = phuongThuc;
    }
    final data = await ApiClient.instance.get<List<dynamic>>(
      ApiConstants.adminNhatKy,
      query: q.isEmpty ? null : q,
    );
    return data
        .map((e) => NhatKyItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

// ============ CONTROLLERS ============

class QuanLyNguoiDungController extends ChangeNotifier {
  List<TaiKhoanAdmin> danhSach = [];
  List<VaiTroThongKe> vaiTro = [];
  bool dangTai = true;
  String? loi;
  String? locVaiTro; // null = tất cả
  String? locTrangThai;
  String tuKhoa = '';

  List<TaiKhoanAdmin> get hienThi {
    var list = danhSach;
    if (locVaiTro != null) {
      list = list.where((e) => e.tenVaiTro == locVaiTro).toList();
    }
    if (locTrangThai != null) {
      list = list.where((e) => e.trangThai == locTrangThai).toList();
    }
    if (tuKhoa.trim().isNotEmpty) {
      final k = tuKhoa.trim().toLowerCase();
      list = list
          .where((e) =>
      e.hoTen.toLowerCase().contains(k) ||
          e.email.toLowerCase().contains(k) ||
          (e.tenVaiTro ?? '').toLowerCase().contains(k))
          .toList();
    }
    return list;
  }

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        AdminService.layDanhSachTaiKhoan(),
        AdminService.layThongKeVaiTro(),
      ]);
      danhSach = results[0] as List<TaiKhoanAdmin>;
      vaiTro = results[1] as List<VaiTroThongKe>;
    } on ApiException catch (e) {
      loi = e.message;
    } catch (e) {
      loi = '$e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void datLocVaiTro(String? ten) {
    locVaiTro = ten;
    notifyListeners();
  }

  void datLocTrangThai(String? tt) {
    locTrangThai = tt;
    notifyListeners();
  }

  void datTuKhoa(String k) {
    tuKhoa = k;
    notifyListeners();
  }

  Future<String?> taoTaiKhoan({
    required String email,
    required String matKhau,
    required int maVaiTro,
    required String hoTen,
  }) async {
    final e1 = AdminNguoiDungRules.kiemTraEmailCongTy(email);
    if (e1 != null) return e1;
    final e2 = AdminNguoiDungRules.kiemTraHoTen(hoTen);
    if (e2 != null) return e2;
    try {
      await AdminService.taoTaiKhoan(
        email: email.trim(),
        matKhau: matKhau,
        maVaiTro: maVaiTro,
        hoTen: hoTen.trim(),
      );
      await tai();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  Future<String?> capNhat({
    required int maNguoiDung,
    required int maVaiTro,
  }) async {
    try {
      await AdminService.capNhatTaiKhoan(
        maNguoiDung: maNguoiDung,
        maVaiTro: maVaiTro,
      );
      await tai();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  Future<String?> kichHoat(int id) async {
    try {
      await AdminService.kichHoat(id);
      await tai();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  Future<String?> khoa(int id) async {
    try {
      await AdminService.khoa(id);
      await tai();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }
}

class NhatKyController extends ChangeNotifier {
  List<NhatKyItem> danhSach = [];
  bool dangTai = true;
  bool dangTaiNgam = false;
  String? loi;
  String tuKhoa = '';
  String? phuongThuc; // GET/POST/PUT/DELETE
  String? loaiHanhDong; // Read/Create/Update/Delete
  bool live = true;

  List<NhatKyItem> get danhSachLoc {
    if (loaiHanhDong == null || loaiHanhDong!.isEmpty) return danhSach;
    final key = loaiHanhDong!.toLowerCase();
    return danhSach.where((e) => e.loaiLabel.toLowerCase() == key).toList();
  }

  int demLoai(String loai) =>
      danhSach.where((e) => e.loaiLabel.toLowerCase() == loai.toLowerCase()).length;

  Future<void> tai({bool ngam = false}) async {
    if (ngam) {
      dangTaiNgam = true;
    } else {
      dangTai = true;
    }
    loi = null;
    notifyListeners();
    try {
      danhSach = await AdminService.layNhatKy(
        tuKhoa: tuKhoa.isEmpty ? null : tuKhoa,
        phuongThuc: phuongThuc,
      );
    } on ApiException catch (e) {
      loi = e.message;
    } catch (e) {
      loi = '$e';
    } finally {
      dangTai = false;
      dangTaiNgam = false;
      notifyListeners();
    }
  }

  void datTuKhoa(String k) {
    tuKhoa = k;
  }

  void datPhuongThuc(String? m) {
    phuongThuc = m;
    tai();
  }

  void datLoaiHanhDong(String? loai) {
    loaiHanhDong = loai;
    notifyListeners();
  }

  void doiLive(bool v) {
    live = v;
    notifyListeners();
  }
}