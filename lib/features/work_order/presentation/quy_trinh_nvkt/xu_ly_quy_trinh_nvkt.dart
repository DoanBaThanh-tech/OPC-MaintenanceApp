part of quy_trinh_nvkt_screen;

/// Tải dữ liệu, đồng bộ tiến độ, claim/lưu bước.
mixin _XuLyQuyTrinhNvkt on _QuyTrinhNvktScreenStateBase {

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      _tenToi = await TokenStorage.getHoTen();
      final y = widget.yeuCau;
      final results = await Future.wait([
        MaterialUsageService.layDanhSachVatTu(),
        if (y.maHoSo != null)
          MaterialUsageService.layHoSoTheoCongViec(
            maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
            maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
          )
        else
          Future.value(null),
      ]);
      if (!mounted) return;
      _dsVatTu = results[0] as List<VatTuOption>;
      final hoSoCu = results[1] as HoSoVatTuItem?;

      for (final b in _buoc) {
        b.dispose();
      }
      _buoc.clear();

      // Mô tả đã chỉnh lúc tạo HS (xưởng/tổ trưởng) — không dùng lại mẫu mặc định
      final moTaTuHoSo = <int, String>{};
      if (y.maHoSo != null) {
        try {
          if (_laBaoTri) {
            final hs =
            await WorkOrderService.layChiTietHoSoBaoTri(y.maHoSo!);
            for (final b in hs.danhSachBuocQuyTrinh) {
              if (b.moTaBuoc.trim().isNotEmpty) {
                moTaTuHoSo[b.soBuoc] = b.moTaBuoc.trim();
              }
            }
          } else {
            final hs =
            await WorkOrderService.layChiTietHoSoSuaChua(y.maHoSo!);
            for (final b in hs.danhSachBuocQuyTrinh) {
              if (b.moTaBuoc.trim().isNotEmpty) {
                moTaTuHoSo[b.soBuoc] = b.moTaBuoc.trim();
              }
            }
          }
        } catch (_) {
          // Không chặn tải quy trình nếu chi tiết HS lỗi
        }
      }

      // Nạp mẫu thiết bị, ưu tiên mô tả từ hồ sơ đã chỉnh
      final maTb = y.maThietBi ?? 0;
      if (maTb > 0) {
        final loai = _laBaoTri ? 'Bảo trì' : 'Sửa chữa';
        final mau = await MaterialUsageService.layQuyTrinhThietBi(
          maThietBi: maTb,
          loaiCongViec: loai,
        );
        for (final b in mau) {
          final moTa = QuyTrinhNvktRules.moTaUuTien(
            moTaHoSo: moTaTuHoSo[b.soBuoc],
            moTaMau: b.moTa,
            soBuoc: b.soBuoc,
          );
          _buoc.add(_BuocState(soBuoc: b.soBuoc, moTa: moTa));
        }
      }
      // HS có bước ngoài mẫu → bổ sung
      for (final e in moTaTuHoSo.entries) {
        final daCo = _buoc.any((b) => b.soBuoc == e.key);
        if (!daCo) {
          _buoc.add(_BuocState(soBuoc: e.key, moTa: e.value));
        }
      }
      _buoc.sort((a, b) => a.soBuoc.compareTo(b.soBuoc));

      // Hồ sơ vật tư đã gửi — chỉ khôi phục khi quy trình mới.
      // Trang cập nhật sau từ chối: chỉ lấy từ tiến độ DaXong/DaCapNhat (tránh bước chỉ tích nháp).
      if (!_cheDoCapNhat && hoSoCu != null && hoSoCu.chiTiet.isNotEmpty) {
        _maHoSoVatTu = hoSoCu.maHoSoVatTu;
        final byBuoc = <int, List<ChiTietVatTuSuDung>>{};
        for (final c in hoSoCu.chiTiet) {
          byBuoc.putIfAbsent(c.soBuoc, () => []).add(c);
        }
        for (final b in _buoc) {
          final dong = byBuoc[b.soBuoc];
          if (dong == null || dong.isEmpty) continue;
          b.daChon = true;
          b.daXong = true;
          b.moRong = false;
          if (dong.first.moTaBuoc.isNotEmpty) {
            b.moTaCtrl.text = dong.first.moTaBuoc;
          }
          for (final c in dong) {
            if (c.tenVatTu.isEmpty || c.soLuong <= 0) continue;
            b.vatTu.add(_VatTuDongState(
              maVatTu: c.maVatTu,
              tenVatTu: c.tenVatTu,
              soLuong: c.soLuong,
              donGia: c.donGia,
            ));
          }
        }
      } else if (_cheDoCapNhat && hoSoCu != null) {
        _maHoSoVatTu = hoSoCu.maHoSoVatTu;
      }

      // Tiến độ bước đã lưu (back app / crash) + khóa bước người khác
      await _dongBoTienDo(silent: true);

      if (_buoc.isEmpty) {
        _loi = 'Chưa có quy trình ${_laBaoTri ? "bảo trì" : "sửa chữa"} '
            'cho thiết bị này trong hệ thống.';
      }
    } catch (e) {
      _loi = e is ApiException ? e.message : '$e';
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  /// Đồng bộ tiến độ từ server (lưu bước + khóa realtime).
  Future<void> _dongBoTienDo({bool silent = false}) async {
    final y = widget.yeuCau;
    if (y.maHoSo == null || _buoc.isEmpty) return;
    try {
      final list = await WorkOrderService.layTienDoBuoc(
        maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
        maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
      );
      if (!mounted) return;
      final tenToi = (_tenToi ?? '').trim().toLowerCase();
      for (final row in list) {
        final soBuocRaw = row['soBuoc'] ?? row['SoBuoc'];
        final soBuoc = soBuocRaw is num
            ? soBuocRaw.toInt()
            : int.tryParse('$soBuocRaw');
        if (soBuoc == null) continue;
        _BuocState? b;
        for (final x in _buoc) {
          if (x.soBuoc == soBuoc) {
            b = x;
            break;
          }
        }
        if (b == null) continue;
        final tenNv =
            (row['tenNhanVien'] ?? row['TenNhanVien'])?.toString() ?? '';
        final tt = (row['trangThai'] ?? row['TrangThai'])?.toString() ?? '';
        final laCuaToi =
            tenToi.isNotEmpty && tenNv.trim().toLowerCase() == tenToi;
        b.tenNguoiGiu = tenNv;
        final ap = QuyTrinhNvktRules.apDungTienDo(
          trangThai: tt,
          laCuaToi: laCuaToi,
          tenNhanVien: tenNv,
          // Sau Xưởng từ chối: không hiện bước tổ trưởng chọn sẵn
          boQuaDuocChon: _cheDoCapNhat,
        );
        // Luôn áp mô tả từ tiến độ (kể cả DuocChon — nội dung lúc tạo/chỉnh HS)
        final moTaTd = (row['moTaBuoc'] ?? row['MoTaBuoc'])?.toString();
        if (moTaTd != null && moTaTd.trim().isNotEmpty) {
          b.moTaCtrl.text = moTaTd.trim();
        }

        if (tt == 'DuocChon') {
          if (_cheDoCapNhat) {
            // Không áp bước tổ trưởng — để trống như bước chưa chọn
            b.daChon = false;
            b.daXong = false;
            b.khoaBoiNguoiKhac = false;
            b.moRong = false;
            b.daLuuDieuChinh = false;
            b.dangMoCapNhat = false;
            b.tenNguoiGiu = null;
          } else {
            b.daChon = true;
            b.daXong = false;
            b.khoaBoiNguoiKhac = false;
            b.moRong = true;
            b.daLuuDieuChinh = false;
            b.tenNguoiGiu = null;
          }
        } else if (tt == 'DaXong' || tt == 'DaCapNhat') {
          b.daChon = ap.daChon;
          b.daXong = ap.daXong;
          b.khoaBoiNguoiKhac = ap.khoaBoiNguoiKhac;
          b.moRong = ap.moRong;
          b.daLuuDieuChinh = false;
          b.dangMoCapNhat = false;
          if (ap.tenHienThi != null && ap.tenHienThi!.isNotEmpty) {
            b.tenNguoiGiu = ap.tenHienThi;
          }
        } else if (tt == 'DangLam' && laCuaToi) {
          // Trang cập nhật sau từ chối: không khôi phục nháp chưa Xong
          if (_cheDoCapNhat) {
            b.daChon = false;
            b.daXong = false;
            b.khoaBoiNguoiKhac = false;
            b.moRong = false;
            b.tenNguoiGiu = null;
            b.dangMoCapNhat = false;
          } else {
            b.daChon = ap.daChon;
            b.daXong = ap.daXong;
            b.khoaBoiNguoiKhac = ap.khoaBoiNguoiKhac;
            b.moRong = ap.moRong;
            b.daLuuDieuChinh = false;
            b.dangMoCapNhat = false;
            b.tenNguoiGiu = null;
          }
        }
        // Khôi phục vật tư: đã Xong / đã cập nhật; nháp DangLam chỉ quy trình mới
        final canRestoreVt = tt == 'DaXong' ||
            tt == 'DaCapNhat' ||
            (!_cheDoCapNhat && tt == 'DangLam' && laCuaToi);
        if (tt == 'DaXong' || tt == 'DaCapNhat') {
          b.tenNguoiGiu = tenNv;
        }
        if (canRestoreVt) {
          final moTa = (row['moTaBuoc'] ?? row['MoTaBuoc'])?.toString();
          if (moTa != null && moTa.isNotEmpty) {
            b.moTaCtrl.text = moTa;
          }
          final jsonVt = (row['jsonVatTu'] ?? row['JsonVatTu'])?.toString();
          if (jsonVt != null && jsonVt.isNotEmpty) {
            try {
              final arr = jsonDecode(jsonVt);
              if (arr is List) {
                for (final d in b.vatTu) {
                  d.dispose();
                }
                b.vatTu.clear();
                for (final item in arr) {
                  if (item is! Map) continue;
                  final m = Map<String, dynamic>.from(item);
                  final ten = m['tenVatTu']?.toString() ?? '';
                  final sl = (m['soLuong'] as num?)?.toInt() ?? 0;
                  // Nháp cho phép sl=0; đã xong vẫn cần ten
                  if (ten.isEmpty) continue;
                  if ((tt == 'DaXong' || tt == 'DaCapNhat') && sl <= 0) {
                    continue;
                  }
                  b.vatTu.add(_VatTuDongState(
                    maVatTu: (m['maVatTu'] as num?)?.toInt(),
                    tenVatTu: ten,
                    soLuong: sl < 0 ? 0 : sl,
                    donGia: (m['donGia'] as num?)?.toInt() ?? 0,
                  ));
                }
              }
            } catch (_) {}
          }
        }
      }
      if (!silent && mounted) setState(() {});
    } catch (_) {
      // Không chặn UI nếu poll lỗi
    }
  }

  Future<bool> _claimBuoc(_BuocState b) async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return false;
    try {
      await WorkOrderService.luuTienDoBuoc(
        maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
        maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
        soBuoc: b.soBuoc,
        moTaBuoc: b.moTaCtrl.text.trim(),
        trangThai: 'DangLam',
      );
      b.khoaBoiNguoiKhac = false;
      b.tenNguoiGiu = _tenToi;
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return false;
    }
  }

  /// Lưu nháp (DangLam + vật tư) — chỉ quy trình mới.
  /// Trang cập nhật sau từ chối: **không** lưu nháp tích chọn (back ra phải mất tích nếu chưa Xong).
  Future<void> _luuNhapBuoc(_BuocState b, {bool silent = true}) async {
    if (_cheDoCapNhat) return;
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;
    if (b.khoaBoiNguoiKhac) return;
    // Đồng bộ số lượng từ text field
    for (final d in b.vatTu) {
      final kq = validateSoLuongVatTu(
        d.slCtrl.text,
        tenVatTu: d.tenVatTu,
        choPhepRong: true,
      );
      if (kq.hopLe && kq.soLuong != null) d.soLuong = kq.soLuong!;
    }
    final jsonVt = jsonEncode(b.vatTu
        .where((d) => d.tenVatTu.isNotEmpty)
        .map((d) => {
      'maVatTu': d.maVatTu,
      'tenVatTu': d.tenVatTu,
      'soLuong': d.soLuong,
      'donGia': d.donGia,
    })
        .toList());
    try {
      await WorkOrderService.luuTienDoBuoc(
        maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
        maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
        soBuoc: b.soBuoc,
        moTaBuoc: b.moTaCtrl.text.trim().isEmpty
            ? 'Bước ${b.soBuoc}'
            : b.moTaCtrl.text.trim(),
        trangThai: 'DangLam',
        jsonVatTu: jsonVt,
      );
      b.tenNguoiGiu = _tenToi;
      b.khoaBoiNguoiKhac = false;
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không lưu được nháp bước. Kiểm tra kết nối.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _luuBuocDaXong(_BuocState b) async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;

    // Ràng buộc: phải chọn vật tư trước khi Xong
    final loiVatTu = <String?>[];
    for (final d in b.vatTu) {
      final kq = validateSoLuongVatTu(
        d.slCtrl.text,
        tenVatTu: d.tenVatTu,
        choPhepRong: false,
      );
      loiVatTu.add(kq.hopLe ? null : (kq.loi ?? 'Số lượng không hợp lệ'));
      if (kq.hopLe) d.soLuong = kq.soLuong!;
    }
    final loiTruocXong = QuyTrinhNvktRules.kiemTraTruocKhiXong(
      soDongVatTu: b.vatTu.length,
      loiSoLuongTungDong: loiVatTu,
    );
    if (loiTruocXong != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loiTruocXong),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }
    final jsonVt = jsonEncode(b.vatTu
        .where((d) => d.tenVatTu.isNotEmpty && d.soLuong > 0)
        .map((d) => {
      'maVatTu': d.maVatTu,
      'tenVatTu': d.tenVatTu,
      'soLuong': d.soLuong,
      'donGia': d.donGia,
    })
        .toList());
    final daXongTruoc = b.daXong;
    try {
      await WorkOrderService.luuTienDoBuoc(
        maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
        maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
        soBuoc: b.soBuoc,
        moTaBuoc: b.moTaCtrl.text.trim().isEmpty
            ? 'Bước ${b.soBuoc}'
            : b.moTaCtrl.text.trim(),
        // Sau từ chối: DaCapNhat · Quy trình mới: DaXong (nút → Cập nhật)
        trangThai: _cheDoCapNhat ? 'DaCapNhat' : 'DaXong',
        jsonVatTu: jsonVt,
      );
      setState(() {
        b.daXong = true;
        b.daChon = true;
        b.moRong = true;
        b.khoaBoiNguoiKhac = false;
        b.tenNguoiGiu = _tenToi;
        b.dangMoCapNhat = false; // khóa lại — bấm Cập nhật để mở lại
        b.daLuuDieuChinh = false;
      });
      if (mounted) {
        final msg = daXongTruoc
            ? 'Đã lưu cập nhật bước ${b.soBuoc} — đã khóa.'
            : 'Đã lưu bước ${b.soBuoc}. Bấm «Cập nhật» nếu cần sửa hoặc bỏ bước.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  /// Bỏ bước → server BoChon + UI trắng (không tích, không VT, không xanh).
  Future<void> _luuBoBuoc(_BuocState b, {bool silent = false}) async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;
    try {
      await WorkOrderService.luuTienDoBuoc(
        maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
        maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
        soBuoc: b.soBuoc,
        moTaBuoc: b.moTaCtrl.text.trim().isEmpty
            ? 'Bước ${b.soBuoc}'
            : b.moTaCtrl.text.trim(),
        trangThai: 'BoChon',
        jsonVatTu: '[]',
      );
      if (!mounted) return;
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
        b.khoaBoiNguoiKhac = false;
        b.tenNguoiGiu = null;
      });
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Đã bỏ bước ${b.soBuoc} — về trạng thái chưa chọn.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _themBuoc() {
    setState(() {
      final next = _buoc.isEmpty
          ? 1
          : (_buoc.map((e) => e.soBuoc).reduce((a, b) => a > b ? a : b) + 1);
      _buoc.add(_BuocState(soBuoc: next, moTa: ''));
    });
  }

  void _xoaBuoc(int index) {
    setState(() {
      _buoc[index].dispose();
      _buoc.removeAt(index);
      for (var i = 0; i < _buoc.length; i++) {
        _buoc[i].soBuoc = i + 1;
      }
    });
  }



}