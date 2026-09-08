import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/presentation/auth_screens.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  ApiClient.instance.onUnauthorized = () async {
    await TokenStorage.xoaPhienDangNhap();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), // ← sửa: về LoginScreen, không phải DashboardScreen
      (route) => false,
    );
  };

  runApp(const OPCApp());
}

class OPCApp extends StatelessWidget {
  const OPCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'OPC Maintenance',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(), // ← sửa: mở app luôn vào màn Đăng nhập trước
    );
  }
}