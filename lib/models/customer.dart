/// A wholesale customer (mteja). Debt balance is derived at runtime from
/// linked sales/payments in providers, not stored redundantly here.
class Customer {
  final String id;
  final String name;
  final String phone;
  final String location;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.location = '',
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? location,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
