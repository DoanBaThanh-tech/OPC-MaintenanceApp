import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/admin_logic.dart';

/// Admin — Quản lý người dùng (TT CĐ · Xưởng · GĐ · NVKT).
class QuanLyNguoiDungScreen extends StatefulWidget {
  const QuanLyNguoiDungScreen({super.key});

  @override
  State<QuanLyNguoiDungScreen> createState() => _QuanLyNguoiDungScreenState();
}

class _QuanLyNguoiDungScreenState extends State<QuanLyNguoiDungScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = QuanLyNguoiDungController();
  late final AnimationController _anim;
  final _searchCtrl = TextEditingController();

  static const _blue = Color(0xFF0B6BCB);
  static const _bg = Color(0xFFF0F7FC);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _ctrl.addListener(() {
      if (mounted) setState(() {});
      if (!_ctrl.dangTai) _anim.forward(from: 0);
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _anim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _mauTt(String tt) {
    switch (tt) {
      case 'Đang hoạt động':
        return const Color(0xFF059669);
      case 'Đã khóa':
        return AppColors.danger;
      case 'Chưa kích hoạt':
        return const Color(0xFFD97706);
      default:
        return Colors.grey;
    }
  }

  Future<void> _moForm({TaiKhoanAdmin? sua}) async {
    final isSua = sua != null;
    final hoTenCtrl = TextEditingController(
        text: (sua?.hoTen == 'Chưa cập nhật') ? '' : (sua?.hoTen ?? ''));
    final emailCtrl = TextEditingController(text: sua?.email ?? '');
    final mkCtrl = TextEditingController();
    final chucVuCtrl = TextEditingController(text: sua?.chucVu ?? '');
    int? maVaiTro =
    isSua ? null : (_ctrl.vaiTro.isNotEmpty ? _ctrl.vaiTro.first.maVaiTro : null);
    String? loiForm;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            InputDecoration dec({String? hint, String? label}) => InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            );

            Widget field(String label, TextEditingController c,
                {bool obscure = false,
                  TextInputType? keyboard,
                  String? hint}) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: c,
                    obscureText: obscure,
                    keyboardType: keyboard,
                    decoration: dec(label: label, hint: hint),
                  ),
                );

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_blue, Color(0xFF38BDF8)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isSua
                                ? Icons.edit_rounded
                                : Icons.person_add_alt_1_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSua
                                    ? 'Cập nhật người dùng'
                                    : 'Tạo tài khoản mới',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              Text(
                                isSua
                                    ? 'Chỉ sửa họ tên · email @opc.com · chức vụ'
                                    : 'Email @opc.com · họ tên có thể để trống',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    field('Họ tên', hoTenCtrl,
                        hint: 'Chỉ chữ cái — để trống nếu chưa biết'),
                    field('Email công ty *', emailCtrl,
                        hint: 'vd: nguyenvana@opc.com',
                        keyboard: TextInputType.emailAddress),
                    if (!isSua) ...[
                      field('Mật khẩu *', mkCtrl, obscure: true),
                      const SizedBox(height: 4),
                      Text('Vai trò *',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                              fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: maVaiTro,
                        decoration: dec(),
                        items: _ctrl.vaiTro
                            .map((v) => DropdownMenuItem(
                          value: v.maVaiTro,
                          child: Text(
                              '${v.tenVaiTro} (${v.soNguoiDung})'),
                        ))
                            .toList(),
                        onChanged: (v) => setModal(() => maVaiTro = v),
                      ),
                      const SizedBox(height: 10),
                    ] else if (sua.tenVaiTro != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.badge_outlined,
                                size: 18, color: _blue),
                            const SizedBox(width: 8),
                            Text('Vai trò: ${sua.tenVaiTro}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                    field('Chức vụ *', chucVuCtrl),
                    if (loiForm != null) ...[
                      const SizedBox(height: 6),
                      Text(loiForm!,
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (isSua) {
                          final err = await _ctrl.capNhat(
                            maNguoiDung: sua.maNguoiDung,
                            email: emailCtrl.text,
                            hoTen: hoTenCtrl.text,
                            chucVu: chucVuCtrl.text,
                          );
                          if (err != null) {
                            setModal(() => loiForm = err);
                            return;
                          }
                        } else {
                          if (maVaiTro == null) {
                            setModal(() => loiForm = 'Chọn vai trò.');
                            return;
                          }
                          if (mkCtrl.text.isEmpty) {
                            setModal(
                                    () => loiForm = 'Vui lòng nhập mật khẩu.');
                            return;
                          }
                          final err = await _ctrl.taoTaiKhoan(
                            email: emailCtrl.text,
                            matKhau: mkCtrl.text,
                            maVaiTro: maVaiTro!,
                            hoTen: hoTenCtrl.text,
                            chucVu: chucVuCtrl.text,
                          );
                          if (err != null) {
                            setModal(() => loiForm = err);
                            return;
                          }
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      },
                      child: Text(
                        isSua ? 'Lưu thay đổi' : 'Tạo tài khoản',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSua
              ? 'Đã cập nhật người dùng'
              : 'Đã tạo tài khoản (chờ kích hoạt)'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _moForm(),
        backgroundColor: _blue,
        elevation: 6,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Thêm người dùng',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: RefreshIndicator(
        color: _blue,
        onRefresh: _ctrl.tai,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            AdminGradientHeader(
              title: 'Quản lý người dùng',
              subtitle:
              '${_ctrl.danhSach.length} tài khoản · ${_ctrl.vaiTro.length} vai trò',
              searchCtrl: _searchCtrl,
              onSearch: _ctrl.datTuKhoa,
              hint: 'Tìm tên, email, vai trò…',
            ),
            if (_ctrl.dangTai)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_ctrl.loi != null)
              SliiverError(loi: _ctrl.loi!, onRetry: _ctrl.tai)
            else ...[
                SliverToBoxAdapter(child: _thongKeVaiTro()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: _boLoc(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliiverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final u = _ctrl.hienThi[i];
                        return FadeTransition(
                          opacity: _anim,
                          child: _userCard(u),
                        );
                      },
                      childCount: _ctrl.hienThi.length,
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _thongKeVaiTro() {
    if (_ctrl.vaiTro.isEmpty) return const SizedBox.shrink();
    final colors = [
      _blue,
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Số lượng theo vai trò',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _ctrl.vaiTro.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final v = _ctrl.vaiTro[i];
                final selected = _ctrl.locVaiTro == v.tenVaiTro;
                final c = colors[i % colors.length];
                return GestureDetector(
                  onTap: () =>
                      _ctrl.datLocVaiTro(selected ? null : v.tenVaiTro),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 138,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                        colors: [c, c.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: selected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: selected ? c : c.withValues(alpha: 0.2),
                          width: selected ? 0 : 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: c.withValues(alpha: selected ? 0.28 : 0.08),
                          blurRadius: selected ? 16 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.tenVaiTro,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color:
                            selected ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${v.soNguoiDung}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            color: selected ? Colors.white : c,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _boLoc() {
    final tts = ['Đang hoạt động', 'Chưa kích hoạt', 'Đã khóa'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Tất cả', _ctrl.locTrangThai == null,
                  () => _ctrl.datLocTrangThai(null)),
          ...tts.map((t) => _chip(
            t,
            _ctrl.locTrangThai == t,
                () =>
                _ctrl.datLocTrangThai(_ctrl.locTrangThai == t ? null : t),
          )),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: on,
        label: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: on ? Colors.white : Colors.grey.shade800)),
        selectedColor: _blue,
        backgroundColor: Colors.white,
        side: BorderSide(color: on ? _blue : Colors.grey.shade300),
        onSelected: (_) => onTap(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _userCard(TaiKhoanAdmin u) {
    final mau = _mauTt(u.trangThai);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: mau, width: 4.5)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _moForm(sua: u),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _blue.withValues(alpha: 0.15),
                            const Color(0xFF38BDF8).withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        u.hoTen.isNotEmpty ? u.hoTen[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: _blue,
                            fontWeight: FontWeight.w900,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.hoTen,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15.5)),
                          const SizedBox(height: 2),
                          Text(u.email,
                              style: TextStyle(
                                  fontSize: 12.5, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: mau.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(u.trangThai,
                          style: TextStyle(
                              color: mau,
                              fontWeight: FontWeight.w800,
                              fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _tag(Icons.badge_outlined, u.tenVaiTro ?? '—'),
                    if (u.chucVu != null && u.chucVu!.isNotEmpty)
                      _tag(Icons.work_outline, u.chucVu!),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _moForm(sua: u),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Sửa',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    if (u.chuaKichHoat || u.daKhoa)
                      TextButton.icon(
                        onPressed: () async {
                          final err = await _ctrl.kichHoat(u.maNguoiDung);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(err ?? 'Đã kích hoạt'),
                            backgroundColor: err == null
                                ? AppColors.success
                                : AppColors.danger,
                          ));
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Kích hoạt',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    if (u.dangHoatDong)
                      TextButton.icon(
                        onPressed: () async {
                          final err = await _ctrl.khoa(u.maNguoiDung);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(err ?? 'Đã khóa tài khoản'),
                            backgroundColor: err == null
                                ? AppColors.success
                                : AppColors.danger,
                          ));
                        },
                        icon: const Icon(Icons.lock_outline,
                            size: 18, color: AppColors.danger),
                        label: const Text('Khóa',
                            style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _blue),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Header gradient dùng chung 2 trang Admin.
class AdminGradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final String hint;
  final VoidCallback? onSearchSubmit;

  const AdminGradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchCtrl,
    required this.onSearch,
    required this.hint,
    this.onSearchSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B6BCB), Color(0xFF0284C7), Color(0xFF38BDF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Color(0x400B6BCB),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              onSubmitted: (_) => onSearchSubmit?.call(),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.9)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SliiverError extends StatelessWidget {
  final String loi;
  final VoidCallback onRetry;
  const SliiverError({super.key, required this.loi, required this.onRetry});
  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(loi),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

// alias
typedef SliiverList = SliverList;