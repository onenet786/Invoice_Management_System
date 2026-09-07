class CompanyModel {
  final String name;
  final String logo; // base64 representation or URL
  final String taxId;
  final String address;
  final String currency; // currency symbol e.g., "$", "PKR", "€"

  CompanyModel({
    required this.name,
    required this.logo,
    required this.taxId,
    required this.address,
    required this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logo': logo,
      'taxId': taxId,
      'address': address,
      'currency': currency,
    };
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      name: json['name'] as String? ?? 'My Solar & IT Corp',
      logo: json['logo'] as String? ?? '',
      taxId: json['taxId'] as String? ?? '',
      address:
          json['address'] as String? ??
          '123 Tech Avenue, Suite 100, Silicon Valley, CA',
      currency: json['currency'] as String? ?? '\$',
    );
  }

  CompanyModel copyWith({
    String? name,
    String? logo,
    String? taxId,
    String? address,
    String? currency,
  }) {
    return CompanyModel(
      name: name ?? this.name,
      logo: logo ?? this.logo,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      currency: currency ?? this.currency,
    );
  }
}
