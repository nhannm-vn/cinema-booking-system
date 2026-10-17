import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/conversation_model.dart';
import '../../repositories/management_repository.dart';

class ManagerConversationsScreen extends StatelessWidget {
  const ManagerConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    final repo = ManagementRepository();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'HỘP THƯ HỖ TRỢ (CSKH)',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: StreamBuilder<List<CinemaConversation>>(
        stream: repo.getConversationsStream(cid),
        builder: (context, snapshot) {
          final conversations = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting &&
              conversations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (conversations.isEmpty) {
            return EmptyState(
              icon: LucideIcons.messageSquare,
              title: 'Chưa có yêu cầu hỗ trợ',
              message:
                  'Khi khách hàng gửi tin nhắn CSKH tới rạp $cid, các cuộc hội thoại sẽ hiển thị tại đây.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xs),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xxs),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ConversationChatDetailScreen(
                        conversation: conv,
                        actor: user,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.canvasElevated,
                    border: Border(
                      bottom: BorderSide(color: AppColors.hairline, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        color: AppColors.canvas,
                        child: const Icon(LucideIcons.user,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  conv.customerName,
                                  style: AppTextStyles.titleSm.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm dd/MM')
                                      .format(conv.lastMessageAt),
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              conv.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm
                                  .copyWith(color: AppColors.body),
                            ),
                            if (conv.bookingCode != null) ...[
                              const SizedBox(height: 4),
                              AppBadge(
                                text: 'ĐƠN #${conv.bookingCode}',
                                variant: AppBadgeVariant.neutral,
                                fontSize: 8,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.chevronRight,
                          size: 16, color: AppColors.muted),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationChatDetailScreen extends StatefulWidget {
  const _ConversationChatDetailScreen({
    required this.conversation,
    required this.actor,
  });

  final CinemaConversation conversation;
  final AppUser actor;

  @override
  State<_ConversationChatDetailScreen> createState() =>
      _ConversationChatDetailScreenState();
}

class _ConversationChatDetailScreenState
    extends State<_ConversationChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ManagementRepository _repo = ManagementRepository();
  bool _isSending = false;

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    setState(() => _isSending = true);
    await _repo.sendSupportMessage(
      conversationId: widget.conversation.id,
      text: text,
      sender: widget.actor,
    );
    if (mounted) setState(() => _isSending = false);
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
              widget.conversation.customerName,
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
            if (widget.conversation.bookingCode != null)
              Text(
                'MÃ ĐƠN: #${widget.conversation.bookingCode}',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessageItem>>(
              stream: _repo.getMessagesStream(widget.conversation.id),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bắt đầu cuộc hội thoại hỗ trợ khách hàng',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == widget.actor.uid ||
                        msg.senderRole == 'manager' ||
                        msg.senderRole == 'staff';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primary
                              : AppColors.canvasElevated,
                          border: Border.all(
                            color: isMe
                                ? AppColors.primary
                                : AppColors.hairline,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: AppTextStyles.bodySm.copyWith(
                                color: isMe
                                    ? AppColors.onPrimary
                                    : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(msg.createdAt),
                              style: AppTextStyles.caption.copyWith(
                                color: isMe
                                    ? AppColors.onPrimary.withValues(alpha: 0.7)
                                    : AppColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            color: AppColors.canvasElevated,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style:
                        AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn phản hồi khách...',
                      hintStyle: TextStyle(color: AppColors.muted),
                      filled: true,
                      fillColor: AppColors.canvas,
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.zero),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                IconButton(
                  icon: const Icon(LucideIcons.send, color: AppColors.primary),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

