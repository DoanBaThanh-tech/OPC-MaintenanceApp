library work_order_detail_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/work_order_logic.dart';
import '../data/work_order_validators.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/material_usage_service.dart';
import '../data/services/work_order_service.dart';
import 'work_order_assign_screen.dart';
import 'widgets/to_truong_chon_buoc_quy_trinh.dart';
import '../data/to_truong_ke_hoach_buoc_logic.dart';

part 'chi_tiet_bao_tri/man_chi_tiet_ho_so_bao_tri.dart';
part 'chi_tiet_bao_tri/man_sua_ho_so_bi_tu_choi.dart';
part 'chi_tiet_bao_tri/mo_hinh_buoc_quy_trinh_chi_tiet.dart';
part 'chi_tiet_bao_tri/giao_dien_quy_trinh_chi_tiet_bao_tri.dart';
part 'chi_tiet_bao_tri/widget_phu_chi_tiet_bao_tri.dart';
part 'chi_tiet_bao_tri/xu_ly_chi_tiet_bao_tri.dart';

/// Màu giao diện chi tiết hồ sơ bảo trì (dùng chung mọi part).
const _kBtBg = Color(0xFFF0F6FB);
const _kBtPrimary = Color(0xFF0068A9);