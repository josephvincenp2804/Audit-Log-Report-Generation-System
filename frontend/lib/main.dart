import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/audit_logs_screen.dart';
import 'screens/loan_management_screen.dart';
import 'screens/report_screen.dart';
import 'screens/simulation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuditSystemApp());
}

class AuditSystemApp extends StatelessWidget {
  const AuditSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audit Log Report Generation System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShellScreen(),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;
  bool _isBackendOnline = false;
  bool _checkingHealth = true;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    setState(() => _checkingHealth = true);
    final healthy = await ApiService.checkHealth();
    if (mounted) {
      setState(() {
        _isBackendOnline = healthy;
        _checkingHealth = false;
      });
    }
  }

  void _showApiSettingsDialog() {
    final controller = TextEditingController(text: ApiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.settings_ethernet, color: AppTheme.nexcentGreen),
            SizedBox(width: 10),
            Text(
              'Configure API Base URL',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.neutralDark),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend FastAPI server base address:',
              style: TextStyle(fontSize: 13, color: AppTheme.bodyGrey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://127.0.0.1:8000',
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                ApiService.baseUrl = controller.text.trim();
              });
              Navigator.of(ctx).pop();
              _checkBackendHealth();
            },
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    final pages = [
      DashboardScreen(
        onNavigateToAuditLogs: () => setState(() => _selectedIndex = 1),
        onNavigateToReports: () => setState(() => _selectedIndex = 3),
        onNavigateToSimulation: () => setState(() => _selectedIndex = 4),
      ),
      const AuditLogsScreen(),
      LoanManagementScreen(
        onLoanChanged: () {
          _checkBackendHealth();
        },
      ),
      const ReportScreen(),
      SimulationScreen(
        onActivityLogged: () {
          _checkBackendHealth();
        },
      ),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            border: Border(
              bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Nexcent Brand Logo Mark
                  InkWell(
                    onTap: () => setState(() => _selectedIndex = 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Geometric Nexcent Green Leaf/Shield Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.nexcentGreen, AppTheme.nexcentGreenDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.nexcentGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Audit Log',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.neutralDark,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Report Generation System',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.nexcentGreen,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Enterprise Compliance & Transactional Audit Trail',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.bodyGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Backend Health Status Pill (Nexcent Style)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isBackendOnline
                          ? AppTheme.nexcentGreenLight
                          : AppTheme.deleteBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isBackendOnline
                            ? AppTheme.nexcentGreen.withOpacity(0.4)
                            : AppTheme.deleteRed.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isBackendOnline ? AppTheme.nexcentGreen : AppTheme.deleteRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _checkingHealth
                              ? 'Checking API...'
                              : (_isBackendOnline ? 'System Online (8000)' : 'API Offline'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isBackendOnline ? AppTheme.nexcentGreenDark : AppTheme.deleteRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Nexcent Quick CTA Button
                  if (isWide)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _selectedIndex = 3),
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: const Row(
                        children: [
                          Text('Simulate Mutation'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14),
                        ],
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Settings Button
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppTheme.neutralGrey),
                    tooltip: 'Configure Backend URL',
                    onPressed: _showApiSettingsDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              extended: true,
              backgroundColor: AppTheme.surfaceWhite,
              selectedIconTheme: const IconThemeData(color: AppTheme.nexcentGreen),
              unselectedIconTheme: const IconThemeData(color: AppTheme.neutralGrey),
              selectedLabelTextStyle: const TextStyle(
                color: AppTheme.nexcentGreenDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppTheme.bodyGrey,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              indicatorColor: AppTheme.nexcentGreenLight,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: Text('Audit Logs'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Loan Portfolio'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.picture_as_pdf_outlined),
                  selectedIcon: Icon(Icons.picture_as_pdf),
                  label: Text('Generate Reports'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.terminal_outlined),
                  selectedIcon: Icon(Icons.terminal),
                  label: Text('DB Simulation'),
                ),
              ],
            ),
          if (isWide) const VerticalDivider(thickness: 1, width: 1, color: AppTheme.cardBorder),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              backgroundColor: AppTheme.surfaceWhite,
              indicatorColor: AppTheme.nexcentGreenLight,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard, color: AppTheme.nexcentGreen),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt, color: AppTheme.nexcentGreen),
                  label: 'Audit Logs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.nexcentGreen),
                  label: 'Loans',
                ),
                NavigationDestination(
                  icon: Icon(Icons.picture_as_pdf_outlined),
                  selectedIcon: Icon(Icons.picture_as_pdf, color: AppTheme.nexcentGreen),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.terminal_outlined),
                  selectedIcon: Icon(Icons.terminal, color: AppTheme.nexcentGreen),
                  label: 'Simulation',
                ),
              ],
            ),
    );
  }
}
