import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_managment_system/models/client_model.dart';
import 'package:invoice_managment_system/models/company_model.dart';
import 'package:invoice_managment_system/models/invoice_item_model.dart';
import 'package:invoice_managment_system/models/invoice_model.dart';
import 'package:invoice_managment_system/services/pdf_service.dart';

void main() {
  test('all invoice PDF templates generate valid documents', () async {
    final invoice = InvoiceModel(
      id: 'test-invoice',
      invoiceNumber: 'INV-TEST-001',
      clientId: 'test-client',
      issueDate: DateTime(2026, 7, 22),
      dueDate: DateTime(2026, 8, 22),
      status: InvoiceStatus.sent,
      notes: 'Template verification',
      items: [
        InvoiceItemModel(
          id: 'item-1',
          productId: 'product-1',
          productName: 'Test Product',
          quantity: 2,
          unitPrice: 100,
          taxRate: 10,
        ),
      ],
      subTotal: 200,
      taxTotal: 20,
      grandTotal: 220,
    );
    final client = ClientModel(
      id: 'test-client',
      name: 'Test Client',
      email: 'client@example.com',
      phone: '+92 300 0000000',
      billingAddress: 'Pakistan',
      shippingAddress: 'Pakistan',
    );
    final company = CompanyModel(
      name: 'Test Company',
      logo: '',
      taxId: 'TAX-1',
      address: 'Pakistan',
      currency: 'PKR',
    );

    for (final template in [
      'Classic',
      'Modern',
      'Minimal',
      'Corporate',
      'Elegant',
    ]) {
      final bytes = await PdfService.generateInvoicePdf(
        invoice: invoice,
        client: client,
        company: company,
        template: template,
      );
      expect(bytes, isNotEmpty, reason: '$template PDF was empty');
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    }
  });
}
