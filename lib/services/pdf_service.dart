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
    String template = 'classic',
  }) async {
    final baseFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

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
        debugPrint('Error loading logo in PDF generation: $e');
      }
    }

    final pdf = pw.Document();

    final String issueStr = DateFormatUtil.toIsoDate(invoice.issueDate);
    final String dueStr = DateFormatUtil.toIsoDate(invoice.dueDate);
    final String issueDisplayStr = DateFormatUtil.toDisplayDate(invoice.issueDate);

    switch (template.toLowerCase()) {
      case 'onenet':
        _buildOneNetTemplate(pdf, invoice, client, company, issueDisplayStr, logoImage, baseFont, boldFont, italicFont);
        break;
      case 'modern':
        _buildModernTemplate(pdf, invoice, client, company, issueStr, dueStr, logoImage, baseFont, boldFont, italicFont);
        break;
      case 'serif':
        _buildSerifTemplate(pdf, invoice, client, company, issueStr, dueStr, logoImage);
        break;
      case 'compact':
        _buildCompactTemplate(pdf, invoice, client, company, issueStr, dueStr, logoImage, baseFont, boldFont, italicFont);
        break;
      case 'classic':
      default:
        _buildClassicTemplate(pdf, invoice, client, company, issueStr, dueStr, logoImage, baseFont, boldFont, italicFont);
        break;
    }

    return pdf.save();
  }

  // ─────────────────────────────────────────────────────────
  // TEMPLATE 1: Classic Template (Default Layout)
  // ─────────────────────────────────────────────────────────
  static void _buildClassicTemplate(
    pw.Document pdf,
    InvoiceModel invoice,
    ClientModel client,
    CompanyModel company,
    String issueStr,
    String dueStr,
    pw.MemoryImage? logoImage,
    pw.Font baseFont,
    pw.Font boldFont,
    pw.Font italicFont,
  ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
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
                      item.productId,
                      item.productName,
                      item.quantity.toString(),
                      "${company.currency}${item.unitPrice.toStringAsFixed(2)}",
                      "${item.taxRate.toStringAsFixed(0)}%",
                      "${company.currency}${item.lineTotal.toStringAsFixed(2)}",
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 20),

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

                if (invoice.notes.isNotEmpty) ...[
                  pw.Text("Notes / Terms:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey800)),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                ],

                pw.Spacer(),
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
  }

  // ─────────────────────────────────────────────────────────
  // TEMPLATE 2: OneNet Solutions / Quote Style (Matches demo.pdf)
  // ─────────────────────────────────────────────────────────
  static void _buildOneNetTemplate(
    pw.Document pdf,
    InvoiceModel invoice,
    ClientModel client,
    CompanyModel company,
    String issueDisplayStr,
    pw.MemoryImage? logoImage,
    pw.Font baseFont,
    pw.Font boldFont,
    pw.Font italicFont,
  ) {
    final orange = PdfColor.fromHex('#f37021');
    final green = PdfColor.fromHex('#8dc63f');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Top full-bleed orange and green header bar with center box
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      height: 15,
                      color: orange,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: orange, width: 2),
                    ),
                    child: pw.Text(
                      invoice.status == InvoiceStatus.draft ? "Quote" : "Invoice",
                      style: pw.TextStyle(
                        color: green,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 15,
                      color: green,
                    ),
                  ),
                ],
              ),
              // Body with vertical margins
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 35, right: 35, top: 25, bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header details: Company left, Logo center, Date/Quote right
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Left Details
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                company.name,
                                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: green),
                              ),
                              if (company.taxId.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text("NTN# ${company.taxId}", style: const pw.TextStyle(fontSize: 9)),
                              ],
                              pw.SizedBox(height: 4),
                              pw.Container(
                                width: 150,
                                child: pw.Text(company.address, style: const pw.TextStyle(fontSize: 8), maxLines: 3),
                              ),
                              if (company.phone.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text("+${company.phone}", style: const pw.TextStyle(fontSize: 8)),
                              ],
                            ],
                          ),
                          // Center Logo
                          pw.Container(
                            width: 100,
                            height: 50,
                            alignment: pw.Alignment.center,
                            child: logoImage != null
                                ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                                : pw.Column(
                                    mainAxisAlignment: pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Text("ONE NET", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue300)),
                                      pw.Text("SOLUTIONS", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                                    ],
                                  ),
                          ),
                          // Right Details
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Container(width: 60, child: pw.Text("Date:", style: const pw.TextStyle(fontSize: 9))),
                                  pw.Text(issueDisplayStr, style: const pw.TextStyle(fontSize: 9)),
                                ],
                              ),
                              pw.SizedBox(height: 2),
                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: 60,
                                    child: pw.Text(
                                      invoice.status == InvoiceStatus.draft ? "Quote No.:" : "Invoice No.:",
                                      style: const pw.TextStyle(fontSize: 9),
                                    ),
                                  ),
                                  pw.Text(invoice.invoiceNumber, style: const pw.TextStyle(fontSize: 9)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),

                      // Bill To section
                      pw.Text(
                        "Bill To:",
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: green),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        client.name,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.Container(
                        width: 200,
                        child: pw.Text(client.billingAddress, style: const pw.TextStyle(fontSize: 8), maxLines: 3),
                      ),
                      pw.SizedBox(height: 15),

                      // Item Table (4 columns matching demo.pdf)
                      pw.TableHelper.fromTextArray(
                        headers: ['Qty', 'Description', 'Unit Price', 'Total'],
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: green, fontSize: 10),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
                        cellStyle: const pw.TextStyle(fontSize: 9),
                        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(1),
                          1: const pw.FlexColumnWidth(6),
                          2: const pw.FlexColumnWidth(2),
                          3: const pw.FlexColumnWidth(2),
                        },
                        cellAlignments: {
                          0: pw.Alignment.center,
                          1: pw.Alignment.centerLeft,
                          2: pw.Alignment.centerRight,
                          3: pw.Alignment.centerRight,
                        },
                        data: invoice.items.map((item) {
                          return [
                            item.quantity.toString(),
                            item.productName,
                            "${company.currency}${item.unitPrice.toStringAsFixed(0)}",
                            "${company.currency}${item.lineTotal.toStringAsFixed(0)}",
                          ];
                        }).toList(),
                      ),
                      pw.SizedBox(height: 10),

                      // Total & terms below table
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Left notes / default terms
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("All Prices are Without Taxes.", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              pw.Text("Price are valid for 2 Days only.", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              pw.Text("100 % Advance Payment.", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              if (invoice.notes.isNotEmpty) ...[
                                pw.SizedBox(height: 8),
                                pw.Container(
                                  width: 250,
                                  child: pw.Text("Notes: ${invoice.notes}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                                ),
                              ],
                            ],
                          ),
                          // Right Total
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Text("Total  ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                                  pw.Text(
                                    "${company.currency}${invoice.grandTotal.toStringAsFixed(0)}",
                                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.Spacer(),

                      pw.Align(
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Text("Thank you for your business.", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom full-bleed orange and green footer bar
              pw.Column(
                children: [
                  pw.Container(
                    height: 4,
                    color: green,
                  ),
                  pw.Container(
                    height: 10,
                    color: orange,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TEMPLATE 3: Modern Minimalist
  // ─────────────────────────────────────────────────────────
  static void _buildModernTemplate(
    pw.Document pdf,
    InvoiceModel invoice,
    ClientModel client,
    CompanyModel company,
    String issueStr,
    String dueStr,
    pw.MemoryImage? logoImage,
    pw.Font baseFont,
    pw.Font boldFont,
    pw.Font italicFont,
  ) {
    final charcoal = PdfColors.blueGrey900;
    final accentGrey = PdfColors.grey100;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Minimal header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoImage != null) ...[
                          pw.Container(
                            width: 50,
                            height: 50,
                            margin: const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                        ],
                        pw.Text(
                          company.name,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: charcoal),
                        ),
                        pw.Text(company.address, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          "INVOICE",
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: charcoal, letterSpacing: 1.5),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text("#${invoice.invoiceNumber}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.grey700)),
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 4),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: _getStatusBgColor(invoice.status),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            invoice.status.name.toUpperCase(),
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _getStatusColor(invoice.status)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 15),

                // Bill-To and Date Grid
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("CLIENT", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500)),
                        pw.SizedBox(height: 4),
                        pw.Text(client.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: charcoal)),
                        pw.Text(client.email, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text("Billing: ${client.billingAddress}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("DATE OF ISSUE", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500)),
                        pw.Text(issueStr, style: pw.TextStyle(fontSize: 9, color: charcoal)),
                        pw.SizedBox(height: 6),
                        pw.Text("DATE DUE", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500)),
                        pw.Text(dueStr, style: pw.TextStyle(fontSize: 9, color: charcoal)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                // Borderless horizontal line table
                pw.TableHelper.fromTextArray(
                  headers: ['SKU', 'Description', 'Qty', 'Unit Price', 'Total'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: charcoal, fontSize: 9),
                  headerDecoration: pw.BoxDecoration(color: accentGrey),
                  cellStyle: const pw.TextStyle(fontSize: 8.5),
                  border: const pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(4.5),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                  },
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  data: invoice.items.map((item) {
                    return [
                      item.productId,
                      item.productName,
                      item.quantity.toString(),
                      "${company.currency}${item.unitPrice.toStringAsFixed(2)}",
                      "${company.currency}${item.lineTotal.toStringAsFixed(2)}",
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 15),

                // Calc Box
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 180,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Subtotal:", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                              pw.Text("${company.currency}${invoice.subTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 9, color: charcoal)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Tax:", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                              pw.Text("${company.currency}${invoice.taxTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 9, color: charcoal)),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            color: charcoal,
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text("Total Due:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white)),
                                pw.Text(
                                  "${company.currency}${invoice.grandTotal.toStringAsFixed(2)}",
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                if (invoice.notes.isNotEmpty) ...[
                  pw.Text("Notes", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: charcoal)),
                  pw.SizedBox(height: 2),
                  pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],

                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text("Invoice generated digitally.", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TEMPLATE 4: Elegant Serif
  // ─────────────────────────────────────────────────────────
  static void _buildSerifTemplate(
    pw.Document pdf,
    InvoiceModel invoice,
    ClientModel client,
    CompanyModel company,
    String issueStr,
    String dueStr,
    pw.MemoryImage? logoImage,
  ) {
    final burgundy = PdfColor.fromHex('#7A1C1C');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: pw.Font.times(),
          bold: pw.Font.timesBold(),
          italic: pw.Font.timesItalic(),
        ),
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(35),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Centered header
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Column(
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          width: 50,
                          height: 50,
                          margin: const pw.EdgeInsets.only(bottom: 6),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      ],
                      pw.Text(
                        company.name,
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: burgundy),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(company.address, style: const pw.TextStyle(fontSize: 8.5)),
                      if (company.taxId.isNotEmpty)
                        pw.Text("Tax ID: ${company.taxId}", style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                // Double lines separator
                pw.Container(
                  height: 1,
                  color: burgundy,
                  margin: const pw.EdgeInsets.only(bottom: 2),
                ),
                pw.Container(
                  height: 0.5,
                  color: burgundy,
                  margin: const pw.EdgeInsets.only(bottom: 15),
                ),

                // Invoice metadata & billing
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("BILL TO", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: burgundy)),
                        pw.SizedBox(height: 4),
                        pw.Text(client.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text(client.email, style: const pw.TextStyle(fontSize: 9)),
                        pw.Container(
                          width: 200,
                          child: pw.Text("Address: ${client.billingAddress}", style: const pw.TextStyle(fontSize: 8.5), maxLines: 3),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("INVOICE DOCUMENT", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: burgundy)),
                        pw.SizedBox(height: 4),
                        pw.Text("Invoice No: ${invoice.invoiceNumber}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                        pw.Text("Issue Date: $issueStr", style: const pw.TextStyle(fontSize: 9)),
                        pw.Text("Due Date: $dueStr", style: const pw.TextStyle(fontSize: 9)),
                        pw.Text("Status: ${invoice.status.name.toUpperCase()}", style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                // Table
                pw.TableHelper.fromTextArray(
                  headers: ['SKU', 'Product Description', 'Qty', 'Unit Price', 'Line Total'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                  headerDecoration: pw.BoxDecoration(color: burgundy),
                  cellStyle: const pw.TextStyle(fontSize: 8.5),
                  border: pw.TableBorder.all(color: burgundy, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.8),
                    1: const pw.FlexColumnWidth(4.2),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.8),
                  },
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  data: invoice.items.map((item) {
                    return [
                      item.productId,
                      item.productName,
                      item.quantity.toString(),
                      "${company.currency}${item.unitPrice.toStringAsFixed(2)}",
                      "${company.currency}${item.lineTotal.toStringAsFixed(2)}",
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 15),

                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 180,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Subtotal:", style: const pw.TextStyle(fontSize: 9)),
                              pw.Text("${company.currency}${invoice.subTotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                          pw.SizedBox(height: 3),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Tax Amount:", style: const pw.TextStyle(fontSize: 9)),
                              pw.Text("${company.currency}${invoice.taxTotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(height: 0.5, color: burgundy),
                          pw.SizedBox(height: 2),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Grand Total:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: burgundy)),
                              pw.Text(
                                "${company.currency}${invoice.grandTotal.toStringAsFixed(2)}",
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: burgundy),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          pw.Container(height: 1.5, color: burgundy),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                if (invoice.notes.isNotEmpty) ...[
                  pw.Text("Terms and Notes", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: burgundy)),
                  pw.SizedBox(height: 3),
                  pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 8.5)),
                ],

                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text("Thank you for your patronage.", style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TEMPLATE 5: Compact Retail / Receipt Style
  // ─────────────────────────────────────────────────────────
  static void _buildCompactTemplate(
    pw.Document pdf,
    InvoiceModel invoice,
    ClientModel client,
    CompanyModel company,
    String issueStr,
    String dueStr,
    pw.MemoryImage? logoImage,
    pw.Font baseFont,
    pw.Font boldFont,
    pw.Font italicFont,
  ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(15),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Small centered logo & company details
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Column(
                  children: [
                    if (logoImage != null) ...[
                      pw.Container(
                        width: 40,
                        height: 40,
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    ],
                    pw.Text(company.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(company.address, style: const pw.TextStyle(fontSize: 8)),
                    pw.Text("Tax ID: ${company.taxId}", style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text("----------------------------------------------------------------------------------------------------", style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),

              // Metadata row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("INVOICE: #${invoice.invoiceNumber}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                  pw.Text("DATE: $issueStr", style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Text("CLIENT: ${client.name} (${client.phone})", style: const pw.TextStyle(fontSize: 8)),
              pw.Text("DUE DATE: $dueStr", style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              pw.Text("----------------------------------------------------------------------------------------------------", style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),

              // Gridless table separated by simple line
              pw.TableHelper.fromTextArray(
                headers: ['Item Description', 'Qty', 'Price', 'Total'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                border: null,
                columnWidths: {
                  0: const pw.FlexColumnWidth(5),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                data: invoice.items.map((item) {
                  return [
                    item.productName,
                    item.quantity.toString(),
                    "${company.currency}${item.unitPrice.toStringAsFixed(2)}",
                    "${company.currency}${item.lineTotal.toStringAsFixed(2)}",
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 4),
              pw.Text("----------------------------------------------------------------------------------------------------", style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 150,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Subtotal:", style: const pw.TextStyle(fontSize: 8)),
                            pw.Text("${company.currency}${invoice.subTotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Tax Amount:", style: const pw.TextStyle(fontSize: 8)),
                            pw.Text("${company.currency}${invoice.taxTotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("GRAND TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            pw.Text("${company.currency}${invoice.grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              if (invoice.notes.isNotEmpty) ...[
                pw.Text("NOTES:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 7.5)),
              ],

              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text("--- CUSTOMER COPY ---", style: const pw.TextStyle(fontSize: 7)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Helper: Status Color mapping
  // ─────────────────────────────────────────────────────────
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

  static PdfColor _getStatusBgColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return PdfColor.fromHex('#E8F5E9');
      case InvoiceStatus.overdue:
        return PdfColor.fromHex('#FFEBEE');
      case InvoiceStatus.partiallyPaid:
        return PdfColor.fromHex('#FFF3E0');
      case InvoiceStatus.sent:
        return PdfColor.fromHex('#E3F2FD');
      case InvoiceStatus.draft:
        return PdfColor.fromHex('#F5F5F5');
    }
  }
}
