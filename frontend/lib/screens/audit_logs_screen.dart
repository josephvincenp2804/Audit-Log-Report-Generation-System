import 'dart:async';
import 'package:flutter/material.dart';
import '../models/audit_log.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/audit_table.dart';
import '../widgets/date_range_selector.dart';
import 'record_details_screen.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String? _selectedAction;
  String? _selectedTable;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'timestamp';
  String _sortOrder = 'desc';

  int _currentPage = 1;
  final int _pageSize = 12;
  int _totalCount = 0;
  int _totalPages = 1;

  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _currentPage = 1;
      });
      _fetchLogs();
    });
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getAuditLogs(
        username: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        actionType: (_selectedAction != null && _selectedAction != 'ALL') ? _selectedAction : null,
        tableName: (_selectedTable != null && _selectedTable != 'ALL') ? _selectedTable : null,
        startDate: _startDate?.toIsoformatString(),
        endDate: _endDate?.toIsoformatString(),
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _logs = data.items;
        _totalCount = data.total;
        _currentPage = data.page;
        _totalPages = data.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedAction = null;
      _selectedTable = null;
      _startDate = null;
      _endDate = null;
      _sortBy = 'timestamp';
      _sortOrder = 'desc';
      _currentPage = 1;
    });
    _fetchLogs();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit Log Trail',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Chronological and verifiable record of database modifications across all entities.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              IconButton(
                onPressed: _fetchLogs,
                icon: const Icon(Icons.refresh, color: AppTheme.accentBlue),
                tooltip: 'Refresh Records',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Filter Controls: Search & Dropdowns
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search by Username
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search username...',
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchLogs();
                                  },
                                )
                              : null,
                          isDense: true,
                        ),
                      ),
                    ),

                    // Filter by Action Type
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<String>(
                        value: _selectedAction ?? 'ALL',
                        decoration: const InputDecoration(
                          labelText: 'Action Type',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Actions')),
                          DropdownMenuItem(value: 'INSERT', child: Text('INSERT')),
                          DropdownMenuItem(value: 'UPDATE', child: Text('UPDATE')),
                          DropdownMenuItem(value: 'DELETE', child: Text('DELETE')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedAction = val;
                            _currentPage = 1;
                          });
                          _fetchLogs();
                        },
                      ),
                    ),

                    // Filter by Table Name
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<String>(
                        value: _selectedTable ?? 'ALL',
                        decoration: const InputDecoration(
                          labelText: 'Table Name',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Tables')),
                          DropdownMenuItem(value: 'employees', child: Text('employees')),
                          DropdownMenuItem(value: 'departments', child: Text('departments')),
                          DropdownMenuItem(value: 'users', child: Text('users')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedTable = val;
                            _currentPage = 1;
                          });
                          _fetchLogs();
                        },
                      ),
                    ),

                    // Sort Order
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: '$_sortBy:$_sortOrder',
                        decoration: const InputDecoration(
                          labelText: 'Sort By',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'timestamp:desc', child: Text('Newest First')),
                          DropdownMenuItem(value: 'timestamp:asc', child: Text('Oldest First')),
                          DropdownMenuItem(value: 'audit_id:desc', child: Text('ID (High to Low)')),
                          DropdownMenuItem(value: 'audit_id:asc', child: Text('ID (Low to High)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            final parts = val.split(':');
                            setState(() {
                              _sortBy = parts[0];
                              _sortOrder = parts[1];
                              _currentPage = 1;
                            });
                            _fetchLogs();
                          }
                        },
                      ),
                    ),

                    // Reset Button
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Date Filter Selector
                DateRangeSelector(
                  startDate: _startDate,
                  endDate: _endDate,
                  onStartDateChanged: (d) {
                    setState(() {
                      _startDate = d;
                      _currentPage = 1;
                    });
                    _fetchLogs();
                  },
                  onEndDateChanged: (d) {
                    setState(() {
                      _endDate = d;
                      _currentPage = 1;
                    });
                    _fetchLogs();
                  },
                  onClear: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _currentPage = 1;
                    });
                    _fetchLogs();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Total Count / Info Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${_logs.length} of $_totalCount audit records',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              // Pagination Status
              Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: AppTheme.accentBlue),
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $_errorMessage', style: const TextStyle(color: AppTheme.deleteRed)),
              ),
            )
          else ...[
            AuditTable(
              records: _logs,
              onRecordTap: (log) => RecordDetailsScreen.show(context, log),
            ),
            const SizedBox(height: 20),

            // Pagination Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _fetchLogs();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text('Previous'),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryNavy),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _currentPage < _totalPages
                      ? () {
                          setState(() => _currentPage++);
                          _fetchLogs();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('Next'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

extension DateTimeIso on DateTime {
  String toIsoformatString() {
    return toIso8601String().split('T')[0];
  }
}

