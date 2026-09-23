import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'models/work_order_models.dart';
import 'services/work_order_service.dart';

// Logic cho work_order_repair_screens.dart

/// Danh sách hồ sơ sửa chữa.
class WorkOrderSuaChuaListController extends ChangeNotifier {
  List<HoSoSuaChua> danhSach = [];
  bool dangTai = true;
  String? loi;
  String? locTrangThai;

  WorkOrderSuaChuaListController({String? trangThaiMacDinh}) {
    locTrangThai = trangThaiMacDinh;
  }

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      danhSach =
      await WorkOrderService.layDanhSachHoSoSuaChua(trangThai: locTrangThai);
    } catch (e) {
      loi = e is ApiException ? e.message : '$e';
      danhSach = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void datLocTrangThai(String? tt) {
    locTrangThai = tt;
    tai();
  }
}

/// Chi tiết hồ sơ sửa chữa + hành động (phân công / hoàn thành).
class ChiTietHoSoSuaChuaController extends ChangeNotifier {
  final int maHoSo;
  ChiTietHoSoSuaChuaController(this.maHoSo);

  HoSoSuaChua? hoSo;
  bool dangTai = true;
  bool dangXuLy = false;
  String? loi;
  String? vaiTro;

  bool get laToTruong =>
      vaiTro == 'Tổ trưởng cơ điện' ||
          vaiTro == 'Tổ trưởng kỹ thuật' ||
          vaiTro == 'Tổ trưởng';
  bool get laNvkt => vaiTro == 'Nhân viên kỹ thuật';

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        WorkOrderService.layChiTietHoSoSuaChua(maHoSo),
        TokenStorage.getVaiTro(),
      ]);
      hoSo = results[0] as HoSoSuaChua;
      vaiTro = results[1] as String?;
    } catch (e) {
      loi = e is ApiException ? e.message : '$e';
      hoSo = null;
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  /// NVKT hoàn thành SC — đồng bộ mọi phân công + TB về Sản xuất.
  Future<bool> nhanVienHoanThanh() async {
    if (hoSo == null) return false;
    dangXuLy = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.nhanVienHoanThanhSuaChua(hoSo!.maHoSoSuaChua);
      await tai();
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } finally {
      dangXuLy = false;
      notifyListeners();
    }
  }
}