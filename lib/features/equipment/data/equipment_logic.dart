import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';

// ============================================================
// MODEL
// ============================================================

class TrangThaiThietBi {
  static const sanXuat = 'Sản xuất';
  static const baoTri = 'Bảo trì';
  static const suaChua = 'Sửa chữa';

  static String chuanHoa(String? raw) {
    if (raw == null || raw.trim().isEmpty) return sanXuat;
    final t = raw.trim().toLowerCase();
    if (t.contains('bảo trì') || t.contains('bao tri')) return baoTri;
    if (t.contains('sửa chữa') || t.contains('sua chua')) return suaChua;
    return sanXuat;
  }
}

class ThietBiModel {
  final int maThietBi;
  final String tenThietBi;
  final String? loaiThietBi;
  final String? viTriLapDat;
  final DateTime? ngayLapDat;
  final String tinhTrangHienTai;
  final String? ghiChu;
  final DateTime? ngayBaoTriGanNhat;
  final DateTime? ngayBaoTriTiepTheo;
  final int? soThangDeXuat;
  final int maChuKy;
  final String? tenDanhMuc;
  final String? moTaChuKy;

  ThietBiModel({
    required this.maThietBi,
    required this.tenThietBi,
    this.loaiThietBi,
    this.viTriLapDat,
    this.ngayLapDat,
    required this.tinhTrangHienTai,
    this.ghiChu,
    this.ngayBaoTriGanNhat,
    this.ngayBaoTriTiepTheo,
    this.soThangDeXuat,
    required this.maChuKy,
    this.tenDanhMuc,
    this.moTaChuKy,
  });

  factory ThietBiModel.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return ThietBiModel(
      maThietBi: (j['maThietBi'] as num?)?.toInt() ?? 0,
      tenThietBi: j['tenThietBi']?.toString() ?? '',
      loaiThietBi: j['loaiThietBi']?.toString(),
      viTriLapDat: j['viTriLapDat']?.toString(),
      ngayLapDat: parseDate(j['ngayLapDat']),
      tinhTrangHienTai: TrangThaiThietBi.chuanHoa(
        j['tinhTrangHienTai']?.toString() ?? j['trangThai']?.toString(),
      ),
      ghiChu: j['ghiChu']?.toString(),
      ngayBaoTriGanNhat: parseDate(j['ngayBaoTriGanNhat']),
      ngayBaoTriTiepTheo: parseDate(j['ngayBaoTriTiepTheo']),
      soThangDeXuat: (j['soThangDeXuat'] as num?)?.toInt(),
      maChuKy: (j['maChuKy'] as num?)?.toInt() ?? 0,
      tenDanhMuc: j['tenDanhMuc']?.toString() ?? j['loaiThietBi']?.toString(),
      moTaChuKy: j['moTaChuKy']?.toString(),
    );
  }

  String get danhMuc =>
      (tenDanhMuc?.trim().isNotEmpty == true)
          ? tenDanhMuc!
          : (loaiThietBi?.trim().isNotEmpty == true ? loaiThietBi! : 'Chưa phân loại');
}

class NhomThietBiTheoDanhMuc {
  final String tenDanhMuc;
  final int maChuKy;
  final int? soThangChuKy;
  final List<ThietBiModel> danhSach;
  final int soSanXuat;
  final int soBaoTri;
  final int soSuaChua;

  NhomThietBiTheoDanhMuc({
    required this.tenDanhMuc,
    required this.maChuKy,
    this.soThangChuKy,
    required this.danhSach,
    required this.soSanXuat,
    required this.soBaoTri,
    required this.soSuaChua,
  });

  int get soLuong => danhSach.length;

  factory NhomThietBiTheoDanhMuc.fromJson(Map<String, dynamic> j) {
    final list = (j['danhSach'] as List? ?? [])
        .map((e) => ThietBiModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return NhomThietBiTheoDanhMuc(
      tenDanhMuc: j['tenDanhMuc']?.toString() ?? 'Chưa phân loại',
      maChuKy: (j['maChuKy'] as num?)?.toInt() ?? 0,
      soThangChuKy: (j['soThangChuKy'] as num?)?.toInt(),
      danhSach: list,
      soSanXuat: (j['soSanXuat'] as num?)?.toInt() ??
          list.where((e) => e.tinhTrangHienTai == TrangThaiThietBi.sanXuat).length,
      soBaoTri: (j['soBaoTri'] as num?)?.toInt() ??
          list.where((e) => e.tinhTrangHienTai == TrangThaiThietBi.baoTri).length,
      soSuaChua: (j['soSuaChua'] as num?)?.toInt() ??
          list.where((e) => e.tinhTrangHienTai == TrangThaiThietBi.suaChua).length,
    );
  }
}

class ThongKeThietBi {
  final int tongSo;
  final int soSanXuat;
  final int soBaoTri;
  final int soSuaChua;

  ThongKeThietBi({
    required this.tongSo,
    required this.soSanXuat,
    required this.soBaoTri,
    required this.soSuaChua,
  });

  factory ThongKeThietBi.fromJson(Map<String, dynamic> j) => ThongKeThietBi(
    tongSo: (j['tongSo'] as num?)?.toInt() ?? 0,
    soSanXuat: (j['soSanXuat'] as num?)?.toInt() ?? 0,
    soBaoTri: (j['soBaoTri'] as num?)?.toInt() ?? 0,
    soSuaChua: (j['soSuaChua'] as num?)?.toInt() ?? 0,
  );

  static ThongKeThietBi empty() =>
      ThongKeThietBi(tongSo: 0, soSanXuat: 0, soBaoTri: 0, soSuaChua: 0);
}

// ============================================================
// SERVICE
// ============================================================

class EquipmentService {
  EquipmentService._();

  /// GET /api/Equipment/theo-danh-muc
  static Future<List<NhomThietBiTheoDanhMuc>> layTheoDanhMuc({String? trangThai}) async {
    final query = <String, dynamic>{};
    if (trangThai != null && trangThai.isNotEmpty) query['trangThai'] = trangThai;

    final data = await ApiClient.instance.get<dynamic>(
      ApiConstants.equipmentTheoDanhMuc,
      query: query.isEmpty ? null : query,
    );

    List list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = data['data'] ?? data['items'] ?? data['danhSach'] ?? [];
    } else {
      list = [];
    }

    return list
        .map((e) => NhomThietBiTheoDanhMuc.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /api/Equipment/thong-ke
  static Future<ThongKeThietBi> layThongKe() async {
    try {
      final data = await ApiClient.instance.get<Map<String, dynamic>>(
        ApiConstants.equipmentThongKe,
      );
      return ThongKeThietBi.fromJson(data);
    } catch (_) {
      return ThongKeThietBi.empty();
    }
  }

  /// GET /api/Equipment/{id}
  static Future<ThietBiModel> layChiTiet(int maThietBi) async {
    final data = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.equipmentDetail(maThietBi),
    );
    return ThietBiModel.fromJson(data);
  }
}

// ============================================================
// CONTROLLER
// ============================================================

class EquipmentListController extends ChangeNotifier {
  List<NhomThietBiTheoDanhMuc> _nhomGoc = [];
  List<NhomThietBiTheoDanhMuc> _nhom = [];
  ThongKeThietBi _thongKe = ThongKeThietBi.empty();
  bool _dangTai = false;
  String? _loi;
  String _tuKhoa = '';
  String? _locTrangThai;

  List<NhomThietBiTheoDanhMuc> get nhom => _nhom;
  ThongKeThietBi get thongKe => _thongKe;
  bool get dangTai => _dangTai;
  String? get loi => _loi;
  String get tuKhoa => _tuKhoa;
  String? get locTrangThai => _locTrangThai;

  Future<void> taiDanhSach() async {
    _dangTai = true;
    _loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        EquipmentService.layTheoDanhMuc(),
        EquipmentService.layThongKe(),
      ]);
      _nhomGoc = results[0] as List<NhomThietBiTheoDanhMuc>;
      _thongKe = results[1] as ThongKeThietBi;

      // Fallback thống kê nếu API thong-ke trống
      if (_thongKe.tongSo == 0 && _nhomGoc.isNotEmpty) {
        int sx = 0, bt = 0, sc = 0, tong = 0;
        for (final n in _nhomGoc) {
          sx += n.soSanXuat;
          bt += n.soBaoTri;
          sc += n.soSuaChua;
          tong += n.soLuong;
        }
        _thongKe = ThongKeThietBi(tongSo: tong, soSanXuat: sx, soBaoTri: bt, soSuaChua: sc);
      }

      _apDungBoLoc();
    } on ApiException catch (e) {
      _loi = e.message;
      _nhomGoc = [];
      _nhom = [];
    } catch (_) {
      _loi = 'Không tải được danh sách thiết bị. Kiểm tra kết nối.';
      _nhomGoc = [];
      _nhom = [];
    } finally {
      _dangTai = false;
      notifyListeners();
    }
  }

  void datTuKhoa(String value) {
    _tuKhoa = value.trim();
    _apDungBoLoc();
    notifyListeners();
  }

  void datLocTrangThai(String? trangThai) {
    _locTrangThai = trangThai;
    _apDungBoLoc();
    notifyListeners();
  }

  void _apDungBoLoc() {
    final q = _tuKhoa.toLowerCase();
    final loc = _locTrangThai;

    _nhom = _nhomGoc
        .map((n) {
      var ds = n.danhSach;
      if (loc != null && loc.isNotEmpty) {
        ds = ds.where((e) => e.tinhTrangHienTai == loc).toList();
      }
      if (q.isNotEmpty) {
        ds = ds.where((e) {
          return e.tenThietBi.toLowerCase().contains(q) ||
              (e.viTriLapDat?.toLowerCase().contains(q) ?? false) ||
              e.maThietBi.toString().contains(q) ||
              n.tenDanhMuc.toLowerCase().contains(q);
        }).toList();
      }
      if (ds.isEmpty) return null;
      return NhomThietBiTheoDanhMuc(
        tenDanhMuc: n.tenDanhMuc,
        maChuKy: n.maChuKy,
        soThangChuKy: n.soThangChuKy,
        danhSach: ds,
        soSanXuat: ds.where((e) => e.tinhTrangHienTai == TrangThaiThietBi.sanXuat).length,
        soBaoTri: ds.where((e) => e.tinhTrangHienTai == TrangThaiThietBi.baoTri).length,
        soSuaChua: ds.where((e) => e.tinhTrangHienTai == TrangThaiThietBi.suaChua).length,
      );
    })
        .whereType<NhomThietBiTheoDanhMuc>()
        .toList();
  }
}

class EquipmentDetailController extends ChangeNotifier {
  ThietBiModel? thietBi;
  bool dangTai = false;
  String? loi;

  Future<void> taiChiTiet(int maThietBi) async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      thietBi = await EquipmentService.layChiTiet(maThietBi);
    } on ApiException catch (e) {
      loi = e.message;
      thietBi = null;
    } catch (_) {
      loi = 'Không tải được chi tiết thiết bị.';
      thietBi = null;
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }
}