library maintenance_plan_screens;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../work_order/presentation/work_order_create_screen.dart';
import '../data/maintenance_plan_logic.dart';
import 'hang_cho_bao_tri_screen.dart';

part 'ke_hoach/man_lich_ke_hoach_12_thang.dart';
part 'ke_hoach/man_chi_tiet_ke_hoach_theo_thang.dart';
part 'ke_hoach/man_lap_ke_hoach_bao_tri.dart';
part 'ke_hoach/widget_lich_ke_hoach.dart';

/// Tên tháng đầy đủ (index 1–12).
const _tenThang = [
  '',
  'Tháng 1',
  'Tháng 2',
  'Tháng 3',
  'Tháng 4',
  'Tháng 5',
  'Tháng 6',
  'Tháng 7',
  'Tháng 8',
  'Tháng 9',
  'Tháng 10',
  'Tháng 11',
  'Tháng 12',
];

/// Tên tháng ngắn (index 1–12) — dùng lịch 12 tháng.
const _tenThangNgan = [
  '',
  'T1',
  'T2',
  'T3',
  'T4',
  'T5',
  'T6',
  'T7',
  'T8',
  'T9',
  'T10',
  'T11',
  'T12',
];