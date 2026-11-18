import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final VoidCallback onClear;

  const DateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onClear,
  });

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (startDate ?? DateTime.now().subtract(const Duration(days: 7)))
        : (endDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.accentBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStart) {
        onStartDateChanged(picked);
      } else {
        onEndDateChanged(picked);
      }
    }
  }

  void _applyPreset(int days) {
    final now = DateTime.now();
    if (days == 0) {
      // Today
      onStartDateChanged(DateTime(now.year, now.month, now.day));
      onEndDateChanged(DateTime(now.year, now.month, now.day));
    } else {
      onStartDateChanged(now.subtract(Duration(days: days)));
      onEndDateChanged(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    final hasFilter = startDate != null || endDate != null;
    final isInvalidRange = startDate != null && endDate != null && startDate!.isAfter(endDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Start Date Button
            OutlinedButton.icon(
              onPressed: () => _pickDate(context, true),
              icon: const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.accentBlue),
              label: Text(
                startDate == null ? 'Start Date' : 'From: ${df.format(startDate!)}',
                style: TextStyle(
                  fontWeight: startDate == null ? FontWeight.normal : FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: startDate != null ? AppTheme.subtleBlue : AppTheme.surfaceWhite,
              ),
            ),

            // End Date Button
            OutlinedButton.icon(
              onPressed: () => _pickDate(context, false),
              icon: const Icon(Icons.event_outlined, size: 16, color: AppTheme.accentBlue),
              label: Text(
                endDate == null ? 'End Date' : 'To: ${df.format(endDate!)}',
                style: TextStyle(
                  fontWeight: endDate == null ? FontWeight.normal : FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: endDate != null ? AppTheme.subtleBlue : AppTheme.surfaceWhite,
              ),
            ),

            // Presets
            ActionChip(
              label: const Text('Today'),
              onPressed: () => _applyPreset(0),
            ),
            ActionChip(
              label: const Text('Last 7 Days'),
              onPressed: () => _applyPreset(7),
            ),
            ActionChip(
              label: const Text('Last 14 Days'),
              onPressed: () => _applyPreset(14),
            ),

            if (hasFilter)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 16, color: AppTheme.deleteRed),
                label: const Text('Clear Dates', style: TextStyle(color: AppTheme.deleteRed)),
              ),
          ],
        ),

        if (isInvalidRange) ...[
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.error_outline, size: 14, color: AppTheme.deleteRed),
              SizedBox(width: 4),
              Text(
                'Start date cannot be after end date',
                style: TextStyle(color: AppTheme.deleteRed, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

