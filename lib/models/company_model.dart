class CompanyModel {
  final String name;
  final String logo; // base64 representation or URL
  final String taxId;
  final String address;
  final String currency; // currency symbol e.g., "$", "PKR", "€"
  final String phone;
  final String whatsappInstance; // EvolutionAPI instance name e.g., "reports4"

  CompanyModel({
    required this.name,
    required this.logo,
    required this.taxId,
    required this.address,
    required this.currency,
    required this.phone,
    required this.whatsappInstance,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logo': logo,
      'taxId': taxId,
      'address': address,
      'currency': currency,
      'phone': phone,
      'whatsappInstance': whatsappInstance,
    };
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      name: json['name'] as String? ?? 'My Solar & IT Corp',
      logo: json['logo'] as String? ?? '',
      taxId: json['taxId'] as String? ?? 'TAX-882200-XX',
      address: json['address'] as String? ?? '123 Tech Avenue, Suite 100, Silicon Valley, CA',
      currency: json['currency'] as String? ?? 'PKR',
      phone: json['phone'] as String? ?? '',
      whatsappInstance: json['whatsappInstance'] as String? ?? '',
    );
  }

  CompanyModel copyWith({
    String? name,
    String? logo,
    String? taxId,
    String? address,
    String? currency,
    String? phone,
    String? whatsappInstance,
  }) {
    return CompanyModel(
      name: name ?? this.name,
      logo: logo ?? this.logo,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      currency: currency ?? this.currency,
      phone: phone ?? this.phone,
      whatsappInstance: whatsappInstance ?? this.whatsappInstance,
    );
  }
}
