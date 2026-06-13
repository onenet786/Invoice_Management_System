import 'package:url_launcher/url_launcher.dart';
import '../models/invoice_model.dart';
import '../models/client_model.dart';
import '../models/company_model.dart';
import '../utils/date_format_util.dart';

class EmailService {
  static Future<bool> sendInvoiceEmail({
    required InvoiceModel invoice,
    required ClientModel client,
    required CompanyModel company,
  }) async {
    final String issueStr = DateFormatUtil.toIsoDate(invoice.issueDate);
    final String dueStr = DateFormatUtil.toIsoDate(invoice.dueDate);

    final subject = Uri.encodeComponent("Invoice ${invoice.invoiceNumber} from ${company.name}");
    
    final itemsList = invoice.items.map(
      (item) => "- ${item.productName} (x${item.quantity}): ${company.currency}${item.lineTotal.toStringAsFixed(2)}"
    ).join("\n");

    final body = Uri.encodeComponent(
      "Dear ${client.name},\n\n"
      "Please find below the summary details of your invoice ${invoice.invoiceNumber}.\n\n"
      "Invoice Details:\n"
      "------------------------------\n"
      "Issue Date: $issueStr\n"
      "Due Date: $dueStr\n"
      "Total Amount Due: ${company.currency}${invoice.grandTotal.toStringAsFixed(2)}\n\n"
      "Items:\n"
      "$itemsList\n\n"
      "Notes:\n"
      "${invoice.notes.isNotEmpty ? invoice.notes : 'N/A'}\n\n"
      "Best regards,\n"
      "${company.name}\n"
      "${company.address}"
    );

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: client.email,
      query: 'subject=$subject&body=$body',
    );

    try {
      return await launchUrl(emailLaunchUri);
    } catch (e) {
      return false;
    }
  }
}
