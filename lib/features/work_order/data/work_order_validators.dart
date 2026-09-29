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

/// Validate giờ (1–24) hoặc phút (1–1440). Chỉ số nguyên dương, không ký tự đặc biệt.
KetQuaValidateThoiGian validateThoiGianDuKien(String raw, {required bool laPhut}) {
  final v = raw.trim();
  // Chuỗi API cũ: "15p" / "15P"
  var text = v;
  var phut = laPhut;
  if (v.toLowerCase().endsWith('p') || v.toLowerCase().endsWith('phút')) {
    phut = true;
    text = v.toLowerCase().replaceAll('phút', '').replaceAll('p', '').trim();
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
  if (phut) {
    if (so > 24 * 60) {
      return const KetQuaValidateThoiGian(
        loi: 'Thời gian dự kiến tối đa 24 giờ (1440 phút)',
        laPhut: true,
      );
    }
    return KetQuaValidateThoiGian(soPhut: so, laPhut: true);
  }
  if (so > 24) {
    return const KetQuaValidateThoiGian(
      loi: 'Trong ngày — tối đa 24 giờ',
      laPhut: false,
    );
  }
  return KetQuaValidateThoiGian(soGio: so, laPhut: false);
}

String? formValidateSoGioDuKien(String? v) {
  final kq = validateSoGioDuKien(v ?? '');
  return kq.loi;
}

String? formValidateThoiGianDuKien(String? v, {required bool laPhut}) {
  return validateThoiGianDuKien(v ?? '', laPhut: laPhut).loi;
}

/// Parse chuỗi đã lưu ("4" | "15p") → tổng phút.
int? parseThoiGianDuKienSangPhut(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final kq = validateThoiGianDuKien(raw.trim(), laPhut: false);
  if (!kq.hopLe) return null;
  return kq.tongPhut;
}