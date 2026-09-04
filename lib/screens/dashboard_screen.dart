import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_finance_pro/models/transaction_model.dart';
import 'package:clinic_finance_pro/services/local_database_service.dart';
import 'package:clinic_finance_pro/widgets/clinic_header.dart';
import 'package:clinic_finance_pro/widgets/summary_cards.dart';
import 'package:clinic_finance_pro/widgets/transaction_data_table.dart';
import 'package:clinic_finance_pro/widgets/transaction_card_list.dart';
import 'package:clinic_finance_pro/screens/data_entry_screen.dart';
import 'package:clinic_finance_pro/screens/monthly_report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalDatabaseService _localDbService = LocalDatabaseService();
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openAddModal() async {
    final refreshNeeded = await DataEntryScreen.show(context);
    if (refreshNeeded == true) {
      setState(() {});
    }
  }

  void _openEditModal(TransactionModel transaction) async {
    final refreshNeeded = await DataEntryScreen.show(
      context,
      transactionToEdit: transaction,
    );
    if (refreshNeeded == true) {
      setState(() {});
    }
  }

  void _confirmDelete(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete this transaction?\n\n'
          'Description: ${transaction.description}\n'
          'Amount: PKR ${transaction.amount.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              if (transaction.id != null) {
                await _localDbService.deleteTransaction(transaction.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted.')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_hospital_rounded, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'Syed Sadiq Poly Clinic',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E), // Deep Teal
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Monthly Reports',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MonthlyReportScreen()),
              );
            },
          ),
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _openAddModal,
              ),
            ),
        ],
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _openAddModal,
            ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _localDbService.streamDailyTransactions(_selectedDate),
        builder: (context, snapshot) {
          final transactions = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

          // Auto Calculations
          final totalIncome = transactions
              .where((t) => t.isIncome)
              .fold(0.0, (sum, t) => sum + t.amount);

          final totalExpenses = transactions
              .where((t) => t.isExpense)
              .fold(0.0, (sum, t) => sum + t.amount);

          final netBalance = totalIncome - totalExpenses;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32.0 : 16.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ClinicHeader(
                  title: 'SYED SADIQ POLY CLINIC & LAB',
                  subtitle: 'Daily Financial Management & Ledger Dashboard',
                ),
                const SizedBox(height: 16),
                // Date Selector Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF0F766E)),
                      const SizedBox(width: 10),
                      Text(
                        'Daily Ledger: $formattedDate',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          side: const BorderSide(color: Color(0xFF0F766E)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                        label: const Text('Change Date'),
                        onPressed: _pickDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Auto-Calculated Summary Cards
                SummaryCards(
                  totalIncome: totalIncome,
                  totalExpenses: totalExpenses,
                  netBalance: netBalance,
                ),
                const SizedBox(height: 24),

                // Transactions List / Table Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${transactions.length} Records',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Real-time Data View
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                    ),
                  )
                else if (isDesktop)
                  TransactionDataTable(
                    transactions: transactions,
                    onEdit: _openEditModal,
                    onDelete: _confirmDelete,
                  )
                else
                  TransactionCardList(
                    transactions: transactions,
                    onEdit: _openEditModal,
                    onDelete: _confirmDelete,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
