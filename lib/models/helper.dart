/// A helper (msaidizi) the owner lets into the app on their own phone. A
/// helper can only see customers, add customers and make cash sales.
class Helper {
  final String id;
  final String name;
  final String phone;
  final String salt;
  final String passwordHash;
  final bool active;
  final DateTime createdAt;

  const Helper({
    required this.id,
    required this.name,
    required this.phone,
    required this.salt,
    required this.passwordHash,
    this.active = true,
    required this.createdAt,
  });

  Helper copyWith({String? name, String? phone, String? salt, String? passwordHash, bool? active}) => Helper(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        salt: salt ?? this.salt,
        passwordHash: passwordHash ?? this.passwordHash,
        active: active ?? this.active,
        createdAt: createdAt,
      );

  factory Helper.fromJson(Map<String, dynamic> json) => Helper(
        id: json['id'],
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        salt: json['salt'] ?? '',
        passwordHash: json['password_hash'] ?? '',
        active: json['active'] ?? true,
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'salt': salt,
        'password_hash': passwordHash,
        'active': active,
        'created_at': createdAt.toIso8601String(),
      };
}
