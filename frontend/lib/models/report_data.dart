import 'audit_log.dart';

class ReportData {
  final int totalRecords;
  final int insertCount;
  final int updateCount;
  final int deleteCount;
  final Map<String, dynamic> appliedFilters;
  final DateTime generatedAt;
  final List<AuditLog> records;

  ReportData({
    required this.totalRecords,
    required this.insertCount,
    required this.updateCount,
    required this.deleteCount,
    required this.appliedFilters,
    required this.generatedAt,
    required this.records,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'] as List<dynamic>? ?? [];
    DateTime parsedGen;
    try {
      parsedGen = DateTime.parse(json['generated_at']);
    } catch (_) {
      parsedGen = DateTime.now();
    }

    return ReportData(
      totalRecords: json['total_records'] ?? 0,
      insertCount: json['insert_count'] ?? 0,
      updateCount: json['update_count'] ?? 0,
      deleteCount: json['delete_count'] ?? 0,
      appliedFilters: Map<String, dynamic>.from(json['applied_filters'] ?? {}),
      generatedAt: parsedGen,
      records: rawRecords
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

