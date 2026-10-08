part of work_order_detail_screen;

/// Tải quy trình / chỉnh sửa Xưởng / gửi xưởng trên chi tiết BT.
extension _ChiTietBaoTriXuLy on _WorkOrderBaoTriDetailScreenState {
  Future<void> _taiQuyTrinhVatTu([HoSoBaoTri? hsHint]) async {
    setState(() {
      _dangTaiQuyTrinh = true;
      _loiQuyTrinh = null;
    });
    try {
      final hs = hsHint ?? _controller.hoSo;
      final maTb = hs?.maThietBi ?? 0;
      final results = await Future.wait([
        MaterialUsageService.layHoSoTheoCongViec(
          maHoSoBaoTri: widget.maHoSoBaoTri,
        ),
        WorkOrderService.layTienDoBuoc(maHoSoBaoTri: widget.maHoSoBaoTri),
        maTb > 0
            ? MaterialUsageService.layQuyTrinhThietBi(
          maThietBi: maTb,
          loaiCongViec: 'Bảo trì',
        )
            : Future.value(<BuocQuyTrinh>[]),
      ]);
      final hsVt = results[0] as HoSoVatTuItem?;
      final tienDo = results[1] as List<Map<String, dynamic>>;
      final mau = results[2] as List<BuocQuyTrinh>;

      final vtTheoBuoc = <int, List<ChiTietVatTuSuDung>>{};
      if (hsVt != null) {
        for (final c in hsVt.chiTiet) {
          vtTheoBuoc.putIfAbsent(c.soBuoc, () => []).add(c);
        }
      }
      final tdTheoBuoc = <int, Map<String, dynamic>>{};
      for (final row in tienDo) {
        final so = (row['soBuoc'] as num?)?.toInt() ??
            (row['SoBuoc'] as num?)?.toInt();
        if (so == null) continue;
        tdTheoBuoc[so] = row;
      }

      final soBuocSet = <int>{};
      for (final b in mau) {
        soBuocSet.add(b.soBuoc);
      }
      soBuocSet.addAll(tdTheoBuoc.keys);
      soBuocSet.addAll(vtTheoBuoc.keys);
      final sorted = soBuocSet.toList()..sort();

      final views = <_BuocQtDetailView>[];
      for (final so in sorted) {
        String? mauB;
        for (final e in mau) {
          if (e.soBuoc == so) {
            mauB = e.moTa;
            break;
          }
        }
        final td = tdTheoBuoc[so];
        final moTaTd = (td?['moTaBuoc'] ?? td?['MoTaBuoc'])?.toString();
        final tt = (td?['trangThai'] ?? td?['TrangThai'])?.toString() ?? '';
        final tenNv = (td?['tenNhanVien'] ?? td?['TenNhanVien'])?.toString();
        final moTaVt = vtTheoBuoc[so]
            ?.map((e) => e.moTaBuoc.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .join(' · ');
        final daThucHien = tt == 'DaXong' ||
            tt == 'DaCapNhat' ||
            (vtTheoBuoc[so]?.any((c) => c.soLuong > 0) ?? false);
        final daChon = daThucHien ||
            tt == 'DangLam' ||
            tt == 'DuocChon' ||
            vtTheoBuoc.containsKey(so);
        views.add(_BuocQtDetailView(
          soBuoc: so,
          moTa: (moTaTd != null && moTaTd.isNotEmpty)
              ? moTaTd
              : (moTaVt != null && moTaVt.isNotEmpty)
              ? moTaVt
              : (mauB ?? 'Bước $so'),
          trangThai: tt,
          tenNhanVien: tenNv,
          daThucHien: daThucHien,
          daChon: daChon,
          vatTu: vtTheoBuoc[so] ?? const [],
        ));
      }

      if (!mounted) return;
      setState(() {
        _hoSoVatTu = hsVt;
        _dsBuocFull = views;
        _dangTaiQuyTrinh = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loiQuyTrinh = e is ApiException ? e.message : '$e';
        _dangTaiQuyTrinh = false;
      });
    }
  }

  @override

  String? _fmtGio(TimeOfDay? t) => _xuongCtrl.fmtGio(t);

  void _onThoiGianXuongChanged(String v) {
    _xuongCtrl.datThoiGianTuChuoi(v);
  }

  Future<void> _batDauChinhSuaXuong(HoSoBaoTri hs) async {
    _noiDungXuongCtrl.text = hs.noiDungCongViec ?? '';
    // Giữ chuỗi gốc ("15p" / "4") để nhận đúng đơn vị phút/giờ
    final raw = (hs.thoiGianDuKien ?? '').trim();
    final chiSo = raw.replaceAll(RegExp(r'[^0-9]'), '');
    _thoiGianXuongCtrl.text = chiSo;
    await _xuongCtrl.batDauChinhSua(hs, thoiGianText: raw.isEmpty ? chiSo : raw);
  }

  void _huyChinhSuaXuong() {
    _xuongCtrl.huyChinhSua();
  }

  Future<void> _luuChinhSuaXuong(HoSoBaoTri hs) async {
    final ok = await _xuongCtrl.luu(
      maHoSoBaoTri: hs.maHoSoBaoTri,
      noiDungCongViec: _noiDungXuongCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu chỉnh sửa.')),
      );
      await _controller.taiChiTiet();
      setState(() {});
    } else if (_xuongCtrl.loi != null) {
      // Thông báo đỏ — không cho lưu khi sai nghiệp vụ (đổi sang tháng khác, …)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_xuongCtrl.loi!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

}