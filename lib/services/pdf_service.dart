import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';
import '../models/client_model.dart';
import '../models/company_model.dart';

class PdfService {
  static Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required ClientModel client,
    required CompanyModel company,
    String template = 'Classic',
  }) async {
    final pdf = pw.Document();
    final style = _templateStyle(template);
    pw.MemoryImage? logo;
    if (company.logo.isNotEmpty) {
      try {
        logo = pw.MemoryImage(base64Decode(company.logo));
      } catch (_) {
        logo = null;
      }
    }

    final String issueStr = invoice.issueDate.toIso8601String().split('T')[0];
    final String dueStr = invoice.dueDate.toIso8601String().split('T')[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (style.banner)
                  pw.Container(
                    width: double.infinity,
                    height: 8,
                    margin: const pw.EdgeInsets.only(bottom: 16),
                    decoration: pw.BoxDecoration(
                      color: style.accent,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                // Header (Company Name, Invoice title)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logo != null) ...[
                          pw.Image(
                            logo,
                            width: 64,
                            height: 42,
                            fit: pw.BoxFit.contain,
                          ),
                          pw.SizedBox(height: 8),
                        ],
                        pw.Text(
                          company.name,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: style.heading,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          company.address,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "Tax ID: ${company.taxId}",
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          style.invoiceTitle,
                          style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: style.accent,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "Invoice Number: ${invoice.invoiceNumber}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        pw.Text(
                          "Status: ${invoice.status.name.toUpperCase()}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: _getStatusColor(invoice.status),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 15),

                // Client details & dates
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "BILL TO:",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          client.name,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.Text(
                          client.email,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          client.phone,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          width: 220,
                          child: pw.Text(
                            "Address: ${client.billingAddress}",
                            style: const pw.TextStyle(fontSize: 9),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text(
                              "Issue Date: ",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            pw.Text(
                              issueStr,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text(
                              "Due Date: ",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            pw.Text(
                              dueStr,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                // Table of items
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Product/Service SKU',
                    'Description',
                    'Qty',
                    'Unit Price',
                    'Tax',
                    'Total',
                  ],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                  headerDecoration: pw.BoxDecoration(color: style.accent),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1),
                    5: const pw.FlexColumnWidth(1.8),
                  },
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.center,
                    5: pw.Alignment.centerRight,
                  },
                  data: invoice.items.map((item) {
                    return [
                      item.productId, // We can show standard IDs or SKU references
                      item.productName,
                      item.quantity.toString(),
                      "${company.currency}${item.unitPrice.toStringAsFixed(2)}",
                      "${item.taxRate.toStringAsFixed(0)}%",
                      "${company.currency}${item.lineTotal.toStringAsFixed(2)}",
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 20),

                // Calculation Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "Subtotal:",
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                              pw.Text(
                                "${company.currency}${invoice.subTotal.toStringAsFixed(2)}",
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "Tax Total:",
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                              pw.Text(
                                "${company.currency}${invoice.taxTotal.toStringAsFixed(2)}",
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Divider(thickness: 1, color: PdfColors.grey300),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "Grand Total:",
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                  color: style.accent,
                                ),
                              ),
                              pw.Text(
                                "${company.currency}${invoice.grandTotal.toStringAsFixed(2)}",
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                  color: style.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),

                // Notes
                if (invoice.notes.isNotEmpty) ...[
                  pw.Text(
                    "Notes / Terms:",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.notes,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],

                pw.Spacer(),
                // Footer
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 4),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    style.footerText,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static _PdfTemplateStyle _templateStyle(String template) {
    switch (template) {
      case 'Modern':
        return const _PdfTemplateStyle(
          accent: PdfColors.teal700,
          heading: PdfColors.teal900,
          invoiceTitle: 'INVOICE / MODERN',
          footerText: 'Simple. Clear. Professional.',
          banner: true,
        );
      case 'Minimal':
        return const _PdfTemplateStyle(
          accent: PdfColors.grey800,
          heading: PdfColors.black,
          invoiceTitle: 'INVOICE',
          footerText: 'Thank you.',
          banner: false,
        );
      case 'Corporate':
        return const _PdfTemplateStyle(
          accent: PdfColors.blue900,
          heading: PdfColors.blueGrey900,
          invoiceTitle: 'TAX INVOICE',
          footerText: 'Issued electronically by the accounts department.',
          banner: true,
        );
      case 'Elegant':
        return const _PdfTemplateStyle(
          accent: PdfColors.deepPurple700,
          heading: PdfColors.deepPurple900,
          invoiceTitle: 'Invoice',
          footerText: 'With appreciation for your business.',
          banner: false,
        );
      default:
        return const _PdfTemplateStyle(
          accent: PdfColors.indigo900,
          heading: PdfColors.blueGrey800,
          invoiceTitle: 'INVOICE',
          footerText: 'Thank you for your business!',
          banner: false,
        );
    }
  }

  static PdfColor _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return PdfColors.green700;
      case InvoiceStatus.overdue:
        return PdfColors.red700;
      case InvoiceStatus.partiallyPaid:
        return PdfColors.orange700;
      case InvoiceStatus.sent:
        return PdfColors.blue700;
      case InvoiceStatus.draft:
        return PdfColors.grey700;
    }
  }

  static Future<Uint8List> generateSampleInvoicePdf({
    required CompanyModel company,
    String template = 'Classic',
  }) async {
    final sampleClient = ClientModel(
      id: 'sample-client',
      name: 'Acme Global Enterprises',
      email: 'billing@acmeglobal.com',
      phone: '+1 (555) 019-2831',
      billingAddress: '100 Innovation Blvd, Suite 300, San Francisco, CA 94107',
      shippingAddress: '100 Innovation Blvd, Suite 300, San Francisco, CA 94107',
    );

    final sampleInvoice = InvoiceModel(
      id: 'sample-inv',
      invoiceNumber: 'INV-2026-PREVIEW',
      clientId: 'sample-client',
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      status: InvoiceStatus.sent,
      notes: 'Thank you for your business. Payment due within 30 days.',
      items: [
        InvoiceItemModel(
          id: 'item-1',
          productId: 'SKU-SOL-550',
          productName: 'Monocrystalline Solar Panel (550W)',
          quantity: 4,
          unitPrice: 249.99,
          taxRate: 15.0,
        ),
        InvoiceItemModel(
          id: 'item-2',
          productId: 'SKU-IT-SRV',
          productName: 'Managed Cloud Infrastructure Setup',
          quantity: 1,
          unitPrice: 1200.00,
          taxRate: 10.0,
        ),
      ],
      subTotal: 2199.96,
      taxTotal: 270.00,
      grandTotal: 2469.96,
    );

    return generateInvoicePdf(
      invoice: sampleInvoice,
      client: sampleClient,
      company: company,
      template: template,
    );
  }
}

class _PdfTemplateStyle {
  final PdfColor accent;
  final PdfColor heading;
  final String invoiceTitle;
  final String footerText;
  final bool banner;

  const _PdfTemplateStyle({
    required this.accent,
    required this.heading,
    required this.invoiceTitle,
    required this.footerText,
    required this.banner,
  });
}
