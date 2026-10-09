import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../work_order/presentation/work_order_detail_screen.dart';
import '../../work_order/presentation/work_order_repair_screens.dart';
import '../data/thong_bao_models.dart';
import '../data/thong_bao_service.dart';

class ManThongBaoScreen extends StatefulWidget {
  const ManThongBaoScreen({super.key});

  @override
  State<ManThongBaoScreen> createState() => _ManThongBaoScreenState();
}

class _ManThongBaoScreenState extends State<ManThongBaoScreen>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF0068A9);
  static const _sky = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF0F7FC);

  late final AnimationController _enter;
  List<ThongBaoItem> _list = [];

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    ThongBaoRealtimeService.instance.stream.listen((e) {
      if (mounted) setState(() => _list = e);
    });
    ThongBaoRealtimeService.instance.refresh();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Future<void> _tienHanh(ThongBaoItem tb) async {
    HapticFeedback.lightImpact();
    await ThongBaoRealtimeService.instance.danhDauDaDoc(tb.maThongBao);
    if (!mounted) return;
    if (tb.maHoSoBaoTri != null && tb.maHoSoBaoTri! > 0) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WorkOrderBaoTriDetailScreen(maHoSoBaoTri: tb.maHoSoBaoTri!),
        ),
      );
    } else if (tb.maHoSoSuaChua != null && tb.maHoSoSuaChua! > 0) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChiTietHoSoSuaChuaScreen(maHoSo: tb.maHoSoSuaChua!),
        ),
      );
    }
    await ThongBaoRealtimeService.instance.refresh();
  }

  String _fmtTime(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(fade);
    final chuaDoc = _list.where((e) => !e.daDoc).length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Thông báo',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (chuaDoc > 0)
            TextButton(
              onPressed: () => ThongBaoRealtimeService.instance.danhDauTatCa(),
              child: const Text('Đọc tất cả',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: RefreshIndicator(
            color: _blue,
            onRefresh: () => ThongBaoRealtimeService.instance.refresh(),
            child: _list.isEmpty
                ? ListView(
              children: [
                SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.25),
                Icon(Icons.notifications_none_rounded,
                    size: 72, color: _blue.withValues(alpha: 0.35)),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Chưa có thông báo',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B)),
                  ),
                ),
              ],
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              itemCount: _list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final tb = _list[i];
                final accent = tb.isSuaChua
                    ? const Color(0xFFEA580C)
                    : _blue;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    color: tb.daDoc
                        ? Colors.white
                        : accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: tb.daDoc
                          ? Colors.grey.shade200
                          : accent.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent,
                                  accent.withValues(alpha: 0.75),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              tb.isSuaChua
                                  ? Icons.handyman_rounded
                                  : Icons.build_circle_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tb.tieuDe,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    if (!tb.daDoc)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tb.noiDung,
                                  style: TextStyle(
                                    fontSize: 13.2,
                                    height: 1.35,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _fmtTime(tb.ngayTao),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [accent, _sky],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _tienHanh(tb),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded,
                                size: 22),
                            label: const Text(
                              'Tiến hành',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}