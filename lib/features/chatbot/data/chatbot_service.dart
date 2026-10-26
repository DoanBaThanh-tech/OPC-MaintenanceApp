import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/token_storage.dart';

class ChatTinNhan {
  final String role; // user | assistant
  final String content;
  final DateTime luc;

  ChatTinNhan({
    required this.role,
    required this.content,
    DateTime? luc,
  }) : luc = luc ?? DateTime.now();

  bool get laBot => role == 'assistant';
}

class ChatbotService {
  ChatbotService._();
  static final instance = ChatbotService._();

  Future<({bool online, String? model, String? message})> kiemTra() async {
    final data = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.aiTrangThai,
    );
    return (
    online: data['online'] == true,
    model: data['model']?.toString(),
    message: data['message']?.toString(),
    );
  }

  Future<String> guiTinNhan({
    required String cauHoi,
    required List<ChatTinNhan> lichSu,
  }) async {
    final hoTen = await TokenStorage.getHoTen();
    final body = <String, dynamic>{
      'cauHoi': cauHoi,
      if (hoTen != null && hoTen.trim().isNotEmpty) 'hoTen': hoTen.trim(),
      'lichSu': lichSu
          .map((e) => {
        'role': e.role,
        'content': e.content,
      })
          .toList(),
    };
    // OPC Intent Engine — thường < 2s
    final data = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.aiChat,
      body,
      timeout: const Duration(seconds: 20),
    );
    final traLoi = data['traLoi']?.toString();
    if (traLoi == null || traLoi.isEmpty) {
      throw Exception('AI không trả lời.');
    }
    return traLoi;
  }
}