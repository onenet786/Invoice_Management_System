class ScannedQuoteTemplate {
  final String title;
  final String clientName;
  final String handwrittenText;
  final List<ScannedLineItem> items;
  final double taxRate;
  final String notes;

  ScannedQuoteTemplate({
    required this.title,
    required this.clientName,
    required this.handwrittenText,
    required this.items,
    required this.taxRate,
    required this.notes,
  });
}

class ScannedLineItem {
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;

  ScannedLineItem({
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
  });
}

class OcrScanService {
  static final List<ScannedQuoteTemplate> sampleTemplates = [
    ScannedQuoteTemplate(
      title: 'Solar System Layout Quote (EcoPower)',
      clientName: 'EcoPower Solutions Inc.',
      handwrittenText:
          'QUOTE FOR: EcoPower Solutions Inc.\n'
          'Project: Site A Solar Farm Setup\n\n'
          '- 12x Tier-1 Monocrystalline Solar Panel (550W) @ \$240.00 each\n'
          '- 2x Hybrid Solar Inverter (10kW, Three-Phase) @ \$1,300.00 each\n'
          '- 4x Solar DC Cable (4mm², Weatherproof, 100m Roll) @ \$100.00 each\n'
          '- 3x MPPT Solar Charge Controller (60A, 150V) @ \$310.00 each\n\n'
          'Tax rate: 15% standard solar VAT.\n'
          'Notes: Deliver items directly to Austin site. Payment due Net 30.',
      items: [
        ScannedLineItem(
          productName: 'Tier-1 Monocrystalline Solar Panel (550W)',
          sku: 'SOL-PV-550M',
          quantity: 12,
          unitPrice: 240.00,
        ),
        ScannedLineItem(
          productName: 'Hybrid Solar Inverter (10kW, Three-Phase)',
          sku: 'SOL-INV-10K3P',
          quantity: 2,
          unitPrice: 1300.00,
        ),
        ScannedLineItem(
          productName: 'Solar DC Cable (4mm², Weatherproof, 100m Roll)',
          sku: 'SOL-CBL-4MM',
          quantity: 4,
          unitPrice: 100.00,
        ),
        ScannedLineItem(
          productName: 'MPPT Solar Charge Controller (60A, 150V)',
          sku: 'SOL-MPPT-60A',
          quantity: 3,
          unitPrice: 310.00,
        ),
      ],
      taxRate: 15.0,
      notes: 'Deliver items directly to Austin site. Payment due Net 30.',
    ),
    ScannedQuoteTemplate(
      title: 'IT Hardware Upgrade Quote (Apex Data)',
      clientName: 'Apex Data Systems',
      handwrittenText:
          'ESTIMATE FOR CUSTOMER: Apex Data Systems\n'
          'Upgrade Phase 2 - Office Servers & Infrastructure\n\n'
          '- 2x Enterprise Rack Server (2U, 2x Intel Xeon, 128GB RAM, 2TB NVMe) @ \$4,600.00\n'
          '- 4x Managed L3 Network Switch (48-Port Gigabit, PoE+) @ \$850.00 each\n'
          '- 6x Wi-Fi 6E Enterprise Access Point (Dual-Band) @ \$270.00\n'
          '- 2x Uninterruptible Power Supply (UPS) (2000VA / 1200W, Rackmount) @ \$410.00\n\n'
          'Taxes: 10% standard hardware sales tax.\n'
          'Notes: Net 15 days term check invoice details.',
      items: [
        ScannedLineItem(
          productName:
              'Enterprise Rack Server (2U, 2x Intel Xeon, 128GB RAM, 2TB NVMe)',
          sku: 'IT-SRV-2U-XEON',
          quantity: 2,
          unitPrice: 4600.00,
        ),
        ScannedLineItem(
          productName: 'Managed L3 Network Switch (48-Port Gigabit, PoE+)',
          sku: 'IT-SWT-48P-L3',
          quantity: 4,
          unitPrice: 850.00,
        ),
        ScannedLineItem(
          productName: 'Wi-Fi 6E Enterprise Access Point (Dual-Band)',
          sku: 'IT-AP-WIFI6E',
          quantity: 6,
          unitPrice: 270.00,
        ),
        ScannedLineItem(
          productName:
              'Uninterruptible Power Supply (UPS) (2000VA / 1200W, Rackmount)',
          sku: 'IT-UPS-2KVA',
          quantity: 2,
          unitPrice: 410.00,
        ),
      ],
      taxRate: 10.0,
      notes: 'Net 15 days term check invoice details.',
    ),
  ];
}
