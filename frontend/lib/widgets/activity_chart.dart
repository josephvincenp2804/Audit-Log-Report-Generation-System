import 'package:flutter/material.dart';
import '../models/dashboard_summary.dart';
import '../theme/app_theme.dart';

class ActivityChart extends StatelessWidget {
  final Map<String, int> distribution;
  final List<DailyTrendItem> dailyTrends;

  const ActivityChart({
    super.key,
    required this.distribution,
    required this.dailyTrends,
  });

  @override
  Widget build(BuildContext context) {
    final int insert = distribution['INSERT'] ?? 0;
    final int update = distribution['UPDATE'] ?? 0;
    final int delete = distribution['DELETE'] ?? 0;
    final int total = insert + update + delete;

    final double insertPct = total > 0 ? (insert / total) * 100 : 0;
    final double updatePct = total > 0 ? (update / total) * 100 : 0;
    final double deletePct = total > 0 ? (delete / total) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit Activity Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '14-Day Timeline Breakdown by Operation Type',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _legendItem('INSERT', AppTheme.insertGreen, insert),
                  _legendItem('UPDATE', AppTheme.updateAmber, update),
                  _legendItem('DELETE', AppTheme.deleteRed, delete),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Segmented Distribution Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (insertPct > 0)
                    Expanded(
                      flex: insert,
                      child: Container(color: AppTheme.insertGreen),
                    ),
                  if (updatePct > 0)
                    Expanded(
                      flex: update,
                      child: Container(color: AppTheme.updateAmber),
                    ),
                  if (deletePct > 0)
                    Expanded(
                      flex: delete,
                      child: Container(color: AppTheme.deleteRed),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Percentage Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INSERT: ${insertPct.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.insertGreen),
              ),
              Text(
                'UPDATE: ${updatePct.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.updateAmber),
              ),
              Text(
                'DELETE: ${deletePct.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.deleteRed),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 14-day bar graph
          const Text(
            'Daily Activity Volume',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: dailyTrends.isEmpty
                ? const Center(child: Text('No trend data available'))
                : CustomPaint(
                    painter: DailyBarChartPainter(dailyTrends: dailyTrends),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class DailyBarChartPainter extends CustomPainter {
  final List<DailyTrendItem> dailyTrends;

  DailyBarChartPainter({required this.dailyTrends});

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyTrends.isEmpty) return;

    final maxVal = dailyTrends
        .map((e) => e.totalCount)
        .fold(0, (prev, curr) => curr > prev ? curr : prev);
    final effectiveMax = maxVal == 0 ? 5 : (maxVal * 1.2).ceil();

    final double bottomAxisHeight = 24.0;
    final double chartHeight = size.height - bottomAxisHeight;
    final int n = dailyTrends.length;
    final double barWidth = (size.width / n) * 0.55;
    final double step = size.width / n;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = AppTheme.cardBorder
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 4; i++) {
      final y = chartHeight - (chartHeight * (i / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final insertPaint = Paint()..color = AppTheme.insertGreen;
    final updatePaint = Paint()..color = AppTheme.updateAmber;
    final deletePaint = Paint()..color = AppTheme.deleteRed;

    for (int i = 0; i < n; i++) {
      final item = dailyTrends[i];
      final x = (i * step) + (step - barWidth) / 2;

      final double insH = (item.insertCount / effectiveMax) * chartHeight;
      final double updH = (item.updateCount / effectiveMax) * chartHeight;
      final double delH = (item.deleteCount / effectiveMax) * chartHeight;

      double curY = chartHeight;

      // Draw Insert
      if (insH > 0) {
        final r = Rect.fromLTWH(x, curY - insH, barWidth, insH);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), insertPaint);
        curY -= insH;
      }

      // Draw Update
      if (updH > 0) {
        final r = Rect.fromLTWH(x, curY - updH, barWidth, updH);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), updatePaint);
        curY -= updH;
      }

      // Draw Delete
      if (delH > 0) {
        final r = Rect.fromLTWH(x, curY - delH, barWidth, delH);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), deletePaint);
      }

      // Draw date label for every 2nd or 3rd bar
      if (i % 2 == 0 || i == n - 1) {
        final dateParts = item.date.split('-');
        final label = dateParts.length >= 3 ? '${dateParts[1]}/${dateParts[2]}' : item.date;

        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(x + (barWidth - tp.width) / 2, chartHeight + 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

