import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/admin_logic.dart';

/// Admin — Quản lý người dùng (UI hiện đại).
class QuanLyNguoiDungScreen extends StatefulWidget {
  const QuanLyNguoiDungScreen({super.key});

  @override
  State<QuanLyNguoiDungScreen> createState() => _QuanLyNguoiDungScreenState();
}

class _QuanLyNguoiDungScreenState extends State<QuanLyNguoiDungScreen>
    with TickerProviderStateMixin {
  final _ctrl = QuanLyNguoiDungController();
  late final AnimationController _listAnim;
  late final AnimationController _fabAnim;
  final _searchCtrl = TextEditingController();

  static const _blue = Color(0xFF0B6BCB);
  static const _sky = Color(0xFF38BDF8);
  static const _bg = Color(0xFFEEF6FC);

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
      if (!_ctrl.dangTai) _listAnim.forward(from: 0);
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _listAnim.dispose();
    _fabAnim.dispose();
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
        return Colors.blueGrey;
    }
  }

  Future<void> _moForm({TaiKhoanAdmin? sua}) async {
    final isSua = sua != null;
    final hoTenCtrl = TextEditingController(
        text: (sua?.hoTen == 'Chưa cập nhật') ? '' : (sua?.hoTen ?? ''));
    final emailCtrl = TextEditingController(text: sua?.email ?? '');
    final mkCtrl = TextEditingController();
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
            InputDecoration dec({String? hint, String? label}) => InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF0F7FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            );

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
              ),
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 14,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 22,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: _blue.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_blue, _sky],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _blue.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSua
                                ? Icons.swap_horiz_rounded
                                : Icons.person_add_alt_1_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSua
                                    ? 'Đổi vai trò'
                                    : 'Tạo tài khoản mới',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 19),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSua
                                    ? 'Chỉ được chỉnh sửa vai trò'
                                    : 'Họ tên có thể để trống nếu chưa biết',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (isSua) ...[
                      // Chỉ xem họ tên + email
                      _infoChip(Icons.person_outline, sua.hoTen),
                      const SizedBox(height: 8),
                      _infoChip(Icons.mail_outline, sua.email),
                      const SizedBox(height: 16),
                      Text('Vai trò *',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade700,
                              fontSize: 13)),
                      const SizedBox(height: 8),
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
                    ] else ...[
                      TextField(
                        controller: hoTenCtrl,
                        decoration: dec(
                          label: 'Họ tên (tuỳ chọn)',
                          hint: 'Để trống nếu chưa biết tên',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: dec(
                          label: 'Email công ty *',
                          hint: 'vd: nguyenvana@opc.com',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: mkCtrl,
                        obscureText: true,
                        decoration: dec(label: 'Mật khẩu *'),
                      ),
                      const SizedBox(height: 12),
                      Text('Vai trò *',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade700,
                              fontSize: 13)),
                      const SizedBox(height: 8),
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
                    ],
                    if (loiForm != null) ...[
                      const SizedBox(height: 12),
                      Text(loiForm!,
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        shadowColor: _blue.withValues(alpha: 0.4),
                      ),
                      onPressed: () async {
                        if (isSua) {
                          if (maVaiTro == null) {
                            setModal(() => loiForm = 'Chọn vai trò.');
                            return;
                          }
                          final err = await _ctrl.capNhat(
                            maNguoiDung: sua.maNguoiDung,
                            maVaiTro: maVaiTro!,
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
                          );
                          if (err != null) {
                            setModal(() => loiForm = err);
                            return;
                          }
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      },
                      child: Text(
                        isSua ? 'Lưu vai trò' : 'Tạo tài khoản',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15.5),
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
              ? 'Đã cập nhật vai trò'
              : 'Đã tạo tài khoản (chờ kích hoạt)'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fabScale = CurvedAnimation(
      parent: _fabAnim,
      curve: Curves.elasticOut,
    );

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: ScaleTransition(
        scale: fabScale,
        child: FloatingActionButton.extended(
          onPressed: () => _moForm(),
          backgroundColor: _blue,
          elevation: 8,
          highlightElevation: 12,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Thêm người dùng',
              style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
      body: RefreshIndicator(
        color: _blue,
        onRefresh: _ctrl.tai,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            _buildHeader(),
            if (_ctrl.dangTai)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_ctrl.loi != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_ctrl.loi!),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _ctrl.tai, child: const Text('Thử lại')),
                    ],
                  ),
                ),
              )
            else ...[
                SliverToBoxAdapter(child: _thongKeVaiTro()),
                SliiverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: _boLoc(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final u = _ctrl.hienThi[i];
                        final start = (i * 0.06).clamp(0.0, 0.6);
                        final anim = CurvedAnimation(
                          parent: _listAnim,
                          curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
                        );
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(anim),
                            child: _userCard(u),
                          ),
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

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF075985), _blue, _sky],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quản lý người dùng',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: -0.4)),
                      const SizedBox(height: 2),
                      Text(
                        '${_ctrl.danhSach.length} tài khoản · ${_ctrl.vaiTro.length} vai trò',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _ctrl.datTuKhoa,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Tìm tên, email, vai trò…',
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7)),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.9)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Số lượng theo vai trò',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _ctrl.vaiTro.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final v = _ctrl.vaiTro[i];
                final selected = _ctrl.locVaiTro == v.tenVaiTro;
                final c = colors[i % colors.length];
                return GestureDetector(
                  onTap: () =>
                      _ctrl.datLocVaiTro(selected ? null : v.tenVaiTro),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: 142,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                        colors: [c, c.withValues(alpha: 0.78)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: selected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? c : c.withValues(alpha: 0.18),
                        width: selected ? 0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.withValues(alpha: selected ? 0.32 : 0.1),
                          blurRadius: selected ? 18 : 12,
                          offset: const Offset(0, 5),
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
                            fontSize: 28,
                            color: selected ? Colors.white : c,
                            height: 1,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: on ? 2 : 0,
        pressElevation: 4,
      ),
    );
  }

  Widget _userCard(TaiKhoanAdmin u) {
    final mau = _mauTt(u.trangThai);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: mau, width: 5)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _moForm(sua: u),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _blue.withValues(alpha: 0.18),
                            _sky.withValues(alpha: 0.22),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        u.hoTen.isNotEmpty ? u.hoTen[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: _blue,
                            fontWeight: FontWeight.w900,
                            fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.hoTen,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 3),
                          Text(u.email,
                              style: TextStyle(
                                  fontSize: 12.5, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: mau.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
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
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.badge_outlined, size: 15, color: _blue),
                      const SizedBox(width: 6),
                      Text(u.tenVaiTro ?? '—',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _moForm(sua: u),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Đổi vai trò',
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
}

/// Header gradient dùng chung (nhật ký hệ thống).
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
            colors: [Color(0xFF075985), Color(0xFF0B6BCB), Color(0xFF38BDF8)],
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

typedef SliiverToBoxAdapter = // ignore: camel_case_types
SliverToBoxAdapter;