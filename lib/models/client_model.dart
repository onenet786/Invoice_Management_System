class ClientModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String billingAddress;
  final String shippingAddress;

  ClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.billingAddress,
    required this.shippingAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'billingAddress': billingAddress,
      'shippingAddress': shippingAddress,
    };
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      billingAddress: json['billingAddress'] as String? ?? '',
      shippingAddress: json['shippingAddress'] as String? ?? '',
    );
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? billingAddress,
    String? shippingAddress,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
    );
  }
}
