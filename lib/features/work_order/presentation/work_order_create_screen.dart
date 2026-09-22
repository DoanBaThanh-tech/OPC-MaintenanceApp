import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_exception.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _noiDungController = TextEditingController();
  final _thoiGianController = TextEditingController(text: '4');

  @override
  void dispose() {
    _controller.dispose();
    _noiDungController.dispose();
    _thoiGianController.dispose();
    super.dispose();
  }

  Future<void> _luu(bool guiDuyet) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _controller.luu(
      maChiTietKeHoach: widget.maChiTietKeHoach,
      maThietBi: widget.maThietBi,
      noiDungCongViec: _noiDungController.text.trim(),
      thoiGianDuKien: _thoiGianController.text.trim(),
      guiDuyet: guiDuyet,
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo hồ sơ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
                        const SizedBox(height: 16),
                        const Text('Thời gian dự kiến (giờ)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _thoiGianController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                          decoration: const InputDecoration(
                            hintText: 'Ví dụ: 4',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                            suffixText: 'giờ',
                          ),
                          // Số dương, không ký tự đặc biệt, tối đa 24 giờ trong ngày
                          validator: (v) {
                            final raw = v?.trim() ?? '';
                            if (raw.isEmpty) {
                              return 'Vui lòng nhập giờ dự kiến bảo trì';
                            }
                            if (!RegExp(r'^\d+$').hasMatch(raw)) {
                              return 'Chỉ được nhập số dương (không chữ, không ký tự đặc biệt)';
                            }
                            final so = int.tryParse(raw);
                            if (so == null || so <= 0) {
                              return 'Giờ dự kiến phải là số dương lớn hơn 0';
                            }
                            if (so > 24) {
                              return 'Bảo trì trong ngày — tối đa 24 giờ';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            return Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _controller.dangLuu ? null : () => _luu(false),
                                    child: const Text('Lưu nháp', maxLines: 1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
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
                                  ),
                                ),
                              ],
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