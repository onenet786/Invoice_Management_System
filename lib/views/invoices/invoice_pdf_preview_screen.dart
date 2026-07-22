import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../providers/app_state_provider.dart';
import '../../models/invoice_model.dart';
import '../../models/client_model.dart';
import '../../services/pdf_service.dart';

class InvoicePdfPreviewScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoicePdfPreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final client = state.clients.firstWhere(
      (c) => c.id == invoice.clientId,
      orElse: () => ClientModel(
        id: '',
        name: 'Unknown Client',
        email: 'N/A',
        phone: 'N/A',
        billingAddress: 'No address',
        shippingAddress: 'No address',
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('PDF Preview - ${invoice.invoiceNumber}')),
      body: PdfPreview(
        build: (format) => PdfService.generateInvoicePdf(
          invoice: invoice,
          client: client,
          company: state.company,
          template: state.pdfTemplate,
        ),
        canDebug: false,
        actions: const [],
        pdfFileName: '${invoice.invoiceNumber}.pdf',
      ),
    );
  }
}
