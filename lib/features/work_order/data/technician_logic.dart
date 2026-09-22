import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import 'models/work_order_models.dart';
import 'services/work_order_service.dart';

// Export để presentation chỉ cần import file logic này
export 'models/work_order_models.dart';
export 'services/work_order_service.dart';

// Logic cho technician_screens.dart (quản lý yêu cầu / kết quả thực hiện)

class QuanLyYeuCauController extends ChangeNotifier {
  List<YeuCauPhanCong> danhSach = [];
  bool dangTai = true;
  String? loi;
  String tabLoai = 'Bảo trì'; // Bảo trì | Sửa chữa

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      danhSach = await WorkOrderService.layYeuCauCuaToi(loai: tabLoai);
    } catch (e) {
      loi = 'Không tải được yêu cầu: $e';
      danhSach = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void doiTab(String loai) {
    if (tabLoai == loai) return;
    tabLoai = loai;
    tai();
  }

  List<YeuCauPhanCong> get choXacNhan =>
      danhSach.where((e) => e.choXacNhan).toList();
  List<YeuCauPhanCong> get khac =>
      danhSach.where((e) => !e.choXacNhan).toList();
}

class KetQuaThucHienController extends ChangeNotifier {
  List<YeuCauPhanCong> dsXacNhan = [];
  YeuCauPhanCong? chon;
  DateTime? ngayGhiNhan;
  String ghiChu = '';
  bool dangTai = true;
  bool dangLuu = false;
  String? loi;
  String? loiNgay; // chữ đỏ dưới ngày

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      dsXacNhan = await WorkOrderService.layYeuCauDaXacNhan();
    } catch (e) {
      loi = 'Không tải danh sách: $e';
      dsXacNhan = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void chonYeuCau(YeuCauPhanCong? y) {
    chon = y;
    loiNgay = null;
    loi = null;
    // Tự gán ngày ghi nhận = ngày dự kiến bảo trì theo hồ sơ (nếu có)
    if (y?.ngayDuKienBaoTri != null) {
      final dk = y!.ngayDuKienBaoTri!;
      ngayGhiNhan = DateTime(dk.year, dk.month, dk.day);
    } else {
      ngayGhiNhan = null;
    }
    notifyListeners();
  }

  void datNgayGhiNhan(DateTime d) {
    ngayGhiNhan = d;
    loiNgay = null;
    if (chon?.ngayDuKienBaoTri != null) {
      final dk = chon!.ngayDuKienBaoTri!;
      final ngayDk = DateTime(dk.year, dk.month, dk.day);
      final ngayChon = DateTime(d.year, d.month, d.day);
      // Không được chọn ngày/tháng trước ngày dự kiến bảo trì
      if (ngayChon.isBefore(ngayDk)) {
        loiNgay =
        'Ngày ghi nhận không được trước ngày dự kiến bảo trì (${ngayDk.day.toString().padLeft(2, '0')}/${ngayDk.month.toString().padLeft(2, '0')}/${ngayDk.year}).';
      } else if (d.year != dk.year || d.month != dk.month) {
        // Phải nằm đúng tháng/năm dự kiến bảo trì theo hồ sơ
        loiNgay =
        'Ngày ghi nhận phải nằm trong tháng ${dk.month}/${dk.year} (tháng dự kiến bảo trì theo hồ sơ).';
      }
    }
    notifyListeners();
  }

  Future<bool> xacNhanHoanThanh({required int maNhanVienGhiNhan}) async {
    if (chon == null) {
      loi = 'Vui lòng chọn hồ sơ bảo trì';
      notifyListeners();
      return false;
    }
    if (ngayGhiNhan == null) {
      loi = 'Vui lòng chọn ngày ghi nhận';
      notifyListeners();
      return false;
    }
    if (loiNgay != null) {
      loi = loiNgay;
      notifyListeners();
      return false;
    }

    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.ghiNhanKetQua(
        maPhanCong: chon!.maPhanCong,
        maNhanVienGhiNhan: maNhanVienGhiNhan,
        ghiChu: ghiChu.trim().isEmpty ? null : ghiChu.trim(),
        ngayGhiNhan: ngayGhiNhan,
        soLieuGhiNhan: 'Hoàn thành',
      );
      // Làm mới danh sách
      await tai();
      chon = null;
      ngayGhiNhan = null;
      ghiChu = '';
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } catch (e) {
      loi = '$e';
      return false;
    } finally {
      dangLuu = false;
      notifyListeners();
    }
  }
}