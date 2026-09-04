import 'package:flutter/material.dart';
import 'package:clinic_finance_pro/screens/dashboard_screen.dart';
import 'package:clinic_finance_pro/screens/patient_receipt_screen.dart';
import 'package:clinic_finance_pro/screens/clinic_token_screen.dart';
import 'package:clinic_finance_pro/services/local_database_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PatientReceiptScreen(),
    ClinicTokenScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {
      'title': 'Expense Sheet & Ledger',
      'subtitle': 'Financial Management',
      'icon': Icons.account_balance_wallet_outlined,
      'activeIcon': Icons.account_balance_wallet_rounded,
    },
    {
      'title': 'Lab Test Receipt (A4)',
      'subtitle': 'A4 4-in-1 Paper Saver',
      'icon': Icons.science_outlined,
      'activeIcon': Icons.science_rounded,
    },
    {
      'title': 'Clinic Token Slip',
      'subtitle': 'Doctor Parachi Printer',
      'icon': Icons.confirmation_number_outlined,
      'activeIcon': Icons.confirmation_number_rounded,
    },
  ];

  void _showBackupSettingsModal(BuildContext context) {
    final localDb = LocalDatabaseService();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFF0F766E), size: 30),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Database & Hardware Storage',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text('100% Local Hardware Storage Engine (Hive DB)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_hospital, size: 16, color: Color(0xFF0F766E)),
                        SizedBox(width: 8),
                        Text('SYED SADIQ POLY CLINIC & HOSPITAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text('Address: Muhallah Doake, G.T. Road, Muridke', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    SizedBox(height: 4),
                    Text('Ph: +92 300 4915255', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    SizedBox(height: 8),
                    Divider(height: 1),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text('Pure Offline Hardware DB Active (Zero Internet Required)', style: TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Export JSON Database Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () async {
                        final jsonStr = await localDb.exportBackupJson();
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Local Database Backup Generated'),
                              content: SingleChildScrollView(
                                child: SelectableText(jsonStr),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    if (isDesktop) {
      final isExpanded = width > 1050;
      final sidebarWidth = isExpanded ? 280.0 : 88.0;

      return Scaffold(
        body: Row(
          children: [
            // Custom Commercial Desktop Luxury Sidebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: sidebarWidth,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF064E3B), // Deep Emerald Teal Header
                    Color(0xFF0F766E), // Dark Teal
                    Color(0xFF115E59), // Deep Slate Teal Bottom
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(4, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Clinic Header Logo Pill Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: Color(0xFF0F766E),
                              size: 24,
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SYED SADIQ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    'Poly Clinic & Hospital',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 16),

                  // Navigation Links
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navItems.length,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemBuilder: (context, index) {
                        final item = _navItems[index];
                        final isSelected = _currentIndex == index;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () => setState(() => _currentIndex = index),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? item['activeIcon'] : item['icon'],
                                    color: isSelected
                                        ? const Color(0xFF0F766E)
                                        : Colors.white70,
                                    size: 24,
                                  ),
                                  if (isExpanded) ...[
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'],
                                            style: TextStyle(
                                              color: isSelected
                                                  ? const Color(0xFF0F172A)
                                                  : Colors.white,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            item['subtitle'],
                                            style: TextStyle(
                                              color: isSelected
                                                  ? const Color(0xFF0F766E)
                                                  : Colors.white60,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F766E),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Sidebar Footer Hardware Status Pill
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: InkWell(
                      onTap: () => _showBackupSettingsModal(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisAlignment: isExpanded
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981), // Emerald Green Pulse
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (isExpanded) ...[
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hive Offline Storage',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '100% Local Hardware DB',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.shield_outlined, color: Colors.white70, size: 18),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Main Content Body Screen
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile Layout with Bottom Navigation Bar
      return Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF0F766E),
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          elevation: 12,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Expense Ledger',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.science_outlined),
              activeIcon: Icon(Icons.science_rounded),
              label: 'Lab Receipt',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number_rounded),
              label: 'Clinic Token',
            ),
          ],
        ),
      );
    }
  }
}
