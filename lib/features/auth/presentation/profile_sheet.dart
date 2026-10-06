import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
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
  static const _blue = Color(0xFF0B6BCB);
  static const _sky = Color(0xFF38BDF8);
  static const _bg = Color(0xFFF0F7FC);

  final _hoTenCtrl = TextEditingController();
  final _sdtCtrl = TextEditingController();
  DateTime? _ngayVaoLam;

  String? _email;
  String? _vaiTro;
  bool _dangTai = true;
  bool _dangLuu = false;
  String? _loi;

  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _tai();
  }

  @override
  void dispose() {
    _anim.dispose();
    _hoTenCtrl.dispose();
    _sdtCtrl.dispose();
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
      _hoTenCtrl.text =
      hs.hoTen == 'Chưa cập nhật' ? '' : hs.hoTen;
      _sdtCtrl.text = hs.soDienThoai ?? '';
      _ngayVaoLam = hs.ngayVaoLam;
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
    setState(() {
      _dangLuu = true;
      _loi = null;
    });
    try {
      final hs = await ProfileService.capNhat(
        hoTen: _hoTenCtrl.text,
        soDienThoai: _sdtCtrl.text,
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

  InputDecoration _dec({String? label, String? hint, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: _bg,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
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

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: _anim,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: _dangTai
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_blue, _sky],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (_hoTenCtrl.text.isNotEmpty
                            ? _hoTenCtrl.text[0]
                            : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22),
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
                                fontWeight: FontWeight.w900,
                                fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Chỉnh sửa họ tên, số điện thoại…',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Email + vai trò chỉ xem
                _readonlyRow(Icons.mail_outline_rounded, 'Email',
                    _email ?? '—'),
                const SizedBox(height: 8),
                _readonlyRow(Icons.badge_outlined, 'Vai trò',
                    _vaiTro ?? '—'),
                const SizedBox(height: 16),
                TextField(
                  controller: _hoTenCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _dec(
                    label: 'Họ tên *',
                    hint: 'Chỉ chữ cái và khoảng trắng',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sdtCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _dec(
                    label: 'Số điện thoại',
                    hint: 'Tối đa 10 số — VD: 0901234567',
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _ngayVaoLam ?? now,
                      firstDate: DateTime(1990),
                      lastDate: now,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: _blue,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _ngayVaoLam = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: _dec(
                      label: 'Ngày vào làm',
                      suffix: const Icon(Icons.calendar_today_rounded,
                          size: 18, color: _blue),
                    ),
                    child: Text(
                      _ngayVaoLam == null
                          ? 'Chọn ngày'
                          : _fmtDate(_ngayVaoLam!),
                      style: TextStyle(
                        color: _ngayVaoLam == null
                            ? Colors.grey.shade500
                            : Colors.grey.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (_loi != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _loi!,
                    style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _dangLuu ? null : _luu,
                  child: _dangLuu
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _dangLuu
                      ? null
                      : () => Navigator.pop(context),
                  child: Text(
                    'Đóng',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _readonlyRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _blue),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.lock_outline_rounded,
              size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}