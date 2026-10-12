import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/token_storage.dart';
import 'thong_bao_models.dart';

/// Callback khi user bấm thông báo / nút «Tiến hành» ngoài app.
typedef ThongBaoTapCallback = void Function(ThongBaoItem? item);

/// Poll API → hiện **thông báo hệ thống** khi có phân công mới.
/// Sau khi NVKT bấm Tiến hành (ngoài app hoặc trong app) → đánh dấu đã xử lý,
/// không hiện lại thông báo đó nữa.
class ThongBaoRealtimeService {
  ThongBaoRealtimeService._();
  static final instance = ThongBaoRealtimeService._();

  static const actionTienHanh = 'tien_hanh';
  static const _keyDaXuLy = 'thong_bao_da_xu_ly_ids';

  final _plugin = FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();
  Timer? _timer;
  final Set<int> _daHienLocal = {};
  final Set<int> _daXuLyLocal = {};
  final Map<int, ThongBaoItem> _cacheById = {};
  bool _ready = false;
  ThongBaoTapCallback? onTap;

  Future<void> init({ThongBaoTapCallback? onTap}) async {
    this.onTap = onTap;
    await _taiDaXuLyLocal();
    if (_ready) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _xuLyBamThongBao,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse != null) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _xuLyBamThongBao(launch!.notificationResponse!);
      });
    }

    _ready = true;
  }

  Future<void> _taiDaXuLyLocal() async {
    final raw = await _storage.read(key: _keyDaXuLy);
    if (raw == null || raw.isEmpty) return;
    for (final p in raw.split(',')) {
      final id = int.tryParse(p.trim());
      if (id != null) _daXuLyLocal.add(id);
    }
  }

  Future<void> _luuDaXuLyLocal() async {
    await _storage.write(
      key: _keyDaXuLy,
      value: _daXuLyLocal.join(','),
    );
  }

  void _xuLyBamThongBao(NotificationResponse resp) {
    final id = int.tryParse(resp.payload ?? '');
    final item = id == null ? null : _cacheById[id];
    onTap?.call(item);
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => refresh());
    refresh();
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    if (!await TokenStorage.daDangNhap()) return;
    try {
      final data = await ApiClient.instance.get<List<dynamic>>(
        ApiConstants.thongBao,
      );
      final list = data
          .whereType<Map>()
          .map((e) => ThongBaoItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      for (final tb in list) {
        _cacheById[tb.maThongBao] = tb;
        // Đồng bộ: đã đọc trên server → coi như đã xử lý local
        if (tb.daDoc) {
          _daXuLyLocal.add(tb.maThongBao);
          _daHienLocal.add(tb.maThongBao);
          await _plugin.cancel(tb.maThongBao);
        }
      }
      await _luuDaXuLyLocal();

      // Chỉ hiện TB chưa đọc + chưa từng xử lý/tiến hành
      for (final tb in list.where((e) => !e.daDoc)) {
        if (_daHienLocal.contains(tb.maThongBao)) continue;
        if (_daXuLyLocal.contains(tb.maThongBao)) continue;
        _daHienLocal.add(tb.maThongBao);
        await _hienThongBaoNgoaiApp(tb);
      }
    } catch (e) {
      debugPrint('ThongBao poll: $e');
    }
  }

  Future<void> _hienThongBaoNgoaiApp(ThongBaoItem tb) async {
    if (!_ready) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'opc_phan_cong',
        'Phân công công việc',
        channelDescription:
        'Thông báo khi được phân công bảo trì / sửa chữa',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF0068A9),
        styleInformation: BigTextStyleInformation(tb.noiDung),
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            actionTienHanh,
            'Tiến hành',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      tb.maThongBao,
      tb.tieuDe,
      tb.noiDung,
      details,
      payload: '${tb.maThongBao}',
    );
  }

  /// Đánh dấu 1 thông báo đã xử lý (bấm Tiến hành trên notification).
  Future<void> danhDauDaDoc(int ma) async {
    _daXuLyLocal.add(ma);
    _daHienLocal.add(ma);
    await _luuDaXuLyLocal();
    await _plugin.cancel(ma);
    try {
      await ApiClient.instance.put<Map<String, dynamic>>(
        '${ApiConstants.thongBao}/$ma/da-doc',
        {},
      );
    } catch (_) {}
  }

  /// Đánh dấu mọi TB gắn hồ sơ sau khi bấm «Tiến hành quy trình» trong app.
  Future<void> danhDauTheoHoSo({
    int? maHoSoBaoTri,
    int? maHoSoSuaChua,
  }) async {
    for (final e in _cacheById.values) {
      final matchBt =
          maHoSoBaoTri != null && e.maHoSoBaoTri == maHoSoBaoTri;
      final matchSc =
          maHoSoSuaChua != null && e.maHoSoSuaChua == maHoSoSuaChua;
      if (matchBt || matchSc) {
        _daXuLyLocal.add(e.maThongBao);
        _daHienLocal.add(e.maThongBao);
        await _plugin.cancel(e.maThongBao);
      }
    }
    await _luuDaXuLyLocal();

    try {
      final parts = <String>[];
      if (maHoSoBaoTri != null) parts.add('maHoSoBaoTri=$maHoSoBaoTri');
      if (maHoSoSuaChua != null) parts.add('maHoSoSuaChua=$maHoSoSuaChua');
      final qs = parts.isEmpty ? '' : '?${parts.join('&')}';
      await ApiClient.instance.put<Map<String, dynamic>>(
        '${ApiConstants.thongBao}/da-doc-theo-ho-so$qs',
        {},
      );
    } catch (e) {
      debugPrint('danhDauTheoHoSo: $e');
    }
  }
}