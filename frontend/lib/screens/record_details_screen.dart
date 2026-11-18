import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/audit_log.dart';
import '../theme/app_theme.dart';

class RecordDetailsScreen extends StatelessWidget {
  final AuditLog auditLog;

  const RecordDetailsScreen({super.key, required this.auditLog});

  static void show(BuildContext context, AuditLog log) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: RecordDetailsScreen(auditLog: log),
        ),
      ),
    );
  }

  String _formatJson(dynamic val) {
    if (val == null) return 'None (N/A)';
    if (val is String) {
      try {
        final decoded = jsonDecode(val);
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(decoded);
      } catch (_) {
        return val;
      }
    }
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(val);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm:ss UTC');
    final color = AppTheme.getActionColor(auditLog.actionType);
    final bgColor = AppTheme.getActionBgColor(auditLog.actionType);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Audit Log #${auditLog.auditId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        auditLog.actionType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Metadata Grid
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        _metaItem('Username', auditLog.username, Icons.person_outline),
                        _metaItem('User ID', auditLog.userId?.toString() ?? 'System', Icons.badge_outlined),
                        _metaItem('Target Table', auditLog.tableName, Icons.table_chart_outlined),
                        _metaItem('Record ID', auditLog.recordId, Icons.tag),
                        _metaItem('IP Address', auditLog.ipAddress ?? '127.0.0.1', Icons.dns_outlined),
                        _metaItem('Timestamp', df.format(auditLog.timestamp), Icons.schedule_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Value Changes Section
                  const Text(
                    'State Payload & Change Diff',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (auditLog.actionType == 'INSERT') ...[
                    _jsonCard('New Value (Inserted Record)', _formatJson(auditLog.newValueParsed ?? auditLog.newValue), AppTheme.insertGreen),
                  ] else if (auditLog.actionType == 'DELETE') ...[
                    _jsonCard('Previous Value (Deleted Record)', _formatJson(auditLog.previousValueParsed ?? auditLog.previousValue), AppTheme.deleteRed),
                  ] else ...[
                    // UPDATE: Side by side or stacked diff
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 550) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _jsonCard('Previous Value', _formatJson(auditLog.previousValueParsed ?? auditLog.previousValue), AppTheme.updateAmber),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _jsonCard('New Value', _formatJson(auditLog.newValueParsed ?? auditLog.newValue), AppTheme.insertGreen),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _jsonCard('Previous Value', _formatJson(auditLog.previousValueParsed ?? auditLog.previousValue), AppTheme.updateAmber),
                              const SizedBox(height: 12),
                              _jsonCard('New Value', _formatJson(auditLog.newValueParsed ?? auditLog.newValue), AppTheme.insertGreen),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value, IconData icon) {
    return SizedBox(
      width: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.accentBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _jsonCard(String title, String content, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: borderColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: borderColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(maxHeight: 260),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFFE2E8F0),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

