import 'dart:convert';

class AuditLog {
  final int auditId;
  final int? userId;
  final String username;
  final String actionType;
  final String tableName;
  final String recordId;
  final String? previousValue;
  final String? newValue;
  final String? ipAddress;
  final DateTime timestamp;
  final dynamic previousValueParsed;
  final dynamic newValueParsed;

  AuditLog({
    required this.auditId,
    this.userId,
    required this.username,
    required this.actionType,
    required this.tableName,
    required this.recordId,
    this.previousValue,
    this.newValue,
    this.ipAddress,
    required this.timestamp,
    this.previousValueParsed,
    this.newValueParsed,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    dynamic prevParsed;
    dynamic nextParsed;

    if (json.containsKey('previous_value_parsed')) {
      prevParsed = json['previous_value_parsed'];
    } else if (json['previous_value'] != null) {
      try {
        prevParsed = jsonDecode(json['previous_value']);
      } catch (_) {
        prevParsed = json['previous_value'];
      }
    }

    if (json.containsKey('new_value_parsed')) {
      nextParsed = json['new_value_parsed'];
    } else if (json['new_value'] != null) {
      try {
        nextParsed = jsonDecode(json['new_value']);
      } catch (_) {
        nextParsed = json['new_value'];
      }
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['timestamp']);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AuditLog(
      auditId: json['audit_id'] ?? 0,
      userId: json['user_id'],
      username: json['username'] ?? 'unknown',
      actionType: json['action_type'] ?? 'UNKNOWN',
      tableName: json['table_name'] ?? '',
      recordId: json['record_id']?.toString() ?? '',
      previousValue: json['previous_value'],
      newValue: json['new_value'],
      ipAddress: json['ip_address'],
      timestamp: parsedDate,
      previousValueParsed: prevParsed,
      newValueParsed: nextParsed,
    );
  }
}

class PaginatedAuditLogs {
  final List<AuditLog> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedAuditLogs({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedAuditLogs.fromJson(Map<String, dynamic> json) {
    final rawList = json['items'] as List<dynamic>? ?? [];
    return PaginatedAuditLogs(
      items: rawList.map((e) => AuditLog.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 15,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

