import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCards extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final String currencySymbol;

  const SummaryCards({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    this.currencySymbol = 'PKR ',
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$currencySymbol${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final isTablet = width > 600 && width <= 900;

    final cards = [
      _buildMetricCard(
        context: context,
        title: 'Total Income',
        amount: totalIncome,
        icon: Icons.arrow_upward_rounded,
        accentColor: const Color(0xFF10B981), // Emerald green
        backgroundColor: const Color(0xFFECFDF5),
      ),
      _buildMetricCard(
        context: context,
        title: 'Total Expenses',
        amount: totalExpenses,
        icon: Icons.arrow_downward_rounded,
        accentColor: const Color(0xFFEF4444), // Coral red
        backgroundColor: const Color(0xFFFEF2F2),
      ),
      _buildMetricCard(
        context: context,
        title: 'Net Revenue / Balance',
        amount: netBalance,
        icon: netBalance >= 0
            ? Icons.account_balance_wallet_rounded
            : Icons.warning_rounded,
        accentColor: netBalance >= 0
            ? const Color(0xFF3B82F6) // Royal blue
            : const Color(0xFFF59E0B), // Amber warning
        backgroundColor: netBalance >= 0
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFFFFBEB),
        isHighlight: true,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: card,
                  ),
                ))
            .toList(),
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.only(right: 6.0), child: cards[0])),
              Expanded(child: Padding(padding: const EdgeInsets.only(left: 6.0), child: cards[1])),
            ],
          ),
          const SizedBox(height: 12),
          cards[2],
        ],
      );
    } else {
      return Column(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: card,
                ))
            .toList(),
      );
    }
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required double amount,
    required IconData icon,
    required Color accentColor,
    required Color backgroundColor,
    bool isHighlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight
              ? accentColor.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: isHighlight ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatAmount(amount),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isHighlight
                          ? (amount >= 0 ? accentColor : const Color(0xFFDC2626))
                          : Colors.grey.shade900,
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
}
