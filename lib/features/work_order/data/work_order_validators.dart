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

/// Validate giờ (1–24) hoặc phút (1–1440).
/// Chỉ số nguyên dương, không ký tự đặc biệt.
/// Trần tuyệt đối: giờ ≤ 24, phút ≤ 1440 — không bị giảm theo giờ bắt đầu.
/// [gioBatDau]: nếu có và bắt đầu + thời lượng > 24:00 → báo lỗi tổ hợp
/// (không đổi trần thuộc tính thời gian dự kiến).
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

  // Trần tuyệt đối thuộc tính: giờ ≤ 24, phút ≤ 1440
  if (phut) {
    if (so > 1440) {
      return const KetQuaValidateThoiGian(
        loi: 'Số phút không quá 1440 (tối đa 1 ngày). Chỉ nhập số nguyên dương.',
        laPhut: true,
      );
    }
  } else {
    if (so > 24) {
      return const KetQuaValidateThoiGian(
        loi: 'Số giờ không quá 24. Chỉ nhập số nguyên dương.',
        laPhut: false,
      );
    }
  }

  final tongPhut = phut ? so : so * 60;

  // Tổ hợp với giờ bắt đầu: không được tràn sang ngày hôm sau
  if (gioBatDau != null) {
    final maxPhut = maxPhutConLaiTrongNgay(gioBatDau);
    if (tongPhut > maxPhut) {
      final h = gioBatDau.hour.toString().padLeft(2, '0');
      final m = gioBatDau.minute.toString().padLeft(2, '0');
      return KetQuaValidateThoiGian(
        loi: phut
            ? 'Giờ bắt đầu $h:$m + $so phút vượt quá 24:00. '
            'Chọn giờ bắt đầu sớm hơn hoặc giảm số phút.'
            : 'Giờ bắt đầu $h:$m + $so giờ vượt quá 24:00. '
            'Chọn giờ bắt đầu sớm hơn hoặc giảm số giờ.',
        laPhut: phut,
      );
    }
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

// ─── Số lượng vật tư (NVKT quy trình) ───────────────────────────────

/// Kết quả validate số lượng vật tư.
class KetQuaValidateSoLuong {
  final int? soLuong;
  final String? loi;

  const KetQuaValidateSoLuong({this.soLuong, this.loi});

  bool get hopLe => loi == null && soLuong != null && soLuong! > 0;
}

/// Regex cho phép khi nhập: rỗng hoặc toàn chữ số (để gõ được "0" rồi hiện lỗi đỏ).
/// Thập phân / ký tự đặc biệt bị chặn ở inputFormatters (digitsOnly).
final RegExp soLuongVatTuChoPhepNhap = RegExp(r'^\d*$');

/// Số lượng vật tư: số nguyên dương (> 0), không 0, không thập phân, không ký tự đặc biệt.
///
/// [tenVatTu]: tên để gắn vào thông báo (tuỳ chọn).
/// [choPhepRong]: true → chuỗi rỗng không báo lỗi (đang gõ); false → bắt buộc khi gửi/cập nhật.
KetQuaValidateSoLuong validateSoLuongVatTu(
    String raw, {
      String? tenVatTu,
      bool choPhepRong = false,
    }) {
  final t = raw.trim();
  final nhan = (tenVatTu != null && tenVatTu.trim().isNotEmpty)
      ? '«${tenVatTu.trim()}»'
      : '';

  if (t.isEmpty) {
    if (choPhepRong) return const KetQuaValidateSoLuong();
    return KetQuaValidateSoLuong(
      loi: 'Vui lòng nhập số lượng vật tư${nhan.isEmpty ? '' : ' $nhan'}',
    );
  }

  // Chặn thập phân / dấu âm / ký tự đặc biệt
  if (t.contains('.') ||
      t.contains(',') ||
      t.contains('-') ||
      t.contains(' ') ||
      !RegExp(r'^\d+$').hasMatch(t)) {
    return KetQuaValidateSoLuong(
      loi:
      'Số lượng${nhan.isEmpty ? '' : ' $nhan'} phải là số nguyên (không thập phân, không ký tự đặc biệt)',
    );
  }

  final n = int.tryParse(t);
  if (n == null) {
    return KetQuaValidateSoLuong(
      loi: 'Số lượng${nhan.isEmpty ? '' : ' $nhan'} không hợp lệ',
    );
  }
  // 0 hoặc số âm (không xảy ra với digitsOnly) → lỗi đỏ
  if (n <= 0) {
    return KetQuaValidateSoLuong(
      loi: 'Số lượng${nhan.isEmpty ? '' : ' $nhan'} phải lớn hơn 0',
    );
  }
  return KetQuaValidateSoLuong(soLuong: n);
}

/// Form field helper — trả về chuỗi lỗi hoặc null (hợp lệ / đang để trống khi [choPhepRong]).
String? formValidateSoLuongVatTu(
    String? value, {
      String? tenVatTu,
      bool choPhepRong = true,
    }) {
  return validateSoLuongVatTu(
    value ?? '',
    tenVatTu: tenVatTu,
    choPhepRong: choPhepRong,
  ).loi;
}