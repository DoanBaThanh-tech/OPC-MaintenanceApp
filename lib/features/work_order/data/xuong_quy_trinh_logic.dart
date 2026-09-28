import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import 'models/work_order_models.dart';
import 'models/material_usage_models.dart';
import 'services/work_order_service.dart';
import 'services/material_usage_service.dart';

/// Logic nghiệp vụ trang **Quy trình** của Xưởng.
/// NVKT bấm Xong → HS BT/SC = "Chờ xác nhận" → xuất hiện tại đây.
/// Xưởng Xác nhận → Hoàn thành; Từ chối → NVKT cập nhật lại quy trình.
class XuongQuyTrinhController extends ChangeNotifier {
  List<HoSoBaoTri> dsBaoTri = [];
  List<HoSoSuaChua> dsSuaChua = [];
  bool dangTai = true;
  String? loi;

  /// Tab: 0 = Bảo trì, 1 = Sửa chữa
  int tabIndex = 0;

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        WorkOrderService.layDanhSachHoSoBaoTri(),
        WorkOrderService.layDanhSachHoSoSuaChua(),
      ]);
      final allBt = results[0] as List<HoSoBaoTri>;
      final allSc = results[1] as List<HoSoSuaChua>;
      // Chỉ lấy hồ sơ NVKT đã gửi quy trình (Chờ xác nhận)
      dsBaoTri = allBt.where((e) => e.choXacNhanKetQua).toList();
      dsSuaChua = allSc.where((e) => e.choXacNhanKetQua).toList();
    } catch (e) {
      loi = e is ApiException ? e.message : '$e';
      dsBaoTri = [];
      dsSuaChua = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void doiTab(int i) {
    if (tabIndex == i) return;
    tabIndex = i;
    notifyListeners();
  }

  Future<(bool ok, String? message)> xacNhan({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
  }) async {
    try {
      await WorkOrderService.xuongXacNhanKetQua(
        maHoSoBaoTri: maHoSoBaoTri,
        maHoSoSuaChua: maHoSoSuaChua,
        xacNhan: true,
      );
      await tai();
      return (true, null);
    } on ApiException catch (e) {
      return (false, e.message);
    } catch (e) {
      return (false, '$e');
    }
  }

  Future<(bool ok, String? message)> tuChoi({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
    required String lyDo,
  }) async {
    final lyDoTrim = lyDo.trim();
    if (lyDoTrim.isEmpty) {
      return (false, 'Vui lòng nhập lý do từ chối');
    }
    try {
      await WorkOrderService.xuongXacNhanKetQua(
        maHoSoBaoTri: maHoSoBaoTri,
        maHoSoSuaChua: maHoSoSuaChua,
        xacNhan: false,
        lyDo: lyDoTrim,
      );
      await tai();
      return (true, null);
    } on ApiException catch (e) {
      return (false, e.message);
    } catch (e) {
      return (false, '$e');
    }
  }

  /// Tải hồ sơ vật tư + bước quy trình theo công việc.
  Future<HoSoVatTuItem?> layQuyTrinhVatTu({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
  }) async {
    try {
      return await MaterialUsageService.layHoSoTheoCongViec(
        maHoSoBaoTri: maHoSoBaoTri,
        maHoSoSuaChua: maHoSoSuaChua,
      );
    } catch (_) {
      return null;
    }
  }
}