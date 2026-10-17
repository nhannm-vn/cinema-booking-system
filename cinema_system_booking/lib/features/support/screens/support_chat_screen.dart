import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../booking/providers/booking_provider.dart';

class SupportChatMessage {
  const SupportChatMessage({
    required this.id,
    required this.isCustomer,
    required this.text,
    this.attachedBookingId,
    required this.timestamp,
  });

  final String id;
  final bool isCustomer;
  final String text;
  final String? attachedBookingId;
  final DateTime timestamp;
}

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({
    super.key,
    this.initialBookingId,
  });

  final String? initialBookingId;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCinema = 'Cinema Flagship Q.1';
  String? _pinnedBookingCode;

  final List<SupportChatMessage> _messages = [
    SupportChatMessage(
      id: 'msg_0',
      isCustomer: false,
      text:
          'Xin chào quý khách! Trung tâm CSKH Cinema hân hạnh được hỗ trợ. Bạn đang cần giải đáp về đặt vé, lịch chiếu hay quy định rạp nào ạ?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pinnedBookingCode = widget.initialBookingId;
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({String? customText, String? bookingId}) {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty && bookingId == null) return;

    final customerMsg = SupportChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      isCustomer: true,
      text: text,
      attachedBookingId: bookingId ?? _pinnedBookingCode,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(customerMsg);
      if (customText == null) _textController.clear();
      _pinnedBookingCode = null;
    });
    _scrollToBottom();

    // Auto smart response for common questions
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      String reply = 'Cảm ơn bạn đã liên hệ! Chuyên viên CSKH tại $_selectedCinema sẽ phản hồi chi tiết trong giây lát.';

      final lower = text.toLowerCase();
      if (lower.contains('hủy') || lower.contains('đổi vé')) {
        reply =
            'Chính sách hủy vé: Khán giả được hủy vé trực tuyến trước giờ chiếu tối thiểu 2 giờ. Vui lòng vào tab "VÉ CỦA TÔI", chọn vé cần hủy và bấm "HỦY VÉ NÀY".';
      } else if (lower.contains('độ tuổi') || lower.contains('t16') || lower.contains('t18')) {
        reply =
            'Quy định độ tuổi: Khán giả xem phim nhãn T13, T16, T18 vui lòng mang theo CCCD/VNeID để nhân viên soát vé kiểm tra trước khi vào phòng chiếu.';
      } else if (lower.contains('đồ ăn') || lower.contains('bắp')) {
        reply =
            'Rạp không áp dụng mang đồ ăn bên ngoài vào phòng chiếu. Bạn có thể đặt trước các combo bắp phô mai và nước ngọt ngay trong app để nhận tại quầy nhé!';
      } else if (bookingId != null || lower.contains('mã booking') || lower.contains('dn88')) {
        reply =
            'Hệ thống đã ghi nhận đơn đặt vé [${bookingId ?? "DN8872KP"}]. Vé của bạn đã thanh toán thành công và có hiệu lực. Bạn chỉ cần mở mã QR tại tab "VÉ CỦA TÔI" khi tới rạp.';
      }

      setState(() {
        _messages.add(
          SupportChatMessage(
            id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
            isCustomer: false,
            text: reply,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _showAttachBookingPicker() {
    final bookings = context.read<BookingProvider>().userBookings;
    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa có đơn đặt vé nào để đính kèm')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHỌN ĐƠN VÉ ĐÍNH KÈM',
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            ...bookings.take(3).map((b) {
              return ListTile(
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _pinnedBookingCode = b.id);
                  _sendMessage(
                    customText: 'Tôi cần hỗ trợ về đơn đặt vé mã [${b.id}] (${b.movieTitle})',
                    bookingId: b.id,
                  );
                },
                leading: const Icon(LucideIcons.ticket, color: AppColors.primary),
                title: Text(
                  '${b.id} · ${b.movieTitle}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${b.cinemaName} · Ghế: ${b.seatIds.join(", ")}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HỖ TRỢ TRỰC TUYẾN',
              style: AppTextStyles.titleSm.copyWith(
                color: AppColors.ink,
                letterSpacing: 1.2,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$_selectedCinema · Trực tuyến',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.building, size: 20, color: AppColors.ink),
            tooltip: 'Chọn cụm rạp hỗ trợ',
            color: AppColors.canvasElevated,
            onSelected: (val) => setState(() => _selectedCinema = val),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'Cinema Flagship Q.1',
                child: Text('Cinema Flagship Quận 1', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 'Cinema Tân Bình Hub',
                child: Text('Cinema Tân Bình Hub', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. QUICK FAQ TOPIC CHIPS
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            color: AppColors.canvasElevated,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickChip('Quy định đổi/hủy vé'),
                _buildQuickChip('Quy định độ tuổi T16/T18'),
                _buildQuickChip('Đồ ăn mang vào rạp'),
                _buildQuickChip('Kiểm tra mã booking'),
              ],
            ),
          ),

          // 2. CHAT MESSAGES STREAM
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // 3. PINNED BOOKING INDICATOR
          if (_pinnedBookingCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.canvasElevated,
              child: Row(
                children: [
                  const Icon(LucideIcons.paperclip, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Đang đính kèm mã vé: $_pinnedBookingCode',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _pinnedBookingCode = null),
                    child: const Icon(LucideIcons.x, size: 14, color: AppColors.muted),
                  ),
                ],
              ),
            ),

          // 4. INPUT BAR
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: const BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Attach Booking Button
                  IconButton(
                    tooltip: 'Đính kèm vé cần hỏi',
                    icon: const Icon(LucideIcons.ticket, color: AppColors.muted),
                    onPressed: _showAttachBookingPicker,
                  ),

                  // Text Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: AppRadius.none,
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'Nhập câu hỏi của bạn...',
                          hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Send Button
                  Material(
                    color: AppColors.primary,
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
                    child: InkWell(
                      onTap: () => _sendMessage(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(LucideIcons.send, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 7, bottom: 7),
      child: ActionChip(
        backgroundColor: AppColors.canvas,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.none,
          side: BorderSide(color: AppColors.hairline),
        ),
        label: Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 11),
        ),
        onPressed: () => _sendMessage(customText: label),
      ),
    );
  }

  Widget _buildMessageBubble(SupportChatMessage msg) {
    final isMe = msg.isCustomer;
    final timeStr = DateFormatter.timeOnly(msg.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.none,
              ),
              child: const Icon(LucideIcons.headset, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2C2C2C) : AppColors.canvasElevated,
                border: Border.all(
                  color: isMe ? AppColors.primary : AppColors.hairline,
                  width: 1,
                ),
                borderRadius: AppRadius.none,
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (msg.attachedBookingId != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 6),
                      color: AppColors.canvas,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.ticket, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'MÃ VÉ: ${msg.attachedBookingId}',
                            style: AppTextStyles.captionUppercase.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    msg.text,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.ink,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 12),
        ],
      ),
    );
  }
}
