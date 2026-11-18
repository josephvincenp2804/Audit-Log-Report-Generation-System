import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/audit_log.dart';
import '../theme/app_theme.dart';

/// Nexcent-styled Audit Log Data Table
class AuditTable extends StatelessWidget {
  final List<AuditLog> records;
  final Function(AuditLog log) onRecordTap;
  final bool compact;

  const AuditTable({
    super.key,
    required this.records,
    required this.onRecordTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.lightGrey.withOpacity(0.6)),
            const SizedBox(height: 12),
            const Text(
              'No Audit Records Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.neutralDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'No audit activity matches the selected criteria.',
              style: TextStyle(fontSize: 13, color: AppTheme.bodyGrey),
            ),
          ],
        ),
      );
    }

    final df = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBackground),
            headingTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
              letterSpacing: 0.5,
            ),
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            horizontalMargin: 18,
            columnSpacing: 24,
            columns: [
              const DataColumn(label: Text('ID')),
              const DataColumn(label: Text('TIMESTAMP (UTC)')),
              const DataColumn(label: Text('OPERATOR')),
              const DataColumn(label: Text('ACTION')),
              const DataColumn(label: Text('TABLE')),
              const DataColumn(label: Text('RECORD ID')),
              const DataColumn(label: Text('IP ADDRESS')),
              if (!compact) ...[
                const DataColumn(label: Text('CHANGES SUMMARY')),
              ],
              const DataColumn(label: Text('DETAILS')),
            ],
            rows: records.map((r) {
              return DataRow(
                onSelectChanged: (_) => onRecordTap(r),
                cells: [
                  DataCell(
                    Text(
                      '#${r.auditId}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.neutralDark),
                    ),
                  ),
                  DataCell(
                    Text(
                      df.format(r.timestamp),
                      style: const TextStyle(fontSize: 12, color: AppTheme.bodyGrey),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.nexcentGreenLight,
                          child: Text(
                            r.username.isNotEmpty ? r.username[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.nexcentGreenDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          r.username,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.neutralDark),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getActionBgColor(r.actionType),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.getActionColor(r.actionType).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        r.actionType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getActionColor(r.actionType),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBackground,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Text(
                        r.tableName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.neutralDark),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.recordId,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.bodyGrey),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lan_outlined, size: 13, color: AppTheme.lightGrey),
                        const SizedBox(width: 4),
                        Text(
                          r.ipAddress ?? '-',
                          style: const TextStyle(fontSize: 12, color: AppTheme.bodyGrey, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          r.actionType == 'INSERT'
                              ? 'Created record ${r.recordId}'
                              : (r.actionType == 'DELETE'
                                  ? 'Deleted record ${r.recordId}'
                                  : 'Updated properties'),
                          style: const TextStyle(fontSize: 12, color: AppTheme.bodyGrey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  DataCell(
                    InkWell(
                      onTap: () => onRecordTap(r),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.nexcentGreenLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.nexcentGreenDark,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 14, color: AppTheme.nexcentGreenDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
