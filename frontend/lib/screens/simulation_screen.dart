import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SimulationScreen extends StatefulWidget {
  final VoidCallback onActivityLogged;

  const SimulationScreen({super.key, required this.onActivityLogged});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Employee> _employees = [];
  List<Department> _departments = [];
  bool _isLoadingData = true;

  // Insert Form Controllers
  final _insertFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _titleController = TextEditingController();
  final _salaryController = TextEditingController();
  int? _selectedDeptId;
  String _selectedStatus = 'Active';
  String _actingUser = 'admin';

  // Update Form Controllers
  Employee? _selectedEmpForUpdate;
  final _updTitleController = TextEditingController();
  final _updSalaryController = TextEditingController();
  String _updStatus = 'Active';

  bool _isSubmitting = false;
  String? _successBanner;
  String? _errorBanner;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEntities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
    _salaryController.dispose();
    _updTitleController.dispose();
    _updSalaryController.dispose();
    super.dispose();
  }

  Future<void> _loadEntities() async {
    setState(() => _isLoadingData = true);
    try {
      final emps = await ApiService.getSimulationEmployees();
      final depts = await ApiService.getSimulationDepartments();

      setState(() {
        _employees = emps;
        _departments = depts;
        if (_departments.isNotEmpty && _selectedDeptId == null) {
          _selectedDeptId = _departments.first.id;
        }
        if (_employees.isNotEmpty && _selectedEmpForUpdate == null) {
          _onSelectEmployeeForUpdate(_employees.first);
        }
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorBanner = 'Failed to load entities: $e';
        _isLoadingData = false;
      });
    }
  }

  void _onSelectEmployeeForUpdate(Employee emp) {
    setState(() {
      _selectedEmpForUpdate = emp;
      _updTitleController.text = emp.jobTitle;
      _updSalaryController.text = emp.salary.toStringAsFixed(0);
      _updStatus = emp.status;
    });
  }

  Future<void> _submitInsert() async {
    if (!_insertFormKey.currentState!.validate()) return;
    if (_selectedDeptId == null) return;

    setState(() {
      _isSubmitting = true;
      _successBanner = null;
      _errorBanner = null;
    });

    try {
      final payload = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department_id': _selectedDeptId,
        'job_title': _titleController.text.trim(),
        'salary': double.tryParse(_salaryController.text.trim()) ?? 80000.0,
        'status': _selectedStatus,
        'acting_username': _actingUser,
        'acting_ip': '192.168.1.100',
      };

      final result = await ApiService.simulateInsertEmployee(payload);
      final auditId = result['audit_log']?['audit_id'];

      setState(() {
        _isSubmitting = false;
        _successBanner = 'Transaction Succeeded! Created Employee & Generated Audit Log #$auditId with INSERT payload snapshot.';
      });

      widget.onActivityLogged();
      await _loadEntities();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorBanner = e.toString();
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (_selectedEmpForUpdate == null) return;

    setState(() {
      _isSubmitting = true;
      _successBanner = null;
      _errorBanner = null;
    });

    try {
      final payload = {
        'job_title': _updTitleController.text.trim(),
        'salary': double.tryParse(_updSalaryController.text.trim()) ?? _selectedEmpForUpdate!.salary,
        'status': _updStatus,
        'acting_username': _actingUser,
        'acting_ip': '192.168.1.100',
      };

      final result = await ApiService.simulateUpdateEmployee(_selectedEmpForUpdate!.id, payload);
      final auditId = result['audit_log']?['audit_id'];

      setState(() {
        _isSubmitting = false;
        _successBanner = 'Transaction Succeeded! Updated Employee #${_selectedEmpForUpdate!.id} and created Audit Log #$auditId (Previous & New states recorded).';
      });

      widget.onActivityLogged();
      await _loadEntities();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorBanner = e.toString();
      });
    }
  }

  Future<void> _confirmAndDelete(Employee emp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.deleteRed),
            SizedBox(width: 10),
            Text('Confirm Employee Deletion'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete employee #${emp.id} (${emp.fullName})?\n\n'
          'An immutable DELETE audit record will be logged with the complete prior state.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deleteRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Record'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isSubmitting = true;
        _successBanner = null;
        _errorBanner = null;
      });

      try {
        final result = await ApiService.simulateDeleteEmployee(emp.id, username: _actingUser);
        final auditId = result['audit_log']?['audit_id'];

        setState(() {
          _isSubmitting = false;
          _selectedEmpForUpdate = null;
          _successBanner = 'Atomic Deletion Succeeded! Employee #${emp.id} removed and DELETE Audit Log #$auditId recorded with prior state.';
        });

        widget.onActivityLogged();
        await _loadEntities();
      } catch (e) {
        setState(() {
          _isSubmitting = false;
          _errorBanner = e.toString();
        });
      }
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Database Simulation Console',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Execute live transactional database mutations (INSERT, UPDATE, DELETE) with atomic SQLAlchemy audit trail capture.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // User Attribution Picker
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: AppTheme.nexcentGreen),
                const SizedBox(width: 12),
                const Text(
                  'Acting System User:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _actingUser,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('admin (SuperAdmin)')),
                    DropdownMenuItem(value: 'sarah.connor', child: Text('sarah.connor (HR Manager)')),
                    DropdownMenuItem(value: 'alex.smith', child: Text('alex.smith (IT Auditor)')),
                    DropdownMenuItem(value: 'marcus.vance', child: Text('marcus.vance (Finance Dir)')),
                    DropdownMenuItem(value: 'elena.rodriguez', child: Text('elena.rodriguez (Eng Lead)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _actingUser = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Success / Error Alerts
          if (_successBanner != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.insertBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.insertGreen.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.insertGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_successBanner!, style: const TextStyle(color: AppTheme.insertGreen, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          if (_errorBanner != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.deleteBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.deleteRed.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.deleteRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_errorBanner!, style: const TextStyle(color: AppTheme.deleteRed, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          // Simulation Tabs
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.nexcentGreenDark,
                  unselectedLabelColor: AppTheme.bodyGrey,
                  indicatorColor: AppTheme.nexcentGreen,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(icon: Icon(Icons.add_circle_outline), text: 'Simulate INSERT'),
                    Tab(icon: Icon(Icons.edit_note), text: 'Simulate UPDATE'),
                    Tab(icon: Icon(Icons.delete_outline), text: 'Simulate DELETE'),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    height: 480,
                    child: _isLoadingData
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.nexcentGreen))
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildInsertTab(),
                              _buildUpdateTab(),
                              _buildDeleteTab(),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- TAB 1: INSERT ---
  Widget _buildInsertTab() {
    return Form(
      key: _insertFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Employee Record',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Inserting this employee will execute an atomic database transaction and record an INSERT audit log with the new value JSON payload.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      hintText: 'e.g. John',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      hintText: 'e.g. Doe',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Corporate Email',
                      hintText: 'e.g. jdoe@example.com',
                    ),
                    validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: 'e.g. +1-555-0199',
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<int>(
                    value: _selectedDeptId,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: _departments.map((d) {
                      return DropdownMenuItem(value: d.id, child: Text('${d.name} (${d.code})'));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDeptId = val),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Job Title',
                      hintText: 'e.g. Software Engineer',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _salaryController,
                    decoration: const InputDecoration(
                      labelText: 'Salary (USD)',
                      hintText: 'e.g. 85000',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Valid number required' : null,
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Employment Status'),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(value: 'On Leave', child: Text('On Leave')),
                      DropdownMenuItem(value: 'Terminated', child: Text('Terminated')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitInsert,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.insertGreen),
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_task),
              label: const Text('Execute INSERT Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: UPDATE ---
  Widget _buildUpdateTab() {
    if (_employees.isEmpty) {
      return const Center(child: Text('No employees available to update.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modify Existing Employee Record',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select an employee from the database, adjust values, and execute transaction to capture previous and new states in the audit log.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Employee Selector
          SizedBox(
            width: 360,
            child: DropdownButtonFormField<int>(
              value: _selectedEmpForUpdate?.id,
              decoration: const InputDecoration(labelText: 'Select Employee to Update'),
              items: _employees.map((e) {
                return DropdownMenuItem(
                  value: e.id,
                  child: Text('#${e.id} - ${e.fullName} (${e.jobTitle})'),
                );
              }).toList(),
              onChanged: (id) {
                if (id != null) {
                  final emp = _employees.firstWhere((e) => e.id == id);
                  _onSelectEmployeeForUpdate(emp);
                }
              },
            ),
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 260,
                child: TextFormField(
                  controller: _updTitleController,
                  decoration: const InputDecoration(labelText: 'Job Title'),
                ),
              ),
              SizedBox(
                width: 260,
                child: TextFormField(
                  controller: _updSalaryController,
                  decoration: const InputDecoration(labelText: 'Salary (USD)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  value: _updStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'On Leave', child: Text('On Leave')),
                    DropdownMenuItem(value: 'Terminated', child: Text('Terminated')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _updStatus = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitUpdate,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.updateAmber),
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.sync),
            label: const Text('Execute UPDATE Transaction'),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: DELETE ---
  Widget _buildDeleteTab() {
    if (_employees.isEmpty) {
      return const Center(child: Text('No employees available to delete.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Simulate Employee Deletion',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecting delete triggers a confirmation dialog. Upon confirmation, the employee record is purged from SQLite and an immutable DELETE audit entry is generated.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView.separated(
            itemCount: _employees.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final emp = _employees[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.deleteRed.withOpacity(0.1),
                  child: Text(
                    emp.firstName[0],
                    style: const TextStyle(color: AppTheme.deleteRed, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text('${emp.fullName} (#${emp.id})', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${emp.jobTitle} • ${emp.email} • \$${emp.salary.toStringAsFixed(0)}'),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deleteRed),
                  icon: const Icon(Icons.delete_forever, size: 16),
                  label: const Text('Delete'),
                  onPressed: _isSubmitting ? null : () => _confirmAndDelete(emp),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

