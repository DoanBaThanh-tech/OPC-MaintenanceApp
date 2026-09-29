import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_screens.dart';
import 'features/auth/presentation/splash_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  ApiClient.instance.onUnauthorized = () async {
    await TokenStorage.xoaPhienDangNhap();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
      theme: AppTheme.light,
      // Splash → Đăng nhập (sau ~2.8s + hiệu ứng)
      home: const SplashScreen(),
    );
  }
}