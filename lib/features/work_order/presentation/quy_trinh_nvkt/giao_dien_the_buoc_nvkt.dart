part of quy_trinh_nvkt_screen;

/// UI từng bước quy trình NVKT.
mixin _GiaoDienTheBuocNvkt on _QuyTrinhNvktScreenStateBase, _XuLyQuyTrinhNvkt, _XuLyVatTuVaHoanThanhNvkt {

  Widget _buildBuocCard(int index) {
    final b = _buoc[index];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: b.daXong
                ? const Color(0xFF6EE7B7)
                : b.daChon
                ? _blue.withValues(alpha: 0.45)
                : const Color(0xFFE0F2FE),
            width: b.daChon || b.daXong ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (b.daXong ? const Color(0xFF059669) : _blue)
                  .withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(21)),
                gradient: LinearGradient(
                  colors: b.daXong
                      ? [
                    const Color(0xFFD1FAE5),
                    const Color(0xFFECFDF5),
                  ]
                      : b.daChon
                      ? [
                    _blue.withValues(alpha: 0.14),
                    _blueSoft.withValues(alpha: 0.06),
                  ]
                      : [
                    const Color(0xFFF8FBFE),
                    Colors.white,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: b.daChon,
                    activeColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: !QuyTrinhNvktRules.coTheDoiCheckbox(
                      daXong: b.daXong,
                      khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
                      cheDoCapNhat: _cheDoCapNhat,
                      dangXuLy: _dangXuLy,
                      daLuuDieuChinh: b.daLuuDieuChinh,
                      dangMoCapNhat: b.dangMoCapNhat,
                    )
                        ? null
                        : (v) async {
                      // Chỉ tích chọn local — không claim DangLam (tránh khóa sớm).
                      // Khóa chỉ khi bấm Xong (DaXong trên server).
                      if (v == true) {
                        await _dongBoTienDo(silent: true);
                        if (b.khoaBoiNguoiKhac) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  QuyTrinhNvktRules.goiYChuaChonBuoc(
                                    khoaBoiNguoiKhac: true,
                                    daXong: true,
                                    tenNguoiGiu: b.tenNguoiGiu,
                                  ),
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                          return;
                        }
                        setState(() {
                          b.daChon = true;
                          b.moRong = true;
                          b.tenNguoiGiu = _tenToi;
                        });
                        // Lưu nháp ngay — back/văng app không mất tích chọn
                        await _luuNhapBuoc(b);
                      } else {
                        if (!QuyTrinhNvktRules.coTheBoTich(
                          daXong: b.daXong,
                          cheDoCapNhat: _cheDoCapNhat,
                          daLuuDieuChinh: b.daLuuDieuChinh,
                          dangMoCapNhat: b.dangMoCapNhat,
                        )) {
                          return;
                        }
                        final canBoServer = b.daXong || _cheDoCapNhat;
                        // Về trạng thái trắng ngay: bỏ tích + xóa VT + hết xanh
                        setState(() {
                          for (final v in b.vatTu) {
                            v.dispose();
                          }
                          b.vatTu.clear();
                          b.daChon = false;
                          b.daXong = false;
                          b.moRong = false;
                          b.dangMoCapNhat = false;
                          b.daLuuDieuChinh = false;
                          b.tenNguoiGiu = null;
                        });
                        // Lưu server ngay để back vào lại không còn tích
                        if (canBoServer) {
                          await _luuBoBuoc(b, silent: true);
                        } else {
                          await _luuNhapBuoc(b);
                        }
                      }
                    },
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: b.daXong
                            ? [AppColors.success, const Color(0xFF34D399)]
                            : const [_blue, _blueSoft],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: b.daXong
                        ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                        : Text(
                      '${b.soBuoc}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      QuyTrinhNvktRules.tieuDeBuoc(
                        soBuoc: b.soBuoc,
                        daXong: b.daXong,
                        dangLam: b.daChon && !b.daXong,
                        tenNguoiThucHien: b.tenNguoiGiu,
                      ),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                  if (b.vatTu.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${b.vatTu.length} VT',
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    b.moTaCtrl.text.trim().isEmpty
                        ? 'Bước ${b.soBuoc}'
                        : b.moTaCtrl.text.trim(),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (b.daChon) ...[
                    const SizedBox(height: 12),
                    ...List.generate(b.vatTu.length, (j) {
                      final d = b.vatTu[j];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.inventory_2_rounded,
                                    size: 18, color: _blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    d.tenVatTu,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 13.5),
                                  ),
                                ),
                                if (_coTheSuaVatTu(b))
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () async {
                                      setState(() {
                                        d.dispose();
                                        b.vatTu.removeAt(j);
                                      });
                                      await _luuNhapBuoc(b);
                                    },
                                    icon:
                                    const Icon(Icons.close_rounded, size: 18),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: d.slCtrl,
                                    enabled: _coTheSuaVatTu(b),
                                    readOnly: !_coTheSuaVatTu(b),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      FilteringTextInputFormatter.allow(
                                        soLuongVatTuChoPhepNhap,
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Số lượng',
                                      hintText: 'Số nguyên > 0',
                                      errorText: _coTheSuaVatTu(b)
                                          ? formValidateSoLuongVatTu(
                                        d.slCtrl.text,
                                        tenVatTu: d.tenVatTu,
                                        choPhepRong: true,
                                      )
                                          : null,
                                      isDense: true,
                                      filled: true,
                                      fillColor: _coTheSuaVatTu(b)
                                          ? Colors.white
                                          : const Color(0xFFF1F5F9),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                    ),
                                    onChanged: !_coTheSuaVatTu(b)
                                        ? null
                                        : (v) {
                                      final kq = validateSoLuongVatTu(
                                        v,
                                        tenVatTu: d.tenVatTu,
                                        choPhepRong: true,
                                      );
                                      d.soLuong = kq.soLuong ?? 0;
                                      setState(() {});
                                      // Lưu nháp số lượng
                                      _luuNhapBuoc(b);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Đơn giá',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                    ),
                                    child: Text(
                                      _fmtTien(d.donGia),
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_coTheSuaVatTu(b))
                      TextButton.icon(
                        onPressed: () => _themVatTu(index),
                        icon: const Icon(Icons.add_box_outlined,
                            size: 20, color: _blue),
                        label: const Text(
                          'Thêm vật tư',
                          style: TextStyle(
                              color: _blue, fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (QuyTrinhNvktRules.ghiChuBuocDaXong(
                      daXong: b.daXong,
                      khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
                      cheDoCapNhat: _cheDoCapNhat,
                      tenNguoiGiu: b.tenNguoiGiu,
                    ) !=
                        null) ...[
                      const SizedBox(height: 6),
                      Text(
                        QuyTrinhNvktRules.ghiChuBuocDaXong(
                          daXong: b.daXong,
                          khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
                          cheDoCapNhat: _cheDoCapNhat,
                          tenNguoiGiu: b.tenNguoiGiu,
                        )!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (!b.khoaBoiNguoiKhac)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: !QuyTrinhNvktRules.coTheBamXong(
                            daXong: b.daXong,
                            khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
                            cheDoCapNhat: _cheDoCapNhat,
                            dangXuLy: _dangXuLy,
                            daLuuDieuChinh: b.daLuuDieuChinh,
                          )
                              ? null
                              : () {
                            // Đã Xong + chưa mở → mở khóa (Cập nhật) — cả sau từ chối
                            if (b.daXong && !b.dangMoCapNhat) {
                              setState(() {
                                b.dangMoCapNhat = true;
                                b.moRong = true;
                                b.daLuuDieuChinh = false;
                              });
                              return;
                            }
                            // Đang mở cập nhật + đã bỏ tích → hủy bước về trạng thái ban đầu
                            if (b.dangMoCapNhat && !b.daChon) {
                              _luuBoBuoc(b);
                              return;
                            }
                            // Xong lần đầu hoặc Lưu cập nhật
                            _luuBuocDaXong(b);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: b.dangMoCapNhat
                                ? const Color(0xFF059669)
                                : b.daXong
                                ? const Color(0xFF0284C7)
                                : _blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            b.dangMoCapNhat
                                ? Icons.save_rounded
                                : b.daXong
                                ? Icons.edit_rounded
                                : Icons.done_all_rounded,
                            size: 18,
                          ),
                          label: Text(
                            QuyTrinhNvktRules.nhanNutXong(
                              daXong: b.daXong,
                              cheDoCapNhat: _cheDoCapNhat,
                              daLuuDieuChinh: b.daLuuDieuChinh,
                              dangMoCapNhat: b.dangMoCapNhat,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        QuyTrinhNvktRules.goiYChuaChonBuoc(
                          khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
                          daXong: b.daXong,
                          tenNguoiGiu: b.tenNguoiGiu,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}