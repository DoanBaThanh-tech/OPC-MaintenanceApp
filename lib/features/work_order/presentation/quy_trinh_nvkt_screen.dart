library quy_trinh_nvkt_screen;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/models/work_order_models.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/material_usage_service.dart';
import '../data/services/work_order_service.dart';
import '../data/work_order_validators.dart';
import '../data/quy_trinh_nvkt_logic.dart';

part 'quy_trinh_nvkt/man_quy_trinh_nvkt.dart';
part 'quy_trinh_nvkt/widget_vien_net_dut.dart';
part 'quy_trinh_nvkt/trang_thai_buoc_va_vat_tu_nvkt.dart';
part 'quy_trinh_nvkt/xu_ly_quy_trinh_nvkt.dart';
part 'quy_trinh_nvkt/xu_ly_vat_tu_va_hoan_thanh_nvkt.dart';
part 'quy_trinh_nvkt/giao_dien_the_buoc_nvkt.dart';

/// Màu UI quy trình NVKT (dùng chung).
const _blue = Color(0xFF0068A9);
const _blueMid = Color(0xFF0284C7);
const _blueSoft = Color(0xFF0EA5E9);
const _bg = Color(0xFFF0F7FC);