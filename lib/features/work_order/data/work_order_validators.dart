class KetQuaValidateSoGio {
  final int? soGio;
  final String? loi;
  const KetQuaValidateSoGio({this.soGio, this.loi});
  bool get hopLe => loi == null && soGio != null && soGio! > 0 && soGio! <= 24;
}

/// Số nguyên dương 1–24, không chữ / ký tự đặc biệt / thập phân.
KetQuaValidateSoGio validateSoGioDuKien(String raw) {
  final v = raw.trim();
  if (v.isEmpty) {
    return const KetQuaValidateSoGio(loi: 'Vui lòng nhập số giờ dự kiến');
  }
  if (!RegExp(r'^\d+$').hasMatch(v)) {
    return const KetQuaValidateSoGio(
      loi:
      'Chỉ được nhập số nguyên (không chữ, không ký tự đặc biệt, không số thập phân)',
    );
  }
  final so = int.tryParse(v);
  if (so == null || so <= 0) {
    return const KetQuaValidateSoGio(
      loi: 'Số giờ dự kiến phải là số nguyên dương lớn hơn 0',
    );
  }
  if (so > 24) {
    return const KetQuaValidateSoGio(
      loi: 'Bảo trì trong ngày — tối đa 24 giờ',
    );
  }
  return KetQuaValidateSoGio(soGio: so);
}

/// Validator cho TextFormField (trả về null nếu hợp lệ).
String? formValidateSoGioDuKien(String? v) {
  final kq = validateSoGioDuKien(v ?? '');
  return kq.loi;
}