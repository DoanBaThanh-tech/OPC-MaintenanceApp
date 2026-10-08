part of quy_trinh_nvkt_screen;

/// Trang quy trình BT/SC — NVKT tự tạo bước + vật tư (đơn giá chỉ đọc) + nội dung CV.
/// Xong → Chờ xác nhận Xưởng. Có thể cập nhật lại khi Xưởng từ chối.
class QuyTrinhNvktScreen extends StatefulWidget {
  final YeuCauPhanCong yeuCau;

  const QuyTrinhNvktScreen({super.key, required this.yeuCau});

  @override
  State<QuyTrinhNvktScreen> createState() => _QuyTrinhNvktScreenState();
}

class _QuyTrinhNvktScreenState extends State<QuyTrinhNvktScreen>
    with _XuLyQuyTrinhNvkt, _XuLyVatTuVaHoanThanhNvkt, _GiaoDienTheBuocNvkt
with TickerProviderStateMixin {

final List<_BuocState> _buoc = [];
List<VatTuOption> _dsVatTu = [];
final _noiDungCtrl = TextEditingController();
bool _dangTai = true;
bool _dangXuLy = false;
String? _loi;
int? _maHoSoVatTu;
String? _tenToi;
Timer? _pollTimer;

late final AnimationController _headerAnim;
late final AnimationController _pulseAnim;

bool get _laBaoTri => widget.yeuCau.laBaoTri;
bool get _cheDoCapNhat => widget.yeuCau.biTuChoi;

bool _coTheSuaVatTu(_BuocState b) => QuyTrinhNvktRules.coTheSuaVatTu(
  daChon: b.daChon,
  daXong: b.daXong,
  khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
  cheDoCapNhat: _cheDoCapNhat,
  dangXuLy: _dangXuLy,
  daLuuDieuChinh: b.daLuuDieuChinh,
  dangMoCapNhat: b.dangMoCapNhat,
);

@override
void initState() {
  super.initState();
  _headerAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  )..forward();
  _pulseAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  _tai();
  // Không poll realtime — reload trang là thấy bước người khác đã làm
}

@override
void dispose() {
  _pollTimer?.cancel();
  _headerAnim.dispose();
  _pulseAnim.dispose();
  _noiDungCtrl.dispose();
  for (final b in _buoc) {
    b.dispose();
  }
  super.dispose();
}

Widget build(BuildContext context) {
  final title = _cheDoCapNhat
      ? 'Cập nhật quy trình'
      : (_laBaoTri ? 'Quy trình bảo trì' : 'Quy trình sửa chữa');
  final top = MediaQuery.paddingOf(context).top;

  return Scaffold(
    backgroundColor: _bg,
    body: Column(
      children: [
        // ===== HEADER =====
        FadeTransition(
          opacity: CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: _headerAnim, curve: Curves.easeOutCubic)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(8, top + 6, 16, 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_blue, _blueMid, _blueSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: _blue.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) {
                          final s = 0.92 + 0.08 * _pulseAnim.value;
                          return Transform.scale(
                            scale: s,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                '${_buoc.length} bước',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.precision_manufacturing_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.yeuCau.tenThietBi ?? 'Thiết bị',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_cheDoCapNhat)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 10, right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Xưởng đã từ chối — chỉnh bước / vật tư rồi gửi lại',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ===== BODY =====
        Expanded(
          child: _dangTai
              ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                      color: _blue, strokeWidth: 3),
                ),
                SizedBox(height: 14),
                Text('Đang tải quy trình…',
                    style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          )
              : _loi != null
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(_loi!, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _tai,
                    style: FilledButton.styleFrom(
                        backgroundColor: _blue),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          )
              : ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              // Hint card
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - t)),
                    child: child,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _blue.withValues(alpha: 0.08),
                        _blueSoft.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _blue.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _blue.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.tips_and_updates_rounded,
                            color: _blue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tự thêm bước & vật tư. Đơn giá lấy từ hệ thống (không sửa). '
                              'Không bắt buộc làm đủ mọi bước khi bấm Xong.',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Steps
              ...List.generate(
                _buoc.length,
                    (i) => _buildBuocCard(i),
              ),

              const SizedBox(height: 4),
              // Bước lấy từ quy trình thiết bị — không thêm thủ công
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blue.withValues(alpha: 0.15)),
                ),
                child: const Text(
                  'Tích chọn bước cần làm → chọn vật tư (đã chọn sẽ ẩn trong bước) → bấm Xong từng bước. Không bắt buộc đủ mọi bước.',
                  style: TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 22),
              const Text(
                'Nội dung công việc',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _noiDungCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                    'Mô tả công việc đã làm / ghi chú gửi Xưởng…',
                    hintStyle:
                    TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ===== BOTTOM: Tổng tiền + Hoàn thành quy trình =====
        if (!_dangTai && _loi == null)
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_rounded,
                          color: Color(0xFF059669), size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Tổng tiền vật tư',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                      Text(
                        _fmtTien(_tinhTongTien()),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [_blue, _blueMid, _blueSoft],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _dangXuLy ? null : _xong,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: _dangXuLy
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white),
                          )
                              : Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 22),
                              const SizedBox(width: 10),
                              Text(
                                _cheDoCapNhat
                                    ? 'Lưu & gửi lại Xưởng'
                                    : 'Hoàn thành quy trình',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
}