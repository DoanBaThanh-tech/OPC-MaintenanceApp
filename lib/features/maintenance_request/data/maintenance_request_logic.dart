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

  /// Sửa yêu cầu bị từ chối rồi gửi lại xưởng (trạng thái → Chờ xác nhận)
  static Future<void> suaYeuCau({
    required int maYeuCau,
    required int maThietBi,
    required int thang,
    required int nam,
    required DateTime ngayBaoTri,
    required double thoiGianDuKien,
    required String gioBatDau,
    required String gioKetThuc,
    String? ghiChu,
  }) async {
    await ApiClient.instance.put('${ApiConstants.workOrder}/yeu-cau-bao-tri/$maYeuCau', {
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
}

/// Danh sách yêu cầu của Tổ trưởng cơ điện (tab Bảo trì) — giữ mọi trạng thái để quản lý
class DanhSachYeuCauController extends ChangeNotifier {
  List<YeuCauBaoTriItem> danhSachGoc = [];
  bool dangTai = true;
  String? loi;

  /// Bộ lọc: danh mục thiết bị, thiết bị, năm
  String? locDanhMuc;
  int? locMaThietBi;
  int? locNam;

  List<YeuCauBaoTriItem> get danhSach {
    return danhSachGoc.where((y) {
      if (locDanhMuc != null && locDanhMuc!.isNotEmpty) {
        final dm = y.danhMuc ?? 'Chưa phân loại';
        if (dm != locDanhMuc) return false;
      }
      if (locMaThietBi != null && y.maThietBi != locMaThietBi) return false;
      if (locNam != null && y.namBaoTri != locNam) return false;
      return true;
    }).toList();
  }

  /// Các danh mục có trong danh sách gốc
  List<String> get cacDanhMuc {
    final s = danhSachGoc.map((y) => y.danhMuc ?? 'Chưa phân loại').toSet().toList()..sort();
    return s;
  }

  /// Thiết bị (id + tên) — lọc theo danh mục đang chọn nếu có
  List<({int ma, String ten})> get cacThietBi {
    final filtered = locDanhMuc == null || locDanhMuc!.isEmpty
        ? danhSachGoc
        : danhSachGoc.where((y) => (y.danhMuc ?? 'Chưa phân loại') == locDanhMuc);
    final map = <int, String>{};
    for (final y in filtered) {
      map[y.maThietBi] = y.tenThietBi ?? 'TB #${y.maThietBi}';
    }
    final list = map.entries.map((e) => (ma: e.key, ten: e.value)).toList();
    list.sort((a, b) => a.ten.compareTo(b.ten));
    return list;
  }

  /// Các năm có trong danh sách gốc
  List<int> get cacNam {
    final s = danhSachGoc.map((y) => y.namBaoTri).toSet().toList()..sort((a, b) => b.compareTo(a));
    return s;
  }

  void datLocDanhMuc(String? dm) {
    locDanhMuc = dm;
    // Reset thiết bị nếu không còn khớp danh mục
    if (locMaThietBi != null && locDanhMuc != null) {
      final still = cacThietBi.any((t) => t.ma == locMaThietBi);
      if (!still) locMaThietBi = null;
    }
    notifyListeners();
  }

  void datLocThietBi(int? ma) {
    locMaThietBi = ma;
    notifyListeners();
  }

  void datLocNam(int? nam) {
    locNam = nam;
    notifyListeners();
  }

  void xoaLoc() {
    locDanhMuc = null;
    locMaThietBi = null;
    locNam = null;
    notifyListeners();
  }

  bool get dangLoc => locDanhMuc != null || locMaThietBi != null || locNam != null;

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      // Lấy toàn bộ yêu cầu (mọi trạng thái) để quản lý
      danhSachGoc = await MaintenanceRequestService.layDanhSach();
      danhSachGoc.sort((a, b) => b.maYeuCauBaoTri.compareTo(a.maYeuCauBaoTri));
    } catch (e) {
      loi = '$e';
      danhSachGoc = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
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
  String? loiThoiGian;

  /// null = tạo mới; có id = đang sửa yêu cầu bị từ chối
  int? maYeuCauDangSua;
  bool get dangSua => maYeuCauDangSua != null;

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

  List<String> get cacDanhMuc {
    final q = (timKiem ?? '').trim().toLowerCase();
    if (q.isEmpty) return nhomThietBi.map((e) => e.tenDanhMuc).toList();
    // Tìm theo tên danh mục hoặc có thiết bị khớp tên
    return nhomThietBi
        .where((n) =>
    n.tenDanhMuc.toLowerCase().contains(q) ||
        n.danhSach.any((t) => t.tenThietBi.toLowerCase().contains(q)))
        .map((e) => e.tenDanhMuc)
        .toList();
  }

  /// Bảo trì trong ngày: số nguyên dương 1–24 (không thập phân, không ký tự đặc biệt)
  static const int maxGioTrongNgay = 24;

  bool get thoiGianHopLe {
    final raw = thoiGianCtrl.text.trim();
    if (raw.isEmpty) return false;
    if (!RegExp(r'^\d+$').hasMatch(raw)) return false;
    final v = int.tryParse(raw);
    return v != null && v > 0 && v <= maxGioTrongNgay;
  }

  void validateThoiGian() {
    final raw = thoiGianCtrl.text.trim();
    if (raw.isEmpty) {
      loiThoiGian = 'Vui lòng nhập số giờ dự kiến';
      gioBatDau = null;
      gioKetThuc = null;
      notifyListeners();
      return;
    }
    // Chỉ số nguyên — cấm chữ, ký tự đặc biệt, thập phân
    if (!RegExp(r'^\d+$').hasMatch(raw)) {
      loiThoiGian =
      'Chỉ được nhập số nguyên (không chữ, không ký tự đặc biệt, không số thập phân)';
      gioBatDau = null;
      gioKetThuc = null;
      notifyListeners();
      return;
    }
    final v = int.tryParse(raw);
    if (v == null || v <= 0) {
      loiThoiGian = 'Số giờ dự kiến phải là số nguyên dương lớn hơn 0';
      gioBatDau = null;
      gioKetThuc = null;
    } else if (v > maxGioTrongNgay) {
      loiThoiGian = 'Bảo trì trong ngày — tối đa $maxGioTrongNgay giờ';
      gioBatDau = null;
      gioKetThuc = null;
    } else {
      loiThoiGian = null;
    }
    notifyListeners();
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

  /// Xoá form sau khi gửi thành công
  void resetForm() {
    maYeuCauDangSua = null;
    danhMucChon = null;
    thietBiChon = null;
    thang = DateTime.now().month;
    nam = DateTime.now().year;
    ngayBaoTri = null;
    thoiGianCtrl.clear();
    gioBatDau = null;
    gioKetThuc = null;
    ghiChuCtrl.clear();
    timKiem = '';
    loi = null;
    loiThoiGian = null;
    notifyListeners();
  }

  TimeOfDay? _parseGio(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Nạp dữ liệu yêu cầu bị từ chối để chỉnh sửa
  Future<void> napTuYeuCau(YeuCauBaoTriItem y) async {
    maYeuCauDangSua = y.maYeuCauBaoTri;
    thang = y.thangBaoTri;
    nam = y.namBaoTri;
    ngayBaoTri = y.ngayBaoTri;
    thoiGianCtrl.text = y.thoiGianDuKien.toString().replaceAll(RegExp(r'\.0$'), '');
    gioBatDau = _parseGio(y.gioBatDau);
    gioKetThuc = _parseGio(y.gioKetThuc);
    ghiChuCtrl.text = y.ghiChu ?? '';
    loi = null;
    loiThoiGian = null;
    // Chờ danh mục/thiết bị tải xong rồi gán
    if (nhomThietBi.isEmpty) await taiThietBi();
    danhMucChon = y.danhMuc;
    thietBiChon = null;
    for (final n in nhomThietBi) {
      for (final t in n.danhSach) {
        if (t.maThietBi == y.maThietBi) {
          danhMucChon = n.tenDanhMuc;
          thietBiChon = t;
          break;
        }
      }
      if (thietBiChon != null) break;
    }
    notifyListeners();
  }

  Future<bool> gui() async {
    loi = null;
    validateThoiGian();

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
    // Ngày bảo trì phải > ngày tạo (hôm nay)
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final ngay = DateTime(ngayBaoTri!.year, ngayBaoTri!.month, ngayBaoTri!.day);
    if (!ngay.isAfter(today)) {
      loi = 'Ngày bảo trì phải sau ngày tạo yêu cầu.';
      notifyListeners();
      return false;
    }
    if (!thoiGianHopLe) {
      loi = loiThoiGian ??
          'Thời gian dự kiến phải lớn hơn 0 và không quá $maxGioTrongNgay giờ trong ngày.';
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
      final tg = int.parse(thoiGianCtrl.text.trim()).toDouble();
      final gc = ghiChuCtrl.text.trim().isEmpty ? null : ghiChuCtrl.text.trim();
      if (dangSua) {
        await MaintenanceRequestService.suaYeuCau(
          maYeuCau: maYeuCauDangSua!,
          maThietBi: thietBiChon!.maThietBi,
          thang: thang,
          nam: nam,
          ngayBaoTri: ngayBaoTri!,
          thoiGianDuKien: tg,
          gioBatDau: fmt(gioBatDau!),
          gioKetThuc: fmt(gioKetThuc!),
          ghiChu: gc,
        );
      } else {
        await MaintenanceRequestService.taoYeuCau(
          maThietBi: thietBiChon!.maThietBi,
          thang: thang,
          nam: nam,
          ngayBaoTri: ngayBaoTri!,
          thoiGianDuKien: tg,
          gioBatDau: fmt(gioBatDau!),
          gioKetThuc: fmt(gioKetThuc!),
          ghiChu: gc,
        );
      }
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