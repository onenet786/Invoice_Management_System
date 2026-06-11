class ProductModel {
  final String id;
  final String name;
  final String description;
  final String sku;
  final double unitPrice;
  final String category; // "Solar" or "IT"
  final double taxRate; // as percentage, e.g. 15.0

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.sku,
    required this.unitPrice,
    required this.category,
    required this.taxRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'unitPrice': unitPrice,
      'category': category,
      'taxRate': taxRate,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Solar',
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? sku,
    double? unitPrice,
    String? category,
    double? taxRate,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      unitPrice: unitPrice ?? this.unitPrice,
      category: category ?? this.category,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}
