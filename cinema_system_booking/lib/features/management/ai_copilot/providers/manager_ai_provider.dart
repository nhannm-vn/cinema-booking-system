import 'package:flutter/foundation.dart';
import '../models/manager_ai_message.dart';
import '../services/manager_ai_service.dart';

class ManagerAiProvider extends ChangeNotifier {
  ManagerAiProvider({
    ManagerAiService? aiService,
  }) : _aiService = aiService ?? ManagerAiService() {
    _initWelcomeMessage();
  }

  final ManagerAiService _aiService;
  final List<ManagerAiMessage> _messages = [];
  bool _isLoading = false;
  String? _currentError;

  List<ManagerAiMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get currentError => _currentError;
  String get apiKey => _aiService.currentApiKey;

  final List<AiPromptTemplate> promptTemplates = const [
    AiPromptTemplate(
      title: 'Phân công ca trực hôm nay',
      prompt:
          'Dựa vào danh sách nhân viên và các suất chiếu hôm nay của rạp, hãy lập bảng phân chia công việc chi tiết (Soát vé, Quầy F&B, Vệ sinh rạp) và cung cấp mẫu tin nhắn để gửi cho nhóm nhân sự.',
      category: 'Phân việc',
      iconName: 'users',
    ),
    AiPromptTemplate(
      title: 'Checklist vệ sinh 15 phút',
      prompt:
          'Hướng dẫn quy trình và checklist vệ sinh phòng chiếu trong 15 phút giãn cách giữa 2 suất chiếu để đảm bảo phòng sạch sẽ và đúng giờ chiếu tiếp theo.',
      category: 'Vận hành',
      iconName: 'sparkles',
    ),
    AiPromptTemplate(
      title: 'Tối ưu bán bắp nước F&B',
      prompt:
          'Gợi ý các kịch bản up-sell/cross-sell combo bắp nước hiệu quả cho nhân viên quầy đối với các suất chiếu phim hot hôm nay để tăng doanh thu.',
      category: 'Doanh thu',
      iconName: 'utensils',
    ),
    AiPromptTemplate(
      title: 'Xử lý khiếu nại của khách',
      prompt:
          'Khách hàng khiếu nại phòng chiếu quá lạnh và bắp nước bị ỉu, hướng dẫn nhân viên và quản lý các bước xử lý hòa nhã, lịch sự và phương án đền bù thỏa đáng.',
      category: 'CSKH',
      iconName: 'messageSquare',
    ),
    AiPromptTemplate(
      title: 'Kiểm tra độ tuổi xem phim',
      prompt:
          'Quy định pháp luật và quy trình cho nhân viên soát vé khi kiểm tra độ tuổi đối với phim phân loại T18/T16/T13, cách từ chối lịch sự nếu khách không đủ tuổi.',
      category: 'Quy chuẩn',
      iconName: 'shieldAlert',
    ),
    AiPromptTemplate(
      title: 'Xử lý sự cố máy chiếu',
      prompt:
          'Quy trình ứng phó khẩn cấp khi máy chiếu gặp sự cố kỹ thuật gián đoạn suất chiếu: thông báo tại phòng, hoàn tiền hoặc tặng voucher đổi vé cho khách.',
      category: 'Khẩn cấp',
      iconName: 'alertTriangle',
    ),
  ];

  void _initWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(
        ManagerAiMessage(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          text:
              'Xin chào Quản lý! Tôi là **CineManager AI Copilot** 🎬.\n\nTôi được tích hợp trí tuệ nhân tạo Gemini để hỗ trợ bạn trong việc:\n* 👥 **Phân công ca trực & vị trí làm việc** cho nhân viên chi nhánh.\n* 🧹 **Lập kế hoạch dọn rạp** trong 15 phút giãn cách giữa các suất.\n* 🍿 **Tư vấn chiến lược bán combo F&B** và tăng doanh thu.\n* ⚠️ **Xử lý sự cố vận hành**, giải quyết khiếu nại khách hàng theo chuẩn SOP.\n\nHãy chọn một chủ đề gợi ý bên dưới hoặc đặt câu hỏi trực tiếp cho tôi!',
          isUser: false,
          timestamp: DateTime.now(),
          actionSuggestions: [
            'Phân công ca trực hôm nay',
            'Checklist vệ sinh 15 phút',
            'Tối ưu bán bắp nước F&B',
          ],
        ),
      );
    }
  }

  Future<void> sendMessage(String text,
      {required CinemaAiContext context}) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isLoading) return;

    final userMessage = ManagerAiMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmedText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isLoading = true;
    _currentError = null;
    notifyListeners();

    try {
      final aiResponse = await _aiService.generateResponse(
        conversationHistory: _messages,
        latestUserPrompt: trimmedText,
        context: context,
      );

      final suggestions = _extractSuggestions(aiResponse);

      final botMessage = ManagerAiMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        actionSuggestions: suggestions,
      );

      _messages.add(botMessage);
    } catch (e) {
      _currentError = e.toString().replaceFirst('Exception: ', '');
      _messages.add(
        ManagerAiMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          text:
              '⚠️ Không thể hoàn thành phản hồi: $_currentError\n\nVui lòng kiểm tra lại kết nối mạng hoặc thử lại với yêu cầu khác.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String>? _extractSuggestions(String text) {
    final lower = text.toLowerCase();
    final suggestions = <String>[];

    if (lower.contains('phân công') || lower.contains('ca trực')) {
      suggestions.add('Sao chép thông báo gửi Staff');
    }
    if (lower.contains('vệ sinh') || lower.contains('checklist')) {
      suggestions.add('In checklist kiểm tra');
    }
    if (lower.contains('khiếu nại') || lower.contains('đổi vé')) {
      suggestions.add('Mở danh sách Bookings');
    }
    if (lower.contains('bắp nước') || lower.contains('combo')) {
      suggestions.add('Xem danh mục đồ ăn');
    }

    return suggestions.isNotEmpty ? suggestions : null;
  }

  void clearConversation() {
    _messages.clear();
    _currentError = null;
    _initWelcomeMessage();
    notifyListeners();
  }

  void updateApiKey(String newKey) {
    _aiService.updateApiKey(newKey);
    notifyListeners();
  }
}

