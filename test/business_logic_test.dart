import 'package:flutter_test/flutter_test.dart';

import 'package:dagaabook/core/transaction_ids.dart';
import 'package:dagaabook/models/payment.dart';
import 'package:dagaabook/models/sale.dart';
import 'package:dagaabook/models/stock_item.dart';

Sale _sale({String stockId = 's1', int boxes = 2, double price = 65000, String tx = ''}) => Sale(
      id: 'x$boxes$price',
      stockItemId: stockId,
      stockType: 'Dagaa',
      customerName: 'Juma',
      magunia: boxes,
      pricePerBag: price,
      paymentType: tx.isEmpty ? PaymentType.cash : PaymentType.mobile,
      amountPaid: boxes * price,
      date: DateTime(2026, 11, 6),
      transactionId: tx,
    );

void main() {
  final stock = StockItem(
    id: 's1',
    type: 'Dagaa',
    totalMagunia: 10,
    soldMagunia: 3,
    purchasePricePerBag: 50000,
    sellingPricePerBag: 65000,
    dateAdded: DateTime(2026, 11, 1),
  );

  test('Profit per box is selling minus buying price', () {
    expect(stock.profitPerBag, 15000);
  });

  test('Profit earned uses the price each box actually sold for', () {
    final sales = [_sale(boxes: 2, price: 65000), _sale(boxes: 1, price: 60000), _sale(stockId: 'other', boxes: 5)];
    expect(stock.profitEarned(sales), 2 * 15000 + 1 * 10000);
  });

  test('A transaction ID can only be used once, ignoring case and spaces', () {
    final sales = [_sale(tx: 'QGH7K2L9XP')];
    final payments = [Payment(id: 'p1', customerId: 'c1', amount: 1000, date: DateTime(2026), method: 'mobile', transactionId: 'ABC123')];

    expect(TransactionIds.isUsed(' qgh7k2l9xp ', sales, payments), isTrue);
    expect(TransactionIds.isUsed('abc123', sales, payments), isTrue);
    expect(TransactionIds.isUsed('NEW999', sales, payments), isFalse);
    expect(TransactionIds.isUsed('', sales, payments), isFalse);
  });

  test('Sale and payment keep the transaction ID when saved and loaded', () {
    final sale = Sale.fromJson(_sale(tx: 'QGH7K2L9XP').toJson());
    expect(sale.transactionId, 'QGH7K2L9XP');

    final payment = Payment.fromJson(
      Payment(id: 'p1', customerId: 'c1', amount: 1000, date: DateTime(2026), method: 'mobile', transactionId: 'ABC123').toJson(),
    );
    expect(payment.isMobile, isTrue);
    expect(payment.transactionId, 'ABC123');
  });

  test('Older saved sales without a transaction ID still load', () {
    final json = _sale().toJson()..remove('transaction_id');
    expect(Sale.fromJson(json).transactionId, '');
  });
}
