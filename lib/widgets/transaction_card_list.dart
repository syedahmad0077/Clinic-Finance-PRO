import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_finance_pro/models/transaction_model.dart';

class TransactionCardList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final Function(TransactionModel) onEdit;
  final Function(TransactionModel) onDelete;
  final String currencySymbol;

  const TransactionCardList({
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
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No Transactions Today',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + below to add a new record.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        final isIncome = t.isIncome;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isIncome
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded // Money in
                        : Icons.arrow_upward_rounded, // Money out
                    color: isIncome
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.description,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            t.user?.role.toLowerCase() == 'lab'
                                ? Icons.science_outlined
                                : Icons.medical_services_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            t.enteredByDisplayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount & Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${_formatAmount(t.amount)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isIncome
                            ? const Color(0xFF047857)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => onEdit(t),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.edit_outlined,
                                size: 18, color: Colors.blue.shade600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => onDelete(t),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.red.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
