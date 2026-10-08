part of quy_trinh_nvkt_screen;

/// Chọn vật tư và hoàn thành gửi Xưởng.
mixin _XuLyVatTuVaHoanThanhNvkt on _QuyTrinhNvktScreenStateBase, _XuLyQuyTrinhNvkt {

  Future<void> _themVatTu(int buocIdx) async {
    final b = _buoc[buocIdx];
    if (!_coTheSuaVatTu(b)) return;
    final daChon = b.vatTu
        .map((e) => e.maVatTu)
        .whereType<int>()
        .toSet();
    final listVt = await _chonNhieuVatTu(excludeMa: daChon, daChonMa: daChon);
    if (listVt == null || listVt.isEmpty) return;
    setState(() {
      for (final vt in listVt) {
        b.vatTu.add(_VatTuDongState(
          maVatTu: vt.maVatTu,
          tenVatTu: vt.tenVatTu,
          soLuong: 1,
          donGia: vt.donGia,
        ));
      }
    });
    await _luuNhapBuoc(b);
  }


  /// Chọn nhiều vật tư một lúc; vật tư đã chọn trong bước hiện badge «Đã chọn».
  Future<List<VatTuOption>?> _chonNhieuVatTu({
    Set<int> excludeMa = const {},
    Set<int> daChonMa = const {},
  }) async {
    if (_dsVatTu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có danh sách vật tư')),
      );
      return null;
    }
    final selected = <int>{};
    return showModalBottomSheet<List<VatTuOption>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final filter = TextEditingController();
        var list = List<VatTuOption>.from(_dsVatTu);
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              height: MediaQuery.sizeOf(ctx).height * 0.78,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Chọn nhiều vật tư',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: filter,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc mã…',
                        prefixIcon: const Icon(Icons.search_rounded, color: _blue),
                        filled: true,
                        fillColor: const Color(0xFFF0F9FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        final q = v.trim().toLowerCase();
                        setModal(() {
                          list = _dsVatTu
                              .where((e) =>
                          e.tenVatTu.toLowerCase().contains(q) ||
                              e.maVatTu.toString().contains(q))
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[i];
                        final daCo = daChonMa.contains(e.maVatTu);
                        final dangChon = selected.contains(e.maVatTu);
                        return CheckboxListTile(
                          value: dangChon || daCo,
                          onChanged: daCo
                              ? null
                              : (v) {
                            setModal(() {
                              if (v == true) {
                                selected.add(e.maVatTu);
                              } else {
                                selected.remove(e.maVatTu);
                              }
                            });
                          },
                          title: Text(e.tenVatTu,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            daCo
                                ? 'Đã chọn trong bước này — chỉnh số lượng trên dòng có sẵn'
                                : 'Mã ${e.maVatTu}',
                            style: TextStyle(
                              fontSize: 12,
                              color: daCo ? Colors.orange.shade800 : Colors.grey.shade600,
                            ),
                          ),
                          secondary: daCo
                              ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Đã chọn',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: Colors.orange)),
                          )
                              : null,
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: selected.isEmpty
                            ? null
                            : () {
                          final out = _dsVatTu
                              .where((e) => selected.contains(e.maVatTu))
                              .toList();
                          Navigator.pop(ctx, out);
                        },
                        child: Text(
                          selected.isEmpty
                              ? 'Chọn ít nhất 1 vật tư'
                              : 'Thêm ${selected.length} vật tư',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<VatTuOption?> _chonVatTu({Set<int> excludeMa = const {}}) async {
    if (_dsVatTu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có danh sách vật tư')),
      );
      return null;
    }
    final conLai = _dsVatTu.where((e) => !excludeMa.contains(e.maVatTu)).toList();
    if (conLai.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã chọn hết vật tư trong bước này. '
                'Tăng số lượng trên dòng đã có, hoặc chuyển bước khác để chọn lại.',
          ),
        ),
      );
      return null;
    }
    return showModalBottomSheet<VatTuOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final filter = TextEditingController();
        var list = List<VatTuOption>.from(conLai);
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              height: MediaQuery.sizeOf(ctx).height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_blue, _blueSoft],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.inventory_2_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chọn vật tư',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              if (excludeMa.isNotEmpty)
                                Text(
                                  'Đã ẩn ${excludeMa.length} vật tư đã chọn trong bước này — chỉnh số lượng trên dòng có sẵn',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade600,
                                    height: 1.25,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: filter,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc mã…',
                        prefixIcon:
                        const Icon(Icons.search_rounded, color: _blue),
                        filled: true,
                        fillColor: const Color(0xFFF0F9FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        final q = v.trim().toLowerCase();
                        setModal(() {
                          list = conLai
                              .where((e) =>
                          e.tenVatTu.toLowerCase().contains(q) ||
                              e.maVatTu.toString().contains(q))
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Không còn vật tư phù hợp.\n'
                              'Tăng số lượng trên dòng đã chọn trong bước này.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, height: 1.35),
                        ),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[i];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration:
                          Duration(milliseconds: 220 + (i % 8) * 30),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, child) => Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - t)),
                              child: child,
                            ),
                          ),
                          child: Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side:
                              BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor:
                                _blue.withValues(alpha: 0.12),
                                child: Text(
                                  '${e.maVatTu}',
                                  style: const TextStyle(
                                      color: _blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              title: Text(e.tenVatTu,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                'Đơn giá: ${_fmtTien(e.donGia)}'
                                    '${e.donViTinh != null ? ' · ${e.donViTinh}' : ''}',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12.5),
                              ),
                              trailing: const Icon(
                                  Icons.add_circle_rounded,
                                  color: _blue),
                              onTap: () => Navigator.pop(ctx, e),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _fmtTien(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf ₫';
  }

  /// Tổng tiền mọi vật tư đã chọn trên các bước (logic file).
  int _tinhTongTien() {
    final dong = <({int soLuong, int donGia})>[];
    for (final b in _buoc) {
      for (final d in b.vatTu) {
        final sl = int.tryParse(d.slCtrl.text.trim()) ?? d.soLuong;
        dong.add((soLuong: sl, donGia: d.donGia));
      }
    }
    return QuyTrinhNvktRules.tongTienVatTu(dong);
  }

  Future<void> _xong() async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;

    // Chỉ gửi các bước đã tích chọn và đã bấm Xong (không bắt buộc đủ mọi bước)
    // Chỉ ghi nhận bước đã bấm Xong (+ vật tư). Tích mà chưa Xong → không hợp lệ.
    final buocGui = _buoc.where((b) => b.daChon && b.daXong).toList();
    final chiTichChuaXong =
    _buoc.where((b) => b.daChon && !b.daXong).map((b) => b.soBuoc).toList();
    if (buocGui.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            chiTichChuaXong.isNotEmpty
                ? 'Bước ${chiTichChuaXong.join(", ")} đã tích nhưng chưa bấm Xong — không được ghi nhận. Hãy Xong ít nhất 1 bước có vật tư.'
                : 'Hãy tích chọn ít nhất 1 bước, chọn vật tư, bấm Xong từng bước rồi hoàn thành quy trình.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    for (final b in buocGui) {
      for (final d in b.vatTu) {
        final kq = validateSoLuongVatTu(
          d.slCtrl.text,
          tenVatTu: d.tenVatTu,
          choPhepRong: false,
        );
        if (!kq.hopLe) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(kq.loi ?? 'Số lượng không hợp lệ'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
        d.soLuong = kq.soLuong!;
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_cheDoCapNhat ? const Color(0xFF059669) : AppColors.success)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.send_rounded,
                color: _cheDoCapNhat
                    ? const Color(0xFF059669)
                    : AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _cheDoCapNhat
                    ? 'Bạn có cần chỉnh sửa gì nữa không'
                    : 'Hoàn thành quy trình?',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          _cheDoCapNhat
              ? 'Nếu đã chỉnh xong, bấm «Gửi xưởng» để gửi lại quy trình. Bấm «Hủy» để ở lại chỉnh tiếp.'
              : 'Gửi ${buocGui.length} bước đã hoàn thành (kèm vật tư) về Xưởng xác nhận. Không bắt buộc làm đủ mọi bước.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          if (_cheDoCapNhat) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 1.4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Hủy',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Gửi xưởng',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hoàn thành quy trình'),
            ),
          ],
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _dangXuLy = true);
    try {
      final buocApi = <BuocQuyTrinh>[];
      final buffer = StringBuffer();
      for (final b in buocGui) {
        final moTa = b.moTaCtrl.text.trim().isEmpty
            ? 'Bước ${b.soBuoc}'
            : b.moTaCtrl.text.trim();
        final buoc = BuocQuyTrinh(soBuoc: b.soBuoc, moTa: moTa);
        for (final d in b.vatTu) {
          if (d.tenVatTu.isEmpty || d.soLuong <= 0) continue;
          buoc.vatTuList.add(VatTuDong(
            maVatTu: d.maVatTu,
            tenVatTu: d.tenVatTu,
            soLuong: d.soLuong,
            donGia: d.donGia,
          ));
        }
        buocApi.add(buoc);
        buffer.writeln('Bước ${b.soBuoc}: $moTa');
        for (final d in buoc.vatTuList) {
          buffer.writeln('  - ${d.tenVatTu} x ${d.soLuong}');
        }
      }
      final noiDung = _noiDungCtrl.text.trim();
      if (noiDung.isNotEmpty) {
        buffer.writeln('Nội dung công việc: $noiDung');
      }

      final coVatTu = buocApi
          .any((b) => b.vatTuList.any((d) => d.soLuong > 0 && d.tenVatTu.isNotEmpty));
      if (coVatTu) {
        if (_maHoSoVatTu != null) {
          await MaterialUsageService.capNhatHoSoVatTu(
            maHoSoVatTu: _maHoSoVatTu!,
            maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
            maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
            maThietBi: y.maThietBi ?? 0,
            tenThietBi: y.tenThietBi ?? '',
            loaiCongViec: _laBaoTri ? 'Bảo trì' : 'Sửa chữa',
            buoc: buocApi,
          );
        } else {
          final created = await MaterialUsageService.taoHoSoVatTu(
            maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
            maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
            maThietBi: y.maThietBi ?? 0,
            tenThietBi: y.tenThietBi ?? '',
            loaiCongViec: _laBaoTri ? 'Bảo trì' : 'Sửa chữa',
            buoc: buocApi,
          );
          _maHoSoVatTu = created?.maHoSoVatTu;
        }
      }

      if (y.maPhanCong != null) {
        try {
          await WorkOrderService.ghiNhanKetQua(
            maPhanCong: y.maPhanCong!,
            maNhanVienGhiNhan: 0,
            ghiChu: buffer.toString().trim(),
            soLieuGhiNhan:
            noiDung.isNotEmpty ? noiDung : buffer.toString().trim(),
          );
        } catch (_) {}
      }

      if (_laBaoTri) {
        await WorkOrderService.nhanVienHoanThanhBaoTri(y.maHoSo!);
      } else {
        await WorkOrderService.nhanVienHoanThanhSuaChua(y.maHoSo!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cheDoCapNhat
              ? 'Đã gửi lại — chờ Xưởng xác nhận'
              : 'Đã gửi — hồ sơ Chờ xác nhận (Xưởng)'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }


}