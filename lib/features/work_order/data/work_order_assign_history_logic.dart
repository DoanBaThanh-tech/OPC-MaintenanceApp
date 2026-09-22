import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import 'models/work_order_models.dart';
import 'services/work_order_service.dart';

// Logic cho work_order_assign_history_screen.dart

class LichSuPhanCongController extends ChangeNotifier {
  List<LichSuPhanCong> _tatCa = [];
  bool dangTai = true;
  bool dangHuy = false;
  String? loi;
  /// 'Bảo trì' | 'Sửa chữa' | null = tất cả
  String? tabLoai = 'Bảo trì';

  List<LichSuPhanCong> get danhSach {
    if (tabLoai == null) return _tatCa;
    return _tatCa.where((e) => (e.loai ?? '') == tabLoai).toList();
  }

  int demTheoLoai(String loai) =>
      _tatCa.where((e) => (e.loai ?? '') == loai).length;

  void doiTab(String? loai) {
    if (tabLoai == loai) return;
    tabLoai = loai;
    notifyListeners();
  }

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      _tatCa = await WorkOrderService.layLichSuPhanCong();
    } catch (e) {
      loi = 'Không tải được lịch sử: $e';
      _tatCa = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  Future<bool> huyPhanCong(int maPhanCong) async {
    dangHuy = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.huyPhanCong(maPhanCong);
      await tai();
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } catch (e) {
      loi = '$e';
      return false;
    } finally {
      dangHuy = false;
      notifyListeners();
    }
  }
}