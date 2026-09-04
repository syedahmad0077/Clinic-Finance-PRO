import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_finance_pro/models/transaction_model.dart';
import 'package:clinic_finance_pro/services/local_database_service.dart';
import 'package:clinic_finance_pro/widgets/summary_cards.dart';
import 'package:clinic_finance_pro/widgets/transaction_data_table.dart';
import 'package:clinic_finance_pro/widgets/transaction_card_list.dart';
import 'package:clinic_finance_pro/screens/data_entry_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final LocalDatabaseService _localDbService = LocalDatabaseService();

  late int _selectedYear;
  late int _selectedMonth;
  
  List<TransactionModel> _monthlyTransactions = [];
  bool _isLoading = true;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _fetchMonthlyData();
  }

  Future<void> _fetchMonthlyData() async {
    setState(() => _isLoading = true);
    final data = await _localDbService.fetchMonthlyTransactions(_selectedYear, _selectedMonth);
    if (mounted) {
      setState(() {
        _monthlyTransactions = data;
        _isLoading = false;
      });
    }
  }

  double get _totalIncome => _monthlyTransactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpenses => _monthlyTransactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _netRevenue => _totalIncome - _totalExpenses;

  // Breakdown by staff role (Muzaffar Lab vs Dr Naeem Clinic)
  double get _labIncome => _monthlyTransactions
      .where((t) => t.isIncome && (t.user?.role.toLowerCase() == 'lab'))
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _clinicIncome => _monthlyTransactions
      .where((t) => t.isIncome && (t.user?.role.toLowerCase() == 'clinic'))
      .fold(0.0, (sum, t) => sum + t.amount);

  void _openEditModal(TransactionModel transaction) async {
    final refreshNeeded = await DataEntryScreen.show(
      context,
      transactionToEdit: transaction,
    );
    if (refreshNeeded == true) {
      _fetchMonthlyData();
    }
  }

  void _confirmDelete(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete this transaction entry?\n\n'
          'Description: ${transaction.description}\n'
          'Amount: PKR ${transaction.amount.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (transaction.id != null) {
                await _localDbService.deleteTransaction(transaction.id!);
                await _fetchMonthlyData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction deleted successfully!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Financial Report',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Syed Sadiq Poly Clinic Ledger Engine',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar (Month & Year Selector Card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, color: Color(0xFF0F766E)),
                  const SizedBox(width: 10),
                  const Text(
                    'Select Period:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 16),

                  // Month Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedMonth,
                          isExpanded: true,
                          items: List.generate(12, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(_months[index]),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMonth = val);
                              _fetchMonthlyData();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Year Dropdown
                  Container(
                    width: 110,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        items: List.generate(10, (index) {
                          final year = 2024 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedYear = val);
                            _fetchMonthlyData();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Summary Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_months[_selectedMonth - 1]} $_selectedYear Financial Summary',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${_monthlyTransactions.length} Entries',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary Cards
            SummaryCards(
              totalIncome: _totalIncome,
              totalExpenses: _totalExpenses,
              netBalance: _netRevenue,
            ),
            const SizedBox(height: 20),

            // Role Breakdown Widget (Lab vs Clinic)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Income Distribution by Department / Staff',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleMetricTile(
                          title: 'Muzaffar (Lab)',
                          amount: _labIncome,
                          icon: Icons.science_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoleMetricTile(
                          title: 'Dr. Naeem Sadiq (Clinic)',
                          amount: _clinicIncome,
                          icon: Icons.medical_services_rounded,
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transactions Breakdown Header
            const Text(
              'Monthly Ledger Detailed Statements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Data View (Desktop Table or Mobile Cards)
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                    ),
                  )
                : isDesktop
                    ? TransactionDataTable(
                        transactions: _monthlyTransactions,
                        onEdit: _openEditModal,
                        onDelete: _confirmDelete,
                      )
                    : TransactionCardList(
                        transactions: _monthlyTransactions,
                        onEdit: _openEditModal,
                        onDelete: _confirmDelete,
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleMetricTile({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  'PKR ${formatter.format(amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
