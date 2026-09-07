# INVOICEY - ENTERPRISE INVOICE MANAGEMENT SYSTEM
## System Architecture, Data Flow & Business Logic Explanation

---

## 1. System Architecture & High-Level Data Flow

Invoicey is architected around a reactive state management pattern utilizing Flutter's `Provider` paradigm (`AppStateProvider`), anchored by an offline-first storage engine (`StorageService` backed by `SharedPreferences`), and interfaced with native device platforms (biometrics, PDF generation, native URL launchers) and external cloud infrastructure (Google Drive API, RESTful Remote Sync Server).

```
+-----------------------------------------------------------------------------------------+
|                                      PRESENTATION LAYER                                 |
|  [Login / Biometrics]  [Dashboard]  [Invoice Wizard]  [Clients]  [Inventory]  [Settings]|
+--------------------------------------------+--------------------------------------------+
                                             | User Actions & Form Submissions
                                             v
+-----------------------------------------------------------------------------------------+
|                                    BUSINESS LOGIC LAYER                                 |
|                                     AppStateProvider                                    |
|   * Role-based Permissions (canWrite, isAdmin)  * Sequential Invoice/Quote Numbering    |
|   * Dynamic SKU Generation                      * Financial Aggregations & Tax Engine   |
|   * Dynamic Overdue Status Lifecycle Tracker    * Quote-to-Invoice 1-Click Conversion   |
+--------------------+-----------------------+-----------------------+--------------------+
                     |                       |                       |
                     v                       v                       v
+-----------------------------+ +--------------------------+ +----------------------------+
|        STORAGE LAYER        | |     DISPATCH SERVICES    | |     CLOUD BACKUP & SYNC    |
|       StorageService        | | * PdfService (5 themes)  | | * BackupService (GDrive)   |
|  * SharedPreferences (JSON) | | * WhatsappService        | | * RemoteSyncService (REST) |
|  * Local JSON Import/Export | | * EmailService (mailto)  | | * Optimistic Concurrency   |
+-----------------------------+ +--------------------------+ +----------------------------+
```

### End-to-End Execution Pipeline (From User Input to Output)

1. **User Action Ingestion**:
   - The user triggers an interaction on a view (e.g., clicking *Save Invoice* in `InvoiceWizardScreen`).
2. **Authorization & Validation Gate**:
   - `AppStateProvider` evaluates role authorization (`canWrite` check: must be `admin` or `manager`). If unauthorized, execution halts immediately with user feedback.
   - Form state validates non-empty client, item counts $\ge 1$, positive quantities, and valid numbering tokens.
3. **Reactive State Mutation**:
   - The newly constructed model (`InvoiceModel`, `ClientModel`, etc.) is appended or updated in the in-memory state collections (`_invoices`, `_clients`, `_products`).
   - Line items, subtotals, VAT/sales tax components, and grand totals are calculated deterministically using floating-point rounding guards.
4. **Local Persistence Commit**:
   - The mutated collection is serialized into structured JSON and written synchronously to persistent key-value storage via `StorageService`.
5. **Dynamic Cascade Hooks**:
   - **Overdue Check**: If the modified invoice affects due date cycles, `_checkOverdueInvoices()` evaluates date boundaries.
   - **Auto-Backup Trigger**: If Google Drive integration is active and `autoBackupEnabled` is true, `_triggerAutoBackupIfEnabled()` asynchronously generates a timestamped JSON snapshot (`invoicey_backup_YYYYMMDD_HHMM.json`) and registers it in the snapshot ledger.
   - **Cloud Sync Hook**: If the Remote Sync client is connected, an updated workspace payload is pushed to the central HTTPS REST API, validating expected revision numbers.
6. **Reactive UI Repaint**:
   - `notifyListeners()` emits across all active listeners, causing the Dashboard financial cards, KPI bars, and recent lists to re-render.

---

## 2. Inter-Module Connectivity Graph

The modules within Invoicey do not function in isolation; mutations in one module propagate across multiple downstream components.

```
                   +-------------------+
                   |  Company Profile  |
                   | (Legal & Currency)|
                   +---------+---------+
                             |
         +-------------------+-------------------+
         |                                       |
         v                                       v
+------------------+                   +--------------------+
|  Client Database |                   |  Product Inventory |
| (Names & Address)|                   | (SKUs, Taxes, Cost)|
+--------+---------+                   +---------+----------+
         |                                       |
         +-------------------+-------------------+
                             | Selected into
                             v
                   +-------------------+
                   |  Invoice Wizard   |
                   | (3-Step Lifecycle)|
                   +---------+---------+
                             |
             +---------------+---------------+
             |                               |
             v                               v
   +-------------------+           +-------------------+
   | Dashboard Metrics |           | Dispatch Channels |
   | (Revenue/Overdue) |           | (PDF/WhatsApp/Mail|
   +-------------------+           +-------------------+
             |                               |
             +---------------+---------------+
                             | Mutation triggers
                             v
                   +-------------------+
                   | Cloud Backup/Sync |
                   | (Drive & REST API)|
                   +-------------------+
```

### Key Module Interactions:

1. **Client Database $\to$ Invoices**:
   - The Invoice Wizard pulls directly from `state.clients`. Invoices store `clientId` as a relational key.
   - Invoice detail screens, PDF preview generators, WhatsApp dispatches, and Email formatters dynamically resolve client contact details (email, international phone, billing/shipping address) via `clientId`.
2. **Product Catalog $\to$ Invoice Line Items**:
   - Line items in the wizard pull SKU, product name, standard unit price, and default tax rate from `state.products`.
   - Adding a line item computes:
     $$\text{Line Subtotal} = \text{Quantity} \times \text{Unit Price}$$
     $$\text{Line Tax} = \text{Line Subtotal} \times \left(\frac{\text{Tax Rate}}{100}\right)$$
     $$\text{Line Total} = \text{Line Subtotal} + \text{Line Tax}$$
3. **Quotation $\to$ 1-Click Invoice Transformation**:
   - `convertQuoteToInvoice()` reads an existing `InvoiceModel` where `documentType == InvoiceDocumentType.quote`.
   - It stamps the quote's `convertedInvoiceId` with the new invoice ID, generates a sequential invoice number, and registers the newly minted document as an active `draft` invoice.
4. **Invoice Lifecycle $\to$ Dashboard Metrics**:
   - When an invoice status moves to `paid`, `DashboardScreen` adds its `grandTotal` to `totalRevenue`.
   - When marked `sent` or `partiallyPaid`, it contributes to `pendingPayments`.
   - When `dueDate` lapses past `DateTime.now()`, it automatically converts to `overdue`, subtracting from pending and alerting under `overdueAmount`.
5. **Mutation Cascades $\to$ Disaster Recovery**:
   - Adding/editing/deleting clients, products, or invoices automatically fires `_triggerAutoBackupIfEnabled()`.
   - This keeps the Google Drive cloud snapshots and Remote Sync workspace identical with local device state without manual user intervention.

---

## 3. The "WHY" of Each Module: Impact & Risk Analysis

This section analyzes the purpose of each module, detailing what system failures and business risks occur if a module is removed or disabled.

---

### Module: Authentication & RBAC (`UserModel`, `LoginScreen`)
- **Purpose**: Restricts system access, controls identity, and governs write vs read-only permissions (`admin`, `manager`, `viewer`).
- **If Removed / Disabled**:
  - Unauthenticated users could wipe client records, modify company bank details, or alter product pricing.
  - Viewers (e.g., external auditors or interns) could accidentally delete invoices or issue unauthorized billing.
- **Operational Risk**: Critical financial fraud, accidental data deletion, loss of audit accountability.

---

### Module: Biometric Security (`LocalAuthentication`, `local_auth`)
- **Purpose**: Provides hardware-level biometric gating (Fingerprint, Touch ID, Face ID) for instant administrator sign-in on mobile and workstation hardware.
- **If Removed / Disabled**:
  - The application falls back exclusively to text passwords.
- **Operational Risk**: Reduced security on shared devices, increased vulnerability to password shoulder-surfing in field environments (e.g., on-site solar installation trucks).

---

### Module: Onboarding Gateway (`OnboardingScreen`, `StorageService.setupCompany`)
- **Purpose**: Manages initial software deployment, allowing clean business setup or pre-seeding sample data for testing.
- **If Removed / Disabled**:
  - The application would launch with `null` company profiles and empty user lists, crashing the dashboard and navigation shells due to unhandled missing company currency and administrator credentials.
- **Operational Risk**: Complete initial launch failure and inability to deploy to new workstations.

---

### Module: Dashboard Analytics (`DashboardScreen`, `fl_chart`)
- **Purpose**: Aggregates raw transactional data into high-level business intelligence: cash flow balances, pending payments, overdue aging, and monthly sales trends.
- **If Removed / Disabled**:
  - Business owners would have no visual ledger of cash flow. Overdue accounts could only be identified by manually opening every individual invoice record.
- **Operational Risk**: Delayed receivables collection, severe cash-flow deficits, and inability to assess quarterly sales trends.

---

### Module: Client Database (`ClientModel`, `ClientListScreen`)
- **Purpose**: Centralized directory of customer accounts, tax information, billing destinations, and communication endpoints (emails and phone numbers).
- **If Removed / Disabled**:
  - The Invoice Wizard would have no client records to reference. Every invoice would require re-typing company legal names, tax IDs, shipping sites, emails, and phone numbers from scratch.
  - Automated WhatsApp and Email dispatch would fail due to missing phone numbers and email addresses.
- **Operational Risk**: High rate of invoice delivery errors, mismatched client tax identifiers, and severe administrative overhead.

---

### Module: Product Catalog & Inventory (`ProductModel`, `ProductListScreen`)
- **Purpose**: Stores standard commercial inventory with pre-calculated unit prices, tax percentages, categories, and automated SKU numbering.
- **If Removed / Disabled**:
  - Users would have to manually key in product descriptions, unit costs, and tax percentages on every single line item.
- **Operational Risk**: Price inconsistency across clients, erroneous tax computations leading to regulatory penalties, and inventory classification errors.

---

### Module: Invoice & Quotation Engine (`InvoiceModel`, `InvoiceWizardScreen`)
- **Purpose**: The core commercial engine of the application. Generates legally binding sequential invoices, manages payment statuses, records terms, and computes mathematical taxes and subtotals.
- **If Removed / Disabled**:
  - The software ceases to be an invoicing application.
- **Operational Risk**: Inability to conduct business, complete collapse of billing and revenue recognition.

---

### Module: OCR Quotation Scanner (`OcrScanService`, `ScanQuotationDialog`)
- **Purpose**: Parses scanned or handwritten quotation sheets, extracting line items, quantities, and pricing into structured invoice items.
- **If Removed / Disabled**:
  - Field technicians and sales reps generating paper site surveys (e.g., solar roof assessments) must manually transcribe every hardware component into the app.
- **Operational Risk**: Transscription errors, misquoted component costs, and delayed sales pipeline turnaround.

---

### Module: Multi-Template PDF Engine (`PdfService`, `printing`)
- **Purpose**: Renders pixel-perfect, vector-based PDF invoices across 5 distinct visual designs (`Classic`, `Modern`, `Minimal`, `Corporate`, `Elegant`) formatted for standard A4/Letter printing and digital archiving.
- **If Removed / Disabled**:
  - Clients could not receive official PDF documents. Invoices would exist solely as internal database entries.
- **Operational Risk**: Client refusal to pay without official tax invoices, breach of commercial compliance standards.

---

### Module: Multi-Channel Dispatch (`WhatsappService`, `EmailService`)
- **Purpose**: One-touch client dispatch via pre-formatted WhatsApp text summaries, native WhatsApp PDF file attachments, and pre-addressed `mailto:` emails.
- **If Removed / Disabled**:
  - Users would have to manually open an external email client or messaging app, search for the client's number, copy-paste invoice details, and manually locate the PDF on their disk to attach.
- **Operational Risk**: Drastic reduction in communication speed, increased friction in payment reminder workflows, delayed payment receipts.

---

### Module: Google Drive Backup & Recovery (`BackupService`)
- **Purpose**: Generates versioned, portable JSON backups on local disk and Google Drive, with automatic background upload upon data changes and a rolling 10-snapshot historical restore ledger.
- **If Removed / Disabled**:
  - If the host machine suffers hardware failure, disk corruption, or accidental software deletion, all financial history, invoices, and client directories are permanently lost.
- **Operational Risk**: Catastrophic, unrecoverable data loss and total loss of corporate accounting history.

---

### Module: Remote Cloud Sync Server (`RemoteSyncService`)
- **Purpose**: Real-time cross-workstation synchronization with a central REST API, authenticated via Google ID tokens and protected by revision-locking conflict detection (`HTTP 409 Conflict`).
- **If Removed / Disabled**:
  - Data remains permanently trapped on a single physical machine. Multi-device operations (e.g., office billing clerk + mobile field manager) become impossible.
- **Operational Risk**: Fragmented data silos, conflicting invoice sequences across devices, inability to scale operations across multiple team members.

---

## 4. Concrete Business Logic Rules & Mathematical Formulas

This section documents the specific business logic rules, data validation checks, and mathematical formulas embedded within the application.

---

### 4.1 Sequential Invoice Numbering Format Tokenizer
- **Location**: `AppStateProvider.generateNextInvoiceNumber()`, `StorageService.invoiceNumberFormat`
- **Validation Rule**:
  ```dart
  RegExp(r'\{N{1,6}\}').allMatches(format).length == 1
  ```
  The format pattern **must contain exactly one sequence token** consisting of between 1 and 6 `N` characters (e.g., `{NN}`, `{NNNN}`, `{NNNNNN}`).
- **Supported Dynamic Tokens**:
  - `{YYYY}`: Evaluated to `date.year.toString()` (e.g., `2026`).
  - `{YY}`: Evaluated to `(date.year % 100).toString().padLeft(2, '0')` (e.g., `26`).
  - `{MM}`: Evaluated to `date.month.toString().padLeft(2, '0')` (e.g., `09`).
  - `{N...}`: Sequence width determined by token character count (e.g., `{NNNN}` $\implies$ 4 digits, `0001`).
- **Algorithm**:
  1. The prefix and suffix strings surrounding `{N...}` are extracted and resolved with the current date tokens.
  2. An anchored regular expression (`^prefix(\d+)suffix$`) scans all existing invoices in the database.
  3. The highest matching integer sequence is detected (`maxSeq`).
  4. The next sequential number is constructed:
     $$\text{Next Sequence} = \text{maxSeq} + 1$$
     $$\text{Invoice Number} = \text{prefix} + \text{padLeft}(\text{Next Sequence}, \text{width}, \text{'0'}) + \text{suffix}$$

---

### 4.2 Dynamic Product SKU Generation Algorithm
- **Location**: `AppStateProvider.generateProductSku()`
- **Formula**:
  $$\text{SKU} = [\text{Category Code (3)}] - [\text{Product Code (8)}] - [\text{Sequence (001-999)}]$$
- **Cleaning & Code Extraction Rules**:
  1. All non-alphanumeric characters are stripped: `value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')`.
  2. If the string consists of multiple words:
     - Take up to the first 3 words.
     - Extract up to the first 3 characters of each word and concatenate.
  3. The category code is clamped to 3 characters and padded right with `X` if shorter (e.g., `IT` $\to$ `ITX`, `Solar` $\to$ `SOL`).
  4. The product code is clamped to 8 characters and padded right with `X` (e.g., `Enterprise Rack Server` $\to$ `ENTRACSE`).
  5. The sequence integer begins at `1` and iterates upwards until a candidate SKU does not collide with any existing product SKU in the database:
     ```dart
     candidate = '$categoryCode-$productCode-${sequence.toString().padLeft(3, '0')}';
     ```

---

### 4.3 Financial precision & Tax Calculations
- **Location**: `InvoiceItemModel`, `InvoiceWizardScreen`, `PdfService`
- **Formulas**:
  - **Line Subtotal**:
    $$\text{lineSubtotal} = \text{unitPrice} \times \text{quantity}$$
  - **Line Tax**:
    $$\text{lineTax} = \text{lineSubtotal} \times \left(\frac{\text{taxRate}}{100.0}\right)$$
  - **Line Total**:
    $$\text{lineTotal} = \text{lineSubtotal} + \text{lineTax}$$
  - **Invoice Aggregates**:
    $$\text{SubTotal} = \sum_{i=1}^{n} \text{lineSubtotal}_i$$
    $$\text{TaxTotal} = \sum_{i=1}^{n} \text{lineTax}_i$$
    $$\text{GrandTotal} = \sum_{i=1}^{n} \text{lineTotal}_i = \text{SubTotal} + \text{TaxTotal}$$
- **Constraint**: All financial displays format to exactly two decimal places using the company's designated currency symbol: `NumberFormat.currency(symbol: currency, decimalDigits: 2)`.

---

### 4.4 Dynamic Overdue Status Lifecycle Tracker
- **Location**: `AppStateProvider._checkOverdueInvoices()`
- **Execution Event**: Evaluated on every application boot, database reload, or session refresh.
- **Rule**:
  ```dart
  if (invoice.status == InvoiceStatus.sent || invoice.status == InvoiceStatus.partiallyPaid) {
    if (invoice.dueDate.isBefore(DateTime.now())) {
      invoice.status = InvoiceStatus.overdue;
    }
  }
  ```
  - **Exclusion**: Invoices in `draft` status are **never** marked overdue (as they have not been issued to the debtor).
  - Invoices in `paid` status are **never** marked overdue.
  - Mutations are automatically saved to persistent storage if any invoice is updated to `overdue`.

---

### 4.5 Quote-to-Invoice 1-Click Conversion Safeguards
- **Location**: `AppStateProvider.convertQuoteToInvoice(InvoiceModel quote)`
- **Constraints**:
  1. **Role Check**: Current user must have `canWrite` permission (`admin` or `manager`).
  2. **Type Check**: `quote.documentType == InvoiceDocumentType.quote`.
  3. **Idempotency Safeguard**:
     ```dart
     if (quote.convertedInvoiceId != null) return null;
     ```
     Prevents converting the same quote multiple times, eliminating duplicate billing.
- **Mutation Actions**:
  - Spawns a new `InvoiceModel` with `documentType = InvoiceDocumentType.invoice`, a new sequential invoice number, issue date set to `now`, due date set to `now + 30 days`, status set to `draft`, and identical items/totals.
  - Updates the parent quote record with `convertedInvoiceId = newInvoice.id`.

---

### 4.6 Optimistic Concurrency Control (Remote Cloud Sync)
- **Location**: `RemoteSyncService.uploadWorkspace()`
- **Mechanism**:
  - The client stores an integer revision tracker: `_revisionKey`.
  - When pushing workspace data via `PUT /v1/workspace`, the request includes:
    ```json
    {
      "payload": { ... },
      "expectedRevision": currentRevision
    }
    ```
  - If the cloud server's revision is higher (meaning another team member pushed updates from another machine):
    - The server responds with `HTTP 409 Conflict`.
    - `RemoteSyncService` throws a `RemoteSyncException`:
      *"Cloud data changed on another device. Download it before uploading again."*
    - The local user is blocked from overwriting cloud changes and must download the latest revision first.
