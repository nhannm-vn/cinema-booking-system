import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../booking/models/food_item.dart';
import '../../providers/management_provider.dart';

class ManagerFoodsScreen extends StatefulWidget {
  const ManagerFoodsScreen({super.key});

  @override
  State<ManagerFoodsScreen> createState() => _ManagerFoodsScreenState();
}

class _ManagerFoodsScreenState extends State<ManagerFoodsScreen> {
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'all',
    'combo',
    'popcorn',
    'drink',
    'snack',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFoods();
    });
  }

  void _loadFoods() {
    final user = context.read<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    context.read<ManagementProvider>().loadFoods(cid);
  }

  void _showAddEditFoodDialog({
    FoodItem? food,
    required String cinemaId,
    required AppUser actor,
  }) {
    final nameCtrl = TextEditingController(text: food?.name ?? '');
    final priceCtrl =
        TextEditingController(text: food != null ? '${food.price}' : '');
    final descCtrl = TextEditingController(text: food?.description ?? '');
    final imgCtrl = TextEditingController(
        text: food?.imageUrl ??
            'https://images.unsplash.com/photo-1585647347384-2593bc35786b?w=400');
    String category = food?.category ?? 'combo';
    bool isAvailable = food?.isAvailable ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isSubmitting = false;

          return AlertDialog(
            backgroundColor: AppColors.canvasElevated,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: Text(
              food == null ? 'THÊM MÓN MỚI' : 'SỬA MÓN ĂN',
              style: AppTextStyles.titleSm.copyWith(
                color: AppColors.ink,
                letterSpacing: 1.2,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Tên món ăn / Combo',
                        labelStyle: TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Vui lòng nhập tên món'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      dropdownColor: AppColors.canvasElevated,
                      decoration: const InputDecoration(
                        labelText: 'Phân loại',
                        labelStyle: TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'combo', child: Text('COMBO')),
                        DropdownMenuItem(
                            value: 'popcorn', child: Text('BẮP RANG')),
                        DropdownMenuItem(
                            value: 'drink', child: Text('NƯỚC NGỌT / TRÀ')),
                        DropdownMenuItem(
                            value: 'snack', child: Text('ĐỒ ĂN NHẸ (SNACK)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Đơn giá (VNĐ)',
                        labelStyle: TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập giá';
                        }
                        if (int.tryParse(val) == null) {
                          return 'Giá phải là số nguyên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Mô tả chi tiết',
                        labelStyle: TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    TextFormField(
                      controller: imgCtrl,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'URL hình ảnh món',
                        labelStyle: TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'HỦY',
                  style: AppTextStyles.captionUppercase
                      .copyWith(color: AppColors.muted),
                ),
              ),
              AppButton.primary(
                text: 'LƯU MÓN',
                isLoading: isSubmitting,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  setModalState(() => isSubmitting = true);

                  final managementProv = context.read<ManagementProvider>();
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);

                  try {
                    await managementProv.saveFood(
                      cinemaId: cinemaId,
                      foodId: food?.id,
                      name: nameCtrl.text.trim(),
                      category: category,
                      price: int.parse(priceCtrl.text.trim()),
                      description: descCtrl.text.trim(),
                      imageUrl: imgCtrl.text.trim(),
                      isAvailable: isAvailable,
                      actor: actor,
                    );

                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Đã lưu món ${nameCtrl.text}!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    setModalState(() => isSubmitting = false);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteFood(FoodItem food, String cinemaId, AppUser actor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'XÓA MÓN ĂN',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.warning),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${food.name}" khỏi thực đơn rạp không?',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'HỦY',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
          ),
          AppButton.primary(
            text: 'XÓA MÓN',
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await context.read<ManagementProvider>().deleteFood(
                      cinemaId: cinemaId,
                      foodId: food.id,
                      actor: actor,
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa món ${food.name}!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    final provider = context.watch<ManagementProvider>();

    final filteredFoods = provider.foodList.where((f) {
      if (_selectedCategory != 'all' && f.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'MENU ĐỒ ĂN CỦA RẠP',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(LucideIcons.rotateCw, size: 18),
            onPressed: _loadFoods,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. CATEGORY CHIPS
          Container(
            color: AppColors.canvasElevated,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  String label = 'TẤT CẢ';
                  if (cat == 'combo') label = 'COMBO';
                  if (cat == 'popcorn') label = 'BẮP';
                  if (cat == 'drink') label = 'NƯỚC';
                  if (cat == 'snack') label = 'SNACK';

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        label,
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: isSelected ? AppColors.onPrimary : AppColors.ink,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.canvas,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(color: AppColors.hairline, height: 1),

          // 2. FOOD ITEMS LIST
          Expanded(
            child: provider.isLoading
                ? _buildLoadingSkeleton()
                : provider.errorMessage != null
                    ? ErrorState(
                        message: provider.errorMessage!,
                        onRetry: _loadFoods,
                      )
                    : filteredFoods.isEmpty
                        ? EmptyState(
                            title: 'Chưa có món ăn nào',
                            message:
                                'Thêm món ăn hoặc combo vào menu đồ ăn của rạp.',
                            actionLabel: 'THÊM MÓN ĂN MỚI',
                            onAction: () => _showAddEditFoodDialog(
                              cinemaId: cid,
                              actor: user,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            itemCount: filteredFoods.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.xxs),
                            itemBuilder: (context, index) {
                              final food = filteredFoods[index];
                              return _buildFoodItem(food, cid, user);
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        color: AppColors.canvasElevated,
        child: AppButton.primary(
          text: 'THÊM MÓN ĂN MỚI',
          icon: const Icon(LucideIcons.plus, size: 16),
          onPressed: () => _showAddEditFoodDialog(
            cinemaId: cid,
            actor: user,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItem(FoodItem food, String cinemaId, AppUser actor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          left: BorderSide(
            color: food.isAvailable ? AppColors.primary : AppColors.muted,
            width: 3,
          ),
          bottom: const BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Image
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Container(
              width: 56,
              height: 56,
              color: AppColors.canvas,
              child: CachedNetworkImage(
                imageUrl: food.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(LucideIcons.utensils,
                    color: AppColors.muted, size: 24),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        food.name,
                        style: AppTextStyles.titleSm.copyWith(
                          color: food.isAvailable
                              ? AppColors.ink
                              : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AppBadge(
                      text: food.category.toUpperCase(),
                      variant: AppBadgeVariant.neutral,
                      fontSize: 8,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatVnd(food.price),
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (food.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    food.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Instant Availability Toggle Switch
          Column(
            children: [
              Switch(
                value: food.isAvailable,
                activeThumbColor: AppColors.primary,
                inactiveTrackColor: AppColors.canvas,
                onChanged: (val) {
                  context.read<ManagementProvider>().toggleFoodAvailability(
                        cinemaId: cinemaId,
                        foodId: food.id,
                        isAvailable: val,
                        actor: actor,
                      );
                },
              ),
              Text(
                food.isAvailable ? 'CÒN HÀNG' : 'HẾT HÀNG',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: food.isAvailable
                      ? AppColors.success
                      : AppColors.warning,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          // Edit/Delete menu
          PopupMenuButton<String>(
            color: AppColors.canvasElevated,
            icon: const Icon(LucideIcons.moreVertical,
                size: 16, color: AppColors.muted),
            onSelected: (val) {
              if (val == 'edit') {
                _showAddEditFoodDialog(
                  food: food,
                  cinemaId: cinemaId,
                  actor: actor,
                );
              } else if (val == 'delete') {
                _confirmDeleteFood(food, cinemaId, actor);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Chỉnh sửa thông tin'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Xóa món', style: TextStyle(color: AppColors.warning)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xs),
      children: const [
        SkeletonBox(width: double.infinity, height: 75),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 75),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 75),
      ],
    );
  }
}
