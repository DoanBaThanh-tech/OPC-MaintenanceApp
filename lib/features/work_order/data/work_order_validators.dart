import 'package:flutter/material.dart' show TimeOfDay;

/// Kết quả validate thời gian dự kiến (giờ hoặc phút).
class KetQuaValidateThoiGian {
  final int? soGio;
  final int? soPhut;
  final String? loi;
  final bool laPhut;

  const KetQuaValidateThoiGian({
    this.soGio,
    this.soPhut,
    this.loi,
    this.laPhut = false,
  });

  bool get hopLe =>
      loi == null &&
          ((laPhut && soPhut != null && soPhut! > 0) ||
              (!laPhut && soGio != null && soGio! > 0));

  /// Tổng phút để cộng vào giờ bắt đầu.
  int get tongPhut {
    if (laPhut) return soPhut ?? 0;
    return (soGio ?? 0) * 60;
  }

  /// Chuỗi lưu API: giờ = "4", phút = "15p"
  String get chuoiLuu {
    if (laPhut) return '${soPhut}p';
    return '${soGio}';
  }
}

/// @deprecated alias — giữ tương thích code cũ (chỉ giờ).
class KetQuaValidateSoGio {
  final int? soGio;
  final String? loi;
  const KetQuaValidateSoGio({this.soGio, this.loi});
  bool get hopLe => loi == null && soGio != null && soGio! > 0 && soGio! <= 24;
}

/// Số nguyên dương 1–24 giờ (tương thích cũ).
KetQuaValidateSoGio validateSoGioDuKien(String raw) {
  final kq = validateThoiGianDuKien(raw, laPhut: false);
  if (kq.loi != null) return KetQuaValidateSoGio(loi: kq.loi);
  return KetQuaValidateSoGio(soGio: kq.soGio);
}

/// Số phút còn lại trong ngày kể từ [gioBatDau] đến 24:00.
/// Nếu chưa chọn giờ bắt đầu → tối đa cả ngày (1440 phút).
int maxPhutConLaiTrongNgay(TimeOfDay? gioBatDau) {
  if (gioBatDau == null) return 24 * 60;
  final daQua = gioBatDau.hour * 60 + gioBatDau.minute;
  final con = 24 * 60 - daQua;
  return con > 0 ? con : 0;
}

/// Validate giờ (1–24) hoặc phút (1–max trong ngày).
/// Chỉ số nguyên dương, không ký tự đặc biệt.
/// [gioBatDau]: nếu có → không cho thời lượng tràn sang ngày hôm sau.
KetQuaValidateThoiGian validateThoiGianDuKien(
    String raw, {
      required bool laPhut,
      TimeOfDay? gioBatDau,
    }) {
  final v = raw.trim();
  var text = v;
  var phut = laPhut;
  if (v.toLowerCase().endsWith('p') ||
      v.toLowerCase().contains('phút') ||
      v.toLowerCase().contains('phut')) {
    phut = true;
    text = v
        .toLowerCase()
        .replaceAll('phút', '')
        .replaceAll('phut', '')
        .replaceAll('p', '')
        .trim();
  }

  if (text.isEmpty) {
    return KetQuaValidateThoiGian(
      loi: phut
          ? 'Vui lòng nhập số phút dự kiến'
          : 'Vui lòng nhập số giờ dự kiến',
      laPhut: phut,
    );
  }
  if (!RegExp(r'^\d+$').hasMatch(text)) {
    return KetQuaValidateThoiGian(
      loi:
      'Chỉ được nhập số nguyên dương (không chữ, không ký tự đặc biệt, không thập phân)',
      laPhut: phut,
    );
  }
  final so = int.tryParse(text);
  if (so == null || so <= 0) {
    return KetQuaValidateThoiGian(
      loi: phut
          ? 'Số phút phải là số nguyên dương lớn hơn 0'
          : 'Số giờ phải là số nguyên dương lớn hơn 0',
      laPhut: phut,
    );
  }

  final maxPhut = maxPhutConLaiTrongNgay(gioBatDau);
  final tongPhut = phut ? so : so * 60;

  if (tongPhut > maxPhut) {
    if (gioBatDau != null) {
      final h = gioBatDau.hour.toString().padLeft(2, '0');
      final m = gioBatDau.minute.toString().padLeft(2, '0');
      return KetQuaValidateThoiGian(
        loi: phut
            ? 'Từ $h:$m chỉ còn tối đa $maxPhut phút trong ngày (không tràn sang ngày sau)'
            : 'Từ $h:$m chỉ còn tối đa ${(maxPhut / 60).floor()} giờ ${maxPhut % 60} phút trong ngày',
        laPhut: phut,
      );
    }
    return KetQuaValidateThoiGian(
      loi: phut
          ? 'Thời gian dự kiến tối đa 1 ngày (1440 phút)'
          : 'Trong ngày — tối đa 24 giờ',
      laPhut: phut,
    );
  }

  if (phut) {
    return KetQuaValidateThoiGian(soPhut: so, laPhut: true);
  }
  return KetQuaValidateThoiGian(soGio: so, laPhut: false);
}

String? formValidateSoGioDuKien(String? v) {
  final kq = validateSoGioDuKien(v ?? '');
  return kq.loi;
}

String? formValidateThoiGianDuKien(
    String? v, {
      required bool laPhut,
      TimeOfDay? gioBatDau,
    }) {
  return validateThoiGianDuKien(
    v ?? '',
    laPhut: laPhut,
    gioBatDau: gioBatDau,
  ).loi;
}

/// Parse chuỗi đã lưu ("4" | "15p") → tổng phút.
int? parseThoiGianDuKienSangPhut(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final kq = validateThoiGianDuKien(raw.trim(), laPhut: false);
  if (!kq.hopLe) return null;
  return kq.tongPhut;
}

/// Hiển thị đẹp: "4" → "4 giờ", "15p" → "15 phút"
String formatThoiGianDuKienHienThi(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '—';
  final kq = validateThoiGianDuKien(raw.trim(), laPhut: false);
  if (!kq.hopLe) return raw.trim();
  if (kq.laPhut) return '${kq.soPhut} phút';
  return '${kq.soGio} giờ';
}

/// Tính giờ kết thúc; null nếu tràn sang ngày hôm sau.
TimeOfDay? tinhGioKetThuc({
  required TimeOfDay gioBatDau,
  required int tongPhut,
}) {
  if (tongPhut <= 0) return null;
  final start = gioBatDau.hour * 60 + gioBatDau.minute;
  final end = start + tongPhut;
  if (end > 24 * 60) return null; // tràn ngày
  if (end == 24 * 60) {
    // 24:00 hiển thị 23:59 cho TimeOfDay
    return const TimeOfDay(hour: 23, minute: 59);
  }
  return TimeOfDay(hour: end ~/ 60, minute: end % 60);
}