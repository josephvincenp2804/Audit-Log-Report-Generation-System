import 'package:flutter/material.dart';
import '../models/dashboard_summary.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/summary_card.dart';
import '../widgets/activity_chart.dart';
import '../widgets/audit_table.dart';
import 'record_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToAuditLogs;
  final VoidCallback onNavigateToReports;
  final VoidCallback onNavigateToSimulation;

  const DashboardScreen({
    super.key,
    required this.onNavigateToAuditLogs,
    required this.onNavigateToReports,
    required this.onNavigateToSimulation,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getDashboardSummary();
      setState(() {
        _summary = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.nexcentGreen),
            SizedBox(height: 16),
            Text(
              'Loading audit dashboard metrics...',
              style: TextStyle(color: AppTheme.bodyGrey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.deleteRed.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.deleteBg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.cloud_off_outlined, size: 40, color: AppTheme.deleteRed),
              ),
              const SizedBox(height: 18),
              const Text(
                'Unable to Connect to API',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.neutralDark),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.bodyGrey),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _fetchSummary,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    final summary = _summary!;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return RefreshIndicator(
      onRefresh: _fetchSummary,
      color: AppTheme.nexcentGreen,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. NEXCENT HERO BANNER (Matching Top of Reference Image)
            // ==========================================
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Segoe UI',
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                            children: [
                              TextSpan(
                                text: 'Transactional audit trail\n',
                                style: TextStyle(color: AppTheme.neutralDark),
                              ),
                              TextSpan(
                                text: 'with zero data loss',
                                style: TextStyle(color: AppTheme.nexcentGreen),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Surveillance engine actively recording INSERT, UPDATE and DELETE mutations with atomic rollback guarantees across all enterprise SQLite tables.',
                          style: TextStyle(fontSize: 14, color: AppTheme.bodyGrey, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: widget.onNavigateToReports,
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                              label: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Generate Compliance Report'),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, size: 14),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: widget.onNavigateToSimulation,
                              icon: const Icon(Icons.flash_on, size: 16),
                              label: const Text('Simulate Activity'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.scaffoldBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.verified, color: AppTheme.nexcentGreen, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Audit Integrity Status',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.neutralDark,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.nexcentGreenLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '100% HEALTHY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.nexcentGreenDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _heroInfoRow('Active Entities', '${summary.activityByTable.length} Tables'),
                            const SizedBox(height: 10),
                            _heroInfoRow('Total Audited Events', '${summary.totalActivities} Records'),
                            const SizedBox(height: 10),
                            _heroInfoRow('Contributing Users', '${summary.activityByUser.length} Operators'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // 2. MONITORED TABLES STRIP ("Our Clients" Bar Style)
            // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Text(
                    'MONITORED TABLES:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.lightGrey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: summary.activityByTable.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.scaffoldBackground,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.table_chart_outlined, size: 14, color: AppTheme.nexcentGreen),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.key.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.neutralDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppTheme.nexcentGreenLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${entry.value}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.nexcentGreenDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // 3. NEXCENT STATS COUNTERS ("Helping a local business reinvent itself")
            // ==========================================
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int cols = 4;
                if (width < 640) {
                  cols = 1;
                } else if (width < 1000) {
                  cols = 2;
                }

                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: cols == 1 ? 3.4 : 2.2,
                  children: [
                    SummaryCard(
                      title: 'Total Audit Activities',
                      value: summary.totalActivities.toString(),
                      icon: Icons.shield_outlined,
                      accentColor: AppTheme.nexcentGreen,
                      subtitle: 'Active events in ledger',
                      onTap: widget.onNavigateToAuditLogs,
                    ),
                    SummaryCard(
                      title: 'INSERT Operations',
                      value: summary.insertCount.toString(),
                      icon: Icons.add_circle_outline,
                      accentColor: AppTheme.insertGreen,
                      subtitle: '${((summary.insertCount / (summary.totalActivities == 0 ? 1 : summary.totalActivities)) * 100).toStringAsFixed(1)}% of all actions',
                      onTap: widget.onNavigateToAuditLogs,
                    ),
                    SummaryCard(
                      title: 'UPDATE Operations',
                      value: summary.updateCount.toString(),
                      icon: Icons.edit_note,
                      accentColor: AppTheme.updateAmber,
                      subtitle: '${((summary.updateCount / (summary.totalActivities == 0 ? 1 : summary.totalActivities)) * 100).toStringAsFixed(1)}% of all actions',
                      onTap: widget.onNavigateToAuditLogs,
                    ),
                    SummaryCard(
                      title: 'DELETE Operations',
                      value: summary.deleteCount.toString(),
                      icon: Icons.delete_sweep_outlined,
                      accentColor: AppTheme.deleteRed,
                      subtitle: '${((summary.deleteCount / (summary.totalActivities == 0 ? 1 : summary.totalActivities)) * 100).toStringAsFixed(1)}% of all actions',
                      onTap: widget.onNavigateToAuditLogs,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ==========================================
            // 4. AUDIT ACTIVITY SUMMARY (Callout Box 7)
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.nexcentGreenLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline, color: AppTheme.nexcentGreenDark, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AUDIT ACTIVITY SUMMARY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.nexcentGreenDark,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.auditActivitySummary,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.bodyGrey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // 5. ACTIVITY DISTRIBUTION CHART (Item 6)
            // ==========================================
            ActivityChart(
              distribution: summary.activityByAction,
              dailyTrends: summary.dailyTrends,
            ),
            const SizedBox(height: 24),

            // ==========================================
            // 6. RECENT AUDIT ACTIVITIES (Item 5)
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Audit Activities',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.neutralDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Real-time streaming ledger of recent transactional mutations',
                              style: TextStyle(fontSize: 12, color: AppTheme.bodyGrey),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: widget.onNavigateToAuditLogs,
                          icon: const Text('View All Records', style: TextStyle(fontWeight: FontWeight.w600)),
                          label: const Icon(Icons.arrow_forward, size: 14),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.nexcentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  AuditTable(
                    records: summary.recentActivities,
                    compact: true,
                    onRecordTap: (log) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecordDetailsScreen(auditLog: log),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.bodyGrey, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.neutralDark),
        ),
      ],
    );
  }
}
