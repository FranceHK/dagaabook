class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String businessName;
  final String location;
  final DateTime createdAt;

  const User({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    required this.phone,
    this.businessName = '',
    this.location = '',
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      businessName: json['business_name'] ?? '',
      location: json['location'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'business_name': businessName,
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
