import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_logic.dart';
import '../data/profile_logic.dart';

/// Bottom sheet chỉnh sửa thông tin cá nhân — không đổi email / vai trò.
Future<String?> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ProfileSheetBody(),
  );
}

class _ProfileSheetBody extends StatefulWidget {
  const _ProfileSheetBody();

  @override
  State<_ProfileSheetBody> createState() => _ProfileSheetBodyState();
}

class _ProfileSheetBodyState extends State<_ProfileSheetBody>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF0068A9);
  static const _sky = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF0F7FC);
  static const _slate = Color(0xFF0F172A);

  final _hoTenCtrl = TextEditingController();
  final _sdtCtrl = TextEditingController();
  final _emailLienHeCtrl = TextEditingController();
  final _mkCuCtrl = TextEditingController();
  final _mkMoiCtrl = TextEditingController();
  final _mkLaiCtrl = TextEditingController();
  DateTime? _ngayVaoLam;

  String? _email;
  String? _vaiTro;
  int? _maNd;
  bool _dangTai = true;
  bool _dangLuu = false;
  bool _dangDoiMk = false;
  String? _loi;
  String? _loiMk;

  /// Mật khẩu đã mở sau PIN
  bool _hienMatKhau = false;
  String? _matKhauHien;
  bool _anMkCu = true;
  bool _anMkMoi = true;
  bool _anMkLai = true;
  bool _moFormDoiMk = false;

  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _tai();
  }

  @override
  void dispose() {
    _anim.dispose();
    _hoTenCtrl.dispose();
    _sdtCtrl.dispose();
    _emailLienHeCtrl.dispose();
    _mkCuCtrl.dispose();
    _mkMoiCtrl.dispose();
    _mkLaiCtrl.dispose();
    super.dispose();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final hs = await ProfileService.layHoSo();
      _email = hs.email;
      _vaiTro = hs.tenVaiTro;
      _maNd = hs.maNguoiDung;
      _hoTenCtrl.text = hs.hoTen == 'Chưa cập nhật' ? '' : hs.hoTen;
      _sdtCtrl.text = hs.soDienThoai ?? '';
      _emailLienHeCtrl.text = hs.emailLienHe ?? '';
      _ngayVaoLam = hs.ngayVaoLam;
      if (_maNd != null) {
        _matKhauHien = await ProfileVault.layMatKhau(_maNd!);
      }
    } on ApiException catch (e) {
      _loi = e.message;
    } catch (e) {
      _loi = '$e';
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  Future<void> _luu() async {
    final e1 = ProfileRules.kiemTraHoTen(_hoTenCtrl.text);
    if (e1 != null) {
      setState(() => _loi = e1);
      return;
    }
    final e2 = ProfileRules.kiemTraSdt(_sdtCtrl.text);
    if (e2 != null) {
      setState(() => _loi = e2);
      return;
    }
    final e3 = ProfileRules.kiemTraEmailLienHe(_emailLienHeCtrl.text);
    if (e3 != null) {
      setState(() => _loi = e3);
      return;
    }
    setState(() {
      _dangLuu = true;
      _loi = null;
    });
    try {
      final hs = await ProfileService.capNhat(
        hoTen: _hoTenCtrl.text,
        soDienThoai: _sdtCtrl.text,
        emailLienHe: _emailLienHeCtrl.text,
        ngayVaoLam: _ngayVaoLam,
      );
      if (!mounted) return;
      Navigator.pop(context, hs.hoTen);
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } catch (e) {
      setState(() => _loi = '$e');
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  Future<bool> _xacThucPin() async {
    final ma = _maNd ?? await TokenStorage.getMaNguoiDung();
    if (ma == null) return false;
    final coPin = await ProfileVault.daCoPin(ma);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String? err;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                coPin ? 'Nhập mã PIN 4 số' : 'Tạo mã PIN 4 số',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    coPin
                        ? 'Nhập mã PIN chỉ bạn biết để xem mật khẩu tài khoản.'
                        : 'Tạo mã PIN 4 số để bảo vệ việc xem mật khẩu. '
                        'Người khác vào máy cũng không xem được nếu không biết PIN.',
                    style: TextStyle(
                        color: Colors.grey.shade600, height: 1.35, fontSize: 13.5),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    maxLength: 4,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        letterSpacing: 12,
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _blue, width: 1.5),
                      ),
                    ),
                  ),
                  if (err != null) ...[
                    const SizedBox(height: 8),
                    Text(err!,
                        style: const TextStyle(
                            color: AppColors.danger, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Hủy')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _blue),
                  onPressed: () async {
                    final pin = ctrl.text.trim();
                    if (pin.length != 4) {
                      setLocal(() => err = 'PIN phải đủ 4 số');
                      return;
                    }
                    if (!coPin) {
                      await ProfileVault.luuPin(ma, pin);
                      if (ctx.mounted) Navigator.pop(ctx, true);
                      return;
                    }
                    final dung = await ProfileVault.kiemTraPin(ma, pin);
                    if (!dung) {
                      setLocal(() => err = 'PIN không đúng');
                      return;
                    }
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(coPin ? 'Xác nhận' : 'Tạo PIN'),
                ),
              ],
            );
          },
        );
      },
    );
    ctrl.dispose();
    return ok == true;
  }

  Future<void> _bamMat() async {
    if (_hienMatKhau) {
      setState(() => _hienMatKhau = false);
      return;
    }
    final ok = await _xacThucPin();
    if (!ok || !mounted) return;
    final ma = _maNd ?? await TokenStorage.getMaNguoiDung();
    final pwd = ma == null ? null : await ProfileVault.layMatKhau(ma);
    setState(() {
      _matKhauHien = pwd;
      _hienMatKhau = true;
    });
    if (pwd == null || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Chưa có mật khẩu trên thiết bị này. Đăng nhập lại hoặc đổi mật khẩu để lưu xem được.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _doiMatKhau() async {
    final e1 = AuthValidators.matKhauMoi(_mkMoiCtrl.text);
    if (_mkCuCtrl.text.isEmpty) {
      setState(() => _loiMk = 'Nhập mật khẩu hiện tại');
      return;
    }
    if (e1 != null) {
      setState(() => _loiMk = e1);
      return;
    }
    if (_mkMoiCtrl.text != _mkLaiCtrl.text) {
      setState(() => _loiMk = 'Mật khẩu xác nhận không khớp');
      return;
    }
    setState(() {
      _dangDoiMk = true;
      _loiMk = null;
    });
    try {
      await ProfileService.doiMatKhau(
        matKhauCu: _mkCuCtrl.text,
        matKhauMoi: _mkMoiCtrl.text,
      );
      final ma = _maNd ?? await TokenStorage.getMaNguoiDung();
      if (ma != null) {
        await ProfileVault.luuMatKhau(ma, _mkMoiCtrl.text);
      }
      if (!mounted) return;
      setState(() {
        _matKhauHien = _mkMoiCtrl.text;
        _hienMatKhau = false;
        _moFormDoiMk = false;
        _mkCuCtrl.clear();
        _mkMoiCtrl.clear();
        _mkLaiCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã đổi mật khẩu thành công'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _loiMk = e.message);
    } catch (e) {
      setState(() => _loiMk = '$e');
    } finally {
      if (mounted) setState(() => _dangDoiMk = false);
    }
  }

  InputDecoration _dec({String? label, String? hint, Widget? suffix, IconData? prefix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: _bg,
        prefixIcon: prefix == null ? null : Icon(prefix, color: _blue.withValues(alpha: 0.75), size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _blue, width: 1.4),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    final fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Header gradient
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_blue, _sky],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        (_hoTenCtrl.text.isNotEmpty
                            ? _hoTenCtrl.text[0]
                            : (_email ?? '?')[0])
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin cá nhân',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _vaiTro ?? '—',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _dangTai
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionCard(
                        title: 'Tài khoản',
                        icon: Icons.badge_rounded,
                        children: [
                          _readonlyTile(Icons.mail_outline_rounded, 'Email đăng nhập', _email ?? '—'),
                          const SizedBox(height: 10),
                          _readonlyTile(Icons.work_outline_rounded, 'Vai trò', _vaiTro ?? '—'),
                          const SizedBox(height: 12),
                          // Mật khẩu + mắt
                          Text('Mật khẩu tài khoản',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _blue.withValues(alpha: 0.12)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_rounded,
                                    color: _blue.withValues(alpha: 0.8),
                                    size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _hienMatKhau
                                        ? (_matKhauHien?.isNotEmpty == true
                                        ? _matKhauHien!
                                        : '(Chưa lưu trên máy)')
                                        : '••••••••••',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: _hienMatKhau ? 15 : 18,
                                      letterSpacing: _hienMatKhau ? 0.5 : 3,
                                      color: _slate,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: _hienMatKhau
                                      ? 'Ẩn mật khẩu'
                                      : 'Hiện mật khẩu (cần PIN)',
                                  onPressed: _bamMat,
                                  icon: Icon(
                                    _hienMatKhau
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: _blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bấm biểu tượng mắt → nhập PIN 4 số để xem. '
                                'Mật khẩu chỉ lưu trên thiết bị sau khi đăng nhập / đổi MK.',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                                height: 1.3),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => setState(
                                    () => _moFormDoiMk = !_moFormDoiMk),
                            icon: Icon(
                              _moFormDoiMk
                                  ? Icons.expand_less_rounded
                                  : Icons.lock_reset_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _moFormDoiMk
                                  ? 'Thu gọn đổi mật khẩu'
                                  : 'Đổi mật khẩu',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800),
                            ),
                            style: TextButton.styleFrom(
                                foregroundColor: _blue),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            child: _moFormDoiMk
                                ? Column(
                              children: [
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _mkCuCtrl,
                                  obscureText: _anMkCu,
                                  decoration: _dec(
                                    label: 'Mật khẩu hiện tại',
                                    prefix: Icons.lock_outline,
                                    suffix: IconButton(
                                      icon: Icon(_anMkCu
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () => setState(
                                              () => _anMkCu = !_anMkCu),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _mkMoiCtrl,
                                  obscureText: _anMkMoi,
                                  decoration: _dec(
                                    label: 'Mật khẩu mới',
                                    prefix: Icons.password_rounded,
                                    suffix: IconButton(
                                      icon: Icon(_anMkMoi
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () => setState(
                                              () =>
                                          _anMkMoi = !_anMkMoi),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _mkLaiCtrl,
                                  obscureText: _anMkLai,
                                  decoration: _dec(
                                    label: 'Nhập lại mật khẩu mới',
                                    prefix: Icons.verified_user_outlined,
                                    suffix: IconButton(
                                      icon: Icon(_anMkLai
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () => setState(
                                              () =>
                                          _anMkLai = !_anMkLai),
                                    ),
                                  ),
                                ),
                                if (_loiMk != null) ...[
                                  const SizedBox(height: 8),
                                  Text(_loiMk!,
                                      style: const TextStyle(
                                          color: AppColors.danger,
                                          fontWeight:
                                          FontWeight.w600)),
                                ],
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: FilledButton(
                                    onPressed: _dangDoiMk
                                        ? null
                                        : _doiMatKhau,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _blue,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius
                                              .circular(12)),
                                    ),
                                    child: _dangDoiMk
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                      CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors
                                              .white),
                                    )
                                        : const Text(
                                      'Lưu mật khẩu mới',
                                      style: TextStyle(
                                          fontWeight:
                                          FontWeight
                                              .w800),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: 'Thông tin liên hệ',
                        icon: Icons.person_rounded,
                        children: [
                          TextField(
                            controller: _hoTenCtrl,
                            decoration: _dec(
                                label: 'Họ và tên',
                                prefix: Icons.badge_outlined),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _sdtCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: _dec(
                                label: 'Số điện thoại',
                                prefix: Icons.phone_outlined),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailLienHeCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec(
                              label: 'Email nhận OTP (Gmail…)',
                              hint: 'Gmail cá nhân gắn với tài khoản',
                              prefix: Icons.alternate_email_rounded,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _ngayVaoLam ?? now,
                                firstDate: DateTime(1990),
                                lastDate: now,
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme:
                                    const ColorScheme.light(
                                        primary: _blue),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setState(() => _ngayVaoLam = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: InputDecorator(
                              decoration: _dec(
                                label: 'Ngày vào làm',
                                prefix: Icons.calendar_month_rounded,
                              ),
                              child: Text(
                                _ngayVaoLam == null
                                    ? 'Chọn ngày'
                                    : _fmtDate(_ngayVaoLam!),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _ngayVaoLam == null
                                      ? Colors.grey
                                      : _slate,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_loi != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_loi!,
                              style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                                colors: [_blue, _sky]),
                            boxShadow: [
                              BoxShadow(
                                color: _blue.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _dangLuu ? null : _luu,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(14)),
                            ),
                            child: _dangLuu
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white),
                            )
                                : const Text(
                              'Lưu thông tin',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _blue.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: _blue),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: _slate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _readonlyTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _blue.withValues(alpha: 0.8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _slate)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}