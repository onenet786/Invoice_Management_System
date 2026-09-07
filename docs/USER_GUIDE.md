# INVOICEY - ENTERPRISE INVOICE MANAGEMENT SYSTEM
## Comprehensive User & Operations Manual

---

## 1. Executive Summary & Application Overview

**Invoicey** is a cross-platform invoice and billing control center designed for businesses handling product sales, service billing, and inventory tracking (with built-in support for specialized industries such as Solar Energy and IT Infrastructure). The application provides complete lifecycle management for invoices and quotations, offline-first local storage, client directories, SKU-based product catalogs, multi-template PDF generation, automated messaging channels (WhatsApp and Email), and multi-tier cloud synchronization.

### Key Capabilities
- **Role-Based Access Control (RBAC)**: Enforced segregation between **Administrator**, **Manager**, and **Viewer** accounts.
- **Biometric Security**: Native integration with device biometric hardware (Fingerprint, Touch ID, Face ID) alongside standard email/password authentication.
- **Offline-First Resilience**: Full offline operation powered by local storage with automated and manual Google Drive snapshot backups.
- **Multi-Cloud Workspace Synchronization**: REST API connectivity with Google Authentication and optimistic-concurrency revision locking.
- **Flexible Document Engine**: Sequential numbering format templates, quotation-to-invoice one-click conversion, OCR-assisted quotation scanning, and five designer PDF themes.

---

## 2. Getting Started & Initial Onboarding

Upon launching Invoicey for the first time, users are greeted by the Onboarding Gateway. Data remains localized on the host device until cloud synchronization is explicitly configured.

```
+-------------------------------------------------------------------------+
|                           WELCOME TO INVOICEY                           |
|                    How would you like to begin?                         |
|                                                                         |
|  +---------------------------------+  +-------------------------------+  |
|  |     [Set Up My Company]         |  |   [Explore Sample Company]    |  |
|  |  Create a clean workspace with  |  |  Preload ready-made clients,  |  |
|  |  custom legal details & admin   |  |  products, and sample invoices|  |
|  |  credentials. (Recommended)     |  |  for immediate testing.       |  |
|  +---------------------------------+  +-------------------------------+  |
+-------------------------------------------------------------------------+
```

### Option A: Clean Company Setup (Production Use)
1. Select **Set up my company**.
2. Complete **Step 1: Business Profile**:
   - **Company Legal Name**: Official name displayed on invoice headers (e.g., *Apex Solutions Ltd*).
   - **Tax ID / VAT / GST**: Optional tax identifier (e.g., *TAX-88921-US*).
   - **Operating Currency**: Select your currency symbol or ISO code (e.g., `$`, `EUR`, `GBP`, `PKR (Rs)`, `INR (₹)`, `AED`).
   - **Registered Office Address**: Full physical or mailing address.
3. Complete **Step 2: Administrator Account**:
   - **Admin Name**: Full name of the primary system administrator.
   - **Email Address**: Used for login and system recovery alerts.
   - **Master Password**: Minimum 6 characters.
4. Click **Complete Setup**. You will be redirected to the Login screen with your administrative credentials initialized.

### Option B: Explore Sample Company (Demo & Sandbox)
1. Click **Explore sample company**.
2. Invoicey automatically initializes an enterprise workspace seeded with:
   - **Company**: *My Solar & IT Corp*
   - **3 User Accounts**:
     - Administrator: `admin@invoice.com` / `admin123`
     - Project Manager: `manager@invoice.com` / `manager123`
     - General Viewer: `viewer@invoice.com` / `viewer123`
   - **3 Established Clients**: *EcoPower Solutions Inc.*, *Apex Data Systems*, *Global Tech Consulting*.
   - **14 Seed Products**: Across Solar Panels, Inverters, Battery Banks, Enterprise Rack Servers, and Managed Switches.
   - **Pre-configured Invoices**: Paid and overdue invoice samples for instant dashboard visualization.

---

## 3. Authentication & Security

[Screenshot Placeholder: Login Screen showing Email, Password fields, Sign In button, and Biometric Authentication trigger]

### 3.1 Standard Authentication
1. Launch Invoicey.
2. Enter your registered **Email Address** and **Password**.
3. Click **Sign In**.
4. The system validates credentials against stored accounts. Upon verification, the application opens the main navigation workspace and displays your role badge (`ADMIN`, `MANAGER`, or `VIEWER`) in the top navigation bar.

### 3.2 Biometric Authentication (Fingerprint / Face ID)
1. If biometric authentication has been activated in **Settings**, Invoicey displays a **Sign in with Biometrics** button beneath the primary login form.
2. Click the biometric button to prompt the platform's native biometric dialog.
3. Authenticate using your fingerprint scanner or facial recognition sensor.
4. Upon confirmation, Invoicey signs into the administrator session directly without manual password entry.

---

## 4. Module-by-Module Step-by-Step Usage Guide

### Module 1: Dashboard Analytics
[Screenshot Placeholder: Dashboard screen showing 4 KPI cards (Total Revenue, Pending, Overdue, Invoices count), Monthly Sales Bar Chart, and dynamic Filter bar]

The Dashboard provides executive visibility into accounts receivable, sales velocity, and payment health.

#### Step-by-Step Instructions:
1. **Review Financial Metrics**:
   - **Total Revenue (Paid)**: Aggregate sum of all finalized, paid invoices.
   - **Pending Payments**: Total outstanding funds from invoices marked *Sent* or *Partially Paid*.
   - **Overdue Amount**: Critical balance of invoices that have surpassed their due date without complete settlement.
   - **Total Invoices**: Count of documents matching current filter criteria.
2. **Filter Analytics Data**:
   - Locate the **Filter Controls Card** at the top.
   - **Client Filter**: Select a specific customer to isolate their individual account balance and invoice volume.
   - **Status Filter**: Filter by *Draft*, *Sent*, *Partially Paid*, *Paid*, or *Overdue*.
   - **Fiscal Year**: Switch calendar years (e.g., *2025*, *2026*) to recompute annual sales trends.
3. **Analyze Monthly Sales Trends**:
   - The interactive bar chart illustrates cumulative revenue generated each calendar month (January through December).
   - Draft invoices are excluded from the chart to ensure financial reporting accuracy.
4. **Inspect Recent Documents**:
   - Scroll down to the **Recent Invoices** table to inspect recent transaction numbers, client names, issue dates, and amounts.
   - Tap any invoice row to open its detailed breakdown screen.

---

### Module 2: Client Management
[Screenshot Placeholder: Client Database screen showing customer cards, search bar, and Add Client button]

The Client Database maintains all debtor records, shipping logistics, and contact points required for invoice generation.

#### Adding a New Client:
1. Navigate to **Clients** via the left sidebar or bottom navigation bar.
2. Click the **+ Add Client** button in the top right corner.
3. In the dialog window, populate:
   - **Client / Business Name** *(Required)*: Legal company or individual name.
   - **Email Address** *(Required)*: Primary accounting email address for electronic dispatch.
   - **Phone Number** *(Required)*: International phone number for WhatsApp message dispatch.
   - **Billing Address** *(Required)*: Registered billing address appearing on invoice headers.
   - **Shipping Address** *(Optional)*: Delivery site address for equipment dispatch.
4. Click **Save Client**. The client is immediately available in the Invoice Wizard.

#### Editing or Deleting a Client:
1. Use the real-time search bar to filter clients by name, email, or telephone.
2. On any client card:
   - Click the **Edit (Pencil)** icon to modify contact or address parameters.
   - Click the **Delete (Trash)** icon to remove the client. (A confirmation dialog will prevent accidental deletion).

> [!NOTE]
> Write operations (Add, Edit, Delete) are accessible exclusively to **Administrators** and **Managers**.

---

### Module 3: Product Catalog & Inventory
[Screenshot Placeholder: Product Catalog screen displaying category tabs (All, Solar, IT, Hardware, Services), SKU badges, unit prices, and Add Product button]

The Product Catalog contains all billable stock units, services, and hardware with pre-assigned tax rates and SKUs.

#### Adding a New Product:
1. Navigate to **Inventory** in the main menu.
2. Click **+ Add Product**.
3. Fill in the product specifications:
   - **Item Name**: Descriptive commercial name (e.g., *Tier-1 Monocrystalline Solar Panel (550W)*).
   - **Category**: Select an existing category or enter a custom classification (e.g., *Solar*, *IT*, *Hardware*, *Services*).
   - **Stock Keeping Unit (SKU)**:
     - You can enter a custom SKU or click **Auto Generate**.
     - Invoicey automatically generates an industry-standard sequential SKU based on the category and name (e.g., `SOL-TIER1MO-001`).
   - **Unit Price**: Base unit price excluding tax.
   - **Tax Rate (%)**: Standard percentage tax (e.g., `15.0` for 15% VAT, or `10.0` for sales tax).
   - **Description**: Detailed technical specifications printed on invoice line items.
4. Click **Save Product**.

#### Filtering & Searching Catalog Items:
- Use the **Category Tabs** (*All*, *Solar*, *IT*, *Hardware*, *Services*, etc.) to isolate product segments.
- Use the search bar to query by product name, SKU, or keyword description.

---

### Module 4: Invoice & Quotation Engine
[Screenshot Placeholder: 3-Step Invoice Wizard showing Step 1 Client Selection, Step 2 Line Items with calculations, and Step 3 Review & Issue]

Invoicey provides a comprehensive 3-step wizard for generating both binding Invoices and preliminary Quotations.

#### Step 1: Customer & Date Selection
1. From the **Invoices** tab, click **Create Invoice** (or **Create Quote**).
2. The **Invoice Number** is pre-filled using your system's sequential format (e.g., `INV-2026-0003`).
3. Select a **Target Client** from the customer dropdown.
4. Set the **Issue Date** (defaults to today) and **Due Date** (defaults to Net 30 days).
5. Click **Continue to Line Items**.

#### Step 2: Line Items & Pricing
1. Select a product from the **Select Product Catalog Item** dropdown.
   - Unit price and applicable tax rate will automatically populate.
2. Enter the **Quantity**.
3. Adjust the unit price or tax rate if a client-specific negotiated rate applies.
4. Click **Add Item to Invoice**.
5. The line item appears in the calculation breakdown:
   - Line Subtotal = Quantity x Unit Price
   - Line Tax = Line Subtotal x (Tax Rate / 100)
   - Line Total = Line Subtotal + Line Tax
6. Add additional products or delete mistakes using the red delete icon.
7. Click **Continue to Review**.

#### Step 3: Review, Status & Issue
1. Review the calculated financial summary:
   - **Subtotal**: Sum of base item amounts.
   - **Tax Total**: Cumulative VAT/sales tax.
   - **Grand Total**: Final invoice balance payable.
2. Select the **Initial Status**:
   - `Draft`: Saved locally for revision; not counted in dashboard sales analytics.
   - `Sent`: Dispatched to client; monitored under pending receivables.
   - `Paid`: Settlement complete; counted under paid revenue.
   - `Partially Paid`: Fractional payment received.
   - `Overdue`: Flagged when settlement exceeds due date.
3. Enter optional **Terms / Notes** (e.g., *Bank Transfer details, payment terms Net 30*).
4. Click **Issue Invoice** (or **Save Changes**).

---

### Module 5: OCR Quotation Scanning
[Screenshot Placeholder: Scan Quotation Dialog with sample template selection, extracted line items preview, and Import to Wizard button]

Invoicey features an integrated OCR scanner simulation allowing users to import physical quotation sheets or purchase estimates into structured invoices with zero manual typing.

#### Step-by-Step Instructions:
1. Navigate to the **Invoices** screen.
2. Click **Scan Quote** in the header action bar.
3. Select a scanned template (e.g., *Solar System Layout Quote (EcoPower)* or *IT Hardware Upgrade Quote (Apex Data)*).
4. Inspect the extracted handwritten notes, detected line items, quantities, unit prices, and tax rates.
5. Click **Import Scanned Items**.
6. Invoicey launches the Invoice Wizard with the customer, line items, and notes automatically populated and verified.

---

### Module 6: Quote-to-Invoice 1-Click Conversion
[Screenshot Placeholder: Invoice Detail Screen displaying a Quote document with 'Convert to Invoice' button]

When an estimate or quote is approved by a client, it can be converted into an official tax invoice without re-entering data.

#### Step-by-Step Instructions:
1. Open the target **Quote** from the Invoices list.
2. In the top action bar, click **Convert to Invoice**.
3. The system instantly:
   - Generates the next sequential invoice number (e.g., `INV-2026-0004`).
   - Copies all line items, customer details, and pricing.
   - Links the quote to the newly created invoice via its `convertedInvoiceId`.
   - Sets the invoice status to `Draft` ready for dispatch.

---

### Module 7: Document Delivery & Sharing (PDF, WhatsApp, Email)
[Screenshot Placeholder: Document Sharing modal showing WhatsApp formatted text preview and Native Share PDF button]

#### 1. PDF Generation & Preview
1. On any Invoice Detail screen, click **View PDF**.
2. The built-in PDF Preview engine renders the complete document using the active company template.
3. Use the top toolbar to **Print**, **Save as PDF**, or **Share** to external applications.

#### 2. WhatsApp Direct Messaging
1. Click **WhatsApp** on the invoice screen.
2. Choose one of two sharing modes:
   - **Send Text Summary**: Formats an invoice dispatch note with emojis, line item bullet points, and grand totals, opening WhatsApp directly with the client's phone number pre-filled.
   - **Share PDF Document**: Renders the formatted PDF and opens the native device share sheet to attach the file directly to any WhatsApp chat or group.

#### 3. Native Email Dispatch
1. Click **Email**.
2. Invoicey triggers the system email client (`mailto:`) with the recipient, subject line (`Invoice INV-2026-0001 from [Company]`), and formatted invoice summary pre-loaded.
3. If the invoice was in `Draft` status, Invoicey automatically updates its status to `Sent`.

---

### Module 8: Settings & Enterprise Configuration
[Screenshot Placeholder: Settings Screen showing Company Legal Details, PDF Template Selector, Biometrics, Invoice Numbering Format, and Cloud Backup controls]

#### 1. Company Legal Identity & Logo
- **Legal Name, Tax ID, Currency, Office Address**: Configure branding details printed across all PDFs and messages.
- **Company Logo**: Upload a PNG or JPG file (up to 5 MB). The image is converted into base64 storage for offline persistence.

#### 2. Invoice Numbering Format
- Administrators can define custom numbering formats using dynamic date and sequence tokens:
  - `{YYYY}`: 4-digit year (e.g., `2026`)
  - `{YY}`: 2-digit year (e.g., `26`)
  - `{MM}`: 2-digit month (e.g., `09`)
  - `{NNNN}`: Sequential counter padded to specified digits (e.g., `0001` for `{NNNN}`, or `00001` for `{NNNNN}`).
  - Example: `INV-{YYYY}-{MM}-{NNNN}` generates `INV-2026-09-0001`.

#### 3. PDF Designer Templates
- Select from five templates:
  - **Classic**: Traditional corporate layout with clear borders and structured tables.
  - **Modern**: Clean contemporary design with indigo primary headers.
  - **Minimal**: High-contrast typography with minimal lines for fast printing.
  - **Corporate**: Executive navy palette with distinct company credentials block.
  - **Elegant**: Refined dark slate styling for premium luxury billing.
- Click **Preview** to inspect sample output before saving.

#### 4. Testing Sandbox (Role Switcher)
- Located in Settings, this tool allows testing permission policies on demand.
- Select **Admin**, **Manager**, or **Viewer** to switch current session privileges in real-time.

#### 5. Google Drive Backup & Recovery
- **Link Google Account**: Associate a corporate Google account for cloud storage.
- **Auto-Backup**: When enabled, Invoicey automatically uploads a JSON snapshot to Google Drive upon every invoice, client, or company modification.
- **Manual Sync**: Triggers immediate snapshot creation.
- **Snapshot History**: Stores the last 10 snapshots with timestamp, invoice count, client count, and byte size. Clicking any snapshot restores the database to that exact historical state.
- **Export / Import Local JSON**: Allows saving `.json` backup archives to local disk or restoring backups via file picker.

#### 6. Remote Cloud Sync Server
- Enables cross-device synchronization with a centralized HTTPS API backend.
- Enter the API URL and sign in using Google ID Token authentication.
- Automatically handles version revisions and provides optimistic concurrency conflict alerts (`HTTP 409 Conflict`) if remote changes occur simultaneously.

---

## 5. Role-Based Operations Guide

```
+------------------------------------+-------+---------+--------+
| Feature / Operation                | Admin | Manager | Viewer |
+------------------------------------+-------+---------+--------+
| View Dashboard & Analytics         |  YES  |   YES   |  YES   |
| Browse Clients, Products, Invoices |  YES  |   YES   |  YES   |
| View & Download PDF Documents      |  YES  |   YES   |  YES   |
| Create & Edit Invoices & Quotes    |  YES  |   YES   |   NO   |
| Delete Invoices                    |  YES  |   YES   |   NO   |
| Add, Edit, Delete Clients          |  YES  |   YES   |   NO   |
| Add, Edit, Delete Products         |  YES  |   YES   |   NO   |
| Trigger WhatsApp & Email Reminders |  YES  |   YES   |   NO   |
| Modify Company Legal Profile/Logo  |  YES  |   NO    |   NO   |
| Edit Invoice Numbering Format      |  YES  |   NO    |   NO   |
| Configure Cloud Sync & Drive Snap  |  YES  |   NO    |   NO   |
| Switch Roles via Testing Sandbox   |  YES  |   YES   |  YES   |
+------------------------------------+-------+---------+--------+
```

### 5.1 Administrator Guide
- **Scope**: Full system authority, security configuration, and financial setup.
- **Key Responsibilities**:
  1. Set up company legal credentials, tax registrations, and brand logos.
  2. Define and lock the invoice numbering format schema.
  3. Manage cloud disaster recovery (Google Drive links and Remote Sync server URLs).
  4. Perform data restoration from previous snapshots when necessary.
  5. Audit user permissions and data integrity across all modules.

### 5.2 Manager Guide
- **Scope**: Day-to-day operational execution and sales transactions.
- **Key Responsibilities**:
  1. Maintain up-to-date client contact directories and shipping destinations.
  2. Manage the product catalog, standard pricing, and tax classifications.
  3. Prepare quotations and convert approved estimates into active invoices.
  4. Dispatch invoices via WhatsApp and Email.
  5. Record customer payments by updating invoice status to `Paid` or `Partially Paid`.

### 5.3 Viewer Guide
- **Scope**: Read-only oversight, auditing, and document retrieval.
- **Key Responsibilities**:
  1. Monitor accounts receivable health on the Dashboard analytics graphs.
  2. Search and review historical invoices and client billing ledgers.
  3. Preview, print, or download PDF invoices for accounting archives.
  4. Any attempted mutations (creation, deletion, updates) will display an explicit `Access Denied` notification.

---

## 6. Troubleshooting & Problem Resolution

### Issue 1: "Access Denied: Viewers cannot create or edit invoices"
- **Cause**: Current logged-in account has the `viewer` role assigned.
- **Resolution**: Log out and sign in with a Manager or Admin account. If using the demo sandbox, navigate to **Settings** -> **Testing Sandbox** and select **Admin** or **Manager**.

### Issue 2: "Cloud data changed on another device. Download it before uploading again."
- **Cause**: Optimistic locking conflict (`HTTP 409 Conflict`). Another workstation updated the remote sync workspace, incrementing the revision counter.
- **Resolution**: Open **Settings** -> **Remote Cloud Sync**, click **Download Workspace** to merge the latest cloud data, review the updated records, and then proceed with your upload.

### Issue 3: "Biometric verification failed / Not available"
- **Cause**: The device lacks biometric hardware, hardware permissions are denied, or no fingerprints/facial profiles are enrolled in the operating system.
- **Resolution**: Use the standard Email and Password login fields. In **Settings**, ensure biometrics are toggled on only after enrolling credentials in OS system settings.

### Issue 4: "Error: Selected client does not have a valid email address configured"
- **Cause**: The invoice's client profile contains an empty or improperly formatted email string.
- **Resolution**: Navigate to **Clients**, locate the client card, click **Edit**, input a valid RFC-compliant email address, and save. Return to the invoice to launch email dispatch.

### Issue 5: "Could not select logo: Logo must be smaller than 5 MB"
- **Cause**: Image resolution or uncompressed filesize exceeds the 5 megabyte threshold.
- **Resolution**: Compress the PNG or JPG using standard image utilities before importing.

### Issue 6: "Please enter a valid numbering format: must contain exactly one sequence token {NNNN}"
- **Cause**: The custom invoice format string in Settings has either omitted the sequence placeholder or provided multiple sequence blocks.
- **Resolution**: Ensure the format contains exactly one sequence token with 1 to 6 `N` characters (e.g., `INV-{YYYY}-{NNNN}`).

---

## 7. Frequently Asked Questions (FAQs)

**Q1: Does Invoicey require an active internet connection to create invoices?**
> **No.** Invoicey is built with an offline-first architecture. All records (clients, products, invoices, company profiles) are written to local on-device persistent storage. You only need connectivity when dispatching emails, triggering cloud sync, or linking Google Drive.

**Q2: How are overdue invoices tracked?**
> Invoicey automatically checks all saved invoices every time the application launches or reloads. Any invoice in `Sent` or `Partially Paid` status whose `dueDate` is earlier than the current device timestamp is automatically updated to `Overdue`.

**Q3: Can I issue invoices in different currencies for different clients?**
> The base currency is configured globally under **Company Profile** (e.g., `$`, `PKR`, `EUR`) to maintain accounting integrity across dashboard charts and reports. Custom currency codes can be selected in Settings.

**Q4: What happens if I convert a Quote to an Invoice? Does the Quote disappear?**
> **No.** The original Quote is preserved for audit trails. Its `convertedInvoiceId` attribute is updated to link directly to the newly spawned invoice, preventing duplicate conversions.

**Q5: Can I recover deleted invoices?**
> If an invoice was deleted accidentally, it can be restored if **Google Drive Auto-Backup** was enabled or if a recent snapshot was saved. Open **Settings** -> **Snapshot History** and tap **Restore** on the relevant timestamp.

**Q6: Where are PDF invoices saved when downloaded on Windows / Android / iOS?**
> The built-in PDF viewer uses the operating system's native printing and document sharing framework. Clicking **Print** or **Share** allows selecting any destination folder, cloud drive, or physical printer connected to the device.
