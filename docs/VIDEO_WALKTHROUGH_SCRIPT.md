# INVOICEY - ENTERPRISE INVOICE MANAGEMENT SYSTEM
## Scene-by-Scene Browser & App Video Walkthrough Script

---

## Overview & Recording Guidelines
- **Target Video Duration**: Approximately 5 to 7 minutes.
- **Tone**: Professional, crisp, executive, instructional.
- **Language**: Pure English.
- **Pacing**: Steady mouse movements, deliberate clicks, pausing for 1-2 seconds after opening modals or navigating between tabs.

---

### Scene 1: Initial Launch & Onboarding Choice
- **Duration**: 00:00 - 00:35
- **Screen**: Initial Gateway (`OnboardingScreen`)
- **Visual Action**:
  - Open the application. Show the clean welcome screen displaying "Welcome to Invoicey".
  - Hover the cursor over the badge: "Your data stays on this device".
  - Move cursor between the two cards: "Set up my company" and "Explore sample company".
  - Click on "Explore sample company".
- **Spoken Voiceover**:
  > *"Welcome to Invoicey, an enterprise-grade invoice and billing control center designed for seamless cash flow tracking and inventory management. When opening the system for the first time, your data remains completely localized on your host device. Businesses can choose between setting up a fresh company workspace or exploring a pre-seeded corporate environment. For today's demonstration, we'll enter our pre-configured Solar and IT enterprise workspace."*
- **Why This Screen is Essential**:
  - It establishes data privacy guarantees (offline-first, zero mandatory cloud sign-up) and allows testing without overwriting production company data.
- **User Decision Point**:
  - The user decides whether to configure a live, production company profile or load a pre-configured demonstration sandbox.

---

### Scene 2: Authentication & Biometric Access
- **Duration**: 00:35 - 01:10
- **Screen**: Login Screen (`LoginScreen`)
- **Visual Action**:
  - Show the gradient card with the "INVOICEY - Enterprise Invoice Control Center" brand header.
  - Enter email `admin@invoice.com` and password `admin123`.
  - Highlight the "Sign in with Biometrics" button.
  - Click "Sign In". The app loads the main navigation shell and displays the red `ADMIN` role badge in the top navigation bar.
- **Spoken Voiceover**:
  > *"Authentication in Invoicey is both secure and flexible. Users can sign in using their standard enterprise credentials or take advantage of device biometrics such as Touch ID, Windows Hello, or Fingerprint recognition. Upon signing in, the navigation bar immediately reflects your assigned security tier. Today, we're logged in as Super Admin, granting us unrestricted access across billing, inventory, and system configurations."*
- **Why This Screen is Essential**:
  - Enforces role-based boundaries, protecting sensitive financial data and system settings from unauthorized changes.
- **User Decision Point**:
  - The user chooses between password entry or instant biometric verification, establishing their permission context for the session.

---

### Scene 3: Executive Dashboard & Cash Flow Monitoring
- **Duration**: 01:10 - 01:50
- **Screen**: Analytics Dashboard (`DashboardScreen`)
- **Visual Action**:
  - Point to the four metric cards: Total Revenue ($8,450.11), Pending Payments ($0.00), Overdue Amount ($8,212.58), and Total Invoices (2).
  - Interact with the **Filter Controls Card**: Click the Client dropdown, select *EcoPower Solutions Inc.*, and observe the metrics recalculate in real-time.
  - Click **Reset Filters**.
  - Hover over the monthly sales bar chart. Point out the dynamic annual revenue distribution.
  - Scroll down to show the Recent Invoices table.
- **Spoken Voiceover**:
  > *"The Executive Dashboard provides instantaneous visibility into your business's financial health. At a single glance, executives can review realized revenue, outstanding accounts receivable, and aging overdue balances. Multi-dimensional filters allow you to isolate performance by specific client, invoice status, or fiscal year. Notice how the monthly sales bar chart immediately illustrates quarterly cash flow velocity."*
- **Why This Screen is Essential**:
  - Eliminates blind spots in accounts receivable, providing immediate alerts on overdue debts and sales trends.
- **User Decision Point**:
  - The user decides whether immediate debt collection action is required on overdue invoices or reviews historical quarterly revenue.

---

### Scene 4: Client Directory & Customer Profiles
- **Duration**: 01:50 - 02:30
- **Screen**: Client Database (`ClientListScreen`)
- **Visual Action**:
  - Click **Clients** on the sidebar navigation.
  - Type "Apex" into the search bar, showing instant real-time filtering. Clear search.
  - Click **+ Add Client** to show the modal dialog.
  - Quickly showcase the fields: Client Name, Email, Phone, Billing Address, Shipping Address.
  - Click **Cancel**, then point out the Edit and Delete actions on an existing client card.
- **Spoken Voiceover**:
  > *"The Client Directory maintains a consolidated record of your commercial partners. Each client profile stores legal billing addresses, physical delivery destinations, and critical communication channels such as accounting emails and international WhatsApp contact numbers. These endpoints integrate directly into our document dispatch engine, ensuring quotes and invoices reach the proper stakeholders without manual re-entry."*
- **Why This Screen is Essential**:
  - Prevents inaccurate invoice headers and provides the relational foundation for automated WhatsApp and Email dispatch.
- **User Decision Point**:
  - The user decides whether to onboard a new customer, update billing addresses, or verify client tax information.

---

### Scene 5: Inventory & Automatic SKU Generation
- **Duration**: 02:30 - 03:15
- **Screen**: Product Catalog (`ProductListScreen`)
- **Visual Action**:
  - Click **Inventory** on the sidebar.
  - Click through the Category Tabs: *All*, *Solar*, *IT*. Show how products filter instantly.
  - Click **+ Add Product**.
  - In the Name field, type "Commercial Solar Inverter 25kW".
  - In Category, select "Solar".
  - Click the **Auto Generate** button next to SKU. Show the generated code `SOL-COMSOLIN-001`.
  - Enter Unit Price `2800.00` and Tax Rate `15.0`.
  - Click **Cancel** to return to the catalog.
- **Spoken Voiceover**:
  > *"In the Product Catalog, items are categorized with standardized pricing and VAT or sales tax rules. To eliminate catalog ambiguity, Invoicey features an intelligent algorithmic SKU generator. By analyzing the category and product title, the system constructs an industry-standard, collision-free SKU with sequential numbering. This guarantees catalog consistency across complex solar hardware, enterprise IT servers, and recurring services."*
- **Why This Screen is Essential**:
  - Guarantees pricing accuracy and prevents tax calculation mistakes across sales representatives.
- **User Decision Point**:
  - The user decides whether to accept an auto-generated SKU or input custom enterprise inventory codes, and assigns standard tax rates.

---

### Scene 6: The 3-Step Invoice Creation Wizard
- **Duration**: 03:15 - 04:15
- **Screen**: Invoice Wizard (`InvoiceWizardScreen`)
- **Visual Action**:
  - Click **Invoices** on the sidebar, then click **Create Invoice**.
  - **Step 1 (Client Details)**: Note the auto-generated sequential number `INV-2026-0003`. Select *Apex Data Systems*. Click **Continue to Line Items**.
  - **Step 2 (Line Items)**: Select *Enterprise Rack Server* from the dropdown. Quantity: `2`. Click **Add Item to Invoice**.
  - Show the line subtotal, tax calculation, and line total.
  - Select a second item: *Managed L3 Network Switch*, Quantity `1`. Click **Add Item to Invoice**.
  - Highlight the running aggregate chip in the app bar updating in real-time.
  - Click **Continue to Review**.
  - **Step 3 (Review & Issue)**: Review Subtotal, Tax Total, and Grand Total. Select Status `Sent`. Add notes: "Payment Net 30 days via Wire Transfer."
  - Click **Issue Invoice**. Show the success notification.
- **Spoken Voiceover**:
  > *"Creating an invoice is structured through a guided three-step workflow. In Step 1, the invoice is assigned the next sequential number according to our corporate schema, and client dates are locked in. In Step 2, items are added directly from the catalog, with line subtotals, VAT, and aggregates calculated automatically. Finally, Step 3 provides an executive summary where the user confirms payment terms and issues the document into the system."*
- **Why This Screen is Essential**:
  - The central transaction hub of the business, ensuring every issued invoice is mathematically validated and properly linked.
- **User Decision Point**:
  - The user reviews line items, applies negotiated client rates if necessary, sets payment terms, and decides the initial status (Draft vs Sent).

---

### Scene 7: OCR Quotation Scanning & 1-Click Conversion
- **Duration**: 04:15 - 04:55
- **Screen**: Invoices Screen & Scan Dialog (`ScanQuotationDialog`, `InvoiceDetailScreen`)
- **Visual Action**:
  - From the Invoices list, click **Scan Quote**.
  - Select *Solar System Layout Quote (EcoPower)*. Show the handwritten preview text and extracted line items table.
  - Click **Import Scanned Items**. The wizard opens with all 4 solar components pre-populated.
  - Return to Invoices list. Open an existing Quote document.
  - Point to the **Convert to Invoice** button in the header. Click it. Show the alert confirming invoice creation and the updated quote link.
- **Spoken Voiceover**:
  > *"Invoicey bridges the gap between field assessments and accounting. Using our integrated OCR scanning simulation, field survey sheets and handwritten estimates can be imported directly into structured line items with zero manual typing. Furthermore, when a client approves an estimate, a single click converts the quotation into an active tax invoice, assigning a fresh sequential invoice number while preserving the original quote for audit compliance."*
- **Why This Screen is Essential**:
  - Eliminates duplicate data entry between sales estimations and final accounting invoices.
- **User Decision Point**:
  - The user decides whether to accept scanned OCR item interpretations and authorizes converting approved quotes into binding invoices.

---

### Scene 8: Designer PDF Templates, WhatsApp & Email Sharing
- **Duration**: 04:55 - 05:40
- **Screen**: Invoice Detail Screen (`InvoiceDetailScreen`, `InvoicePdfPreviewScreen`)
- **Visual Action**:
  - On the invoice detail screen, click **View PDF**.
  - Showcase the rendered PDF document: company logo, bill-to block, itemized table, tax breakdown, and footer.
  - Return and click **WhatsApp**.
  - Showcase the modal sheet:
    - Point to **Send Text Summary**: Show how it prepares an emoji-rich summary with direct client phone deep-linking.
    - Point to **Share PDF Document**: Show how it leverages native OS sharing.
  - Click **Email** to demonstrate triggering the pre-populated mail client.
- **Spoken Voiceover**:
  > *"Delivering invoices to clients is immediate. The integrated PDF engine formats your invoice into a crisp, vector-rendered document matching your chosen corporate theme. For modern client communication, the WhatsApp module allows dispatching either a concise text summary directly to the client's phone or attaching the complete PDF document through native device sharing. Standard email dispatch is also supported with pre-formatted invoice details."*
- **Why This Screen is Essential**:
  - Multi-channel delivery accelerates client receipt and drastically shortens payment turnaround times.
- **User Decision Point**:
  - The user decides the appropriate communication channel for the client (WhatsApp text summary, official WhatsApp PDF, or formal Email).

---

### Scene 9: Settings, Role Testing Sandbox & Cloud Disaster Recovery
- **Duration**: 05:40 - 06:30
- **Screen**: Settings Screen (`SettingsScreen`)
- **Visual Action**:
  - Click **Settings** on the sidebar.
  - Show the **Company Profile** card with editable legal name, tax ID, currency, and logo preview.
  - In **Preferences**, show the Visual Theme switch (toggle Dark Mode on and off), Biometrics switch, and Invoice Number Format.
  - In **PDF Template**, click **Preview** and cycle through *Classic*, *Modern*, *Minimal*, *Corporate*, and *Elegant*.
  - Scroll down to the **Testing Sandbox**: Click **Viewer**. Show how the role badge switches to grey `VIEWER`. Navigate to Invoices and show that the "Create Invoice" button is cleanly hidden and write actions are restricted.
  - Return to Settings, switch back to **Admin**.
  - Highlight the **Google Drive Backup** card showing the last 10 snapshots and auto-backup toggle.
  - Highlight the **Remote Cloud Sync Server** card with HTTPS URL configuration.
- **Spoken Voiceover**:
  > *"In Settings, administrators maintain complete governance over the corporate environment. You can customize invoice numbering tokens, choose from five designer PDF templates, and switch between light and dark visual themes. The built-in Testing Sandbox allows you to audit the exact user experience for Managers and Viewers in real time. Finally, enterprise disaster recovery is backed by automated Google Drive snapshot histories and optional REST cloud synchronization."*
- **Why This Screen is Essential**:
  - Centralizes governance, legal branding, document styling, security policies, and disaster recovery.
- **User Decision Point**:
  - The administrator decides corporate branding, template styling, security protocols, and cloud backup frequencies.

---

### Scene 10: Conclusion & Wrap-Up
- **Duration**: 06:30 - 06:50
- **Screen**: Dashboard Screen (`DashboardScreen`)
- **Visual Action**:
  - Return to the Dashboard screen showing the clean interface.
  - Move cursor over the INVOICEY logo in the top left.
  - Fade out or end recording.
- **Spoken Voiceover**:
  > *"With offline reliability, role-based protection, automated quotation workflows, and multi-channel delivery, Invoicey provides an all-in-one solution for modern business billing. Thank you for watching this walkthrough of Invoicey."*
