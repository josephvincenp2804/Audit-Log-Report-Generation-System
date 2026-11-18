import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report_data.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/audit_table.dart';
import '../widgets/date_range_selector.dart';
import 'record_details_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _operationType = 'ALL';
  final TextEditingController _usernameController = TextEditingController();

  ReportData? _reportData;
  bool _isLoading = false;
  bool _isDownloadingPdf = false;
  bool _isDownloadingCsv = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default to last 14 days
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 14));
    _generateReport();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  String? _formatDate(DateTime? d) {
    if (d == null) return null;
    final df = DateFormat('yyyy-MM-dd');
    return df.format(d);
  }

  Future<void> _generateReport() async {
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date cannot be after end date.'),
          backgroundColor: AppTheme.deleteRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final data = await ApiService.generateReport(
        startDate: _formatDate(_startDate),
        endDate: _formatDate(_endDate),
        actionType: _operationType != 'ALL' ? _operationType : null,
        username: _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : null,
      );

      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloadingPdf = true;
      _statusMessage = null;
    });

    try {
      await ApiService.downloadPdfReport(
        startDate: _formatDate(_startDate),
        endDate: _formatDate(_endDate),
        actionType: _operationType != 'ALL' ? _operationType : null,
        username: _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : null,
      );

      setState(() {
        _isDownloadingPdf = false;
        _statusMessage = 'PDF Report successfully generated and downloaded!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage ?? 'PDF downloaded'),
            backgroundColor: AppTheme.insertGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloadingPdf = false;
        _errorMessage = 'PDF download error: $e';
      });
    }
  }

  Future<void> _downloadCsv() async {
    setState(() {
      _isDownloadingCsv = true;
      _statusMessage = null;
    });

    try {
      await ApiService.downloadCsvReport(
        startDate: _formatDate(_startDate),
        endDate: _formatDate(_endDate),
        actionType: _operationType != 'ALL' ? _operationType : null,
        username: _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : null,
      );

      setState(() {
        _isDownloadingCsv = false;
        _statusMessage = 'CSV Report successfully generated and downloaded!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage ?? 'CSV downloaded'),
            backgroundColor: AppTheme.insertGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloadingCsv = false;
        _errorMessage = 'CSV download error: $e';
      });
    }
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
                    'Audit Report Generation',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Configure audit parameters, filter scope, preview data, and export compliant PDF & CSV audit documents.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Generate Report'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Parameters Control Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Select Report Filters',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 14),

                // Date Range Section
                DateRangeSelector(
                  startDate: _startDate,
                  endDate: _endDate,
                  onStartDateChanged: (d) => setState(() => _startDate = d),
                  onEndDateChanged: (d) => setState(() => _endDate = d),
                  onClear: () => setState(() {
                    _startDate = null;
                    _endDate = null;
                  }),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Operation & Username Filters
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Operation Type
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: _operationType,
                        decoration: const InputDecoration(
                          labelText: 'Operation Type',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Operations')),
                          DropdownMenuItem(value: 'INSERT', child: Text('INSERT Operations')),
                          DropdownMenuItem(value: 'UPDATE', child: Text('UPDATE Operations')),
                          DropdownMenuItem(value: 'DELETE', child: Text('DELETE Operations')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _operationType = val);
                        },
                      ),
                    ),

                    // Username filter
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username (Optional)',
                          hintText: 'e.g. admin or sconnor',
                          prefixIcon: Icon(Icons.person_search_outlined, size: 18),
                          isDense: true,
                        ),
                      ),
                    ),

                    // Submit button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generateReport,
                      icon: const Icon(Icons.filter_alt_outlined, size: 16),
                      label: const Text('Apply & Preview'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.deleteBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.deleteRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.deleteRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.deleteRed)),
                  ),
                ],
              ),
            ),

          // Report Results Section
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.nexcentGreen),
                    SizedBox(height: 12),
                    Text('Compiling audit log report...', style: TextStyle(color: AppTheme.bodyGrey)),
                  ],
                ),
              ),
            )
          else if (_reportData != null) ...[
            // Report Summary Banner & Download Buttons (Nexcent Style)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Summary Overview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.neutralDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Generated at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_reportData!.generatedAt)} UTC',
                            style: const TextStyle(fontSize: 12, color: AppTheme.bodyGrey),
                          ),
                        ],
                      ),

                      // Download Action Buttons
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          // Download PDF Button
                          OutlinedButton.icon(
                            onPressed: _isDownloadingPdf ? null : _downloadPdf,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.neutralDark,
                              side: const BorderSide(color: AppTheme.cardBorder),
                            ),
                            icon: _isDownloadingPdf
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.nexcentGreen),
                                  )
                                : const Icon(Icons.picture_as_pdf, color: AppTheme.deleteRed, size: 18),
                            label: const Text('Download PDF'),
                          ),

                          // Download CSV Button (Nexcent Green)
                          ElevatedButton.icon(
                            onPressed: _isDownloadingCsv ? null : _downloadCsv,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.nexcentGreen,
                              foregroundColor: Colors.white,
                            ),
                            icon: _isDownloadingCsv
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.table_view, size: 18),
                            label: const Text('Download CSV'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Metrics Cards Row
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _metricBadge('TOTAL ACTIVITIES', _reportData!.totalRecords.toString(), AppTheme.neutralDark),
                      _metricBadge('INSERT OPERATIONS', _reportData!.insertCount.toString(), AppTheme.insertGreen),
                      _metricBadge('UPDATE OPERATIONS', _reportData!.updateCount.toString(), AppTheme.updateAmber),
                      _metricBadge('DELETE OPERATIONS', _reportData!.deleteCount.toString(), AppTheme.deleteRed),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Report Details Table Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detailed Audit Records (${_reportData!.records.length} items)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Filter: ${_reportData!.appliedFilters['action_type']} | Scope: ${_reportData!.appliedFilters['start_date']} to ${_reportData!.appliedFilters['end_date']}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AuditTable(
              records: _reportData!.records,
              onRecordTap: (log) => RecordDetailsScreen.show(context, log),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _metricBadge(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.silverBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.bodyGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

