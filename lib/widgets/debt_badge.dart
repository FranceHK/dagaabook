import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/formatters.dart';

/// Shows a customer's debt balance as a colored pill: green when settled,
/// coral when owing.
class DebtBadge extends StatelessWidget {
  final double balance;
  final String noDebtLabel;

  const DebtBadge({super.key, required this.balance, required this.noDebtLabel});

  @override
  Widget build(BuildContext context) {
    final settled = balance <= 0.5;
    final color = settled ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        settled ? noDebtLabel : AppFormatters.money(balance),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5),
      ),
    );
  }
}
