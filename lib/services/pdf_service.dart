import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/invoice_model.dart';
import '../models/client_model.dart';
import '../models/company_model.dart';
import '../utils/date_format_util.dart';

class PdfService {
  static Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required ClientModel client,
    required CompanyModel company,
  }) async {
    final baseFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        italic: italicFont,
      ),
    );

    final String issueStr = DateFormatUtil.toIsoDate(invoice.issueDate);
    final String dueStr = DateFormatUtil.toIsoDate(invoice.dueDate);

    pw.MemoryImage? logoImage;
    if (company.logo.isNotEmpty) {
      try {
        if (company.logo.startsWith('http://') || company.logo.startsWith('https://')) {
          final response = await http.get(Uri.parse(company.logo)).timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            logoImage = pw.MemoryImage(response.bodyBytes);
          }
        } else {
          String cleanBase64 = company.logo;
          if (company.logo.contains('base64,')) {
            cleanBase64 = company.logo.split('base64,').last;
          }
          final bytes = base64Decode(cleanBase64.trim());
          logoImage = pw.MemoryImage(bytes);
        }
      } catch (e) {
        // Ignore/log error during PDF generation to prevent document rendering failure
        debugPrint('Error loading logo in PDF generation: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header (Company Name, Invoice title)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoImage != null) ...[
                          pw.Container(
                            width: 60,
                            height: 60,
                            margin: const pw.EdgeInsets.only(right: 12),
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                        ],
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              company.name,
                              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(company.address, style: const pw.TextStyle(fontSize: 9)),
                            pw.SizedBox(height: 2),
                            pw.Text("Tax ID: ${company.taxId}", style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          "INVOICE",
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text("Invoice Number: ${invoice.invoiceNumber}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text("Status: ${invoice.status.name.toUpperCase()}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _getStatusColor(invoice.status), fontSize: 9)),
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
                        pw.Text("BILL TO:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(client.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.Text(client.email, style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(client.phone, style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          width: 220,
                          child: pw.Text("Address: ${client.billingAddress}", style: const pw.TextStyle(fontSize: 9), maxLines: 3),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text("Issue Date: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.Text(issueStr, style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text("Due Date: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.Text(dueStr, style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                // Table of items
                pw.TableHelper.fromTextArray(
                  headers: ['Product/Service SKU', 'Description', 'Qty', 'Unit Price', 'Tax', 'Total'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
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
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Subtotal:", style: const pw.TextStyle(fontSize: 10)),
                              pw.Text("${company.currency}${invoice.subTotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Tax Total:", style: const pw.TextStyle(fontSize: 10)),
                              pw.Text("${company.currency}${invoice.taxTotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Divider(thickness: 1, color: PdfColors.grey300),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Grand Total:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.indigo900)),
                              pw.Text("${company.currency}${invoice.grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.indigo900)),
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
                  pw.Text("Notes / Terms:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey800)),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                ],

                pw.Spacer(),
                // Footer
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 4),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text("Thank you for your business!", style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
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
}
