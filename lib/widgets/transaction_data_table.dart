import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_finance_pro/models/transaction_model.dart';

class TransactionDataTable extends StatelessWidget {
  final List<TransactionModel> transactions;
  final Function(TransactionModel) onEdit;
  final Function(TransactionModel) onDelete;
  final String currencySymbol;

  const TransactionDataTable({
    super.key,
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
    this.currencySymbol = 'PKR ',
  });

  String _formatAmount(double amount) {
    return '$currencySymbol${NumberFormat('#,##0.00', 'en_US').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No Transactions Recorded Today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use the Add Entry button to record new income or expenses.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 96,
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              dataRowMaxHeight: 64,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('DATE', style: _headerStyle)),
                DataColumn(label: Text('TYPE', style: _headerStyle)),
                DataColumn(label: Text('DESCRIPTION', style: _headerStyle)),
                DataColumn(label: Text('ENTERED BY', style: _headerStyle)),
                DataColumn(label: Text('AMOUNT', style: _headerStyle)),
                DataColumn(label: Text('ACTIONS', style: _headerStyle)),
              ],
              rows: transactions.map((t) {
                final isIncome = t.isIncome;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        DateFormat('yyyy-MM-dd').format(t.transactionDate),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isIncome
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isIncome
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Text(
                          t.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isIncome
                                ? const Color(0xFF047857)
                                : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 250,
                        child: Text(
                          t.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            t.user?.role.toLowerCase() == 'lab'
                                ? Icons.science_outlined
                                : Icons.medical_services_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t.enteredByDisplayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        '${isIncome ? '+' : '-'}${_formatAmount(t.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isIncome
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                            onPressed: () => onEdit(t),
                            tooltip: 'Edit Entry',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => onDelete(t),
                            tooltip: 'Delete Entry',
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
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Color(0xFF64748B),
    letterSpacing: 0.8,
  );
}
