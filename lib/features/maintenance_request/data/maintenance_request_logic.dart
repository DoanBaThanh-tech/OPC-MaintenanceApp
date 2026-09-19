import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../equipment/data/equipment_logic.dart';

class YeuCauBaoTriItem {
  final int maYeuCauBaoTri;
  final int maThietBi;
  final String? tenThietBi;
  final String? danhMuc;
  final String? tenNguoiYeuCau;
  final String? tenNguoiXacNhan;
  final int thangBaoTri;
  final int namBaoTri;
  final DateTime ngayBaoTri;
  final double thoiGianDuKien;
  final String? gioBatDau;
  final String? gioKetThuc;
  final String trangThai;
  final String? lyDoTuChoi;
  final String? ghiChu;
  final String? nhanHienThi;

  YeuCauBaoTriItem({
    required this.maYeuCauBaoTri,
    required this.maThietBi,
    this.tenThietBi,
    this.danhMuc,
    this.tenNguoiYeuCau,
    this.tenNguoiXacNhan,
    required this.thangBaoTri,
    required this.namBaoTri,
    required this.ngayBaoTri,
    required this.thoiGianDuKien,
    this.gioBatDau,
    this.gioKetThuc,
    required this.trangThai,
    this.lyDoTuChoi,
    this.ghiChu,
    this.nhanHienThi,
  });

  bool get choXacNhan => trangThai == 'Chờ xác nhận';
  bool get daXacNhan => trangThai == 'Đã xác nhận';

  factory YeuCauBaoTriItem.fromJson(Map<String, dynamic> j) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      final s = v.toString();
      return DateTime.tryParse(s) ?? DateTime.now();
    }

    return YeuCauBaoTriItem(
      maYeuCauBaoTri: (j['maYeuCauBaoTri'] as num?)?.toInt() ?? 0,
      maThietBi: (j['maThietBi'] as num?)?.toInt() ?? 0,
      tenThietBi: j['tenThietBi']?.toString(),
      danhMuc: j['danhMuc']?.toString(),
      tenNguoiYeuCau: j['tenNguoiYeuCau']?.toString(),
      tenNguoiXacNhan: j['tenNguoiXacNhan']?.toString(),
      thangBaoTri: (j['thangBaoTri'] as num?)?.toInt() ?? 0,
      namBaoTri: (j['namBaoTri'] as num?)?.toInt() ?? DateTime.now().year,
      ngayBaoTri: parseDate(j['ngayBaoTri']),
      thoiGianDuKien: (j['thoiGianDuKien'] as num?)?.toDouble() ?? 0,
      gioBatDau: j['gioBatDau']?.toString(),
      gioKetThuc: j['gioKetThuc']?.toString(),
      trangThai: j['trangThai']?.toString() ?? '',
      lyDoTuChoi: j['lyDoTuChoi']?.toString(),
      ghiChu: j['ghiChu']?.toString(),
      nhanHienThi: j['nhanHienThi']?.toString(),
    );
  }
}

class MaintenanceRequestService {
  static Future<void> taoYeuCau({
    required int maThietBi,
    required int thang,
    required int nam,
    required DateTime ngayBaoTri,
    required double thoiGianDuKien,
    required String gioBatDau,
    required String gioKetThuc,
    String? ghiChu,
  }) async {
    await ApiClient.instance.post('${ApiConstants.workOrder}/yeu-cau-bao-tri', {
      'maThietBi': maThietBi,
      'thangBaoTri': thang,
      'namBaoTri': nam,
      'ngayBaoTri':
      '${ngayBaoTri.year.toString().padLeft(4, '0')}-${ngayBaoTri.month.toString().padLeft(2, '0')}-${ngayBaoTri.day.toString().padLeft(2, '0')}',
      'thoiGianDuKien': thoiGianDuKien,
      'gioBatDau': gioBatDau,
      'gioKetThuc': gioKetThuc,
      'ghiChu': ghiChu,
    });
  }

  static Future<List<YeuCauBaoTriItem>> layDanhSach({String? trangThai, int? nam, int? thang}) async {
    final q = <String, dynamic>{};
    if (trangThai != null) q['trangThai'] = trangThai;
    if (nam != null) q['nam'] = nam;
    if (thang != null) q['thang'] = thang;
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/yeu-cau-bao-tri',
      query: q.isEmpty ? null : q,
    );
    return data.map((e) => YeuCauBaoTriItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<YeuCauBaoTriItem>> layDeTaoHoSo({int? nam, int? thang}) async {
    final q = <String, dynamic>{};
    if (nam != null) q['nam'] = nam;
    if (thang != null) q['thang'] = thang;
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/yeu-cau-bao-tri/de-tao-ho-so',
      query: q.isEmpty ? null : q,
    );
    return data.map((e) => YeuCauBaoTriItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> xacNhan({required int maYeuCau, required String quyetDinh, String? lyDo}) async {
    await ApiClient.instance.put(
      '${ApiConstants.workOrder}/yeu-cau-bao-tri/$maYeuCau/xac-nhan',
      {'quyetDinh': quyetDinh, 'lyDo': lyDo},
    );
  }
}

class TaoYeuCauBaoTriController extends ChangeNotifier {
  List<NhomThietBiTheoDanhMuc> nhomThietBi = [];
  String? danhMucChon;
  ThietBiModel? thietBiChon;
  int thang = DateTime.now().month;
  int nam = DateTime.now().year;
  DateTime? ngayBaoTri;
  final thoiGianCtrl = TextEditingController();
  TimeOfDay? gioBatDau;
  TimeOfDay? gioKetThuc;
  final ghiChuCtrl = TextEditingController();
  String? timKiem = '';
  bool dangTai = true;
  bool dangGui = false;
  String? loi;

  List<ThietBiModel> get thietBiTheoDanhMuc {
    if (danhMucChon == null) return [];
    final nhom = nhomThietBi.where((n) => n.tenDanhMuc == danhMucChon);
    if (nhom.isEmpty) return [];
    var list = nhom.first.danhSach;
    final q = (timKiem ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) => t.tenThietBi.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<String> get cacDanhMuc => nhomThietBi.map((e) => e.tenDanhMuc).toList();

  bool get thoiGianHopLe {
    final v = double.tryParse(thoiGianCtrl.text.replaceAll(',', '.'));
    return v != null && v > 0;
  }

  Future<void> taiThietBi() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      nhomThietBi = await EquipmentService.layTheoDanhMuc();
    } catch (e) {
      loi = '$e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void chonDanhMuc(String? dm) {
    danhMucChon = dm;
    thietBiChon = null;
    notifyListeners();
  }

  void chonThietBi(ThietBiModel? tb) {
    thietBiChon = tb;
    notifyListeners();
  }

  void setTimKiem(String v) {
    timKiem = v;
    notifyListeners();
  }

  void setThangNam(int t, int n) {
    thang = t;
    nam = n;
    if (ngayBaoTri != null && (ngayBaoTri!.month != t || ngayBaoTri!.year != n)) {
      ngayBaoTri = null;
    }
    notifyListeners();
  }

  Future<bool> gui() async {
    loi = null;
    if (thietBiChon == null) {
      loi = 'Chọn thiết bị.';
      notifyListeners();
      return false;
    }
    if (ngayBaoTri == null) {
      loi = 'Chọn ngày bảo trì.';
      notifyListeners();
      return false;
    }
    if (!thoiGianHopLe) {
      loi = 'Thời gian dự kiến phải là số > 0.';
      notifyListeners();
      return false;
    }
    if (gioBatDau == null || gioKetThuc == null) {
      loi = 'Chọn giờ bắt đầu và kết thúc.';
      notifyListeners();
      return false;
    }
    final start = Duration(hours: gioBatDau!.hour, minutes: gioBatDau!.minute);
    final end = Duration(hours: gioKetThuc!.hour, minutes: gioKetThuc!.minute);
    if (end <= start) {
      loi = 'Giờ kết thúc phải sau giờ bắt đầu.';
      notifyListeners();
      return false;
    }

    dangGui = true;
    notifyListeners();
    try {
      String fmt(TimeOfDay t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
      await MaintenanceRequestService.taoYeuCau(
        maThietBi: thietBiChon!.maThietBi,
        thang: thang,
        nam: nam,
        ngayBaoTri: ngayBaoTri!,
        thoiGianDuKien: double.parse(thoiGianCtrl.text.replaceAll(',', '.')),
        gioBatDau: fmt(gioBatDau!),
        gioKetThuc: fmt(gioKetThuc!),
        ghiChu: ghiChuCtrl.text.trim().isEmpty ? null : ghiChuCtrl.text.trim(),
      );
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } catch (e) {
      loi = '$e';
      return false;
    } finally {
      dangGui = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    thoiGianCtrl.dispose();
    ghiChuCtrl.dispose();
    super.dispose();
  }
}

class XacNhanYeuCauController extends ChangeNotifier {
  List<YeuCauBaoTriItem> danhSach = [];
  bool dangTai = true;
  String? loi;

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      danhSach = await MaintenanceRequestService.layDanhSach(trangThai: 'Chờ xác nhận');
    } catch (e) {
      loi = '$e';
      danhSach = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  Future<bool> xuLy(int maYeuCau, {required String quyetDinh, String? lyDo}) async {
    try {
      await MaintenanceRequestService.xacNhan(maYeuCau: maYeuCau, quyetDinh: quyetDinh, lyDo: lyDo);
      await tai();
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      notifyListeners();
      return false;
    }
  }
}