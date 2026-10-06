import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/admin_logic.dart';

/// Admin — Quản lý người dùng + thống kê số lượng theo vai trò.
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

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
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
        return AppColors.success;
      case 'Đã khóa':
        return AppColors.danger;
      case 'Chưa kích hoạt':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  Future<void> _moForm({TaiKhoanAdmin? sua}) async {
    final hoTenCtrl = TextEditingController(text: sua?.hoTen ?? '');
    final emailCtrl = TextEditingController(text: sua?.email ?? '');
    final mkCtrl = TextEditingController();
    final sdtCtrl = TextEditingController(text: sua?.soDienThoai ?? '');
    final chucVuCtrl = TextEditingController(text: sua?.chucVu ?? '');
    int? maVaiTro = sua?.maVaiTro ??
        (_ctrl.vaiTro.isNotEmpty ? _ctrl.vaiTro.first.maVaiTro : null);
    String? loiForm;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      sua == null ? 'Tạo tài khoản mới' : 'Cập nhật người dùng',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 14),
                    _field('Họ tên *', hoTenCtrl),
                    if (sua == null) ...[
                      _field('Email *', emailCtrl,
                          keyboard: TextInputType.emailAddress),
                      _field('Mật khẩu *', mkCtrl, obscure: true),
                    ],
                    _field('Số điện thoại', sdtCtrl,
                        keyboard: TextInputType.phone),
                    _field('Chức vụ *', chucVuCtrl),
                    const SizedBox(height: 8),
                    Text('Vai trò *',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: maVaiTro,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF0F7FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _ctrl.vaiTro
                          .map((v) => DropdownMenuItem(
                        value: v.maVaiTro,
                        child: Text(
                            '${v.tenVaiTro} (${v.soNguoiDung})'),
                      ))
                          .toList(),
                      onChanged: (v) => setModal(() => maVaiTro = v),
                    ),
                    if (loiForm != null) ...[
                      const SizedBox(height: 10),
                      Text(loiForm!,
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (hoTenCtrl.text.trim().isEmpty ||
                            chucVuCtrl.text.trim().isEmpty ||
                            maVaiTro == null) {
                          setModal(() =>
                          loiForm = 'Vui lòng nhập đủ họ tên, chức vụ, vai trò.');
                          return;
                        }
                        if (sua == null) {
                          if (emailCtrl.text.trim().isEmpty ||
                              mkCtrl.text.isEmpty) {
                            setModal(() =>
                            loiForm = 'Email và mật khẩu không được trống.');
                            return;
                          }
                          final err = await _ctrl.taoTaiKhoan(
                            email: emailCtrl.text.trim(),
                            matKhau: mkCtrl.text,
                            maVaiTro: maVaiTro!,
                            hoTen: hoTenCtrl.text.trim(),
                            soDienThoai: sdtCtrl.text.trim().isEmpty
                                ? null
                                : sdtCtrl.text.trim(),
                            chucVu: chucVuCtrl.text.trim(),
                          );
                          if (err != null) {
                            setModal(() => loiForm = err);
                            return;
                          }
                        } else {
                          final err = await _ctrl.capNhat(
                            maNguoiDung: sua.maNguoiDung,
                            maVaiTro: maVaiTro!,
                            hoTen: hoTenCtrl.text.trim(),
                            soDienThoai: sdtCtrl.text.trim().isEmpty
                                ? null
                                : sdtCtrl.text.trim(),
                            chucVu: chucVuCtrl.text.trim(),
                          );
                          if (err != null) {
                            setModal(() => loiForm = err);
                            return;
                          }
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      },
                      child: Text(sua == null ? 'Tạo tài khoản' : 'Lưu thay đổi',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
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
          content: Text(sua == null
              ? 'Đã tạo tài khoản (chờ kích hoạt)'
              : 'Đã cập nhật người dùng'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _field(String label, TextEditingController c,
      {bool obscure = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF0F7FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _moForm(),
        backgroundColor: _blue,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Thêm người dùng',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: _blue,
        onRefresh: _ctrl.tai,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            if (_ctrl.dangTai)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_ctrl.loi != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_ctrl.loi!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _ctrl.tai,
                            child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
                SliverToBoxAdapter(child: _thongKeVaiTro()),
                SliiverPad(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: _boLoc(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
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

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B6BCB), Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quản lý người dùng',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            '${_ctrl.danhSach.length} tài khoản · ${_ctrl.vaiTro.length} vai trò',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: _ctrl.datTuKhoa,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, email, vai trò…',
              hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              prefixIcon:
              Icon(Icons.search, color: Colors.white.withValues(alpha: 0.9)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thongKeVaiTro() {
    if (_ctrl.vaiTro.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Số lượng theo vai trò',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _ctrl.vaiTro.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final v = _ctrl.vaiTro[i];
                final selected = _ctrl.locVaiTro == v.tenVaiTro;
                return GestureDetector(
                  onTap: () => _ctrl.datLocVaiTro(
                      selected ? null : v.tenVaiTro),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 130,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? _blue : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: selected
                              ? _blue
                              : _blue.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
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
                            color: selected ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${v.soNguoiDung}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: selected ? Colors.white : _blue,
                          ),
                        ),
                        Text(
                          'người',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? Colors.white70
                                : Colors.grey.shade600,
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
          _chipLoc('Tất cả', _ctrl.locTrangThai == null,
                  () => _ctrl.datLocTrangThai(null)),
          ...tts.map((t) => _chipLoc(
            t,
            _ctrl.locTrangThai == t,
                () => _ctrl.datLocTrangThai(
                _ctrl.locTrangThai == t ? null : t),
          )),
        ],
      ),
    );
  }

  Widget _chipLoc(String label, bool on, VoidCallback onTap) {
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
        onSelected: (_) => onTap(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _userCard(TaiKhoanAdmin u) {
    final mau = _mauTt(u.trangThai);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: mau, width: 4)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _blue.withValues(alpha: 0.12),
                  child: Text(
                    u.hoTen.isNotEmpty ? u.hoTen[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: _blue, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.hoTen,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15)),
                      Text(u.email,
                          style: TextStyle(
                              fontSize: 12.5, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _tag(Icons.badge_outlined, u.tenVaiTro ?? '—'),
                if (u.chucVu != null && u.chucVu!.isNotEmpty)
                  _tag(Icons.work_outline, u.chucVu!),
                if (u.soDienThoai != null && u.soDienThoai!.isNotEmpty)
                  _tag(Icons.phone_outlined, u.soDienThoai!),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _moForm(sua: u),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Sửa'),
                ),
                if (u.chuaKichHoat || u.daKhoa)
                  TextButton.icon(
                    onPressed: () async {
                      final err = await _ctrl.kichHoat(u.maNguoiDung);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(err ?? 'Đã kích hoạt'),
                        backgroundColor:
                        err == null ? AppColors.success : AppColors.danger,
                      ));
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Kích hoạt'),
                  ),
                if (u.dangHoatDong)
                  TextButton.icon(
                    onPressed: () async {
                      final err = await _ctrl.khoa(u.maNguoiDung);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(err ?? 'Đã khóa tài khoản'),
                        backgroundColor:
                        err == null ? AppColors.success : AppColors.danger,
                      ));
                    },
                    icon: Icon(Icons.lock_outline,
                        size: 18, color: AppColors.danger),
                    label: Text('Khóa',
                        style: TextStyle(color: AppColors.danger)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _blue),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class SliiverPad extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;
  const SliiverPad({super.key, required this.padding, required this.child});
  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: padding,
    sliver: SliverToBoxAdapter(child: child),
  );
}