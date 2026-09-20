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
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
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
  String? loiThoiGian;
  String? loiNgay;

  List<ThietBiModel> get thietBiTheoDanhMuc {
    if (danhMucChon == null) return [];
    final nhom = nhomThietBi.where((n) => n.tenDanhMuc == danhMucChon);
    if (nhom.isEmpty) return [];
    var list = List<ThietBiModel>.from(nhom.first.danhSach);
    final q = (timKiem ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) => t.tenThietBi.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<String> get cacDanhMuc => nhomThietBi.map((e) => e.tenDanhMuc).toList();

  /// Số > 0, không chữ / ký tự lạ (cho phép gõ sai để hiện lỗi đỏ)
  bool get thoiGianHopLe {
    final raw = thoiGianCtrl.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return false;
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(raw)) return false;
    final v = double.tryParse(raw);
    return v != null && v > 0;
  }

  String? get thongBaoLoiThoiGian {
    final raw = thoiGianCtrl.text.trim();
    if (raw.isEmpty) return null;
    if (thoiGianHopLe) return null;
    return 'Chỉ nhập số dương (không âm, không chữ, không ký tự đặc biệt)';
  }

  void onThoiGianChanged(String _) {
    loiThoiGian = thongBaoLoiThoiGian;
    if (!thoiGianHopLe) {
      gioBatDau = null;
      gioKetThuc = null;
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
    loiNgay = null;
    notifyListeners();
  }

  void setNgayBaoTri(DateTime d) {
    final homNay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (!d.isAfter(homNay)) {
      loiNgay = 'Ngày bảo trì phải lớn hơn ngày tạo yêu cầu (${homNay.day.toString().padLeft(2, '0')}/${homNay.month.toString().padLeft(2, '0')}/${homNay.year})';
      ngayBaoTri = null;
    } else {
      loiNgay = null;
      ngayBaoTri = d;
    }
    notifyListeners();
  }

  void resetForm() {
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
    loiNgay = null;
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
      loi = loiNgay ?? 'Chọn ngày bảo trì (phải sau ngày hôm nay).';
      notifyListeners();
      return false;
    }
    final homNay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (!ngayBaoTri!.isAfter(homNay)) {
      loi = 'Ngày bảo trì phải lớn hơn ngày tạo yêu cầu.';
      notifyListeners();
      return false;
    }
    if (!thoiGianHopLe) {
      loiThoiGian = thongBaoLoiThoiGian ?? 'Thời gian dự kiến không hợp lệ.';
      loi = 'Sửa thời gian dự kiến trước khi gửi.';
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
        thoiGianDuKien: double.parse(thoiGianCtrl.text.trim().replaceAll(',', '.')),
        gioBatDau: fmt(gioBatDau!),
        gioKetThuc: fmt(gioKetThuc!),
        ghiChu: ghiChuCtrl.text.trim().isEmpty ? null : ghiChuCtrl.text.trim(),
      );
      resetForm();
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

class QuanLyYeuCauController extends ChangeNotifier {
  List<YeuCauBaoTriItem> danhSach = [];
  bool dangTai = true;
  String? loi;
  String tab = 'Bảo trì'; // Bảo trì | Sửa chữa

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      if (tab == 'Sửa chữa') {
        // Khuôn sẵn — chưa có API sửa chữa
        danhSach = [];
      } else {
        final all = await MaintenanceRequestService.layDanhSach();
        danhSach = all
            .where((e) => e.trangThai == 'Chờ xác nhận' || e.trangThai == 'Đã xác nhận' || e.trangThai == 'Đã tạo hồ sơ' || e.trangThai == 'Từ chối')
            .toList();
      }
    } catch (e) {
      loi = '$e';
      danhSach = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void doiTab(String t) {
    if (tab == t) return;
    tab = t;
    tai();
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

  Future<bool> xacNhan(int maYeuCau) async {
    try {
      await MaintenanceRequestService.xacNhan(maYeuCau: maYeuCau, quyetDinh: 'Xác nhận');
      await tai();
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      notifyListeners();
      return false;
    }
  }
}