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
  // HELPER: Normalize phone number to international format
  // Strips non-digits, converts 0XXX → 92XXX (Pakistan)
  // ─────────────────────────────────────────────────────────
  static String _normalizePhone(String raw) {
    // Remove all non-digit characters
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    // If starts with 0, replace with Pakistan country code
    if (digits.startsWith('0')) {
      digits = '92${digits.substring(1)}';
    }

    // If starts with +92, just remove the +
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    }

    return digits;
  }

  // ─────────────────────────────────────────────────────────
  // HELPER: Build WhatsApp message text
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
              '• ${item.productName} (x${item.quantity}): '
              '${company.currency}${item.lineTotal.toStringAsFixed(2)}',
        )
        .join('\n');

    return '*Dear ${client.name},*\n\n'
        'Please find the summary of your *Invoice ${invoice.invoiceNumber}* '
        'from *${company.name}*.\n\n'
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
  // HELPER: Send POST request to n8n webhook
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
          'WhatsApp webhook error: '
          'Status ${response.statusCode}, '
          'Body: ${response.body}',
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
  // Called when user taps "Send Invoice" on invoice screen
  // ─────────────────────────────────────────────────────────
  static Future<bool> sendInvoiceWhatsApp({
    required InvoiceModel invoice,
    required ClientModel client,
    required CompanyModel company,
    required String webhookUrl,
    String? apiKey,
  }) async {
    if (webhookUrl.isEmpty) {
      debugPrint('WhatsApp: webhookUrl is empty');
      return false;
    }

    try {
      // 1. Normalize phone number
      final String phone = _normalizePhone(client.phone);
      if (phone.length < 10) {
        debugPrint('WhatsApp: invalid phone number: ${client.phone}');
        return false;
      }

      // 2. Generate PDF
      final pdfBytes = await PdfService.generateInvoicePdf(
        invoice: invoice,
        client: client,
        company: company,
      );
      final String pdfBase64 = base64Encode(pdfBytes);

      // 3. Build message text
      final String message = _buildMessageText(
        invoice: invoice,
        client: client,
        company: company,
      );

      // 4. Build payload — matches n8n Parse & Validate Payload node
      final Map<String, dynamic> payload = {
        'event': 'invoice.send',
        'timestamp': DateTime.now().toIso8601String(),

        // ── Fields n8n reads directly ──
        'phone': phone,
        'message': message,
        'pdf_base64': pdfBase64,
        'fileName': 'Invoice-${invoice.invoiceNumber}.pdf',

        // ── Nested objects (fallback fields in n8n) ──
        'invoice': {
          ...invoice.toJson(),
          'filename': 'Invoice-${invoice.invoiceNumber}.pdf',
          'pdf': pdfBase64,
        },
        'client': {
          ...client.toJson(),
          'phone': phone, // normalized
        },
        'company': company.toJson(),
      };

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
  // METHOD 2: Send Test WhatsApp Message
  // Called from Settings → Test Integration dialog
  // ─────────────────────────────────────────────────────────
  static Future<bool> sendTestWhatsApp({
    required String phone,
    required String message,
    required String webhookUrl,
    required CompanyModel company,
    String? apiKey,
  }) async {
    if (webhookUrl.isEmpty) {
      debugPrint('WhatsApp: webhookUrl is empty');
      return false;
    }

    try {
      // 1. Normalize phone
      final String normalizedPhone = _normalizePhone(phone);
      if (normalizedPhone.length < 10) {
        debugPrint('WhatsApp: invalid phone number: $phone');
        return false;
      }

      // 2. Create dummy client
      final dummyClient = ClientModel(
        id: 'test-client',
        name: 'Test Recipient',
        email: 'test@example.com',
        phone: normalizedPhone,
        billingAddress: '123 Test Street',
        shippingAddress: '123 Test Street',
      );

      // 3. Create dummy invoice
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

      // 4. Generate test PDF
      final pdfBytes = await PdfService.generateInvoicePdf(
        invoice: dummyInvoice,
        client: dummyClient,
        company: company,
      );
      final String pdfBase64 = base64Encode(pdfBytes);

      // 5. Build payload — matches n8n Parse & Validate Payload node
      final Map<String, dynamic> payload = {
        'event': 'invoice.test',
        'timestamp': DateTime.now().toIso8601String(),

        // ── Fields n8n reads directly ──
        'phone': normalizedPhone,
        'message': message,
        'pdf_base64': pdfBase64,
        'fileName': 'Test-Invoice-TEST-0001.pdf',

        // ── Nested objects (fallback fields in n8n) ──
        'invoice': {
          ...dummyInvoice.toJson(),
          'filename': 'Test-Invoice-TEST-0001.pdf',
          'pdf': pdfBase64,
        },
        'client': {...dummyClient.toJson(), 'phone': normalizedPhone},
        'company': company.toJson(),
      };

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
  // METHOD 3: Send Text-Only WhatsApp Message
  // For quick notifications without PDF attachment
  // ─────────────────────────────────────────────────────────
  static Future<bool> sendTextOnlyWhatsApp({
    required String phone,
    required String message,
    required String webhookUrl,
    String? apiKey,
  }) async {
    if (webhookUrl.isEmpty) {
      debugPrint('WhatsApp: webhookUrl is empty');
      return false;
    }

    try {
      final String normalizedPhone = _normalizePhone(phone);
      if (normalizedPhone.length < 10) {
        debugPrint('WhatsApp: invalid phone number: $phone');
        return false;
      }

      // Minimal payload — no PDF, no image
      // n8n will send text only and skip PDF/image branches
      final Map<String, dynamic> payload = {
        'event': 'text.send',
        'timestamp': DateTime.now().toIso8601String(),
        'phone': normalizedPhone,
        'message': message,
        'client': {'phone': normalizedPhone, 'name': 'Customer'},
      };

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
