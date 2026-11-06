import '../models/payment.dart';
import '../models/sale.dart';

/// Checks mobile money transaction references so the same SMS is not
/// recorded twice.
class TransactionIds {
  TransactionIds._();

  static String normalize(String id) => id.trim().toUpperCase();

  static bool isUsed(String id, Iterable<Sale> sales, Iterable<Payment> payments) {
    final key = normalize(id);
    if (key.isEmpty) return false;
    return sales.any((s) => normalize(s.transactionId) == key) ||
        payments.any((p) => normalize(p.transactionId) == key);
  }
}
