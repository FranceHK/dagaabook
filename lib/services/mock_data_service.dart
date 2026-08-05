import '../models/customer.dart';
import '../models/payment.dart';
import '../models/sale.dart';
import '../models/stock_item.dart';

/// Seed/dummy data standing in for the future Neon Postgres-backed API.
///
/// Providers call these `seed*` methods once on startup. When the real
/// backend is wired up, replace calls to this service with calls to a
/// `services/api_service.dart` that has the same method shapes.
class MockDataService {
  static DateTime _daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

  static List<Customer> seedCustomers() {
    return [
      Customer(id: 'c1', name: 'Juma Mwakalinga', phone: '0754 112 233', location: 'Igogo Market', createdAt: _daysAgo(120)),
      Customer(id: 'c2', name: 'Amina Rashidi', phone: '0765 224 559', location: 'Mwaloni', createdAt: _daysAgo(95)),
      Customer(id: 'c3', name: 'Peter Ndege', phone: '0712 998 001', location: 'Nyamagana', createdAt: _daysAgo(80)),
      Customer(id: 'c4', name: 'Fatuma Hassani', phone: '0788 445 671', location: 'Buzuruga', createdAt: _daysAgo(60)),
      Customer(id: 'c5', name: 'Emmanuel Kissima', phone: '0678 331 902', location: 'Igoma', createdAt: _daysAgo(45)),
      Customer(id: 'c6', name: 'Zainabu Omary', phone: '0755 667 812', location: 'Mkuyuni', createdAt: _daysAgo(30)),
      Customer(id: 'c7', name: 'Godfrey Mahenge', phone: '0713 556 220', location: 'Kirumba', createdAt: _daysAgo(15)),
    ];
  }

  static List<StockItem> seedStock() {
    return [
      StockItem(
        id: 's1',
        type: 'Dagaa Kavu - Ziwa Victoria',
        totalMagunia: 20,
        soldMagunia: 7,
        purchasePricePerBag: 130000,
        sellingPricePerBag: 160000,
        dateAdded: _daysAgo(2),
        supplier: 'Kirumba Beach Suppliers',
      ),
      StockItem(
        id: 's2',
        type: 'Dagaa wa Chumvi',
        totalMagunia: 10,
        soldMagunia: 4,
        purchasePricePerBag: 116000,
        sellingPricePerBag: 145000,
        dateAdded: _daysAgo(5),
        supplier: 'Mwaloni Fishers Co-op',
      ),
      StockItem(
        id: 's3',
        type: 'Dagaa Kavu - Daraja A',
        totalMagunia: 25,
        soldMagunia: 9,
        purchasePricePerBag: 144000,
        sellingPricePerBag: 178000,
        dateAdded: _daysAgo(9),
        supplier: 'Igombe Traders',
      ),
      StockItem(
        id: 's4',
        type: 'Dagaa Mchanganyiko',
        totalMagunia: 8,
        soldMagunia: 8,
        purchasePricePerBag: 104000,
        sellingPricePerBag: 130000,
        dateAdded: _daysAgo(14),
        supplier: 'Kirumba Beach Suppliers',
      ),
    ];
  }

  static List<Sale> seedSales() {
    return [
      Sale(id: 'sl1', stockItemId: 's1', stockType: 'Dagaa Kavu - Ziwa Victoria', customerId: 'c1', customerName: 'Juma Mwakalinga', magunia: 3, pricePerBag: 160000, paymentType: PaymentType.partial, amountPaid: 300000, date: _daysAgo(0)),
      Sale(id: 'sl2', stockItemId: 's1', stockType: 'Dagaa Kavu - Ziwa Victoria', customerId: null, customerName: 'Mteja wa Kawaida', magunia: 1, pricePerBag: 160000, paymentType: PaymentType.cash, amountPaid: 160000, date: _daysAgo(0)),
      Sale(id: 'sl3', stockItemId: 's3', stockType: 'Dagaa Kavu - Daraja A', customerId: 'c2', customerName: 'Amina Rashidi', magunia: 4, pricePerBag: 178000, paymentType: PaymentType.partial, amountPaid: 400000, date: _daysAgo(1)),
      Sale(id: 'sl4', stockItemId: 's2', stockType: 'Dagaa wa Chumvi', customerId: 'c3', customerName: 'Peter Ndege', magunia: 2, pricePerBag: 145000, paymentType: PaymentType.mobile, amountPaid: 290000, date: _daysAgo(1)),
      Sale(id: 'sl5', stockItemId: 's3', stockType: 'Dagaa Kavu - Daraja A', customerId: 'c4', customerName: 'Fatuma Hassani', magunia: 3, pricePerBag: 178000, paymentType: PaymentType.credit, amountPaid: 0, date: _daysAgo(2)),
      Sale(id: 'sl6', stockItemId: 's1', stockType: 'Dagaa Kavu - Ziwa Victoria', customerId: 'c1', customerName: 'Juma Mwakalinga', magunia: 2, pricePerBag: 160000, paymentType: PaymentType.credit, amountPaid: 0, date: _daysAgo(3)),
      Sale(id: 'sl7', stockItemId: 's4', stockType: 'Dagaa Mchanganyiko', customerId: 'c5', customerName: 'Emmanuel Kissima', magunia: 4, pricePerBag: 130000, paymentType: PaymentType.cash, amountPaid: 520000, date: _daysAgo(3)),
      Sale(id: 'sl8', stockItemId: 's2', stockType: 'Dagaa wa Chumvi', customerId: 'c2', customerName: 'Amina Rashidi', magunia: 1, pricePerBag: 145000, paymentType: PaymentType.partial, amountPaid: 60000, date: _daysAgo(4)),
      Sale(id: 'sl9', stockItemId: 's3', stockType: 'Dagaa Kavu - Daraja A', customerId: 'c6', customerName: 'Zainabu Omary', magunia: 2, pricePerBag: 178000, paymentType: PaymentType.partial, amountPaid: 100000, date: _daysAgo(5)),
      Sale(id: 'sl10', stockItemId: 's4', stockType: 'Dagaa Mchanganyiko', customerId: 'c7', customerName: 'Godfrey Mahenge', magunia: 4, pricePerBag: 130000, paymentType: PaymentType.credit, amountPaid: 0, date: _daysAgo(6)),
      Sale(id: 'sl11', stockItemId: 's1', stockType: 'Dagaa Kavu - Ziwa Victoria', customerId: null, customerName: 'Mteja wa Kawaida', magunia: 1, pricePerBag: 160000, paymentType: PaymentType.mobile, amountPaid: 160000, date: _daysAgo(6)),
      Sale(id: 'sl12', stockItemId: 's2', stockType: 'Dagaa wa Chumvi', customerId: 'c3', customerName: 'Peter Ndege', magunia: 1, pricePerBag: 145000, paymentType: PaymentType.partial, amountPaid: 50000, date: _daysAgo(7)),
    ];
  }

  static List<Payment> seedPayments() {
    return [
      Payment(id: 'p1', customerId: 'c1', amount: 50000, date: _daysAgo(1), note: 'Malipo ya awali'),
      Payment(id: 'p2', customerId: 'c2', amount: 80000, date: _daysAgo(2)),
      Payment(id: 'p4', customerId: 'c4', amount: 100000, date: _daysAgo(1)),
    ];
  }
}
