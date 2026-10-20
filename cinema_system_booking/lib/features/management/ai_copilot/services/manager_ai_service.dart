import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manager_ai_message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ManagerAiService {
  ManagerAiService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey ?? defaultApiKey,
        _client = client ?? http.Client();

  // Đọc key từ môi trường:
  static String get defaultApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Danh sách các model hoàn toàn FREE, phản hồi nhanh & ổn định nhất:
  static const List<String> availableModels = [
    'gemini-3.5-flash-lite',
    'gemini-2.5-flash'
  ];

  String _apiKey;
  final http.Client _client;

  String get currentApiKey => _apiKey;

  void updateApiKey(String newKey) {
    if (newKey.trim().isNotEmpty) {
      _apiKey = newKey.trim();
    }
  }

  String _buildSystemPrompt(CinemaAiContext context) {
    return '''
Bạn là Trợ lý AI hỗ trợ Quản lý rạp chiếu phim (${context.cinemaName}).
Quản lý trực: ${context.managerName}.
Nhân viên chi nhánh: ${context.staffList.isEmpty ? "Chưa có staff cụ thể (hãy phân bổ theo vị trí tổng quát)" : context.staffList.map((s) => s.fullName).join(", ")}.

YÊU CẦU TRẢ LỜI:
- Trả lời NGẮN GỌN, RÕ RÀNG, DỄ HIỂU (tối đa 150 từ), đi thẳng vào giải pháp.
- Dùng gạch đầu dòng và in đậm để Quản lý dễ đọc nhanh.
- Nếu được yêu cầu phân việc: chỉ định rõ nhân viên làm việc gì (Soát vé, Quầy bắp nước F&B, Vệ sinh rạp 15 phút, Kỹ thuật).
- Nếu được hỏi về sự cố/khiếu nại: đưa ra 3 bước xử lý nhanh, bình tĩnh và lịch sự.
''';
  }

  Future<String> generateResponse({
    required List<ManagerAiMessage> conversationHistory,
    required String latestUserPrompt,
    required CinemaAiContext context,
  }) async {
    final systemPrompt = _buildSystemPrompt(context);

    // Build payload messages
    final contents = <Map<String, dynamic>>[];

    // Lấy 6 tin nhắn gần nhất
    final recentHistory = conversationHistory.length > 6
        ? conversationHistory.sublist(conversationHistory.length - 6)
        : conversationHistory;

    for (final msg in recentHistory) {
      if (msg.isError) continue;
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ],
      });
    }

    // Thêm prompt hiện tại của user
    contents.add({
      'role': 'user',
      'parts': [
        {'text': latestUserPrompt}
      ],
    });

    // Thử model chính, nếu lỗi sẽ tự động thử model tiếp theo
    Exception? lastException;
    for (final modelName in availableModels) {
      try {
        final reply = await _sendApiRequest(
          modelName: modelName,
          systemPrompt: systemPrompt,
          contents: contents,
        );
        if (reply != null && reply.trim().isNotEmpty) {
          return reply.trim();
        }
      } catch (e) {
        lastException = Exception('Model $modelName error: $e');
      }
    }

    throw lastException ??
        Exception('Không thể kết nối đến máy chủ AI. Vui lòng thử lại sau.');
  }

  Future<String?> _sendApiRequest({
    required String modelName,
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
  }) async {
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_apiKey');

    final requestBody = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    });

    // Tăng timeout lên 40s để tránh bị gián đoạn khi mạng chậm
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(const Duration(seconds: 40));

    if (response.statusCode != 200) {
      String errorMessage = 'Lỗi máy chủ AI (${response.statusCode})';
      try {
        final errorJson = jsonDecode(response.body);
        final msg = errorJson['error']?['message'] as String?;
        if (msg != null && msg.isNotEmpty) {
          errorMessage = msg;
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return null;
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      return null;
    }

    final text = parts[0]['text'] as String?;
    return text;
  }
}
