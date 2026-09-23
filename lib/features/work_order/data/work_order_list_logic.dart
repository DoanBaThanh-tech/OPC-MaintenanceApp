import 'package:flutter/foundation.dart';

import 'models/work_order_models.dart';
import 'services/work_order_service.dart';

export 'models/work_order_models.dart';
export 'services/work_order_service.dart';

// Logic cho work_order_list_screen.dart

class WorkOrderBaoTriListController extends ChangeNotifier {
  List<HoSoBaoTri> danhSach = [];
  List<int> cacNamCoKeHoach = [];
  bool dangTai = true;
  String? loi;
  int? namLoc;

  Future<void> taiDanhSach() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        WorkOrderService.layDanhSachHoSoBaoTri(nam: namLoc),
        WorkOrderService.layDanhSachNamCoKeHoach(),
      ]);
      danhSach = results[0] as List<HoSoBaoTri>;
      cacNamCoKeHoach = results[1] as List<int>;
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void datNamLoc(int? nam) {
    namLoc = nam;
    taiDanhSach();
  }


  List<HoSoBaoTri> locTheoTab(String tab) {
    if (tab == 'Tất cả') return danhSach;
    // Tab Chờ duyệt cũng gồm hồ sơ cũ còn gắn nhãn "Chờ xưởng"
    if (tab == 'Chờ duyệt') {
      return danhSach
          .where((h) =>
      h.trangThai == 'Chờ duyệt' ||
          h.trangThai == 'Chờ xưởng' ||
          h.trangThai == 'Chờ GĐ duyệt')
          .toList();
    }
    return danhSach.where((h) => h.trangThai == tab).toList();
  }
}