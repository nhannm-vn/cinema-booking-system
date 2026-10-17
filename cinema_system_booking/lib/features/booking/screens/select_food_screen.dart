import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hold_timer.dart';
import '../../../shared/widgets/quantity_stepper.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../movies/models/movie.dart';
import '../models/cinema.dart';
import '../models/food_item.dart';
import '../models/showtime.dart';
import '../providers/booking_provider.dart';
import 'payment_screen.dart';

class SelectFoodScreen extends StatefulWidget {
  const SelectFoodScreen({
    super.key,
    required this.movie,
    required this.cinema,
    required this.showtime,
    required this.bookingCode,
  });

  final Movie movie;
  final Cinema cinema;
  final Showtime showtime;
  final String bookingCode;

  @override
  State<SelectFoodScreen> createState() => _SelectFoodScreenState();
}

class _SelectFoodScreenState extends State<SelectFoodScreen> {
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'label': 'TẤT CẢ'},
    {'id': 'combo', 'label': 'COMBO'},
    {'id': 'popcorn', 'label': 'BẮP'},
    {'id': 'drink', 'label': 'NƯỚC'},
    {'id': 'snack', 'label': 'SNACK'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadFoods();
    });
  }

  void _onTimerExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
        title: Text(
          'HẾT THỜI GIAN GIỮ GHẾ',
          style: AppTextStyles.titleMd.copyWith(color: AppColors.warning),
        ),
        content: Text(
          'Thời gian giữ ghế 5 phút của bạn đã hết. Ghế đã được nhả cho người khác. Vui lòng chọn lại ghế.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.primary(
            text: 'CHỌN LẠI GHẾ',
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Quay về màn S06
            },
          ),
        ],
      ),
    );
  }

  void _onProceedToPayment() async {
    final provider = context.read<BookingProvider>();
    await provider.saveBookingFoods();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          movie: widget.movie,
          cinema: widget.cinema,
          showtime: widget.showtime,
          bookingCode: widget.bookingCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final holdExpiry = bookingProvider.holdUntil ??
        DateTime.now().add(const Duration(minutes: 5));

    final foods = bookingProvider.foodList.where((f) {
      if (_selectedCategory == 'all') return true;
      return f.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BẮP & NƯỚC',
              style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
            ),
            Text(
              widget.cinema.name,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _onProceedToPayment,
            child: Text(
              'BỎ QUA',
              style: AppTextStyles.button.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. ĐỒNG HỒ GIỮ GHẾ (HOLD TIMER)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            child: Center(
              child: HoldTimer(
                expiresAt: holdExpiry,
                onExpired: _onTimerExpired,
              ),
            ),
          ),

          // 2. TAB PHÂN LOẠI DANH MỤC
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.hairline, width: 1),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xxs),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat['id'] == _selectedCategory;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat['id']!;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.canvasElevated,
                      borderRadius: AppRadius.none,
                      border: isSelected
                          ? null
                          : Border.all(color: AppColors.hairline, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat['label']!,
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.ink,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. DANH SÁCH MÓN ĂN
          Expanded(
            child: bookingProvider.isLoadingFoods
                ? const _FoodLoadingSkeleton()
                : foods.isEmpty
                    ? const EmptyState(
                        title: 'KHÔNG CÓ MÓN ĂN TRONG MỤC NÀY',
                        icon: LucideIcons.utensils,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        itemCount: foods.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final food = foods[index];
                          final qty =
                              bookingProvider.getFoodQuantity(food.id);

                          return _buildFoodRow(food, qty, bookingProvider);
                        },
                      ),
          ),

          // 4. THANH TỔNG TIỀN DÍNH ĐÁY
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border(
                top: BorderSide(color: AppColors.hairline, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookingProvider.foodTotal > 0
                            ? 'Đồ ăn: ${bookingProvider.selectedFoods.length} món'
                            : 'Chưa chọn đồ ăn',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.body),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(bookingProvider.grandTotal),
                        style: AppTextStyles.displayLg
                            .copyWith(color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppButton.primary(
                  text: 'TIẾP TỤC',
                  onPressed: _onProceedToPayment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodRow(FoodItem food, int qty, BookingProvider provider) {
    final isAvailable = food.isAvailable;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          borderRadius: AppRadius.none,
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Row(
          children: [
            // Ảnh vuông món ăn 72x72
            ClipRRect(
              borderRadius: AppRadius.none,
              child: SizedBox(
                width: 72,
                height: 72,
                child: CachedNetworkImage(
                  imageUrl: food.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SkeletonBox(),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.canvas,
                    child: const Icon(LucideIcons.popcorn,
                        color: AppColors.muted, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Tên, mô tả, giá
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    food.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(food.price),
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            // Bộ tăng giảm số lượng hoặc nhãn HẾT HÀNG
            if (!isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.muted, width: 1),
                ),
                child: Text(
                  'HẾT HÀNG',
                  style: AppTextStyles.captionUppercase
                      .copyWith(color: AppColors.muted),
                ),
              )
            else
              QuantityStepper(
                quantity: qty,
                onDecrement: () => provider.decrementFood(food),
                onIncrement: () => provider.incrementFood(food),
              ),
          ],
        ),
      ),
    );
  }
}

class _FoodLoadingSkeleton extends StatelessWidget {
  const _FoodLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xs),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: const Row(
          children: [
            SkeletonBox(width: 72, height: 72),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 16),
                  SizedBox(height: 6),
                  SkeletonBox(width: 200, height: 12),
                  SizedBox(height: 8),
                  SkeletonBox(width: 80, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
