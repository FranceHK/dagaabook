class BusinessProfile {
  final String businessName;
  final String ownerName;
  final String phone;
  final String location;
  final String currency;

  const BusinessProfile({
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.location,
    this.currency = 'TZS',
  });

  BusinessProfile copyWith({
    String? businessName,
    String? ownerName,
    String? phone,
    String? location,
    String? currency,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      currency: currency ?? this.currency,
    );
  }

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        businessName: json['business_name'] ?? '',
        ownerName: json['owner_name'] ?? '',
        phone: json['phone'] ?? '',
        location: json['location'] ?? '',
        currency: json['currency'] ?? 'TZS',
      );

  Map<String, dynamic> toJson() => {
        'business_name': businessName,
        'owner_name': ownerName,
        'phone': phone,
        'location': location,
        'currency': currency,
      };
}
