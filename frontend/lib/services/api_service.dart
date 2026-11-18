import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/audit_log.dart';
import '../models/dashboard_summary.dart';
import '../models/employee.dart';
import '../models/report_data.dart';
import '../models/loan.dart';
import 'file_downloader.dart';

class ApiService {
  static String baseUrl = 'http://127.0.0.1:8000';

  static Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final urlString = '$cleanBase$path';
    final uri = Uri.parse(urlString);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final cleanParams = <String, String>{};
      queryParameters.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          cleanParams[key] = value.toString().trim();
        }
      });
      return uri.replace(queryParameters: cleanParams);
    }
    return uri;
  }

  // Health check
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(_buildUri('/api/health'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Dashboard summary
  static Future<DashboardSummary> getDashboardSummary() async {
    final uri = _buildUri('/api/dashboard/summary');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return DashboardSummary.fromJson(decoded);
    } else {
      throw Exception('Failed to load dashboard summary: ${response.statusCode} - ${response.body}');
    }
  }

  // Audit Logs retrieval with filtering & pagination
  static Future<PaginatedAuditLogs> getAuditLogs({
    String? username,
    String? actionType,
    String? tableName,
    String? startDate,
    String? endDate,
    String sortBy = 'timestamp',
    String sortOrder = 'desc',
    int page = 1,
    int pageSize = 15,
  }) async {
    final uri = _buildUri('/api/audit-logs', {
      'username': username,
      'action_type': actionType,
      'table_name': tableName,
      'start_date': startDate,
      'end_date': endDate,
      'sort_by': sortBy,
      'sort_order': sortOrder,
      'page': page,
      'page_size': pageSize,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return PaginatedAuditLogs.fromJson(decoded);
    } else {
      throw Exception('Failed to load audit logs: ${response.statusCode} - ${response.body}');
    }
  }

  // Single Audit Log details
  static Future<AuditLog> getAuditLogDetail(int auditId) async {
    final uri = _buildUri('/api/audit-logs/$auditId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AuditLog.fromJson(decoded);
    } else {
      throw Exception('Audit log #$auditId not found (${response.statusCode})');
    }
  }

  // Reports Preview Generation
  static Future<ReportData> generateReport({
    String? startDate,
    String? endDate,
    String? actionType,
    String? username,
    String? tableName,
  }) async {
    final uri = _buildUri('/api/reports/generate', {
      'start_date': startDate,
      'end_date': endDate,
      'action_type': actionType,
      'username': username,
      'table_name': tableName,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ReportData.fromJson(decoded);
    } else {
      final errBody = jsonDecode(response.body);
      throw Exception(errBody['detail'] ?? 'Failed to generate report');
    }
  }

  // Download PDF Report
  static Future<String?> downloadPdfReport({
    String? startDate,
    String? endDate,
    String? actionType,
    String? username,
    String? tableName,
  }) async {
    final uri = _buildUri('/api/reports/download/pdf', {
      'start_date': startDate,
      'end_date': endDate,
      'action_type': actionType,
      'username': username,
      'table_name': tableName,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final filename = 'Audit_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      return await FileDownloader.saveAndDownload(
        bytes: bytes,
        filename: filename,
        mimeType: 'application/pdf',
      );
    } else {
      throw Exception('Failed to download PDF: ${response.statusCode}');
    }
  }

  // Download CSV Report
  static Future<String?> downloadCsvReport({
    String? startDate,
    String? endDate,
    String? actionType,
    String? username,
    String? tableName,
  }) async {
    final uri = _buildUri('/api/reports/download/csv', {
      'start_date': startDate,
      'end_date': endDate,
      'action_type': actionType,
      'username': username,
      'table_name': tableName,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final filename = 'Audit_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
      return await FileDownloader.saveAndDownload(
        bytes: bytes,
        filename: filename,
        mimeType: 'text/csv',
      );
    } else {
      throw Exception('Failed to download CSV: ${response.statusCode}');
    }
  }

  // --- Simulation endpoints ---

  static Future<Map<String, dynamic>> simulateInsertEmployee(Map<String, dynamic> data) async {
    final uri = _buildUri('/api/simulation/insert');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Insert simulation failed');
    }
  }

  static Future<Map<String, dynamic>> simulateUpdateEmployee(int employeeId, Map<String, dynamic> data) async {
    final uri = _buildUri('/api/simulation/update/$employeeId');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Update simulation failed');
    }
  }

  static Future<Map<String, dynamic>> simulateDeleteEmployee(int employeeId, {String? username}) async {
    final uri = _buildUri('/api/simulation/delete/$employeeId', {
      'acting_username': username ?? 'admin',
    });
    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Delete simulation failed');
    }
  }

  static Future<List<Employee>> getSimulationEmployees() async {
    final uri = _buildUri('/api/simulation/employees');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to retrieve employees');
    }
  }

  static Future<List<Department>> getSimulationDepartments() async {
    final uri = _buildUri('/api/simulation/departments');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((d) => Department.fromJson(d as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to retrieve departments');
    }
  }

  // --- Loan Endpoints ---

  static Future<List<Loan>> getSimulationLoans() async {
    final uri = _buildUri('/api/simulation/loans');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((l) => Loan.fromJson(l as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to retrieve loans');
    }
  }

  static Future<Map<String, dynamic>> simulateInsertLoan(Map<String, dynamic> data) async {
    final uri = _buildUri('/api/simulation/loans/insert');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Loan creation failed');
    }
  }

  static Future<Map<String, dynamic>> simulateUpdateLoan(int loanId, Map<String, dynamic> data) async {
    final uri = _buildUri('/api/simulation/loans/update/$loanId');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Loan update failed');
    }
  }

  static Future<Map<String, dynamic>> simulateDeleteLoan(int loanId, {String? username}) async {
    final uri = _buildUri('/api/simulation/loans/delete/$loanId', {
      'acting_username': username ?? 'admin',
    });
    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Loan deletion failed');
    }
  }
}

