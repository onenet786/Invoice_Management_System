import 'package:intl/intl.dart';

/// Centralized date formatting utilities for consistent date display
/// across the entire application (views, PDF, emails).
class DateFormatUtil {
  DateFormatUtil._();

  /// Standard display format: `2026-06-13`
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  /// Human-readable display: `13 Jun 2026`
  static final DateFormat _displayDate = DateFormat('dd MMM yyyy');

  /// Short display: `Jun 13, 2026`
  static final DateFormat _shortDate = DateFormat('MMM dd, yyyy');

  /// For invoice number prefix: `13Jun2026-`
  static final DateFormat _invoicePrefix = DateFormat('ddMMMyyyy-');

  /// For backup file names: `13Jun2026-1430`
  static final DateFormat _backupFileName = DateFormat('ddMMMyyyy-HHmm');

  /// Formats a [DateTime] to ISO date string: `2026-06-13`
  static String toIsoDate(DateTime date) => _isoDate.format(date);

  /// Formats a [DateTime] to human-readable display: `13 Jun 2026`
  static String toDisplayDate(DateTime date) => _displayDate.format(date);

  /// Formats a [DateTime] to short display: `Jun 13, 2026`
  static String toShortDate(DateTime date) => _shortDate.format(date);

  /// Formats a [DateTime] for invoice number prefix: `13Jun2026-`
  static String toInvoicePrefix(DateTime date) => _invoicePrefix.format(date);

  /// Formats a [DateTime] for backup file names: `13Jun2026-1430`
  static String toBackupFileName(DateTime date) => _backupFileName.format(date);

  /// Formats a currency value with the given currency symbol.
  static String formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    return formatter.format(amount);
  }
}
