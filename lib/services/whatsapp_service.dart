import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../models/client_model.dart';
import '../models/company_model.dart';
import '../utils/date_format_util.dart';
import 'pdf_service.dart';

class WhatsAppService {
  static Future<bool> sendInvoiceWhatsApp({
    required InvoiceModel invoice,
    required ClientModel client,
    required CompanyModel company,
    required String webhookUrl,
    String? apiKey,
  }) async {
    if (webhookUrl.isEmpty) return false;

    try {
      // 1. Generate PDF in memory
      final pdfBytes = await PdfService.generateInvoicePdf(
        invoice: invoice,
        client: client,
        company: company,
      );
      final String pdfBase64 = base64Encode(pdfBytes);

      // 2. Format a pre-defined message text for WhatsApp (uses * for bold and • for bullet points)
      final String issueStr = DateFormatUtil.toIsoDate(invoice.issueDate);
      final String dueStr = DateFormatUtil.toIsoDate(invoice.dueDate);
      
      final itemsList = invoice.items.map(
        (item) => "• ${item.productName} (x${item.quantity}): ${company.currency}${item.lineTotal.toStringAsFixed(2)}"
      ).join("\n");

      final String messageText = 
          "*Dear ${client.name},*\n\n"
          "Please find the summary of your *Invoice ${invoice.invoiceNumber}* from *${company.name}*.\n\n"
          "*Invoice Details:*\n"
          "• Issue Date: $issueStr\n"
          "• Due Date: $dueStr\n"
          "• Total Amount Due: *${company.currency}${invoice.grandTotal.toStringAsFixed(2)}*\n\n"
          "*Items:*\n"
          "$itemsList\n\n"
          "${invoice.notes.isNotEmpty ? '*Notes:* ${invoice.notes}\n\n' : ''}"
          "Best regards,\n"
          "*${company.name}*";

      // 3. Build payload
      final Map<String, dynamic> payload = {
        'event': 'invoice.send',
        'timestamp': DateTime.now().toIso8601String(),
        'messageText': messageText,
        'pdfBase64': pdfBase64,
        'fileName': 'Invoice-${invoice.invoiceNumber}.pdf',
        'invoice': invoice.toJson(),
        'client': client.toJson(),
        'company': company.toJson(),
      };

      // 4. Send HTTP POST request
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      if (apiKey != null && apiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer $apiKey';
        headers['x-api-key'] = apiKey;
      }

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('WhatsApp n8n webhook error: Status ${response.statusCode}, Body ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp webhook: $e');
      return false;
    }
  }
}
