import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';
import '../models/client_model.dart';
import '../models/company_model.dart';
import 'pdf_service.dart';

class WhatsappService {
  /// Clean phone number for WhatsApp URL (removes spaces, dashes, parentheses)
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  /// Sends a formatted text summary of the invoice directly via WhatsApp
  static Future<bool> sendInvoiceText({
    required InvoiceModel invoice,
    required ClientModel client,
    required CompanyModel company,
    String? phoneOverride,
  }) async {
    final rawPhone = phoneOverride ?? client.phone;
    final phone = cleanPhoneNumber(rawPhone);

    final itemsSummary = invoice.items
        .map(
          (item) =>
              '• ${item.productName} (x${item.quantity}) - ${company.currency}${item.lineTotal.toStringAsFixed(2)}',
        )
        .join('\n');

    final message = '''
📄 *INVOICE: ${invoice.invoiceNumber}*
*From:* ${company.name}
----------------------------------------
👤 *Bill To:* ${client.name}
📅 *Issue Date:* ${invoice.issueDate.toIso8601String().split('T')[0]}
📅 *Due Date:* ${invoice.dueDate.toIso8601String().split('T')[0]}
STATUS: *${invoice.status.name.toUpperCase()}*

🛒 *Items:*
$itemsSummary

----------------------------------------
💰 *Grand Total:* *${company.currency}${invoice.grandTotal.toStringAsFixed(2)}*
----------------------------------------
${invoice.notes.isNotEmpty ? '📌 *Notes:* ${invoice.notes}\n' : ''}Thank you for doing business with us!
''';

    final encodedText = Uri.encodeComponent(message);

    // Try app deep link first, then web API fallbacks
    final Uri appUri = Uri.parse(
      phone.isNotEmpty
          ? 'whatsapp://send?phone=$phone&text=$encodedText'
          : 'whatsapp://send?text=$encodedText',
    );

    final Uri webUri = Uri.parse(
      phone.isNotEmpty
          ? 'https://api.whatsapp.com/send?phone=$phone&text=$encodedText'
          : 'https://api.whatsapp.com/send?text=$encodedText',
    );

    try {
      if (await canLaunchUrl(appUri)) {
        return await launchUrl(appUri);
      } else {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  /// Share generated PDF document via Native Share Sheet (which includes WhatsApp)
  static Future<void> shareInvoicePdf({
    required InvoiceModel invoice,
    required ClientModel client,
    required CompanyModel company,
    String template = 'Classic',
  }) async {
    final pdfBytes = await PdfService.generateInvoicePdf(
      invoice: invoice,
      client: client,
      company: company,
      template: template,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  /// Shows an intuitive modal sheet to share either PDF or Text format to WhatsApp
  static Future<void> showWhatsappShareSheet({
    required BuildContext context,
    required InvoiceModel invoice,
    required ClientModel client,
    required CompanyModel company,
    String template = 'Classic',
  }) async {
    final phoneController = TextEditingController(text: client.phone);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFF25D366),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsApp Invoice Dispatch',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Invoice #${invoice.invoiceNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Client WhatsApp Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+1 234 567 8900',
                  helperText: 'Includes country code for direct message',
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.green),
                ),
                title: const Text(
                  'Send Text Invoice Summary',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Opens WhatsApp with a structured breakdown and grand total.',
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final success = await sendInvoiceText(
                    invoice: invoice,
                    client: client,
                    company: company,
                    phoneOverride: phoneController.text.trim(),
                  );
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open WhatsApp app or web link.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: const Text(
                  'Share PDF Invoice Document',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Generates $template template PDF & opens WhatsApp/Share sheet.',
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await shareInvoicePdf(
                    invoice: invoice,
                    client: client,
                    company: company,
                    template: template,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
