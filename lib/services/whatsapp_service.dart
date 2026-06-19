import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../models/client_model.dart';
import '../models/company_model.dart';
import '../utils/date_format_util.dart';
import 'pdf_service.dart';

class WhatsAppService {
  // ─────────────────────────────────────────────────────────
  // HELPER: Normalize phone to international format
  // Strips non-digits, converts 0XXX → 92XXX (Pakistan)
  // ─────────────────────────────────────────────────────────
  static String _normalizePhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = '92${digits.substring(1)}';
    }
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  // ─────────────────────────────────────────────────────────
  // HELPER: Clean Base64 image payload (strip data URI prefix)
  // ─────────────────────────────────────────────────────────
  static String _cleanImage(String logo) {
    if (logo.startsWith('http://') || logo.startsWith('https://')) {
      return logo;
    }
    if (logo.contains('base64,')) {
      return logo.split('base64,').last.trim();
    }
    return logo.trim();
  }

  // ─────────────────────────────────────────────────────────
  // HELPER: Build formatted WhatsApp invoice message
  // ─────────────────────────────────────────────────────────
  static String _buildMessageText({
    required InvoiceModel invoice,
    required ClientModel client,
    required CompanyModel company,
  }) {
    final String issueStr = DateFormatUtil.toIsoDate(invoice.issueDate);
    final String dueStr = DateFormatUtil.toIsoDate(invoice.dueDate);
    final itemsList = invoice.items
        .map(
          (item) =>
              '• ${item.productName} (x${item.quantity}): ${company.currency}${item.lineTotal.toStringAsFixed(2)}',
        )
        .join('\n');

    return '*Dear ${client.name},*\n\n'
        'Please find the summary of your *Invoice ${invoice.invoiceNumber}* from *${company.name}*.\n\n'
        '*Invoice Details:*\n'
        '• Issue Date: $issueStr\n'
        '• Due Date: $dueStr\n'
        '• Total Amount Due: *${company.currency}${invoice.grandTotal.toStringAsFixed(2)}*\n\n'
        '${itemsList.isNotEmpty ? '*Items:*\n$itemsList\n\n' : ''}'
        '${invoice.notes.isNotEmpty ? '*Notes:* ${invoice.notes}\n\n' : ''}'
        'Best regards,\n'
        '*${company.name}*';
  }

  // ─────────────────────────────────────────────────────────
  // HELPER: POST to n8n webhook
  // ─────────────────────────────────────────────────────────
  static Future<bool> _postToWebhook({
    required String webhookUrl,
    required Map<String, dynamic> payload,
    String? apiKey,
  }) async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
      headers['x-api-key'] = apiKey;
    }
    try {
      final response = await http
          .post(
            Uri.parse(webhookUrl),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('WhatsApp webhook success: ${response.body}');
        return true;
      } else {
        debugPrint(
          'WhatsApp webhook error: Status ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('WhatsApp webhook exception: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // METHOD 1: Send Real Invoice via WhatsApp
  // company.phone = sender (EvolutionAPI instance number)
  // client.phone  = recipient
  // ─────────────────────────────────────────────────────────
  static Future<bool> sendInvoiceWhatsApp({
    required InvoiceModel invoice,
    required ClientModel client,
    required CompanyModel company,
    required String webhookUrl,
    String? apiKey,
    String template = 'classic',
    bool sendText = true,
    bool sendPdf = true,
    bool sendImage = true,
  }) async {
    if (webhookUrl.isEmpty) {
      debugPrint('WhatsApp: webhookUrl is empty');
      return false;
    }
    try {
      // Normalize recipient phone
      final String phone = _normalizePhone(client.phone);
      if (phone.length < 10) {
        debugPrint('WhatsApp: invalid recipient phone: ${client.phone}');
        return false;
      }

      // Determine sender instance (prefer custom instance name, fallback to normalized company phone, fallback to default reports4)
      final String sender = company.whatsappInstance.isNotEmpty
          ? company.whatsappInstance
          : (company.phone.isNotEmpty ? _normalizePhone(company.phone) : 'reports4');

      String? pdfBase64;
      if (sendPdf) {
        // Generate PDF
        final pdfBytes = await PdfService.generateInvoicePdf(
          invoice: invoice,
          client: client,
          company: company,
          template: template,
        );
        pdfBase64 = base64Encode(pdfBytes);
      }

      // Build message
      final String message = _buildMessageText(
        invoice: invoice,
        client: client,
        company: company,
      );

      // Build payload matching n8n Parse & Validate node
      final Map<String, dynamic> payload = {
        'event': 'invoice.send',
        'timestamp': DateTime.now().toIso8601String(),
        // n8n reads these directly
        'phone': phone,
        if (sendText) 'message': message,
        if (sendPdf && pdfBase64 != null) ...{
          'pdf_base64': pdfBase64,
          'fileName': 'Invoice-${invoice.invoiceNumber}.pdf',
        },
        // Nested fallbacks
        'invoice': {
          ...invoice.toJson(),
          if (sendPdf && pdfBase64 != null) ...{
            'filename': 'Invoice-${invoice.invoiceNumber}.pdf',
            'pdf': pdfBase64,
          },
        },
        'client': {...client.toJson(), 'phone': phone},
        'company': company.toJson(),
      };

      debugPrint('WhatsApp Service: Raw company.phone = "${company.phone}"');
      debugPrint('WhatsApp Service: Raw company.whatsappInstance = "${company.whatsappInstance}"');
      debugPrint('WhatsApp Service: Selected sender/instance = "$sender"');

      // Add sender if available
      if (sender.isNotEmpty) {
        payload['sender'] = sender;
        payload['sender_phone'] = sender;
        payload['senderPhone'] = sender;
        payload['sender_number'] = sender;
        payload['senderNumber'] = sender;
      }

      // Add company logo as image if available
      if (sendImage && company.logo.isNotEmpty) {
        payload['image'] = _cleanImage(company.logo);
      }

      debugPrint('WhatsApp webhook payload: ${jsonEncode(payload)}');

      return await _postToWebhook(
        webhookUrl: webhookUrl,
        payload: payload,
        apiKey: apiKey,
      );
    } catch (e) {
      debugPrint('sendInvoiceWhatsApp error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // METHOD 2: Send Test WhatsApp (from Settings dialog)
  // company.phone = sender (set in Company Profile card)
  // phone param   = recipient (entered in test dialog)
  // ─────────────────────────────────────────────────────────
  static Future<bool> sendTestWhatsApp({
    required String phone,
    required String message,
    required String webhookUrl,
    required CompanyModel company,
    String? apiKey,
    String template = 'classic',
    bool sendText = true,
    bool sendPdf = true,
    bool sendImage = true,
  }) async {
    if (webhookUrl.isEmpty) {
      debugPrint('WhatsApp: webhookUrl is empty');
      return false;
    }
    try {
      // Normalize recipient phone
      final String normalizedPhone = _normalizePhone(phone);
      if (normalizedPhone.length < 10) {
        debugPrint('WhatsApp: invalid phone: $phone');
        return false;
      }

      // Sender = custom instance name or normalized company phone or default reports4
      final String sender = company.whatsappInstance.isNotEmpty
          ? company.whatsappInstance
          : (company.phone.isNotEmpty ? _normalizePhone(company.phone) : 'reports4');

      // Dummy client using recipient phone
      final dummyClient = ClientModel(
        id: 'test-client',
        name: 'Test Recipient',
        email: 'test@example.com',
        phone: normalizedPhone,
        billingAddress: '123 Test Street',
        shippingAddress: '123 Test Street',
      );

      // Dummy invoice
      final dummyInvoice = InvoiceModel(
        id: 'test-inv-id',
        invoiceNumber: 'TEST-0001',
        clientId: 'test-client',
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        items: [],
        subTotal: 0.0,
        taxTotal: 0.0,
        grandTotal: 0.0,
        status: InvoiceStatus.draft,
        notes: 'This is a test invoice message.',
      );

      String? pdfBase64;
      if (sendPdf) {
        // Generate test PDF
        final pdfBytes = await PdfService.generateInvoicePdf(
          invoice: dummyInvoice,
          client: dummyClient,
          company: company,
          template: template,
        );
        pdfBase64 = base64Encode(pdfBytes);
      }

      // Build payload matching n8n Parse & Validate node
      final Map<String, dynamic> payload = {
        'event': 'invoice.test',
        'timestamp': DateTime.now().toIso8601String(),
        // n8n reads these directly
        'phone': normalizedPhone,
        if (sendText) 'message': message,
        if (sendPdf && pdfBase64 != null) ...{
          'pdf_base64': pdfBase64,
          'fileName': 'Test-Invoice-TEST-0001.pdf',
        },
        // Nested fallbacks
        'invoice': {
          ...dummyInvoice.toJson(),
          if (sendPdf && pdfBase64 != null) ...{
            'filename': 'Test-Invoice-TEST-0001.pdf',
            'pdf': pdfBase64,
          },
        },
        'client': {...dummyClient.toJson(), 'phone': normalizedPhone},
        'company': company.toJson(),
      };

      debugPrint('WhatsApp Service: Raw company.phone = "${company.phone}"');
      debugPrint('WhatsApp Service: Raw company.whatsappInstance = "${company.whatsappInstance}"');
      debugPrint('WhatsApp Service: Selected sender/instance = "$sender"');

      // Add sender if available
      if (sender.isNotEmpty) {
        payload['sender'] = sender;
        payload['sender_phone'] = sender;
        payload['senderPhone'] = sender;
        payload['sender_number'] = sender;
        payload['senderNumber'] = sender;
      }

      // Add company logo as image if available
      if (sendImage && company.logo.isNotEmpty) {
        payload['image'] = _cleanImage(company.logo);
      }

      debugPrint('WhatsApp test webhook payload: ${jsonEncode(payload)}');

      return await _postToWebhook(
        webhookUrl: webhookUrl,
        payload: payload,
        apiKey: apiKey,
      );
    } catch (e) {
      debugPrint('sendTestWhatsApp error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // METHOD 3: Send Text-Only (no PDF/image)
  // For quick payment reminders, notifications, etc.
  // ─────────────────────────────────────────────────────────
  static Future<bool> sendTextOnlyWhatsApp({
    required String phone,
    required String message,
    required String webhookUrl,
    String? apiKey,
    String? senderPhone,
  }) async {
    if (webhookUrl.isEmpty) {
      debugPrint('WhatsApp: webhookUrl is empty');
      return false;
    }
    try {
      final String normalizedPhone = _normalizePhone(phone);
      if (normalizedPhone.length < 10) {
        debugPrint('WhatsApp: invalid phone: $phone');
        return false;
      }

      final String sender = senderPhone != null && senderPhone.isNotEmpty
          ? _normalizePhone(senderPhone)
          : '';

      final Map<String, dynamic> payload = {
        'event': 'text.send',
        'timestamp': DateTime.now().toIso8601String(),
        'phone': normalizedPhone,
        'message': message,
        'client': {'phone': normalizedPhone, 'name': 'Customer'},
      };

      debugPrint('WhatsApp Service: Raw senderPhone = "$senderPhone"');
      debugPrint('WhatsApp Service: Selected sender/instance = "$sender"');

      if (sender.isNotEmpty) {
        payload['sender'] = sender;
        payload['sender_phone'] = sender;
        payload['senderPhone'] = sender;
        payload['sender_number'] = sender;
        payload['senderNumber'] = sender;
      }

      debugPrint('WhatsApp text-only webhook payload: ${jsonEncode(payload)}');

      return await _postToWebhook(
        webhookUrl: webhookUrl,
        payload: payload,
        apiKey: apiKey,
      );
    } catch (e) {
      debugPrint('sendTextOnlyWhatsApp error: $e');
      return false;
    }
  }
}
