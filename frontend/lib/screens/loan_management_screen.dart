import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LoanManagementScreen extends StatefulWidget {
  final VoidCallback? onLoanChanged;

  const LoanManagementScreen({super.key, this.onLoanChanged});

  @override
  State<LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<LoanManagementScreen> {
  List<Loan> _loans = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _statusBanner;

  // Selected filter scheme
  String _selectedSchemeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getSimulationLoans();
      setState(() {
        _loans = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showDisburseDialog() {
    final formKey = GlobalKey<FormState>();
    final loanNumberCtrl = TextEditingController(text: 'LN-2026-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final borrowerCtrl = TextEditingController();
    final principalCtrl = TextEditingController(text: '100000');
    final roiCtrl = TextEditingController(text: '73.0');
    final tenureCtrl = TextEditingController(text: '120 Days');
    final docFeeCtrl = TextEditingController(text: '3000');

    String selectedType = 'Daily Loan';
    String actingUser = 'john.paul';

    final schemePresets = {
      'Daily Loan': {'roi': 73.0, 'tenure': '120 Days', 'doc': 3000.0},
      'Weekly Loan': {'roi': 40.0, 'tenure': '52 Weeks', 'doc': 3000.0},
      'Personal Loan': {'roi': 26.58, 'tenure': '24 Months', 'doc': 2000.0},
      'Vehicle Loan': {'roi': 24.93, 'tenure': '24 Months', 'doc': 1500.0},
      'Gold Loan': {'roi': 18.0, 'tenure': '60 Days', 'doc': 0.0},
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.monetization_on_outlined, color: AppTheme.nexcentGreen),
                SizedBox(width: 10),
                Text(
                  'Disburse New Loan (SI Capital)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.neutralDark),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select the scheme to auto-populate terms from the SI Capital projection sheet:',
                        style: TextStyle(fontSize: 12, color: AppTheme.bodyGrey),
                      ),
                      const SizedBox(height: 16),

                      // Scheme Selector
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Loan Scheme Type', isDense: true),
                        items: schemePresets.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedType = val;
                              final preset = schemePresets[val]!;
                              roiCtrl.text = preset['roi'].toString();
                              tenureCtrl.text = preset['tenure'].toString();
                              docFeeCtrl.text = preset['doc'].toString();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: loanNumberCtrl,
                              decoration: const InputDecoration(labelText: 'Loan Ref #', isDense: true),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: borrowerCtrl,
                              decoration: const InputDecoration(labelText: 'Borrower Name', hintText: 'e.g. Ramesh Kumar', isDense: true),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: principalCtrl,
                              decoration: const InputDecoration(labelText: 'Principal (INR)', isDense: true),
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || double.tryParse(v) == null ? 'Valid number required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: docFeeCtrl,
                              decoration: const InputDecoration(labelText: 'Doc Fee (INR)', isDense: true),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: roiCtrl,
                              decoration: const InputDecoration(labelText: 'Effective ROI (%)', isDense: true),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: tenureCtrl,
                              decoration: const InputDecoration(labelText: 'Tenure Period', isDense: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Acting Officer
                      DropdownButtonFormField<String>(
                        value: actingUser,
                        decoration: const InputDecoration(labelText: 'Authorizing Officer', isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'john.paul', child: Text('John Paul Rapheal (Auditor)')),
                          DropdownMenuItem(value: 'rajesh.sharma', child: Text('Rajesh Sharma (Credit Mgr)')),
                          DropdownMenuItem(value: 'priya.nair', child: Text('Priya Nair (Gold Appraiser)')),
                          DropdownMenuItem(value: 'anand.verma', child: Text('Anand Verma (Asset Underwriter)')),
                          DropdownMenuItem(value: 'admin', child: Text('System Administrator')),
                        ],
                        onChanged: (val) => setDialogState(() => actingUser = val!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Disburse & Log Audit'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.of(ctx).pop();

                  setState(() => _isLoading = true);
                  try {
                    final payload = {
                      'loan_number': loanNumberCtrl.text.trim(),
                      'loan_type': selectedType,
                      'borrower_name': borrowerCtrl.text.trim(),
                      'principal_amount': double.tryParse(principalCtrl.text.trim()) ?? 100000.0,
                      'interest_rate': double.tryParse(roiCtrl.text.trim()) ?? 15.0,
                      'tenure_period': tenureCtrl.text.trim(),
                      'doc_fee': double.tryParse(docFeeCtrl.text.trim()) ?? 0.0,
                      'status': 'Active',
                      'acting_username': actingUser,
                      'acting_ip': '192.168.1.100',
                    };

                    final result = await ApiService.simulateInsertLoan(payload);
                    final auditId = result['audit_log']?['audit_id'];

                    setState(() {
                      _statusBanner = 'Loan ${loanNumberCtrl.text} disbursed successfully! Recorded INSERT audit log #$auditId.';
                    });

                    widget.onLoanChanged?.call();
                    await _fetchLoans();
                  } catch (e) {
                    setState(() {
                      _errorMessage = 'Disbursement failed: $e';
                      _isLoading = false;
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdateDialog(Loan loan) {
    String newStatus = loan.status;
    final emiCtrl = TextEditingController(text: '25000');
    String actingUser = 'rajesh.sharma';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              'Record Collection / Update #${loan.loanNumber}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppTheme.neutralDark),
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Borrower: ${loan.borrowerName} (${loan.loanType})', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Principal: INR ${NumberFormat('#,##,###').format(loan.principalAmount)}', style: const TextStyle(color: AppTheme.bodyGrey)),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: newStatus,
                    decoration: const InputDecoration(labelText: 'Loan Lifecycle Status', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active / In Repayment')),
                      DropdownMenuItem(value: 'Collection Received', child: Text('Collection Received (Partial Batch)')),
                      DropdownMenuItem(value: 'Fully Recovered', child: Text('Fully Recovered / Closed')),
                      DropdownMenuItem(value: 'Overdue / NPA Watch', child: Text('Overdue (1% NPA Provisioned)')),
                    ],
                    onChanged: (val) => setDialogState(() => newStatus = val!),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: emiCtrl,
                    decoration: const InputDecoration(labelText: 'Collection Amount (INR)', isDense: true),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: actingUser,
                    decoration: const InputDecoration(labelText: 'Recording Officer', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'rajesh.sharma', child: Text('Rajesh Sharma (Credit Mgr)')),
                      DropdownMenuItem(value: 'john.paul', child: Text('John Paul Rapheal (Auditor)')),
                      DropdownMenuItem(value: 'marcus.vance', child: Text('Marcus Vance (Finance)')),
                      DropdownMenuItem(value: 'admin', child: Text('System Administrator')),
                    ],
                    onChanged: (val) => setDialogState(() => actingUser = val!),
                  ),
                ],
              ),
            ),
            actions: [
              OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                child: const Text('Save & Record Audit'),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  setState(() => _isLoading = true);

                  try {
                    final payload = {
                      'status': newStatus,
                      'acting_username': actingUser,
                      'acting_ip': '192.168.1.100',
                    };

                    final result = await ApiService.simulateUpdateLoan(loan.id, payload);
                    final auditId = result['audit_log']?['audit_id'];

                    setState(() {
                      _statusBanner = 'Updated Loan #${loan.loanNumber}! Recorded UPDATE audit log #$auditId (Previous vs New states captured).';
                    });

                    widget.onLoanChanged?.call();
                    await _fetchLoans();
                  } catch (e) {
                    setState(() {
                      _errorMessage = 'Update failed: $e';
                      _isLoading = false;
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDelete(Loan loan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.deleteRed),
            SizedBox(width: 10),
            Text('Void / Cancel Loan Record'),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel loan #${loan.loanNumber} (${loan.borrowerName})?\n\n'
          'This will execute an atomic database deletion and permanently record an immutable DELETE audit entry with complete prior values in the audit ledger.',
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deleteRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete / Void Loan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final result = await ApiService.simulateDeleteLoan(loan.id, username: 'admin');
        final auditId = result['audit_log']?['audit_id'];

        setState(() {
          _statusBanner = 'Loan #${loan.loanNumber} voided. DELETE audit log #$auditId captured with full prior snapshot.';
        });

        widget.onLoanChanged?.call();
        await _fetchLoans();
      } catch (e) {
        setState(() {
          _errorMessage = 'Deletion failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLoans = _selectedSchemeFilter == 'ALL'
        ? _loans
        : _loans.where((l) => l.loanType.toLowerCase().contains(_selectedSchemeFilter.toLowerCase())).toList();

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loan Portfolio Management',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.neutralDark, letterSpacing: -0.5),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'SI Capital & Financial Services Ltd: Manage 5 loan products with full audit lifecycle surveillance.',
                    style: TextStyle(fontSize: 13, color: AppTheme.bodyGrey),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _fetchLoans,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showDisburseDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Disburse New Loan'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status & Error Banners
          if (_statusBanner != null)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.nexcentGreenLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.nexcentGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.nexcentGreenDark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_statusBanner!, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.nexcentGreenDark))),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _statusBanner = null)),
                ],
              ),
            ),

          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.deleteBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.deleteRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.deleteRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.deleteRed, fontWeight: FontWeight.w600))),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _errorMessage = null)),
                ],
              ),
            ),

          // 5 Scheme Overview Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int cols = width < 700 ? 2 : (width < 1100 ? 3 : 5);

              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 2.1,
                children: [
                  _schemeCard('Daily Loan', '73.0% ROI', '120 Days', '₹3,000 Doc', AppTheme.nexcentGreen),
                  _schemeCard('Weekly Loan', '40.0% ROI', '52 Weeks', '₹3,000 Doc', AppTheme.updateAmber),
                  _schemeCard('Personal Loan', '26.58% ROI', '24 Months', '₹2,000 Doc', Colors.purple),
                  _schemeCard('Vehicle Loan', '24.93% ROI', '24 Months', '₹1,500 Doc', Colors.indigo),
                  _schemeCard('Gold Loan', '18.0% ROI', '60 Days', '₹0 Doc', Colors.amber.shade800),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Filter Strip & Live Loans Table
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Active Loans Ledger',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.neutralDark),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.nexcentGreenLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${filteredLoans.length} Loans',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.nexcentGreenDark),
                            ),
                          ),
                        ],
                      ),

                      // Scheme Filter Buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['ALL', 'Daily', 'Weekly', 'Personal', 'Vehicle', 'Gold'].map((filter) {
                            final isSelected = _selectedSchemeFilter.toUpperCase() == filter.toUpperCase();
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: isSelected,
                                selectedColor: AppTheme.nexcentGreenLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppTheme.nexcentGreenDark : AppTheme.bodyGrey,
                                ),
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedSchemeFilter = filter);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Table
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.nexcentGreen)),
                  )
                else if (filteredLoans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No loans found for selected scheme.', style: TextStyle(color: AppTheme.bodyGrey))),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBackground),
                        headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.neutralDark),
                        columns: const [
                          DataColumn(label: Text('LOAN #')),
                          DataColumn(label: Text('SCHEME')),
                          DataColumn(label: Text('BORROWER')),
                          DataColumn(label: Text('PRINCIPAL')),
                          DataColumn(label: Text('ROI (%)')),
                          DataColumn(label: Text('TENURE')),
                          DataColumn(label: Text('DOC FEE')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filteredLoans.map((l) {
                          return DataRow(
                            cells: [
                              DataCell(Text(l.loanNumber, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.neutralDark))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getSchemeColor(l.loanType).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l.loanType,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _getSchemeColor(l.loanType)),
                                  ),
                                ),
                              ),
                              DataCell(Text(l.borrowerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(currencyFmt.format(l.principalAmount), style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(Text('${l.interestRate}%', style: const TextStyle(color: AppTheme.bodyGrey))),
                              DataCell(Text(l.tenurePeriod, style: const TextStyle(color: AppTheme.bodyGrey))),
                              DataCell(Text(currencyFmt.format(l.docFee), style: const TextStyle(color: AppTheme.bodyGrey))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: l.status.contains('Closed') || l.status.contains('Fully')
                                        ? AppTheme.scaffoldBackground
                                        : AppTheme.nexcentGreenLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: l.status.contains('Closed') ? AppTheme.bodyGrey : AppTheme.nexcentGreenDark,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_note, size: 18, color: AppTheme.neutralDark),
                                      tooltip: 'Record Collection / Update Status',
                                      onPressed: () => _showUpdateDialog(l),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.deleteRed),
                                      tooltip: 'Void / Cancel Loan',
                                      onPressed: () => _confirmAndDelete(l),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _schemeCard(String title, String roi, String tenure, String doc, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.neutralDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(roi, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              Text(tenure, style: const TextStyle(fontSize: 11, color: AppTheme.bodyGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSchemeColor(String scheme) {
    final lower = scheme.toLowerCase();
    if (lower.contains('daily')) return AppTheme.nexcentGreen;
    if (lower.contains('weekly')) return AppTheme.updateAmber;
    if (lower.contains('personal')) return Colors.purple;
    if (lower.contains('vehicle')) return Colors.indigo;
    if (lower.contains('gold')) return Colors.amber.shade800;
    return AppTheme.bodyGrey;
  }
}

