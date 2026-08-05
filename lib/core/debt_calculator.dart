import '../models/customer.dart';
import '../models/payment.dart';
import '../models/sale.dart';

/// A customer joined with their computed debt balance.
class CustomerDebt {
  final Customer customer;
  final double balance;
  final DateTime? lastActivity;

  const CustomerDebt({required this.customer, required this.balance, this.lastActivity});

  bool get hasDebt => balance > 0.5;
}

/// Pure helper that joins Customers + Sales + Payments into debt balances.
/// Kept outside any single provider since debt is a cross-cutting view over
/// Mauzo (sales) and Wateja (payments) data.
class DebtCalculator {
  DebtCalculator._();

  static double balanceFor(String customerId, List<Sale> sales, List<Payment> payments) {
    final saleDebt = sales.where((s) => s.customerId == customerId).fold(0.0, (sum, s) => sum + s.outstanding);
    final paid = payments.where((p) => p.customerId == customerId).fold(0.0, (sum, p) => sum + p.amount);
    final balance = saleDebt - paid;
    return balance < 0 ? 0 : balance;
  }

  static List<CustomerDebt> computeAll(List<Customer> customers, List<Sale> sales, List<Payment> payments) {
    return customers.map((c) {
      final balance = balanceFor(c.id, sales, payments);
      final customerSales = sales.where((s) => s.customerId == c.id).toList();
      DateTime? last;
      if (customerSales.isNotEmpty) {
        last = customerSales.map((s) => s.date).reduce((a, b) => a.isAfter(b) ? a : b);
      }
      return CustomerDebt(customer: c, balance: balance, lastActivity: last);
    }).toList();
  }

  static double totalOutstanding(List<Customer> customers, List<Sale> sales, List<Payment> payments) {
    return computeAll(customers, sales, payments).fold(0.0, (sum, cd) => sum + cd.balance);
  }
}
