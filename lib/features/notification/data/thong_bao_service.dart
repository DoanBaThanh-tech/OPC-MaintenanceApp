import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/token_storage.dart';
import 'thong_bao_models.dart';

typedef ThongBaoTapCallback = void Function(ThongBaoItem item);

/// Poll API ~12s — realtime gần; chỉ user đăng nhập thấy TB của mình.
class ThongBaoRealtimeService {
  ThongBaoRealtimeService._();
  static final instance = ThongBaoRealtimeService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _controller = StreamController<List<ThongBaoItem>>.broadcast();
  Stream<List<ThongBaoItem>> get stream => _controller.stream;

  Timer? _timer;
  final Set<int> _daHienLocal = {};
  List<ThongBaoItem> _cache = [];
  bool _ready = false;
  ThongBaoTapCallback? onTap;

  Future<void> init({ThongBaoTapCallback? onTap}) async {
    this.onTap = onTap;
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) {
        final id = int.tryParse(resp.payload ?? '');
        if (id == null) return;
        for (final e in _cache) {
          if (e.maThongBao == id) {
            this.onTap?.call(e);
            break;
          }
        }
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
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
      _cache = list;
      if (!_controller.isClosed) _controller.add(list);

      for (final tb in list.where((e) => !e.daDoc)) {
        if (_daHienLocal.contains(tb.maThongBao)) continue;
        _daHienLocal.add(tb.maThongBao);
        await _hienLocal(tb);
      }
    } catch (e) {
      debugPrint('ThongBao poll: $e');
    }
  }

  Future<void> _hienLocal(ThongBaoItem tb) async {
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
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(
      tb.maThongBao,
      tb.tieuDe,
      tb.noiDung,
      details,
      payload: '${tb.maThongBao}',
    );
  }

  Future<void> danhDauDaDoc(int ma) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.thongBao}/$ma/da-doc',
      {},
    );
    await refresh();
  }

  Future<void> danhDauTatCa() async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.thongBao}/da-doc-tat-ca',
      {},
    );
    await refresh();
  }
}