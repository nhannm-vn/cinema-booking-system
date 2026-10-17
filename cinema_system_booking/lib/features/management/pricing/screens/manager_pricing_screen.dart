import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/seat_widget.dart';
import '../../../booking/models/pricing.dart';
import '../../../booking/repositories/booking_repository.dart';

class ManagerPricingScreen extends StatefulWidget {
  const ManagerPricingScreen({super.key});

  @override
  State<ManagerPricingScreen> createState() => _ManagerPricingScreenState();
}

class _ManagerPricingScreenState extends State<ManagerPricingScreen> {
  PricingRules _rules = PricingRules.defaultRules;
  bool _isLoading = true;

  // Simulator state
  String _simFormat = '2D';
  SeatType _simSeat = SeatType.normal;
  bool _simWeekend = false;
  bool _simPrime = false;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  void _loadPricing() async {
    try {
      final rules = await BookingRepository().getPricingRules();
      if (mounted) {
        setState(() {
          _rules = rules;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _simulatedTotal {
    final base = _rules.baseByFormat[_simFormat] ?? 80000;
    final timeSurcharge = (_simWeekend ? _rules.weekendSurcharge : 0) +
        (_simPrime ? _rules.primeTimeSurcharge : 0);

    if (_simSeat == SeatType.couple) {
      return (2 * base) + _rules.coupleSurcharge + timeSurcharge;
    }

    final seatSurcharge = _simSeat == SeatType.vip ? _rules.vipSurcharge : 0;
    return base + seatSurcharge + timeSurcharge;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'BẢNG GIÁ & PHỤ THU (XEM)',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. BASE PRICES
                  Text(
                    '1. GIÁ CƠ SỞ THEO ĐỊNH DẠNG',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvasElevated,
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Column(
                      children: _rules.baseByFormat.entries.map((e) {
                        return _buildRow(
                          title: 'Định dạng ${e.key}',
                          value: CurrencyFormatter.formatVnd(e.value),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 2. SURCHARGES
                  Text(
                    '2. PHỤ THU LOẠI GHẾ & THỜI ĐIỂM',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvasElevated,
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Column(
                      children: [
                        _buildRow(
                          title: 'Phụ thu Ghế VIP',
                          value:
                              '+${CurrencyFormatter.formatVnd(_rules.vipSurcharge)}',
                        ),
                        _buildRow(
                          title: 'Phụ thu Ghế Đôi (Couple)',
                          value:
                              '+${CurrencyFormatter.formatVnd(_rules.coupleSurcharge)}',
                        ),
                        _buildRow(
                          title: 'Phụ thu Cuối tuần (T6, T7, CN)',
                          value:
                              '+${CurrencyFormatter.formatVnd(_rules.weekendSurcharge)}',
                        ),
                        _buildRow(
                          title:
                              'Phụ thu Giờ vàng (${_rules.primeStartHour}:00 - ${_rules.primeEndHour}:00)',
                          value:
                              '+${CurrencyFormatter.formatVnd(_rules.primeTimeSurcharge)}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 3. INTERACTIVE SIMULATOR (S26 Spec)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.canvasElevated,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CÔNG CỤ THỬ TÍNH GIÁ VÉ',
                              style: AppTextStyles.captionUppercase.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const AppBadge(
                              text: 'MÔ PHỎNG',
                              variant: AppBadgeVariant.primary,
                              fontSize: 9,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Formats
                        Text('Định dạng:',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Row(
                          children: ['2D', '3D', 'IMAX'].map((fmt) {
                            final isSel = _simFormat == fmt;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: InkWell(
                                  onTap: () => setState(() => _simFormat = fmt),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    color: isSel
                                        ? AppColors.primary
                                        : AppColors.canvas,
                                    alignment: Alignment.center,
                                    child: Text(fmt,
                                        style: AppTextStyles.captionUppercase
                                            .copyWith(
                                                color: isSel
                                                    ? AppColors.onPrimary
                                                    : AppColors.ink)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 8),

                        // Seat Types
                        Text('Loại ghế:',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            SeatType.normal,
                            SeatType.vip,
                            SeatType.couple
                          ].map((st) {
                            final isSel = _simSeat == st;
                            String name = 'THƯỜNG';
                            if (st == SeatType.vip) name = 'VIP';
                            if (st == SeatType.couple) name = 'ĐÔI (COUPLE)';

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: InkWell(
                                  onTap: () => setState(() => _simSeat = st),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    color: isSel
                                        ? AppColors.primary
                                        : AppColors.canvas,
                                    alignment: Alignment.center,
                                    child: Text(name,
                                        style: AppTextStyles.captionUppercase
                                            .copyWith(
                                                color: isSel
                                                    ? AppColors.onPrimary
                                                    : AppColors.ink,
                                                fontSize: 9)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 8),

                        // Toggles
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text('Cuối tuần (+10k)',
                                    style: AppTextStyles.bodySm
                                        .copyWith(color: AppColors.ink)),
                                value: _simWeekend,
                                activeColor: AppColors.primary,
                                onChanged: (val) =>
                                    setState(() => _simWeekend = val ?? false),
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text('Giờ vàng (+10k)',
                                    style: AppTextStyles.bodySm
                                        .copyWith(color: AppColors.ink)),
                                value: _simPrime,
                                activeColor: AppColors.primary,
                                onChanged: (val) =>
                                    setState(() => _simPrime = val ?? false),
                              ),
                            ),
                          ],
                        ),

                        const Divider(color: AppColors.hairline),

                        // Result
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'KẾT QUẢ TÍNH TOÁN:',
                              style: AppTextStyles.captionUppercase
                                  .copyWith(color: AppColors.muted),
                            ),
                            Text(
                              CurrencyFormatter.formatVnd(_simulatedTotal),
                              style: AppTextStyles.titleMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    color: AppColors.canvasElevated,
                    child: Text(
                      'Manager chỉ có quyền xem cấu hình giá vé áp dụng. Chỉ Admin mới được phép chỉnh sửa bảng giá vé và phụ thu hệ thống.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRow({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.ink)),
          Text(
            value,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
