import 'invoice_item_model.dart';

enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  partiallyPaid,
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String clientId;
  final DateTime issueDate;
  final DateTime dueDate;
  final InvoiceStatus status;
  final String notes;
  final List<InvoiceItemModel> items;
  final double subTotal;
  final double taxTotal;
  final double grandTotal;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.notes,
    required this.items,
    required this.subTotal,
    required this.taxTotal,
    required this.grandTotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'clientId': clientId,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'items': items.map((e) => e.toJson()).toList(),
      'subTotal': subTotal,
      'taxTotal': taxTotal,
      'grandTotal': grandTotal,
    };
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<InvoiceItemModel> parsedItems =
        list.map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>)).toList();

    return InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      clientId: json['clientId'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      notes: json['notes'] as String? ?? '',
      items: parsedItems,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      taxTotal: (json['taxTotal'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? clientId,
    DateTime? issueDate,
    DateTime? dueDate,
    InvoiceStatus? status,
    String? notes,
    List<InvoiceItemModel>? items,
    double? subTotal,
    double? taxTotal,
    double? grandTotal,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clientId ?? this.clientId,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      subTotal: subTotal ?? this.subTotal,
      taxTotal: taxTotal ?? this.taxTotal,
      grandTotal: grandTotal ?? this.grandTotal,
    );
  }
}
