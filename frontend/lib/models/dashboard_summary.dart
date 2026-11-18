import 'audit_log.dart';

class DailyTrendItem {
  final String date;
  final int insertCount;
  final int updateCount;
  final int deleteCount;
  final int totalCount;

  DailyTrendItem({
    required this.date,
    required this.insertCount,
    required this.updateCount,
    required this.deleteCount,
    required this.totalCount,
  });

  factory DailyTrendItem.fromJson(Map<String, dynamic> json) {
    return DailyTrendItem(
      date: json['date'] ?? '',
      insertCount: json['insert_count'] ?? 0,
      updateCount: json['update_count'] ?? 0,
      deleteCount: json['delete_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
    );
  }
}

class DashboardSummary {
  final int totalActivities;
  final int insertCount;
  final int updateCount;
  final int deleteCount;
  final List<AuditLog> recentActivities;
  final Map<String, int> activityByAction;
  final Map<String, int> activityByTable;
  final Map<String, int> activityByUser;
  final List<DailyTrendItem> dailyTrends;
  final String auditActivitySummary;

  DashboardSummary({
    required this.totalActivities,
    required this.insertCount,
    required this.updateCount,
    required this.deleteCount,
    required this.recentActivities,
    required this.activityByAction,
    required this.activityByTable,
    required this.activityByUser,
    required this.dailyTrends,
    required this.auditActivitySummary,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final rawRecent = json['recent_activities'] as List<dynamic>? ?? [];
    final rawTrends = json['daily_trends'] as List<dynamic>? ?? [];

    return DashboardSummary(
      totalActivities: json['total_activities'] ?? 0,
      insertCount: json['insert_count'] ?? 0,
      updateCount: json['update_count'] ?? 0,
      deleteCount: json['delete_count'] ?? 0,
      recentActivities: rawRecent
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      activityByAction: Map<String, int>.from(json['activity_by_action'] ?? {}),
      activityByTable: Map<String, int>.from(json['activity_by_table'] ?? {}),
      activityByUser: Map<String, int>.from(json['activity_by_user'] ?? {}),
      dailyTrends: rawTrends
          .map((e) => DailyTrendItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      auditActivitySummary: json['audit_activity_summary'] ?? '',
    );
  }
}

