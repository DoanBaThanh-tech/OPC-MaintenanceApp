import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';
import '../../equipment/data/equipment_logic.dart';
import '../data/to_truong_quy_trinh_tao_logic.dart';
import 'widgets/to_truong_chon_quy_trinh_tao.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_exception.dart';
import 'work_order_list_screen.dart';

// ============ MÀN 1: TẠO HỒ SƠ BẢO TRÌ (từ 1 dòng chi tiết kế hoạch) ============

class CreateWorkOrderBaoTriScreen extends StatefulWidget {
  final int maChiTietKeHoach;
  final int maThietBi;
  final String tenThietBi;
  const CreateWorkOrderBaoTriScreen({
    super.key,
    required this.maChiTietKeHoach,
    required this.maThietBi,
    required this.tenThietBi,
  });

  @override
  State<CreateWorkOrderBaoTriScreen> createState() => _CreateWorkOrderBaoTriScreenState();
}

class _CreateWorkOrderBaoTriScreenState extends State<CreateWorkOrderBaoTriScreen> {
  final _controller = CreateWorkOrderBaoTriController();
  final _qtCtrl = ToTruongQuyTrinhTaoController(loaiCongViec: 'Bảo trì');
  final _formKey = GlobalKey<FormState>();
  final _noiDungController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _qtCtrl.dispose();
    _noiDungController.dispose();
    super.dispose();
  }

  Future<void> _luu(bool guiDuyet) async {
    if (!_formKey.currentState!.validate()) return;
    final errQt = _qtCtrl.validate();
    if (errQt != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errQt),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final ok = await _controller.luu(
      maChiTietKeHoach: widget.maChiTietKeHoach,
      maThietBi: widget.maThietBi,
      noiDungCongViec: _noiDungController.text.trim(),
      guiDuyet: guiDuyet,
      danhSachBuoc: _qtCtrl.payloadBuoc(),
    );
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const WorkOrderBaoTriListScreen(),
        ),
            (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      appBar: AppBar(
        title: const Text('Tạo hồ sơ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004E80), Color(0xFF0068A9), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    minWidth: constraints.maxWidth > 500 ? 0 : constraints.maxWidth - 40,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.14),
                                AppColors.primary.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.precision_manufacturing_rounded, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Thiết bị',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.tenThietBi,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: const Text(
                            'Ngày bảo trì thực tế do xưởng chốt đã nằm trong kế hoạch. '
                                'Khi phân công công việc bạn sẽ chọn khung giờ thực hiện chi tiết.',
                            style: TextStyle(fontSize: 12.5, height: 1.35),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ToTruongChonQuyTrinhTao(
                          loaiCongViec: 'Bảo trì',
                          controller: _qtCtrl,
                        ),
                        const SizedBox(height: 16),
                        const Text('Nội dung công việc', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noiDungController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Mô tả công việc bảo trì…',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập nội dung công việc' : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thời gian dự kiến / bắt đầu / kết thúc sẽ được ghi nhận '
                              'khi NVKT bấm Tiến hành quy trình và khi hoàn thành.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            if (_controller.loi == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(_controller.loi!, style: const TextStyle(color: AppColors.danger)),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _controller.dangLuu ? null : () => _luu(true),
                              child: _controller.dangLuu
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : const Text('Gửi bảo trì', maxLines: 1),
                            );
                          },
                        ),
                        SizedBox(height: MediaQuery.viewInsetsOf(context).bottom + 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============ TẠO HỒ SƠ BẢO TRÌ THỦ CÔNG (thiết bị mới) ============

class TaoHoSoBaoTriThuCongScreen extends StatefulWidget {
  const TaoHoSoBaoTriThuCongScreen({super.key});

  @override
  State<TaoHoSoBaoTriThuCongScreen> createState() =>
      _TaoHoSoBaoTriThuCongScreenState();
}

class _TaoHoSoBaoTriThuCongScreenState extends State<TaoHoSoBaoTriThuCongScreen>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF0B6BCB);
  static const _sky = Color(0xFF38BDF8);
  static const _bg = Color(0xFFF0F7FC);

  final _ctrl = CreateWorkOrderBaoTriThuCongController();
  final _qtCtrl = ToTruongQuyTrinhTaoController(loaiCongViec: 'Bảo trì');
  final _noiDung = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _ctrl.khoiTao();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _ctrl.dispose();
    _qtCtrl.dispose();
    _noiDung.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _chonNgay() async {
    final now = DateTime.now();
    final first = now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _ctrl.ngayDuKien ?? first,
      firstDate: first,
      lastDate: DateTime(now.year + 5, 12, 31),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) _ctrl.chonNgay(picked);
  }

  Future<void> _gui() async {
    if (!_formKey.currentState!.validate()) return;
    final errQt = _qtCtrl.validate();
    if (errQt != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errQt),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final ok = await _ctrl.luu(
      noiDungCongViec: _noiDung.text,
      danhSachBuoc: _qtCtrl.payloadBuoc(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Đã tạo hồ sơ bảo trì — chuyển tới danh sách hồ sơ bảo trì.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      // Tiện lợi: vào thẳng trang hồ sơ bảo trì
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const WorkOrderBaoTriListScreen(),
        ),
            (route) => route.isFirst,
      );
    } else if (_ctrl.loi != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ctrl.loi!),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  InputDecoration _dec(String label, {String? error}) => InputDecoration(
    labelText: label,
    errorText: error,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _blue, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Lập BT thủ công',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004E80), _blue, _sky],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(fade),
                child: _ctrl.dangTai
                    ? const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
                    : Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              _blue.withValues(alpha: 0.1),
                              _sky.withValues(alpha: 0.08),
                            ]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _blue.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            'Dành cho thiết bị mới hoặc chưa có trong hàng chờ. '
                                'Sau khi tạo, hồ sơ hiện đúng tháng trên kế hoạch. '
                                'Lập nhanh không tạo lại cùng thiết bị trong cùng tháng.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                                height: 1.35),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _ctrl.danhMucChon,
                          isExpanded: true,
                          decoration: _dec(
                              'Danh mục thiết bị * (${_ctrl.nhoms.length})'),
                          items: _ctrl.nhoms
                              .map((n) => DropdownMenuItem(
                            value: n.tenDanhMuc,
                            child: Text(n.tenDanhMuc,
                                overflow: TextOverflow.ellipsis),
                          ))
                              .toList(),
                          onChanged: _ctrl.chonDanhMuc,
                          validator: (v) =>
                          v == null ? 'Chọn danh mục' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ThietBiModel>(
                          value: _ctrl.thietBiChon,
                          isExpanded: true,
                          decoration: _dec(
                              'Thiết bị * (đang Sản xuất)'),
                          items: _ctrl.dsThietBiTheoDanhMuc
                              .map((tb) => DropdownMenuItem(
                            value: tb,
                            child: Text(tb.tenThietBi,
                                overflow: TextOverflow.ellipsis),
                          ))
                              .toList(),
                          onChanged: _ctrl.chonThietBi,
                          validator: (v) =>
                          v == null ? 'Chọn thiết bị' : null,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _chonNgay,
                          child: InputDecorator(
                            decoration: _dec(
                              'Ngày dự kiến bảo trì *',
                              error: _ctrl.loiNgay,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.event_rounded,
                                    color: _blue, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _ctrl.ngayDuKien == null
                                        ? 'Chọn ngày (sau hôm nay)'
                                        : _fmt(_ctrl.ngayDuKien!),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _ctrl.ngayDuKien == null
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ToTruongChonQuyTrinhTao(
                          loaiCongViec: 'Bảo trì',
                          controller: _qtCtrl,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _noiDung,
                          maxLines: 4,
                          decoration: _dec('Nội dung công việc *'),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Nhập nội dung công việc'
                              : null,
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                          ),
                          onPressed: _ctrl.dangLuu ? null : _gui,
                          child: _ctrl.dangLuu
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                              : const Text('Tạo hồ sơ & gửi xưởng',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}