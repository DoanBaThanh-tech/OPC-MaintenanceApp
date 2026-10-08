library technician_screens;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/technician_logic.dart';
import '../data/models/work_order_models.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/work_order_service.dart';
import '../data/services/material_usage_service.dart';
import '../data/work_order_validators.dart';
import 'quy_trinh_nvkt_screen.dart';

part 'nvkt/man_quan_ly_yeu_cau_nvkt.dart';
part 'nvkt/man_chi_tiet_yeu_cau_nvkt.dart';
part 'nvkt/man_ket_qua_thuc_hien.dart';
part 'nvkt/mo_hinh_buoc_quy_trinh_nvkt.dart';