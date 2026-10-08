library work_order_repair_screens;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_detail_ui.dart';
import '../../../core/network/api_exception.dart';
import '../../equipment/data/equipment_logic.dart' show ThietBiModel;
import '../data/work_order_logic.dart';
import '../data/work_order_validators.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/material_usage_service.dart';
import '../data/services/work_order_service.dart';
import 'work_order_assign_screen.dart';
import 'widgets/to_truong_chon_buoc_quy_trinh.dart';
import '../data/to_truong_ke_hoach_buoc_logic.dart';
import '../data/to_truong_quy_trinh_tao_logic.dart';
import 'widgets/to_truong_chon_quy_trinh_tao.dart';

part 'sua_chua/man_danh_sach_sua_chua.dart';
part 'sua_chua/man_tao_ho_so_sua_chua.dart';
part 'sua_chua/man_chi_tiet_sua_chua.dart';
part 'sua_chua/widget_the_sua_chua.dart';

/// Màu giao diện hồ sơ sửa chữa (dùng chung mọi part trong package).
const _scBg = Color(0xFFF0F6FB);
const _scPrimary = Color(0xFF0068A9);
const _scSoft = Color(0xFF0EA5E9);
const _scAccent = Color(0xFF0284C7);
