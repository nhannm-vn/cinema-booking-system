import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../foods/screens/manager_foods_screen.dart';
import '../../orders/screens/manager_bookings_screen.dart';
import '../../providers/management_provider.dart';
import '../models/manager_ai_message.dart';
import '../providers/manager_ai_provider.dart';

class ManagerAiScreen extends StatefulWidget {
  const ManagerAiScreen({super.key});

  @override
  State<ManagerAiScreen> createState() => _ManagerAiScreenState();
}

class _ManagerAiScreenState extends State<ManagerAiScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isContextExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBranchData();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadBranchData() {
    final user = context.read<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    final prov = context.read<ManagementProvider>();
    prov.loadDashboard(cid);
    prov.loadStaff(cid);
    prov.loadShowtimes(cid);
    prov.loadFoods(cid);
  }

  CinemaAiContext _buildCurrentContext() {
    final user = context.read<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    final prov = context.read<ManagementProvider>();

    String cinemaName = 'Cinestar Quốc Thanh (Q1)';
    switch (cid.toLowerCase()) {
      case 'cn_q1':
        cinemaName = 'Cinestar Quốc Thanh (Q1)';
        break;
      case 'cn_q3':
        cinemaName = 'Cinestar Hai Bà Trưng (Q3)';
        break;
      case 'cn_bt':
        cinemaName = 'Cinestar Bình Thạnh';
        break;
      case 'cn_td':
        cinemaName = 'Cinestar Thủ Đức';
        break;
      default:
        cinemaName = 'Cinestar ${cid.toUpperCase()}';
    }

    return CinemaAiContext(
      cinemaId: cid,
      cinemaName: cinemaName,
      managerName: user.fullName,
      staffList: prov.staffList,
      showtimes: prov.showtimes,
      foodList: prov.foodList,
      dashboardStats: prov.dashboardStats,
    );
  }

  void _sendMessage([String? predefinedText]) {
    final text = predefinedText ?? _textController.text;
    if (text.trim().isEmpty) return;

    final aiProv = context.read<ManagerAiProvider>();
    if (aiProv.isLoading) return;

    final ctx = _buildCurrentContext();
    aiProv.sendMessage(text, context: ctx);

    if (predefinedText == null) {
      _textController.clear();
    }

    _scrollToBottom();
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép nội dung vào bộ nhớ tạm'),
        backgroundColor: AppColors.canvasElevated,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showApiKeyDialog() {
    final aiProv = context.read<ManagerAiProvider>();
    final keyController = TextEditingController(text: aiProv.apiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            const Icon(LucideIcons.key, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'CẤU HÌNH GEMINI API KEY',
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hệ thống đang sử dụng Google Gemini 3.8 Flash cho trợ lý quản lý. Bạn có thể cập nhật key dự phòng nếu cần:',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: keyController,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppColors.canvas,
                hintText: 'Nhập Gemini API Key...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'HỦY',
              style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () {
              if (keyController.text.trim().isNotEmpty) {
                aiProv.updateApiKey(keyController.text.trim());
              }
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã cập nhật Gemini API Key thành công!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(
              'LƯU CẤU HÌNH',
              style: AppTextStyles.captionUppercase.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'LÀM MỚI ĐOẠN HỘI THOẠI?',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Lịch sử tư vấn hiện tại sẽ được xóa và đặt lại về trạng thái ban đầu.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'HỦY',
              style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () {
              context.read<ManagerAiProvider>().clearConversation();
              Navigator.of(ctx).pop();
            },
            child: Text(
              'XÓA HỘI THOẠI',
              style: AppTextStyles.captionUppercase.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<ManagerAiProvider>();
    final messages = aiProv.messages;
    final ctx = _buildCurrentContext();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvasElevated,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'CINE-COPILOT AI',
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const AppBadge(
                  text: 'GEMINI 3.8 FLASH',
                  variant: AppBadgeVariant.primary,
                  fontSize: 9,
                ),
              ],
            ),
            Text(
              'HỖ TRỢ PHÂN VIỆC & VẬN HÀNH RẠP',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.key, color: AppColors.muted, size: 18),
            tooltip: 'Cấu hình API Key',
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw, color: AppColors.muted, size: 18),
            tooltip: 'Làm mới hội thoại',
            onPressed: _showClearConfirmDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. ACTIVE CINEMA CONTEXT BAR
          _buildCinemaContextBar(ctx),

          // 2. QUICK PROMPTS HORIZONTAL CHIPS
          _buildPromptTemplates(aiProv),

          // 3. MESSAGE LIST
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'Bắt đầu hội thoại cùng Cine-Copilot AI',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: messages.length + (aiProv.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return _buildLoadingBubble();
                      }
                      return _buildMessageItem(messages[index]);
                    },
                  ),
          ),

          // 4. INPUT CONTROLS BAR
          _buildInputBar(aiProv),
        ],
      ),
    );
  }

  Widget _buildCinemaContextBar(CinemaAiContext ctx) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isContextExpanded = !_isContextExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ctx.cinemaName.toUpperCase()} · ${ctx.managerName}',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${ctx.staffList.length} staff · ${ctx.showtimes.length} suất',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isContextExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 14,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isContextExpanded)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              color: AppColors.canvas,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DỮ LIỆU ĐANG ĐỒNG BỘ VỚI GEMINI AI:',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Nhân sự: ${ctx.staffList.isEmpty ? "Chưa có staff được thêm" : ctx.staffList.map((s) => s.fullName).join(", ")}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.body),
                  ),
                  Text(
                    '• Suất chiếu hôm nay: ${ctx.showtimes.length} suất (Tỉ lệ lấp đầy: ${ctx.dashboardStats?.occupancyRate.toStringAsFixed(1) ?? "0"}%)',
                    style: AppTextStyles.caption.copyWith(color: AppColors.body),
                  ),
                  if (ctx.dashboardStats != null)
                    Text(
                      '• Doanh thu trong ngày: ${CurrencyFormatter.formatVnd(ctx.dashboardStats!.totalRevenue)} (Vé: ${CurrencyFormatter.formatVnd(ctx.dashboardStats!.ticketRevenue)} · F&B: ${CurrencyFormatter.formatVnd(ctx.dashboardStats!.foodRevenue)})',
                      style: AppTextStyles.caption.copyWith(color: AppColors.body),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPromptTemplates(ManagerAiProvider aiProv) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        itemCount: aiProv.promptTemplates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final tpl = aiProv.promptTemplates[index];
          return ActionChip(
            backgroundColor: AppColors.canvasElevated,
            side: const BorderSide(color: AppColors.hairline, width: 1),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getCategoryIcon(tpl.iconName),
                const SizedBox(width: 4),
                Text(
                  tpl.title,
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            onPressed: () => _sendMessage(tpl.prompt),
          );
        },
      ),
    );
  }

  Widget _getCategoryIcon(String iconName) {
    IconData icon;
    switch (iconName) {
      case 'users':
        icon = LucideIcons.users;
        break;
      case 'sparkles':
        icon = LucideIcons.sparkles;
        break;
      case 'utensils':
        icon = LucideIcons.utensils;
        break;
      case 'messageSquare':
        icon = LucideIcons.messageSquare;
        break;
      case 'shieldAlert':
        icon = LucideIcons.shieldAlert;
        break;
      case 'alertTriangle':
        icon = LucideIcons.alertTriangle;
        break;
      default:
        icon = LucideIcons.bot;
    }
    return Icon(icon, size: 12, color: AppColors.primary);
  }

  Widget _buildMessageItem(ManagerAiMessage msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: const Icon(
                LucideIcons.bot,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: isUser ? AppColors.canvasElevated : AppColors.canvasElevated,
                border: Border(
                  left: BorderSide(
                    color: isUser ? AppColors.primary : AppColors.hairline,
                    width: isUser ? 3 : 1,
                  ),
                  top: const BorderSide(color: AppColors.hairline, width: 1),
                  right: const BorderSide(color: AppColors.hairline, width: 1),
                  bottom: const BorderSide(color: AppColors.hairline, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isUser ? 'QUẢN LÝ (BẠN)' : 'CINEMANAGER COPILOT',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: isUser ? AppColors.primary : AppColors.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!isUser)
                        InkWell(
                          onTap: () => _copyToClipboard(msg.text),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.copy,
                                  size: 11, color: AppColors.muted),
                              const SizedBox(width: 3),
                              Text(
                                'SAO CHÉP',
                                style: AppTextStyles.captionUppercase.copyWith(
                                  color: AppColors.muted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Message text
                  SelectableText(
                    msg.text,
                    style: AppTextStyles.bodySm.copyWith(
                      color: msg.isError ? AppColors.warning : AppColors.ink,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),

                  // Suggested Actions
                  if (msg.actionSuggestions != null &&
                      msg.actionSuggestions!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const Divider(color: AppColors.hairline, height: 1),
                    const SizedBox(height: 6),
                    Text(
                      'HÀNH ĐỘNG ĐỀ XUẤT:',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.muted,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: msg.actionSuggestions!.map((act) {
                        return InkWell(
                          onTap: () {
                            if (act.contains('Sao chép')) {
                              _copyToClipboard(msg.text);
                            } else if (act.contains('Bookings')) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ManagerBookingsScreen(),
                                ),
                              );
                            } else if (act.contains('đồ ăn')) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ManagerFoodsScreen(),
                                ),
                              );
                            } else {
                              _sendMessage(act);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              border: Border.all(
                                color: AppColors.hairline,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.arrowRight,
                                  size: 10,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  act,
                                  style:
                                      AppTextStyles.captionUppercase.copyWith(
                                    color: AppColors.ink,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              color: AppColors.canvasElevated,
              child: const Icon(
                LucideIcons.user,
                color: AppColors.ink,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border.all(color: AppColors.primary, width: 1),
            ),
            child: const Icon(
              LucideIcons.bot,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gemini 3.8 Flash đang phân tích & lên kế hoạch...',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ManagerAiProvider aiProv) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          top: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 1,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.canvas,
                hintText: 'Hỏi phân việc staff, SOP sự cố rạp...',
                hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.hairline),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.focusRing),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Container(
            height: 42,
            width: 48,
            color: aiProv.isLoading ? AppColors.canvas : AppColors.primary,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: aiProv.isLoading ? null : () => _sendMessage(),
                child: Center(
                  child: Icon(
                    LucideIcons.send,
                    color: aiProv.isLoading
                        ? AppColors.muted
                        : AppColors.onPrimary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
