import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../movies/models/movie.dart';
import '../../../movies/providers/movie_provider.dart';
import '../../providers/management_provider.dart';

class AddEditShowtimeScreen extends StatefulWidget {
  const AddEditShowtimeScreen({
    super.key,
    required this.cinemaId,
    this.initialDate,
  });

  final String cinemaId;
  final DateTime? initialDate;

  @override
  State<AddEditShowtimeScreen> createState() => _AddEditShowtimeScreenState();
}

class _AddEditShowtimeScreenState extends State<AddEditShowtimeScreen> {
  Movie? _selectedMovie;
  String _selectedRoomId = 'room_01';
  String _selectedFormat = '2D';
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);

  bool _isSaving = false;
  String? _conflictError;

  final List<Map<String, dynamic>> _rooms = [
    {'id': 'room_01', 'name': 'Phòng 01 - Standard Prime', 'formats': ['2D', '3D'], 'seats': 75},
    {'id': 'room_02', 'name': 'Phòng 02 - IMAX Laser', 'formats': ['IMAX', '2D'], 'seats': 75},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final movieProv = context.read<MovieProvider>();
      if (movieProv.nowShowingMovies.isEmpty) {
        movieProv.loadMovies();
      }
    });
  }

  DateTime get _calculatedStartDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  DateTime get _calculatedEndDateTime {
    final dur = _selectedMovie?.durationMin ?? 120;
    return _calculatedStartDateTime.add(Duration(minutes: dur));
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.canvasElevated,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _conflictError = null;
      });
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.canvasElevated,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _conflictError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedMovie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phim chiếu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _conflictError = null;
    });

    final actor = context.read<AuthProvider>().currentUser;
    final roomObj = _rooms.firstWhere((r) => r['id'] == _selectedRoomId);

    try {
      await context.read<ManagementProvider>().createShowtime(
            cinemaId: widget.cinemaId,
            movieId: _selectedMovie!.id,
            roomId: _selectedRoomId,
            format: _selectedFormat,
            startTime: _calculatedStartDateTime,
            durationMin: _selectedMovie!.durationMin,
            totalSeats: (roomObj['seats'] as num).toInt(),
            actor: actor,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Thêm suất chiếu ${_selectedMovie!.title} thành công lúc ${DateFormat('HH:mm dd/MM').format(_calculatedStartDateTime)}!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _conflictError = e.toString().replaceAll('StateError: ', '').replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movieProv = context.watch<MovieProvider>();
    final movies = movieProv.nowShowingMovies.isNotEmpty
        ? movieProv.nowShowingMovies
        : movieProv.comingSoonMovies;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'THÊM SUẤT CHIẾU',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. SELECT MOVIE
            Text(
              '1. CHỌN PHIM CHIẾU',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Movie>(
                  isExpanded: true,
                  dropdownColor: AppColors.canvasElevated,
                  value: _selectedMovie,
                  hint: Text(
                    'Chọn phim từ danh sách',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                  ),
                  items: movies.map((m) {
                    return DropdownMenuItem<Movie>(
                      value: m,
                      child: Text(
                        '${m.title} (${m.durationMin}p · ${m.ageRating})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedMovie = val;
                      _conflictError = null;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 2. SELECT ROOM
            Text(
              '2. CHỌN PHÒNG CHIẾU',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: AppColors.canvasElevated,
                  value: _selectedRoomId,
                  items: _rooms.map((r) {
                    return DropdownMenuItem<String>(
                      value: r['id'] as String,
                      child: Text(
                        '${r['name']} (${r['seats']} ghế)',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRoomId = val;
                        _conflictError = null;
                        // Adjust default format if IMAX
                        if (val == 'room_02') {
                          _selectedFormat = 'IMAX';
                        } else {
                          _selectedFormat = '2D';
                        }
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 3. SELECT FORMAT
            Text(
              '3. ĐỊNH DẠNG CHIẾU',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: ['2D', '3D', 'IMAX'].map((fmt) {
                final isSelected = _selectedFormat == fmt;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFormat = fmt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.canvasElevated,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.hairline,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          fmt,
                          style: AppTextStyles.captionUppercase.copyWith(
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 4. DATE & TIME PICKER
            Text(
              '4. NGÀY & GIỜ CHIẾU',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      color: AppColors.canvasElevated,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NGÀY CHIẾU',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.muted)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.calendar,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: AppTextStyles.titleSm
                                    .copyWith(color: AppColors.ink),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      color: AppColors.canvasElevated,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GIỜ BẮT ĐẦU',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.muted)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.clock,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                style: AppTextStyles.titleSm
                                    .copyWith(color: AppColors.ink),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // 5. SCHEDULE TIME SUMMARY & BUFFER PREVIEW
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DỰ TÍNH KẾT THÚC SUẤT CHIẾU:',
                        style: AppTextStyles.captionUppercase
                            .copyWith(color: AppColors.muted),
                      ),
                      Text(
                        DateFormat('HH:mm').format(_calculatedEndDateTime),
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thời lượng: ${_selectedMovie?.durationMin ?? 120} phút + 15 phút giãn cách vệ sinh phòng chiếu.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),

            if (_conflictError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.warning, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.alertTriangle,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        _conflictError!,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // SUBMIT BUTTON
            AppButton.primary(
              text: 'LƯU SUẤT CHIẾU',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
