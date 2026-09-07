/**
 * INVOICEY - ENTERPRISE INVOICE MANAGEMENT WEB PLATFORM
 * Multi-tenant workspace partitioning, cloud sync engine,
 * 3-step executive wizard, OCR quotation scanner, WhatsApp/Email dispatch,
 * 5 PDF templates, and dynamic SKU generation.
 */

// ==========================================================================
// Default Fixtures (Synchronized with Flutter StorageService)
// ==========================================================================
const DEFAULT_COMPANY = {
  name: 'My Solar & IT Corp',
  taxId: 'TAX-2026-SOLARIT',
  address: '123 Renewable Energy Way, Suite 4B, Austin, TX 78701',
  currency: '$',
  email: 'finance@mysolarit.com',
  phone: '+1 (512) 555-8822',
  bankDetails: 'Global Tech Bank • Routing: 12200049 • Acc: 9876543210',
  logo: ''
};

const DEFAULT_USERS = [
  { id: 'u-1', name: 'Super Admin', email: 'admin@invoice.com', role: 'admin' },
  { id: 'u-2', name: 'Project Manager', email: 'manager@invoice.com', role: 'manager' },
  { id: 'u-3', name: 'General Viewer', email: 'viewer@invoice.com', role: 'viewer' }
];

const DEFAULT_CLIENTS = [
  {
    id: 'c-1',
    name: 'EcoPower Solutions Inc.',
    email: 'procurement@ecopower.com',
    phone: '+1 (512) 555-0192',
    billingAddress: '456 Green Way, Suite A, Austin, TX 78744',
    shippingAddress: '456 Green Way, Suite A, Austin, TX 78744'
  },
  {
    id: 'c-2',
    name: 'Apex Data Systems',
    email: 'billing@apexdata.net',
    phone: '+1 (206) 555-0143',
    billingAddress: '789 Cloud Tower Blvd, Seattle, WA 98101',
    shippingAddress: '789 Cloud Tower Blvd, Seattle, WA 98101'
  },
  {
    id: 'c-3',
    name: 'Global Tech Consulting',
    email: 'ap@globaltech.com',
    phone: '+1 (415) 555-0288',
    billingAddress: '55 Mission St, San Francisco, CA 94105',
    shippingAddress: '55 Mission St, San Francisco, CA 94105'
  }
];

const DEFAULT_PRODUCTS = [
  {
    id: 'p-sol-1',
    name: 'Tier-1 Monocrystalline Solar Panel (550W)',
    description: 'High-efficiency monocrystalline PV module for residential and commercial systems.',
    sku: 'SOL-PV-550M',
    unitPrice: 249.99,
    category: 'Solar',
    taxRate: 15.0,
    stock: 45
  },
  {
    id: 'p-sol-2',
    name: 'Hybrid Solar Inverter (10kW, Three-Phase)',
    description: 'Smart grid-tied inverter with battery integration backup system.',
    sku: 'SOL-INV-10K3P',
    unitPrice: 1350.00,
    category: 'Solar',
    taxRate: 15.0,
    stock: 12
  },
  {
    id: 'p-sol-3',
    name: 'Lithium-ion LiFePO4 Battery Storage Bank (5.12kWh, 48V)',
    description: 'Long-life wall-mounted lithium energy storage system.',
    sku: 'SOL-BAT-5KWH',
    unitPrice: 1999.00,
    category: 'Solar',
    taxRate: 15.0,
    stock: 8
  },
  {
    id: 'p-sol-4',
    name: 'Aluminum Solar Roof Mounting Structure (4-Panel Kit)',
    description: 'Anodized aluminum rails, clamps, and brackets for rooftop mounting.',
    sku: 'SOL-MNT-4PK',
    unitPrice: 179.50,
    category: 'Solar',
    taxRate: 15.0,
    stock: 30
  },
  {
    id: 'p-it-1',
    name: 'Enterprise Rack Server (2U, 2x Intel Xeon, 128GB RAM, 2TB NVMe)',
    description: 'High-performance database and virtualization platform, redundant PSU.',
    sku: 'IT-SRV-2U-XEON',
    unitPrice: 4799.00,
    category: 'IT',
    taxRate: 10.0,
    stock: 4
  },
  {
    id: 'p-it-2',
    name: 'Managed L3 Network Switch (48-Port Gigabit, PoE+)',
    description: 'High-capacity backbone switch with 4x 10G SFP+ uplink ports.',
    sku: 'IT-SWT-48P-L3',
    unitPrice: 899.99,
    category: 'IT',
    taxRate: 10.0,
    stock: 15
  },
  {
    id: 'p-it-3',
    name: 'Wi-Fi 6E Enterprise Access Point (Dual-Band)',
    description: 'High-density MU-MIMO wireless router with power over ethernet.',
    sku: 'IT-AP-WIFI6E',
    unitPrice: 289.00,
    category: 'IT',
    taxRate: 10.0,
    stock: 22
  }
];

function getSampleInvoices() {
  const d1 = new Date();
  d1.setDate(d1.getDate() - 15);
  const due1 = new Date();
  due1.setDate(due1.getDate() + 15);

  const d2 = new Date();
  d2.setDate(d2.getDate() - 25);
  const due2 = new Date();
  due2.setDate(due2.getDate() - 5);

  return [
    {
      id: 'inv-1',
      invoiceNumber: 'INV-2026-0001',
      clientId: 'c-1',
      issueDate: d1.toISOString().split('T')[0],
      dueDate: due1.toISOString().split('T')[0],
      status: 'paid',
      documentType: 'invoice',
      notes: 'Initial deployment equipment invoice. Standard Solar setup.',
      discount: 0,
      items: [
        {
          id: 'item-1-1',
          productId: 'SOL-PV-550M',
          productName: 'Tier-1 Monocrystalline Solar Panel (550W)',
          quantity: 8,
          unitPrice: 249.99,
          taxRate: 15.0,
          lineTotal: 1999.92
        },
        {
          id: 'item-1-2',
          productId: 'SOL-INV-10K3P',
          productName: 'Hybrid Solar Inverter (10kW, Three-Phase)',
          quantity: 1,
          unitPrice: 1350.00,
          taxRate: 15.0,
          lineTotal: 1350.00
        },
        {
          id: 'item-1-3',
          productId: 'SOL-BAT-5KWH',
          productName: 'Lithium-ion LiFePO4 Battery Storage Bank (5.12kWh, 48V)',
          quantity: 2,
          unitPrice: 1999.00,
          taxRate: 15.0,
          lineTotal: 3998.00
        }
      ],
      subTotal: 7347.92,
      taxTotal: 1102.19,
      grandTotal: 8450.11
    },
    {
      id: 'inv-2',
      invoiceNumber: 'INV-2026-0002',
      clientId: 'c-2',
      issueDate: d2.toISOString().split('T')[0],
      dueDate: due2.toISOString().split('T')[0],
      status: 'overdue',
      documentType: 'invoice',
      notes: 'Enterprise server hardware and networking upgrade.',
      discount: 0,
      items: [
        {
          id: 'item-2-1',
          productId: 'IT-SRV-2U-XEON',
          productName: 'Enterprise Rack Server (2U, 2x Intel Xeon, 128GB RAM, 2TB NVMe)',
          quantity: 1,
          unitPrice: 4799.00,
          taxRate: 10.0,
          lineTotal: 4799.00
        },
        {
          id: 'item-2-2',
          productId: 'IT-SWT-48P-L3',
          productName: 'Managed L3 Network Switch (48-Port Gigabit, PoE+)',
          quantity: 2,
          unitPrice: 899.99,
          taxRate: 10.0,
          lineTotal: 1799.98
        },
        {
          id: 'item-2-3',
          productId: 'IT-AP-WIFI6E',
          productName: 'Wi-Fi 6E Enterprise Access Point (Dual-Band)',
          quantity: 3,
          unitPrice: 289.00,
          taxRate: 10.0,
          lineTotal: 867.00
        }
      ],
      subTotal: 7465.98,
      taxTotal: 746.60,
      grandTotal: 8212.58
    },
    {
      id: 'inv-3',
      invoiceNumber: 'QTE-2026-0001',
      clientId: 'c-3',
      issueDate: new Date().toISOString().split('T')[0],
      dueDate: new Date(Date.now() + 14 * 86400000).toISOString().split('T')[0],
      status: 'sent',
      documentType: 'quote',
      notes: 'Quote for Q3 IT infrastructure rollout. Valid for 14 days.',
      discount: 50.0,
      items: [
        {
          id: 'item-3-1',
          productId: 'IT-SWT-48P-L3',
          productName: 'Managed L3 Network Switch (48-Port Gigabit, PoE+)',
          quantity: 1,
          unitPrice: 899.99,
          taxRate: 10.0,
          lineTotal: 899.99
        }
      ],
      subTotal: 899.99,
      taxTotal: 89.99,
      grandTotal: 939.98
    }
  ];
}

// Sample Scanned Quote Templates (Matching OcrScanService)
const OCR_TEMPLATES = [
  {
    id: 'ocr-1',
    title: 'Solar System Layout Quote (EcoPower)',
    clientName: 'EcoPower Solutions Inc.',
    clientId: 'c-1',
    notes: 'Deliver items directly to Austin site. Payment due Net 30.',
    taxRate: 15.0,
    items: [
      { productName: 'Tier-1 Monocrystalline Solar Panel (550W)', sku: 'SOL-PV-550M', quantity: 12, unitPrice: 240.00 },
      { productName: 'Hybrid Solar Inverter (10kW, Three-Phase)', sku: 'SOL-INV-10K3P', quantity: 2, unitPrice: 1300.00 },
      { productName: 'Solar DC Cable (4mm², Weatherproof, 100m Roll)', sku: 'SOL-CBL-4MM', quantity: 4, unitPrice: 100.00 },
      { productName: 'MPPT Solar Charge Controller (60A, 150V)', sku: 'SOL-MPPT-60A', quantity: 3, unitPrice: 310.00 }
    ]
  },
  {
    id: 'ocr-2',
    title: 'IT Hardware Upgrade Quote (Apex Data)',
    clientName: 'Apex Data Systems',
    clientId: 'c-2',
    notes: 'Net 15 days term. Redundant PSU installation included.',
    taxRate: 10.0,
    items: [
      { productName: 'Enterprise Rack Server (2U, 2x Intel Xeon, 128GB RAM, 2TB NVMe)', sku: 'IT-SRV-2U-XEON', quantity: 2, unitPrice: 4600.00 },
      { productName: 'Managed L3 Network Switch (48-Port Gigabit, PoE+)', sku: 'IT-SWT-48P-L3', quantity: 4, unitPrice: 850.00 },
      { productName: 'Wi-Fi 6E Enterprise Access Point (Dual-Band)', sku: 'IT-AP-WIFI6E', quantity: 6, unitPrice: 270.00 }
    ]
  }
];

// ==========================================================================
// Main Application Singleton
// ==========================================================================
const App = {
  // Active Tenant / Account session
  session: {
    accountId: 'default',
    accountName: 'Default Workspace',
    email: 'admin@invoice.com',
    token: null,
    revision: 0,
    syncStatus: 'offline', // 'synced', 'syncing', 'offline', 'conflict'
    apiUrl: 'http://localhost:3000'
  },

  state: {
    company: null,
    clients: [],
    products: [],
    invoices: [],
    users: [],
    snapshots: [],
    settings: {
      pdfTemplate: 'Classic',
      invoiceNumberFormat: 'INV-{YYYY}-{NNNN}',
      apiUrl: 'http://localhost:3000',
      autoSync: true
    },
    currentRole: 'admin',
    activeTab: 'dashboard',
    
    // View Filters & Toggles
    selectedYear: 2026,
    invoiceFilterStatus: 'all',
    invoiceSearchQuery: '',
    clientSearchQuery: '',
    clientViewMode: 'table', // 'table' | 'cards'
    productSearchQuery: '',
    productCategoryFilter: 'All',
    productViewMode: 'table', // 'table' | 'cards'
    
    // Wizard State (3-Step Executive Model)
    wizardStep: 1,
    wizardEditingInvoiceId: null,
    wizardItems: [],
    
    // Active Inspectors
    activeViewingInvoiceId: null,
    previewTemplate: 'Classic',
    
    // OCR Temp State
    ocrScanning: false,
    ocrSelectedTemplate: null
  },

  init() {
    this.loadAccountSession();
    this.loadStorage();
    this.initTheme();
    this.initEventListeners();
    this.renderHeaderInfo();
    this.renderSyncStatus();
    this.switchTab('dashboard');
    this.updateRBAC();

    // Auto-check remote sync on load
    if (this.session.token) {
      this.downloadWorkspace(false);
    }
  },

  // ========================================================================
  // Multi-Tenant Storage Partitioning
  // ========================================================================
  getStorageKey(key) {
    return `invoicey_${this.session.accountId}_${key}`;
  },

  loadAccountSession() {
    try {
      const savedSession = localStorage.getItem('invoicey_active_session');
      if (savedSession) {
        this.session = { ...this.session, ...JSON.parse(savedSession) };
      }
    } catch (e) {
      console.warn('Could not load session', e);
    }
  },

  saveAccountSession() {
    localStorage.setItem('invoicey_active_session', JSON.stringify(this.session));
  },

  loadStorage() {
    try {
      const compKey = this.getStorageKey('company');
      const storedComp = localStorage.getItem(compKey);
      this.state.company = storedComp ? JSON.parse(storedComp) : { ...DEFAULT_COMPANY };

      const clientsKey = this.getStorageKey('clients');
      const storedClients = localStorage.getItem(clientsKey);
      this.state.clients = storedClients ? JSON.parse(storedClients) : [...DEFAULT_CLIENTS];

      const prodsKey = this.getStorageKey('products');
      const storedProds = localStorage.getItem(prodsKey);
      this.state.products = storedProds ? JSON.parse(storedProds) : [...DEFAULT_PRODUCTS];

      const invsKey = this.getStorageKey('invoices');
      const storedInvs = localStorage.getItem(invsKey);
      this.state.invoices = storedInvs ? JSON.parse(storedInvs) : getSampleInvoices();

      const usersKey = this.getStorageKey('users');
      const storedUsers = localStorage.getItem(usersKey);
      this.state.users = storedUsers ? JSON.parse(storedUsers) : [...DEFAULT_USERS];

      const setsKey = this.getStorageKey('settings');
      const storedSettings = localStorage.getItem(setsKey);
      if (storedSettings) {
        this.state.settings = { ...this.state.settings, ...JSON.parse(storedSettings) };
      }
      this.session.apiUrl = this.state.settings.apiUrl || this.session.apiUrl;
      this.state.previewTemplate = this.state.settings.pdfTemplate || 'Classic';

      const snapsKey = this.getStorageKey('snapshots');
      const storedSnaps = localStorage.getItem(snapsKey);
      this.state.snapshots = storedSnaps ? JSON.parse(storedSnaps) : [];

      const roleKey = this.getStorageKey('current_role');
      const storedRole = localStorage.getItem(roleKey);
      if (storedRole) this.state.currentRole = storedRole;

      // Check overdue invoices on every load (Rule 4.4 from LOGIC_EXPLANATION.md)
      this.checkOverdueInvoices();

      this.saveAll(false);
    } catch (e) {
      console.error('Error loading partition storage', e);
      this.resetToDefaults();
    }
  },

  saveAll(triggerSync = true) {
    localStorage.setItem(this.getStorageKey('company'), JSON.stringify(this.state.company));
    localStorage.setItem(this.getStorageKey('clients'), JSON.stringify(this.state.clients));
    localStorage.setItem(this.getStorageKey('products'), JSON.stringify(this.state.products));
    localStorage.setItem(this.getStorageKey('invoices'), JSON.stringify(this.state.invoices));
    localStorage.setItem(this.getStorageKey('users'), JSON.stringify(this.state.users));
    localStorage.setItem(this.getStorageKey('settings'), JSON.stringify(this.state.settings));
    localStorage.setItem(this.getStorageKey('snapshots'), JSON.stringify(this.state.snapshots));
    localStorage.setItem(this.getStorageKey('current_role'), this.state.currentRole);

    this.saveAccountSession();

    // Auto-sync in background if configured and connected
    if (triggerSync && this.session.token && this.state.settings.autoSync) {
      this.debounceUpload();
    }
  },

  switchAccountWorkspace(accountId, accountName, email = '') {
    this.session.accountId = accountId;
    this.session.accountName = accountName;
    this.session.email = email || `${accountId}@invoice.com`;
    this.session.token = null;
    this.session.revision = 0;
    this.session.syncStatus = 'offline';

    this.saveAccountSession();
    this.loadStorage();
    this.renderHeaderInfo();
    this.renderSyncStatus();
    this.renderCurrentView();
    this.showToast(`Switched to workspace: ${accountName}`, 'info');
  },

  resetToDefaults() {
    this.state.company = { ...DEFAULT_COMPANY };
    this.state.clients = [...DEFAULT_CLIENTS];
    this.state.products = [...DEFAULT_PRODUCTS];
    this.state.invoices = getSampleInvoices();
    this.state.users = [...DEFAULT_USERS];
    this.state.settings = {
      pdfTemplate: 'Classic',
      invoiceNumberFormat: 'INV-{YYYY}-{NNNN}',
      apiUrl: 'http://localhost:3000',
      autoSync: true
    };
    this.saveAll(false);
    this.renderHeaderInfo();
    this.renderCurrentView();
    this.showToast('Workspace reset to sample company data.', 'success');
  },

  // Overdue status lifecycle engine (Rule 4.4)
  checkOverdueInvoices() {
    const today = new Date().toISOString().split('T')[0];
    let mutated = false;
    this.state.invoices.forEach(inv => {
      if (inv.documentType === 'invoice' && (inv.status === 'sent' || inv.status === 'partiallyPaid')) {
        if (inv.dueDate && inv.dueDate < today) {
          inv.status = 'overdue';
          mutated = true;
        }
      }
    });
    if (mutated) {
      this.saveAll(false);
    }
  },

  // ========================================================================
  // Remote Cloud Sync Engine (Cross-Platform Mobile <-> Web)
  // ========================================================================
  renderSyncStatus() {
    const dot = document.getElementById('sync-indicator-dot');
    const text = document.getElementById('sync-indicator-text');
    if (!dot || !text) return;

    dot.className = `sync-dot ${this.session.syncStatus}`;
    switch (this.session.syncStatus) {
      case 'synced':
        text.innerText = `Synced (Rev ${this.session.revision})`;
        break;
      case 'syncing':
        text.innerText = 'Syncing...';
        break;
      case 'conflict':
        text.innerText = 'Conflict: Update on Mobile';
        break;
      default:
        text.innerText = 'Local Offline';
        break;
    }
  },

  async pingApi() {
    const url = this.session.apiUrl.replace(/\/$/, '');
    try {
      const res = await fetch(`${url}/health`);
      if (res.ok) {
        this.showToast(`Sync API is online (${url})`, 'success');
        return true;
      }
      throw new Error(`HTTP ${res.status}`);
    } catch (e) {
      this.showToast(`Cannot reach Sync API at ${url}. Ensure server is running.`, 'error');
      return false;
    }
  },

  async connectWithToken(token) {
    if (!token || !token.trim()) return;
    this.session.token = token.trim();
    this.session.syncStatus = 'syncing';
    this.renderSyncStatus();

    try {
      await this.downloadWorkspace(true);
      this.session.syncStatus = 'synced';
      this.saveAccountSession();
      this.renderSyncStatus();
      this.showToast('Successfully connected to Cloud Workspace!', 'success');
      this.closeModal('modal-account-sync');
    } catch (e) {
      this.session.syncStatus = 'offline';
      this.renderSyncStatus();
      this.showToast(`Failed to connect: ${e.message}`, 'error');
    }
  },

  async downloadWorkspace(notify = true) {
    if (!this.session.token) return;
    const url = this.session.apiUrl.replace(/\/$/, '');

    try {
      const res = await fetch(`${url}/v1/workspace`, {
        headers: { 'Authorization': `Bearer ${this.session.token}` }
      });
      if (res.status === 401) {
        throw new Error('Session token expired. Please re-authenticate.');
      }
      if (!res.ok) throw new Error(`HTTP ${res.status}`);

      const data = await res.json();
      this.session.revision = data.revision || 0;

      if (data.payload && typeof data.payload === 'object') {
        const p = data.payload;
        if (p.company) this.state.company = p.company;
        if (Array.isArray(p.clients)) this.state.clients = p.clients;
        if (Array.isArray(p.products)) this.state.products = p.products;
        if (Array.isArray(p.invoices)) this.state.invoices = p.invoices;
        if (p.settings) this.state.settings = { ...this.state.settings, ...p.settings };

        this.saveAll(false);
        this.renderHeaderInfo();
        this.renderCurrentView();
      }

      this.session.syncStatus = 'synced';
      this.renderSyncStatus();
      if (notify) this.showToast(`Cloud snapshot downloaded (Revision ${this.session.revision}).`, 'success');
    } catch (e) {
      this.session.syncStatus = 'offline';
      this.renderSyncStatus();
      if (notify) this.showToast(`Download failed: ${e.message}`, 'error');
    }
  },

  _debounceTimer: null,
  debounceUpload() {
    clearTimeout(this._debounceTimer);
    this._debounceTimer = setTimeout(() => {
      this.uploadWorkspace(false);
    }, 1200);
  },

  async uploadWorkspace(notify = true) {
    if (!this.session.token) {
      if (notify) this.showToast('Please connect to Sync API with your token first.', 'info');
      return;
    }

    const url = this.session.apiUrl.replace(/\/$/, '');
    this.session.syncStatus = 'syncing';
    this.renderSyncStatus();

    const payload = {
      company: this.state.company,
      clients: this.state.clients,
      products: this.state.products,
      invoices: this.state.invoices,
      settings: this.state.settings
    };

    try {
      const res = await fetch(`${url}/v1/workspace`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.session.token}`
        },
        body: JSON.stringify({
          payload,
          expectedRevision: this.session.revision
        })
      });

      if (res.status === 409) {
        // Optimistic Concurrency Conflict (Rule 4.6)
        this.session.syncStatus = 'conflict';
        this.renderSyncStatus();
        this.showToast('Conflict: Workspace was updated from another device! Please download latest changes first.', 'error');
        return;
      }

      if (!res.ok) throw new Error(`HTTP ${res.status}`);

      const result = await res.json();
      this.session.revision = result.revision;
      this.session.syncStatus = 'synced';
      this.saveAccountSession();
      this.renderSyncStatus();
      if (notify) this.showToast(`Workspace pushed to Cloud (Revision ${this.session.revision}).`, 'success');
    } catch (e) {
      this.session.syncStatus = 'offline';
      this.renderSyncStatus();
      if (notify) this.showToast(`Upload failed: ${e.message}`, 'error');
    }
  },

  // ========================================================================
  // Theme & Role Control
  // ========================================================================
  initTheme() {
    const savedTheme = localStorage.getItem('invoicey_theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);
  },

  toggleTheme() {
    const current = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', current);
    localStorage.setItem('invoicey_theme', current);
    this.showToast(`Switched to ${current} mode.`, 'info');
  },

  setRole(role) {
    this.state.currentRole = role;
    this.saveAll(false);
    this.updateRBAC();
    this.showToast(`Active role: ${role.toUpperCase()}`, 'info');
  },

  updateRBAC() {
    const role = this.state.currentRole;
    const select = document.getElementById('header-role-select');
    if (select) select.value = role;

    const isViewer = role === 'viewer';
    document.querySelectorAll('.rbac-write').forEach(el => {
      el.disabled = isViewer;
      if (isViewer) {
        el.title = 'Action restricted for Viewer role';
        el.classList.add('disabled');
      } else {
        el.title = '';
        el.classList.remove('disabled');
      }
    });
  },

  // ========================================================================
  // Navigation
  // ========================================================================
  switchTab(tabId) {
    this.state.activeTab = tabId;
    document.querySelectorAll('.nav-link').forEach(link => {
      link.classList.toggle('active', link.dataset.tab === tabId);
    });

    document.querySelectorAll('.app-view').forEach(view => {
      view.classList.remove('active');
    });

    const activeView = document.getElementById(`view-${tabId}`);
    if (activeView) activeView.classList.add('active');

    const titles = {
      dashboard: { title: 'Dashboard Analytics', sub: 'Cash flow, revenue health, and sales metrics overview' },
      invoices: { title: 'Invoices & Quotations', sub: 'Monitor full invoice lifecycles, send payment reminders, and download PDFs' },
      clients: { title: 'Client Database', sub: 'Manage customer accounts, billing addresses, and spend history' },
      inventory: { title: 'Inventory & Catalog', sub: 'Monitor stock levels, SKUs, tax rates, and prices' },
      settings: { title: 'System Settings', sub: 'Customize company profile, numbering formats, templates, and sync parameters' }
    };

    if (titles[tabId]) {
      document.getElementById('header-title').innerText = titles[tabId].title;
      document.getElementById('header-subtitle').innerText = titles[tabId].sub;
    }

    document.querySelector('aside.app-sidebar')?.classList.remove('open');
    this.renderCurrentView();
  },

  renderCurrentView() {
    switch (this.state.activeTab) {
      case 'dashboard': this.renderDashboard(); break;
      case 'invoices': this.renderInvoices(); break;
      case 'clients': this.renderClients(); break;
      case 'inventory': this.renderInventory(); break;
      case 'settings': this.renderSettings(); break;
    }
  },

  renderHeaderInfo() {
    const compName = this.state.company?.name || 'My Company';
    const compCurr = this.state.company?.currency || '$';
    const compLogo = this.state.company?.logo;

    const compEl = document.getElementById('sidebar-company-name');
    const currEl = document.getElementById('sidebar-company-currency');
    const avatarEl = document.getElementById('sidebar-company-avatar');

    if (compEl) compEl.innerText = compName;
    if (currEl) currEl.innerText = `Currency: ${compCurr}`;
    if (avatarEl) {
      if (compLogo) {
        avatarEl.innerHTML = `<img src="${compLogo}" alt="Logo" />`;
      } else {
        avatarEl.innerText = compName.charAt(0).toUpperCase();
      }
    }

    const accountBtnText = document.getElementById('header-account-label');
    if (accountBtnText) {
      accountBtnText.innerText = this.session.accountName || this.session.accountId;
    }
  },

  // ========================================================================
  // VIEW: DASHBOARD (Parity: KPI Cards + Status Donut Chart + Year Bar Chart)
  // ========================================================================
  renderDashboard() {
    const clientFilter = document.getElementById('dash-filter-client')?.value || '';
    const statusFilter = document.getElementById('dash-filter-status')?.value || '';
    const year = parseInt(document.getElementById('dash-year-select')?.value, 10) || this.state.selectedYear;
    this.state.selectedYear = year;

    // Populate client filter options
    const clientSelect = document.getElementById('dash-filter-client');
    if (clientSelect && clientSelect.children.length <= 1) {
      this.state.clients.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c.id;
        opt.textContent = c.name;
        clientSelect.appendChild(opt);
      });
    }

    let filtered = this.state.invoices;
    if (clientFilter) filtered = filtered.filter(inv => inv.clientId === clientFilter);
    if (statusFilter) filtered = filtered.filter(inv => inv.status === statusFilter);

    // Filter reset visibility
    const resetBtn = document.getElementById('dash-btn-reset-filters');
    if (resetBtn) {
      resetBtn.style.display = (clientFilter || statusFilter || year !== 2026) ? 'inline-flex' : 'none';
    }

    // Financial KPIs
    let totalRevenue = 0;
    let pendingAmount = 0;
    let overdueAmount = 0;

    filtered.forEach(inv => {
      if (inv.documentType === 'quote') return;
      if (inv.status === 'paid') totalRevenue += inv.grandTotal;
      else if (inv.status === 'sent' || inv.status === 'partiallyPaid') pendingAmount += inv.grandTotal;
      else if (inv.status === 'overdue') overdueAmount += inv.grandTotal;
    });

    const curr = this.state.company.currency;
    document.getElementById('kpi-revenue').innerText = `${curr}${totalRevenue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    document.getElementById('kpi-pending').innerText = `${curr}${pendingAmount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    document.getElementById('kpi-overdue').innerText = `${curr}${overdueAmount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    document.getElementById('kpi-count').innerText = `${filtered.length} Invoices`;

    // Render 12-Month Sales Chart for Selected Year
    this.renderRevenueChart(filtered, year);

    // Render Status Distribution Donut Chart (Mobile Parity!)
    this.renderStatusPieChart(filtered);

    // Render Recent Invoices
    this.renderRecentInvoices(filtered);
  },

  renderStatusPieChart(invoices) {
    const container = document.getElementById('status-donut-box');
    const legend = document.getElementById('status-donut-legend');
    if (!container || !legend) return;

    const counts = { paid: 0, sent: 0, overdue: 0, draft: 0 };
    invoices.forEach(i => {
      if (counts[i.status] !== undefined) counts[i.status]++;
    });

    const total = invoices.length;
    document.getElementById('donut-total-count').innerText = total;

    if (total === 0) {
      container.innerHTML = `<circle cx="85" cy="85" r="60" fill="none" stroke="var(--border)" stroke-width="24" />`;
      legend.innerHTML = '<span style="color: var(--text-muted); font-size: 0.8rem;">No documents</span>';
      return;
    }

    const circumference = 2 * Math.PI * 60; // r=60 => 376.99
    const colors = {
      paid: '#10b981',
      sent: '#0284c7',
      overdue: '#ef4444',
      draft: '#94a3b8'
    };

    let offset = 0;
    let svgCircles = '';
    let legendHtml = '';

    const statuses = [
      { key: 'paid', label: 'Paid' },
      { key: 'sent', label: 'Sent' },
      { key: 'overdue', label: 'Overdue' },
      { key: 'draft', label: 'Draft' }
    ];

    statuses.forEach(st => {
      const cnt = counts[st.key];
      const pct = (cnt / total) * 100;
      const strokeDash = (cnt / total) * circumference;

      if (cnt > 0) {
        svgCircles += `
          <circle cx="85" cy="85" r="60" fill="none" stroke="${colors[st.key]}" stroke-width="24"
                  stroke-dasharray="${strokeDash} ${circumference}"
                  stroke-dashoffset="-${offset}"
                  style="transition: all 0.5s ease;" />
        `;
        offset += strokeDash;
      }

      legendHtml += `
        <div class="legend-item">
          <div class="legend-left">
            <span class="legend-dot" style="background: ${colors[st.key]};"></span>
            <span>${st.label}</span>
          </div>
          <span class="legend-val">${cnt} (${pct.toFixed(0)}%)</span>
        </div>
      `;
    });

    container.innerHTML = svgCircles;
    legend.innerHTML = legendHtml;
  },

  renderRevenueChart(invoices, year) {
    const container = document.getElementById('sales-bar-chart');
    if (!container) return;

    // Build 12-month series
    const months = [];
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (let m = 0; m < 12; m++) {
      months.push({ monthIndex: m, label: monthNames[m], total: 0 });
    }

    invoices.forEach(inv => {
      if (inv.documentType === 'quote' || inv.status === 'draft') return;
      const d = new Date(inv.issueDate);
      if (d.getFullYear() === year) {
        months[d.getMonth()].total += inv.grandTotal;
      }
    });

    const maxVal = Math.max(...months.map(m => m.total), 1000);
    const curr = this.state.company.currency;

    container.innerHTML = '';
    months.forEach(m => {
      const pct = Math.max((m.total / maxVal) * 100, 3);
      const col = document.createElement('div');
      col.className = 'bar-col';
      col.innerHTML = `
        <div class="bar-pill ${m.total > 0 ? 'has-revenue' : ''}" style="height: ${pct}%;" data-tooltip="${curr}${m.total.toFixed(2)}"></div>
        <span class="bar-month">${m.label}</span>
      `;
      container.appendChild(col);
    });
  },

  renderRecentInvoices(invoices) {
    const tbody = document.getElementById('dash-recent-tbody');
    if (!tbody) return;
    tbody.innerHTML = '';

    const curr = this.state.company.currency;
    const recent = [...invoices].sort((a, b) => new Date(b.issueDate) - new Date(a.issueDate)).slice(0, 5);

    if (recent.length === 0) {
      tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 24px;">No invoices match the selected filter.</td></tr>`;
      return;
    }

    recent.forEach(inv => {
      const client = this.getClient(inv.clientId);
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td class="mono" style="font-weight: 700;">
          ${inv.invoiceNumber}
          ${inv.documentType === 'quote' ? '<span class="badge badge-quote" style="margin-left: 6px;">QUOTE</span>' : ''}
        </td>
        <td><strong>${escapeHtml(client?.name || 'Unknown')}</strong></td>
        <td>${inv.issueDate}</td>
        <td class="mono" style="font-weight: 700;">${curr}${inv.grandTotal.toFixed(2)}</td>
        <td><span class="badge badge-${inv.status}">${inv.status.toUpperCase()}</span></td>
        <td>
          <button class="btn btn-outline btn-sm" onclick="App.openInvoiceDetail('${inv.id}')">View</button>
          <button class="btn btn-primary btn-sm" onclick="App.openPdfPreview('${inv.id}')">PDF</button>
        </td>
      `;
      tbody.appendChild(tr);
    });
  },

  resetDashboardFilters() {
    const c = document.getElementById('dash-filter-client');
    const s = document.getElementById('dash-filter-status');
    const y = document.getElementById('dash-year-select');
    if (c) c.value = '';
    if (s) s.value = '';
    if (y) y.value = '2026';
    this.state.selectedYear = 2026;
    this.renderDashboard();
  },

  // ========================================================================
  // VIEW: INVOICES & QUOTES (Parity: Scan Quote, WhatsApp, Email)
  // ========================================================================
  renderInvoices() {
    const tbody = document.getElementById('invoices-tbody');
    if (!tbody) return;

    const filterStatus = this.state.invoiceFilterStatus;
    const query = (this.state.invoiceSearchQuery || '').toLowerCase().trim();

    let list = this.state.invoices.filter(inv => {
      if (filterStatus === 'quotes') {
        if (inv.documentType !== 'quote') return false;
      } else if (filterStatus === 'invoices') {
        if (inv.documentType !== 'invoice') return false;
      } else if (filterStatus !== 'all') {
        if (inv.status !== filterStatus) return false;
      }

      if (query) {
        const client = this.getClient(inv.clientId);
        const matchNum = inv.invoiceNumber.toLowerCase().includes(query);
        const matchClient = (client?.name || '').toLowerCase().includes(query);
        const matchNotes = (inv.notes || '').toLowerCase().includes(query);
        if (!matchNum && !matchClient && !matchNotes) return false;
      }
      return true;
    });

    list.sort((a, b) => new Date(b.issueDate) - new Date(a.issueDate));
    tbody.innerHTML = '';
    const curr = this.state.company.currency;

    if (list.length === 0) {
      tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 32px;">No invoices found matching current criteria.</td></tr>`;
      return;
    }

    list.forEach(inv => {
      const client = this.getClient(inv.clientId);
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td class="mono" style="font-weight: 700;">
          ${inv.invoiceNumber}
          ${inv.documentType === 'quote' ? '<span class="badge badge-quote" style="margin-left: 6px;">QUOTE</span>' : ''}
          ${inv.convertedInvoiceId ? `<span class="badge badge-paid" style="margin-left: 4px; font-size: 0.65rem;" title="Converted to ${inv.convertedInvoiceId}">CONVERTED</span>` : ''}
        </td>
        <td>
          <div style="font-weight: 700;">${escapeHtml(client?.name || 'Unknown')}</div>
          <div style="font-size: 0.75rem; color: var(--text-muted);">${escapeHtml(client?.email || '')}</div>
        </td>
        <td>${inv.issueDate}</td>
        <td>${inv.dueDate}</td>
        <td class="mono" style="font-weight: 700;">${curr}${inv.grandTotal.toFixed(2)}</td>
        <td><span class="badge badge-${inv.status}">${inv.status.toUpperCase()}</span></td>
        <td>
          <div style="display: flex; gap: 4px; align-items: center;">
            <button class="btn btn-outline btn-sm" onclick="App.openInvoiceDetail('${inv.id}')" title="Inspect">View</button>
            <button class="btn btn-primary btn-sm" onclick="App.openPdfPreview('${inv.id}')" title="PDF">PDF</button>
            <button class="btn btn-whatsapp btn-sm" onclick="App.openWhatsAppShare('${inv.id}')" title="Send WhatsApp">
              <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor"><path d="M12.04 2c-5.46 0-9.91 4.45-9.91 9.91 0 1.75.46 3.45 1.32 4.95L2.05 22l5.25-1.38c1.45.79 3.08 1.21 4.74 1.21 5.46 0 9.91-4.45 9.91-9.91 0-2.65-1.03-5.14-2.9-7.01A9.816 9.816 0 0 0 12.04 2z"/></svg>
            </button>
            <button class="btn btn-outline btn-sm" onclick="App.sendInvoiceEmail('${inv.id}')" title="Send Email">
              <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor"><path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/></svg>
            </button>
          </div>
        </td>
      `;
      tbody.appendChild(tr);
    });

    this.updateRBAC();
  },

  setInvoiceFilter(status, elem) {
    this.state.invoiceFilterStatus = status;
    document.querySelectorAll('.filter-tab').forEach(t => t.classList.remove('active'));
    if (elem) elem.classList.add('active');
    this.renderInvoices();
  },

  onInvoiceSearch(query) {
    this.state.invoiceSearchQuery = query;
    this.renderInvoices();
  },

  // ========================================================================
  // 3-STEP EXECUTIVE WIZARD (Parity with InvoiceWizardScreen.dart)
  // Supports Create New & Edit Existing Invoice/Quote
  // ========================================================================
  openWizard(type = 'invoice', invoiceToEdit = null) {
    if (this.state.currentRole === 'viewer') {
      this.showToast('Access Denied: Viewers cannot create or edit invoices.', 'error');
      return;
    }

    this.state.wizardStep = 1;
    this.state.wizardEditingInvoiceId = invoiceToEdit ? invoiceToEdit.id : null;

    const isEdit = invoiceToEdit !== null;
    const isQuote = isEdit ? invoiceToEdit.documentType === 'quote' : type === 'quote';

    document.getElementById('wiz-doc-type').value = isQuote ? 'quote' : 'invoice';
    document.getElementById('wiz-modal-title').innerText = isEdit
      ? `Edit ${isQuote ? 'Quote' : 'Invoice'} ${invoiceToEdit.invoiceNumber}`
      : `Create New ${isQuote ? 'Quotation' : 'Invoice'}`;

    // Populate Clients Selector
    const clientSel = document.getElementById('wiz-client');
    clientSel.innerHTML = '<option value="">-- Select Client --</option>';
    this.state.clients.forEach(c => {
      const opt = document.createElement('option');
      opt.value = c.id;
      opt.textContent = `${c.name} (${c.email})`;
      clientSel.appendChild(opt);
    });

    if (isEdit) {
      document.getElementById('wiz-number').value = invoiceToEdit.invoiceNumber;
      clientSel.value = invoiceToEdit.clientId;
      document.getElementById('wiz-issue-date').value = invoiceToEdit.issueDate;
      document.getElementById('wiz-due-date').value = invoiceToEdit.dueDate;
      document.getElementById('wiz-status-select').value = invoiceToEdit.status;
      document.getElementById('wiz-notes').value = invoiceToEdit.notes || '';
      this.state.wizardItems = invoiceToEdit.items.map(it => ({ ...it }));
    } else {
      // Auto-generate next number
      const num = isQuote ? this.generateNextQuoteNumber() : this.generateNextInvoiceNumber();
      document.getElementById('wiz-number').value = num;

      const today = new Date().toISOString().split('T')[0];
      const due = new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0];
      document.getElementById('wiz-issue-date').value = today;
      document.getElementById('wiz-due-date').value = due;
      document.getElementById('wiz-status-select').value = isQuote ? 'sent' : 'draft';
      document.getElementById('wiz-notes').value = isQuote
        ? 'This quote is valid for 14 days from issue date.'
        : 'Payment is due within 30 days of issue date.';

      this.state.wizardItems = [];
      this.addWizardLineItem();
    }

    this.renderWizardItemsTable();
    this.updateWizardStepUI();
    document.getElementById('modal-wizard').classList.add('active');
  },

  // Numbering format generator (Rule 4.1 from LOGIC_EXPLANATION.md)
  generateNextInvoiceNumber() {
    const year = new Date().getFullYear();
    const count = this.state.invoices.filter(i => i.documentType === 'invoice').length + 1;
    const format = this.state.settings.invoiceNumberFormat || 'INV-{YYYY}-{NNNN}';
    return format
      .replace('{YYYY}', year)
      .replace('{YY}', String(year).slice(-2))
      .replace('{MM}', String(new Date().getMonth() + 1).padStart(2, '0'))
      .replace('{NNNN}', String(count).padStart(4, '0'))
      .replace('{NNN}', String(count).padStart(3, '0'))
      .replace('{NN}', String(count).padStart(2, '0'));
  },

  generateNextQuoteNumber() {
    const year = new Date().getFullYear();
    const count = this.state.invoices.filter(i => i.documentType === 'quote').length + 1;
    return `QTE-${year}-${String(count).padStart(4, '0')}`;
  },

  setWizardStep(step) {
    if (step < 1 || step > 3) return;

    // Step 1 validation
    if (step > 1) {
      const client = document.getElementById('wiz-client').value;
      const num = document.getElementById('wiz-number').value.trim();
      if (!client) {
        this.showToast('Please select a client.', 'error');
        return;
      }
      if (!num) {
        this.showToast('Please enter an invoice number.', 'error');
        return;
      }
    }

    // Step 2 validation
    if (step > 2) {
      if (this.state.wizardItems.length === 0) {
        this.showToast('Validation Error: Invoice must contain at least 1 item.', 'error');
        return;
      }
      for (const it of this.state.wizardItems) {
        if (!it.productName.trim() || it.quantity <= 0 || it.unitPrice < 0) {
          this.showToast('Please complete all line item details with valid quantities and prices.', 'error');
          return;
        }
      }
    }

    this.state.wizardStep = step;
    this.updateWizardStepUI();

    if (step === 3) {
      this.renderWizardReview();
    }
  },

  updateWizardStepUI() {
    const s = this.state.wizardStep;
    for (let i = 1; i <= 3; i++) {
      const stepItem = document.getElementById(`wiz-step-ind-${i}`);
      const page = document.getElementById(`wiz-page-${i}`);
      if (stepItem) {
        stepItem.classList.toggle('active', i === s);
        stepItem.classList.toggle('completed', i < s);
      }
      if (page) page.classList.toggle('active', i === s);
    }

    const prevBtn = document.getElementById('wiz-btn-prev');
    const nextBtn = document.getElementById('wiz-btn-next');
    const saveBtn = document.getElementById('wiz-btn-save');

    if (prevBtn) prevBtn.style.display = s === 1 ? 'none' : 'inline-flex';
    if (nextBtn) nextBtn.style.display = s === 3 ? 'none' : 'inline-flex';
    if (saveBtn) saveBtn.style.display = s === 3 ? 'inline-flex' : 'none';
  },

  addWizardLineItem(prod = null) {
    const item = {
      id: 'item-' + Date.now() + '-' + Math.floor(Math.random() * 1000),
      productId: prod?.sku || prod?.id || '',
      productName: prod?.name || '',
      quantity: 1,
      unitPrice: prod?.unitPrice || 0.0,
      taxRate: prod?.taxRate !== undefined ? prod.taxRate : 10.0,
      lineTotal: prod?.unitPrice || 0.0
    };
    this.state.wizardItems.push(item);
    this.renderWizardItemsTable();
  },

  removeWizardLineItem(idx) {
    this.state.wizardItems.splice(idx, 1);
    if (this.state.wizardItems.length === 0) {
      this.addWizardLineItem();
    } else {
      this.renderWizardItemsTable();
    }
  },

  renderWizardItemsTable() {
    const tbody = document.getElementById('wiz-items-tbody');
    if (!tbody) return;
    tbody.innerHTML = '';
    const curr = this.state.company.currency;

    this.state.wizardItems.forEach((it, idx) => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td style="width: 38%;">
          <input type="text" class="form-control" value="${escapeHtml(it.productName)}" placeholder="Item title / SKU" oninput="App.updateWizardItem(${idx}, 'productName', this.value)" />
          <div style="margin-top: 4px;">
            <select class="form-control" style="font-size: 0.75rem; padding: 4px 8px;" onchange="App.selectInventoryProductForWizard(${idx}, this.value)">
              <option value="">⚡ Quick-Pick Catalog Item...</option>
              ${this.state.products.map(p => `<option value="${p.id}" ${p.sku === it.productId || p.id === it.productId ? 'selected' : ''}>${p.name} (${curr}${p.unitPrice.toFixed(2)})</option>`).join('')}
            </select>
          </div>
        </td>
        <td style="width: 14%;">
          <input type="number" min="1" step="1" class="form-control" value="${it.quantity}" oninput="App.updateWizardItem(${idx}, 'quantity', parseFloat(this.value) || 0)" />
        </td>
        <td style="width: 18%;">
          <input type="number" min="0" step="0.01" class="form-control" value="${it.unitPrice}" oninput="App.updateWizardItem(${idx}, 'unitPrice', parseFloat(this.value) || 0)" />
        </td>
        <td style="width: 14%;">
          <input type="number" min="0" max="100" step="1" class="form-control" value="${it.taxRate}" oninput="App.updateWizardItem(${idx}, 'taxRate', parseFloat(this.value) || 0)" />
        </td>
        <td style="width: 16%; font-weight: 700; font-family: var(--mono); vertical-align: middle;">
          ${curr}${((it.quantity * it.unitPrice) * (1 + it.taxRate / 100)).toFixed(2)}
        </td>
        <td style="vertical-align: middle;">
          <button class="btn btn-outline btn-sm" style="color: var(--danger); padding: 4px 8px;" onclick="App.removeWizardLineItem(${idx})" title="Delete Line Item">✕</button>
        </td>
      `;
      tbody.appendChild(tr);
    });

    this.calculateWizardTotals();
  },

  selectInventoryProductForWizard(idx, prodId) {
    if (!prodId) return;
    const prod = this.state.products.find(p => p.id === prodId);
    if (prod && this.state.wizardItems[idx]) {
      this.state.wizardItems[idx].productId = prod.sku || prod.id;
      this.state.wizardItems[idx].productName = prod.name;
      this.state.wizardItems[idx].unitPrice = prod.unitPrice;
      this.state.wizardItems[idx].taxRate = prod.taxRate;
      this.state.wizardItems[idx].lineTotal = this.state.wizardItems[idx].quantity * prod.unitPrice;
      this.renderWizardItemsTable();
    }
  },

  updateWizardItem(idx, field, value) {
    if (!this.state.wizardItems[idx]) return;
    this.state.wizardItems[idx][field] = value;
    this.calculateWizardTotals();
  },

  calculateWizardTotals() {
    let subTotal = 0;
    let taxTotal = 0;

    this.state.wizardItems.forEach(it => {
      const lineSub = it.quantity * it.unitPrice;
      const lineTax = lineSub * (it.taxRate / 100);
      it.lineTotal = lineSub;
      subTotal += lineSub;
      taxTotal += lineTax;
    });

    const grandTotal = subTotal + taxTotal;
    const curr = this.state.company.currency;

    const subEl = document.getElementById('wiz-subtotal-display');
    const taxEl = document.getElementById('wiz-tax-display');
    const topEl = document.getElementById('wiz-header-total-display');

    if (subEl) subEl.innerText = `${curr}${subTotal.toFixed(2)}`;
    if (taxEl) taxEl.innerText = `${curr}${taxTotal.toFixed(2)}`;
    if (topEl) topEl.innerText = `Total: ${curr}${grandTotal.toFixed(2)}`;

    return { subTotal, taxTotal, grandTotal };
  },

  renderWizardReview() {
    const totals = this.calculateWizardTotals();
    const clientId = document.getElementById('wiz-client').value;
    const client = this.getClient(clientId);
    const curr = this.state.company.currency;

    const revClient = document.getElementById('wiz-rev-client');
    const revNumber = document.getElementById('wiz-rev-number');
    const revDates = document.getElementById('wiz-rev-dates');
    const revItems = document.getElementById('wiz-rev-items');
    const revTotals = document.getElementById('wiz-rev-totals');

    if (revClient) {
      revClient.innerHTML = `
        <strong>${escapeHtml(client?.name || 'Unknown')}</strong><br/>
        <span style="color: var(--text-muted); font-size: 0.85rem;">
          ${escapeHtml(client?.email || '')} • ${escapeHtml(client?.phone || '')}<br/>
          ${escapeHtml(client?.billingAddress || '')}
        </span>
      `;
    }

    if (revNumber) {
      const docType = document.getElementById('wiz-doc-type').value.toUpperCase();
      const status = document.getElementById('wiz-status-select').value.toUpperCase();
      revNumber.innerHTML = `
        <span class="badge badge-paid">${docType}</span>
        <span class="badge badge-sent" style="margin-left: 6px;">${status}</span>
        <strong style="margin-left: 8px;">${document.getElementById('wiz-number').value}</strong>
      `;
    }

    if (revDates) {
      revDates.innerText = `Issued: ${document.getElementById('wiz-issue-date').value} | Due: ${document.getElementById('wiz-due-date').value}`;
    }

    if (revItems) {
      revItems.innerHTML = this.state.wizardItems.map(it => `
        <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid var(--border-light); font-size: 0.88rem;">
          <div>
            <strong>${escapeHtml(it.productName)}</strong>
            <span style="color: var(--text-muted); font-size: 0.8rem;"> (x${it.quantity} @ ${curr}${it.unitPrice.toFixed(2)} + ${it.taxRate}% tax)</span>
          </div>
          <div class="mono" style="font-weight: 700;">${curr}${((it.quantity * it.unitPrice) * (1 + it.taxRate / 100)).toFixed(2)}</div>
        </div>
      `).join('');
    }

    if (revTotals) {
      revTotals.innerHTML = `
        <div style="display: flex; justify-content: space-between; margin-bottom: 4px; font-size: 0.9rem;">
          <span style="color: var(--text-muted);">Subtotal:</span>
          <span class="mono">${curr}${totals.subTotal.toFixed(2)}</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 4px; font-size: 0.9rem;">
          <span style="color: var(--text-muted);">Tax Total:</span>
          <span class="mono">${curr}${totals.taxTotal.toFixed(2)}</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-top: 8px; padding-top: 8px; border-top: 2px solid var(--border); font-size: 1.15rem; font-weight: 800;">
          <span>Grand Total:</span>
          <span class="mono" style="color: var(--primary);">${curr}${totals.grandTotal.toFixed(2)}</span>
        </div>
      `;
    }
  },

  saveWizardInvoice() {
    const totals = this.calculateWizardTotals();
    const docType = document.getElementById('wiz-doc-type').value;
    const invNumber = document.getElementById('wiz-number').value.trim();
    const clientId = document.getElementById('wiz-client').value;
    const issueDate = document.getElementById('wiz-issue-date').value;
    const dueDate = document.getElementById('wiz-due-date').value;
    const status = document.getElementById('wiz-status-select').value;
    const notes = document.getElementById('wiz-notes').value.trim();

    if (this.state.wizardEditingInvoiceId) {
      // Edit mode
      const idx = this.state.invoices.findIndex(i => i.id === this.state.wizardEditingInvoiceId);
      if (idx !== -1) {
        this.state.invoices[idx] = {
          ...this.state.invoices[idx],
          invoiceNumber: invNumber,
          clientId,
          issueDate,
          dueDate,
          status,
          notes,
          items: this.state.wizardItems.map(it => ({ ...it, lineTotal: it.quantity * it.unitPrice })),
          subTotal: totals.subTotal,
          taxTotal: totals.taxTotal,
          grandTotal: totals.grandTotal
        };
        this.showToast(`Updated ${invNumber} successfully!`, 'success');
      }
    } else {
      // Create mode
      const newInvoice = {
        id: 'inv-' + Date.now(),
        invoiceNumber: invNumber,
        clientId,
        issueDate,
        dueDate,
        status,
        documentType: docType,
        notes,
        discount: 0,
        items: this.state.wizardItems.map(it => ({ ...it, lineTotal: it.quantity * it.unitPrice })),
        subTotal: totals.subTotal,
        taxTotal: totals.taxTotal,
        grandTotal: totals.grandTotal
      };

      // Deduct inventory stock
      if (docType === 'invoice') {
        newInvoice.items.forEach(it => {
          if (it.productId) {
            const prod = this.state.products.find(p => p.sku === it.productId || p.id === it.productId);
            if (prod && typeof prod.stock === 'number') {
              prod.stock = Math.max(0, prod.stock - it.quantity);
            }
          }
        });
      }

      this.state.invoices.unshift(newInvoice);
      this.showToast(`Created ${docType.toUpperCase()} ${invNumber}!`, 'success');
    }

    this.saveAll();
    this.closeModal('modal-wizard');
    this.renderCurrentView();
  },

  // ========================================================================
  // OCR QUOTATION SCANNER (Parity with ScanQuotationDialog.dart)
  // ========================================================================
  openOcrScanner() {
    if (this.state.currentRole === 'viewer') {
      this.showToast('Viewers cannot scan quotations.', 'error');
      return;
    }

    this.state.ocrScanning = false;
    this.state.ocrSelectedTemplate = OCR_TEMPLATES[0];

    const sel = document.getElementById('ocr-template-select');
    if (sel) {
      sel.innerHTML = OCR_TEMPLATES.map(t => `<option value="${t.id}">${t.title}</option>`).join('');
    }

    this.updateOcrTemplatePreview();
    document.getElementById('modal-ocr-scanner').classList.add('active');
  },

  updateOcrTemplatePreview() {
    const sel = document.getElementById('ocr-template-select');
    const tId = sel ? sel.value : OCR_TEMPLATES[0].id;
    const t = OCR_TEMPLATES.find(item => item.id === tId) || OCR_TEMPLATES[0];
    this.state.ocrSelectedTemplate = t;

    const preview = document.getElementById('ocr-quote-preview');
    if (preview) {
      preview.innerHTML = `
        <div style="font-size: 0.85rem; line-height: 1.6;">
          <strong>Target Client:</strong> ${escapeHtml(t.clientName)}<br/>
          <strong>Tax Rate:</strong> ${t.taxRate}%<br/>
          <strong>Items Count:</strong> ${t.items.length} items detected<br/>
          <div style="margin-top: 8px; font-family: var(--mono); font-size: 0.78rem; background: var(--surface); padding: 8px; border-radius: 6px; border: 1px solid var(--border);">
            ${t.items.map(it => `• ${it.productName} (x${it.quantity}) @ $${it.unitPrice.toFixed(2)}`).join('<br/>')}
          </div>
        </div>
      `;
    }

    document.getElementById('ocr-laser').style.display = 'none';
    document.getElementById('ocr-progress-bar').style.width = '0%';
    document.getElementById('ocr-btn-import').style.display = 'none';
    document.getElementById('ocr-terminal-logs').innerHTML = '> Ready to scan. Press "Start Neural OCR Analysis" to begin.';
  },

  async triggerOcrScan() {
    const t = this.state.ocrSelectedTemplate;
    if (!t) return;

    this.state.ocrScanning = true;
    const laser = document.getElementById('ocr-laser');
    const pBar = document.getElementById('ocr-progress-bar');
    const term = document.getElementById('ocr-terminal-logs');
    const importBtn = document.getElementById('ocr-btn-import');

    if (laser) laser.style.display = 'block';
    term.innerHTML = '> [1] Initializing neural layout segmentation engine...';

    const steps = [
      'Raw binarization of pixel arrays... Done.',
      'Analyzing alignment margins and skew (Detected: 1.2° skew)... Correcting.',
      'Running handwriting recognition parser (Neural OCR engine V4.2)...',
      `Recognized Client: ${t.clientName} (Confidence: 98.4%)`,
      `Extracted line item: ${t.items[0].productName} (x${t.items[0].quantity})`,
      `Extracted line item: ${t.items[1].productName} (x${t.items[1].quantity})`,
      'Parsed currency: $ (Standard USD rate mappings)',
      `Parsed Terms: ${t.notes}`,
      'Quotation OCR mapping completed with 99.1% overall confidence!'
    ];

    for (let i = 0; i < steps.length; i++) {
      await new Promise(r => setTimeout(r, 380));
      const pct = Math.round(((i + 1) / steps.length) * 100);
      if (pBar) pBar.style.width = `${pct}%`;
      term.innerHTML += `<br/>> [${i + 2}] ${steps[i]}`;
      term.scrollTop = term.scrollHeight;
    }

    if (laser) laser.style.display = 'none';
    if (importBtn) importBtn.style.display = 'inline-flex';
    this.state.ocrScanning = false;
    this.showToast('OCR scan completed successfully!', 'success');
  },

  importOcrIntoWizard() {
    const t = this.state.ocrSelectedTemplate;
    if (!t) return;

    this.closeModal('modal-ocr-scanner');

    // Open wizard as quote with OCR items
    this.openWizard('quote');

    // Select matched client
    const clientSel = document.getElementById('wiz-client');
    if (clientSel && t.clientId) {
      clientSel.value = t.clientId;
    }

    document.getElementById('wiz-notes').value = t.notes || '';

    // Map items
    this.state.wizardItems = t.items.map(it => ({
      id: 'item-ocr-' + Math.floor(Math.random() * 100000),
      productId: it.sku,
      productName: it.productName,
      quantity: it.quantity,
      unitPrice: it.unitPrice,
      taxRate: t.taxRate,
      lineTotal: it.quantity * it.unitPrice
    }));

    this.renderWizardItemsTable();
    this.showToast('Imported scanned quote items directly into wizard!', 'success');
  },

  // ========================================================================
  // MULTI-CHANNEL DISPATCH: WHATSAPP & EMAIL (Parity with Whatsapp/Email Service)
  // ========================================================================
  openWhatsAppShare(invoiceId) {
    const inv = this.state.invoices.find(i => i.id === invoiceId);
    if (!inv) return;

    const client = this.getClient(inv.clientId);
    const comp = this.state.company;
    const curr = comp.currency;

    const rawPhone = client?.phone || '';
    const cleanPhone = rawPhone.replace(/[^0-9+]/g, '');

    const itemsSummary = inv.items
      .map(it => `• ${it.productName} (x${it.quantity}) - ${curr}${it.lineTotal.toFixed(2)}`)
      .join('\n');

    const msg = `📄 *${inv.documentType.toUpperCase()}: ${inv.invoiceNumber}*\n` +
      `*From:* ${comp.name}\n` +
      `----------------------------------------\n` +
      `👤 *Bill To:* ${client?.name || 'Customer'}\n` +
      `📅 *Issue Date:* ${inv.issueDate}\n` +
      `📅 *Due Date:* ${inv.dueDate}\n` +
      `STATUS: *${inv.status.toUpperCase()}*\n\n` +
      `🛒 *Items:*\n${itemsSummary}\n\n` +
      `----------------------------------------\n` +
      `💰 *Grand Total:* *${curr}${inv.grandTotal.toFixed(2)}*\n` +
      `----------------------------------------\n` +
      (inv.notes ? `📌 *Notes:* ${inv.notes}\n\n` : '') +
      `Thank you for doing business with us!`;

    document.getElementById('wa-phone-input').value = cleanPhone;
    document.getElementById('wa-message-preview').innerText = msg;

    document.getElementById('modal-whatsapp-share').classList.add('active');
  },

  sendWhatsAppNow() {
    const phone = document.getElementById('wa-phone-input').value.trim();
    const msg = document.getElementById('wa-message-preview').innerText;
    const encoded = encodeURIComponent(msg);

    const url = phone.length > 0
      ? `https://api.whatsapp.com/send?phone=${phone}&text=${encoded}`
      : `https://api.whatsapp.com/send?text=${encoded}`;

    window.open(url, '_blank');
    this.closeModal('modal-whatsapp-share');
    this.showToast('WhatsApp dispatch launched!', 'success');
  },

  sendInvoiceEmail(invoiceId) {
    const inv = this.state.invoices.find(i => i.id === invoiceId);
    if (!inv) return;

    const client = this.getClient(inv.clientId);
    const comp = this.state.company;
    const curr = comp.currency;

    if (!client || !client.email) {
      this.showToast('Client email is not configured.', 'error');
      return;
    }

    const itemsList = inv.items
      .map(it => `- ${it.productName} (x${it.quantity}): ${curr}${it.lineTotal.toFixed(2)}`)
      .join('\n');

    const subject = encodeURIComponent(`${inv.documentType === 'quote' ? 'Quotation' : 'Invoice'} ${inv.invoiceNumber} from ${comp.name}`);
    const body = encodeURIComponent(
      `Dear ${client.name},\n\n` +
      `Please find below the summary details of your ${inv.documentType} ${inv.invoiceNumber}.\n\n` +
      `Document Details:\n` +
      `------------------------------\n` +
      `Issue Date: ${inv.issueDate}\n` +
      `Due Date: ${inv.dueDate}\n` +
      `Total Amount Due: ${curr}${inv.grandTotal.toFixed(2)}\n\n` +
      `Items:\n` +
      `${itemsList}\n\n` +
      `Notes:\n` +
      `${inv.notes || 'N/A'}\n\n` +
      `Best regards,\n` +
      `${comp.name}\n` +
      `${comp.address}`
    );

    window.location.href = `mailto:${client.email}?subject=${subject}&body=${body}`;

    // Auto mark draft as sent
    if (inv.status === 'draft') {
      inv.status = 'sent';
      this.saveAll();
      this.renderCurrentView();
    }

    this.showToast(`Email client triggered for ${client.email}`, 'info');
  },

  // ========================================================================
  // INVOICE DETAIL & ACTIONS
  // ========================================================================
  openInvoiceDetail(invoiceId) {
    const inv = this.state.invoices.find(i => i.id === invoiceId);
    if (!inv) return;

    this.state.activeViewingInvoiceId = invoiceId;
    const client = this.getClient(inv.clientId);
    const curr = this.state.company.currency;

    document.getElementById('detail-number').innerText = inv.invoiceNumber;
    document.getElementById('detail-type-badge').innerHTML = `
      <span class="badge badge-${inv.status}">${inv.status.toUpperCase()}</span>
      ${inv.documentType === 'quote' ? '<span class="badge badge-quote" style="margin-left: 6px;">QUOTATION</span>' : '<span class="badge badge-paid" style="margin-left: 6px;">TAX INVOICE</span>'}
    `;

    document.getElementById('detail-client-info').innerHTML = `
      <h4 style="font-weight: 800; font-size: 1.1rem; margin-bottom: 4px;">${escapeHtml(client?.name || 'Unknown')}</h4>
      <p style="color: var(--text-muted); font-size: 0.85rem;">
        Email: ${escapeHtml(client?.email || 'N/A')}<br/>
        Phone: ${escapeHtml(client?.phone || 'N/A')}<br/>
        Billing: ${escapeHtml(client?.billingAddress || 'N/A')}
      </p>
    `;

    document.getElementById('detail-dates-info').innerHTML = `
      <p style="font-size: 0.88rem;">
        <strong>Issue Date:</strong> ${inv.issueDate}<br/>
        <strong>Due Date:</strong> ${inv.dueDate}<br/>
        ${inv.convertedInvoiceId ? `<strong>Linked Document:</strong> <span class="mono">${inv.convertedInvoiceId}</span><br/>` : ''}
      </p>
    `;

    // Items table
    const tbody = document.getElementById('detail-items-tbody');
    tbody.innerHTML = inv.items.map(it => `
      <tr>
        <td><strong>${escapeHtml(it.productName)}</strong></td>
        <td style="text-align: center;">${it.quantity}</td>
        <td class="mono" style="text-align: right;">${curr}${it.unitPrice.toFixed(2)}</td>
        <td style="text-align: center;">${it.taxRate}%</td>
        <td class="mono" style="text-align: right; font-weight: 700;">${curr}${((it.quantity * it.unitPrice) * (1 + it.taxRate / 100)).toFixed(2)}</td>
      </tr>
    `).join('');

    // Summary
    document.getElementById('detail-summary').innerHTML = `
      <div style="display: flex; justify-content: space-between; margin-bottom: 4px;"><span>Subtotal:</span><span class="mono">${curr}${inv.subTotal.toFixed(2)}</span></div>
      <div style="display: flex; justify-content: space-between; margin-bottom: 4px;"><span>Tax:</span><span class="mono">${curr}${inv.taxTotal.toFixed(2)}</span></div>
      <div style="display: flex; justify-content: space-between; margin-top: 8px; padding-top: 8px; border-top: 2px solid var(--border); font-size: 1.15rem; font-weight: 800;"><span>Total:</span><span class="mono" style="color: var(--primary);">${curr}${inv.grandTotal.toFixed(2)}</span></div>
    `;

    document.getElementById('detail-notes').innerText = inv.notes || 'No notes specified.';

    const convertBtn = document.getElementById('detail-btn-convert');
    if (convertBtn) {
      convertBtn.style.display = inv.documentType === 'quote' && !inv.convertedInvoiceId ? 'inline-flex' : 'none';
    }

    this.updateRBAC();
    document.getElementById('modal-invoice-detail').classList.add('active');
  },

  editCurrentInvoice() {
    const inv = this.state.invoices.find(i => i.id === this.state.activeViewingInvoiceId);
    if (!inv) return;
    this.closeModal('modal-invoice-detail');
    this.openWizard(inv.documentType, inv);
  },

  editActiveInvoice() {
    this.editCurrentInvoice();
  },

  setInvoiceStatus(newStatus) {
    if (this.state.currentRole === 'viewer') {
      this.showToast('Viewer role cannot alter status.', 'error');
      return;
    }

    const inv = this.state.invoices.find(i => i.id === this.state.activeViewingInvoiceId);
    if (inv) {
      inv.status = newStatus;
      this.saveAll();
      this.openInvoiceDetail(inv.id);
      this.renderCurrentView();
      this.showToast(`Invoice status updated to ${newStatus.toUpperCase()}.`, 'success');
    }
  },

  convertQuoteToInvoice() {
    if (this.state.currentRole === 'viewer') {
      this.showToast('Viewer role cannot convert quotes.', 'error');
      return;
    }

    const quote = this.state.invoices.find(i => i.id === this.state.activeViewingInvoiceId);
    if (!quote || quote.documentType !== 'quote') return;

    if (confirm(`Convert quotation ${quote.invoiceNumber} to an active Tax Invoice?`)) {
      const invNum = this.generateNextInvoiceNumber();

      const newInv = {
        ...quote,
        id: 'inv-' + Date.now(),
        invoiceNumber: invNum,
        documentType: 'invoice',
        status: 'draft',
        convertedInvoiceId: quote.invoiceNumber,
        issueDate: new Date().toISOString().split('T')[0],
        dueDate: new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0]
      };

      quote.convertedInvoiceId = invNum;
      quote.status = 'paid';

      this.state.invoices.unshift(newInv);
      this.saveAll();

      this.closeModal('modal-invoice-detail');
      this.renderCurrentView();
      this.showToast(`Converted! Created new active invoice ${invNum}.`, 'success');
      this.openInvoiceDetail(newInv.id);
    }
  },

  duplicateInvoice(invoiceId) {
    if (this.state.currentRole === 'viewer') {
      this.showToast('Viewer role cannot duplicate.', 'error');
      return;
    }

    const id = invoiceId || this.state.activeViewingInvoiceId;
    const orig = this.state.invoices.find(i => i.id === id);
    if (!orig) return;

    const newNum = orig.documentType === 'quote' ? this.generateNextQuoteNumber() : this.generateNextInvoiceNumber();

    const dupe = {
      ...orig,
      id: 'inv-' + Date.now(),
      invoiceNumber: newNum,
      status: 'draft',
      issueDate: new Date().toISOString().split('T')[0],
      dueDate: new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0],
      convertedInvoiceId: null
    };

    this.state.invoices.unshift(dupe);
    this.saveAll();
    this.renderCurrentView();
    this.showToast(`Duplicated into ${dupe.invoiceNumber}!`, 'success');
    this.openInvoiceDetail(dupe.id);
  },

  deleteInvoice(invoiceId) {
    if (this.state.currentRole === 'viewer') {
      this.showToast('Viewer role cannot delete documents.', 'error');
      return;
    }

    const id = invoiceId || this.state.activeViewingInvoiceId;
    const inv = this.state.invoices.find(i => i.id === id);
    if (!inv) return;

    if (confirm(`Are you sure you want to delete ${inv.invoiceNumber}? This action cannot be undone.`)) {
      this.state.invoices = this.state.invoices.filter(i => i.id !== id);
      this.saveAll();
      this.closeModal('modal-invoice-detail');
      this.renderCurrentView();
      this.showToast(`Deleted ${inv.invoiceNumber}.`, 'info');
    }
  },

  // ========================================================================
  // 5 PDF TEMPLATES RENDERING ENGINE
  // ========================================================================
  openPdfPreview(invoiceId, template = null) {
    const inv = this.state.invoices.find(i => i.id === invoiceId);
    if (!inv) return;

    this.state.activeViewingInvoiceId = invoiceId;
    if (template) this.state.previewTemplate = template;

    this.renderPdfSheet(inv, this.state.previewTemplate);
    document.getElementById('modal-pdf-preview').classList.add('active');
  },

  setPdfTemplate(template) {
    this.state.previewTemplate = template;
    const inv = this.state.invoices.find(i => i.id === this.state.activeViewingInvoiceId);
    if (inv) this.renderPdfSheet(inv, template);
  },

  renderPdfSheet(inv, templateName) {
    const company = this.state.company;
    const client = this.getClient(inv.clientId);
    const curr = company.currency;

    document.querySelectorAll('.pdf-template-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.template === templateName);
    });

    const sheet = document.getElementById('pdf-sheet');
    if (!sheet) return;

    sheet.className = `pdf-invoice-sheet template-${templateName.toLowerCase()}`;

    const titleMap = {
      Classic: inv.documentType === 'quote' ? 'QUOTATION' : 'INVOICE',
      Modern: inv.documentType === 'quote' ? 'QUOTATION / MODERN' : 'INVOICE / MODERN',
      Minimal: inv.documentType === 'quote' ? 'QUOTATION' : 'INVOICE',
      Corporate: inv.documentType === 'quote' ? 'COMMERCIAL QUOTATION' : 'TAX INVOICE',
      Elegant: inv.documentType === 'quote' ? 'Quotation' : 'Invoice'
    };

    const footerMap = {
      Classic: 'Thank you for your business! Please remit payment within the specified terms.',
      Modern: 'Simple. Clear. Professional. Powering clean energy and IT infrastructure.',
      Minimal: 'Thank you.',
      Corporate: 'Issued electronically by the automated billing division. All rights reserved.',
      Elegant: 'With sincere appreciation for our ongoing business partnership.'
    };

    sheet.innerHTML = `
      <div>
        <div class="pdf-banner"></div>

        <!-- Header -->
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 36px;">
          <div>
            ${company.logo ? `<img src="${company.logo}" style="max-height: 48px; max-width: 160px; margin-bottom: 8px; object-fit: contain;" /><br/>` : ''}
            <h1 style="font-size: 1.6rem; font-weight: 900; margin-bottom: 4px;">${escapeHtml(company.name)}</h1>
            <p style="font-size: 0.82rem; color: #475569; line-height: 1.4;">
              ${escapeHtml(company.address)}<br/>
              ${company.taxId ? `Tax Registration ID: <strong>${escapeHtml(company.taxId)}</strong><br/>` : ''}
              ${company.email ? `Email: ${escapeHtml(company.email)} • Phone: ${escapeHtml(company.phone || '')}` : ''}
            </p>
          </div>
          <div style="text-align: right;">
            <div class="pdf-title">${titleMap[templateName] || 'INVOICE'}</div>
            <div style="font-family: var(--mono); font-size: 1.1rem; font-weight: 800; margin-top: 4px;"># ${inv.invoiceNumber}</div>
            <div style="margin-top: 6px;">
              <span class="badge badge-${inv.status}" style="font-size: 0.75rem;">${inv.status.toUpperCase()}</span>
            </div>
          </div>
        </div>

        <!-- Client & Metadata -->
        <div style="display: flex; justify-content: space-between; padding: 16px; background: #f8fafc; border-radius: 8px; margin-bottom: 32px; border: 1px solid #e2e8f0;">
          <div>
            <div style="font-size: 0.72rem; font-weight: 800; color: #64748b; text-transform: uppercase; margin-bottom: 4px;">BILLED TO</div>
            <div style="font-weight: 800; font-size: 1.05rem;">${escapeHtml(client?.name || 'Customer')}</div>
            <div style="font-size: 0.82rem; color: #475569; line-height: 1.4; margin-top: 4px;">
              ${escapeHtml(client?.billingAddress || '')}<br/>
              ${client?.email ? `Contact: ${escapeHtml(client.email)}` : ''}
            </div>
          </div>
          <div style="text-align: right;">
            <div style="font-size: 0.72rem; font-weight: 800; color: #64748b; text-transform: uppercase; margin-bottom: 4px;">DOCUMENT DETAILS</div>
            <div style="font-size: 0.85rem; line-height: 1.5;">
              <strong>Issue Date:</strong> ${inv.issueDate}<br/>
              <strong>Due Date:</strong> ${inv.dueDate}<br/>
              <strong>Payment Terms:</strong> Net 30
            </div>
          </div>
        </div>

        <!-- Line Items -->
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 28px; font-size: 0.88rem;">
          <thead>
            <tr>
              <th class="pdf-th" style="text-align: left; width: 45%;">Item / Description</th>
              <th class="pdf-th" style="text-align: center; width: 12%;">Qty</th>
              <th class="pdf-th" style="text-align: right; width: 15%;">Unit Price</th>
              <th class="pdf-th" style="text-align: center; width: 12%;">Tax</th>
              <th class="pdf-th" style="text-align: right; width: 16%;">Amount</th>
            </tr>
          </thead>
          <tbody>
            ${inv.items.map(it => `
              <tr style="border-bottom: 1px solid #e2e8f0;">
                <td style="padding: 12px 10px;">
                  <div style="font-weight: 700;">${escapeHtml(it.productName)}</div>
                  ${it.productId ? `<div style="font-size: 0.72rem; color: #64748b; font-family: var(--mono);">${it.productId}</div>` : ''}
                </td>
                <td style="padding: 12px 10px; text-align: center;">${it.quantity}</td>
                <td style="padding: 12px 10px; text-align: right; font-family: var(--mono);">${curr}${it.unitPrice.toFixed(2)}</td>
                <td style="padding: 12px 10px; text-align: center;">${it.taxRate}%</td>
                <td style="padding: 12px 10px; text-align: right; font-family: var(--mono); font-weight: 700;">${curr}${((it.quantity * it.unitPrice) * (1 + it.taxRate / 100)).toFixed(2)}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>

        <!-- Summary & Notes -->
        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 32px;">
          <div style="flex: 1; font-size: 0.85rem; color: #475569; background: #f8fafc; padding: 16px; border-radius: 8px; border: 1px solid #e2e8f0;">
            <strong style="color: #0f172a; display: block; margin-bottom: 4px;">Notes & Remittance:</strong>
            ${escapeHtml(inv.notes || 'No special terms.')}<br/><br/>
            ${company.bankDetails ? `<strong>Banking Info:</strong><br/>${escapeHtml(company.bankDetails)}` : ''}
          </div>

          <div style="width: 260px;">
            <div style="display: flex; justify-content: space-between; padding: 6px 0; font-size: 0.88rem; color: #475569;">
              <span>Subtotal:</span>
              <span style="font-family: var(--mono);">${curr}${inv.subTotal.toFixed(2)}</span>
            </div>
            <div style="display: flex; justify-content: space-between; padding: 6px 0; font-size: 0.88rem; color: #475569;">
              <span>Taxes:</span>
              <span style="font-family: var(--mono);">${curr}${inv.taxTotal.toFixed(2)}</span>
            </div>
            <div style="display: flex; justify-content: space-between; padding: 12px 0; border-top: 2px solid #0f172a; font-size: 1.25rem; font-weight: 900; margin-top: 8px;">
              <span>Total Due:</span>
              <span style="font-family: var(--mono);">${curr}${inv.grandTotal.toFixed(2)}</span>
            </div>
          </div>
        </div>
      </div>

      <div class="pdf-footer" style="margin-top: 48px;">
        ${footerMap[templateName] || footerMap.Classic}
      </div>
    `;
  },

  printActivePdf() {
    window.print();
  },

  // ========================================================================
  // VIEW: CLIENTS (Parity: Table & Card Grid Views, Contact Shortcuts)
  // ========================================================================
  setClientViewMode(mode) {
    this.state.clientViewMode = mode;
    document.getElementById('clients-btn-table')?.classList.toggle('active', mode === 'table');
    document.getElementById('clients-btn-cards')?.classList.toggle('active', mode === 'cards');
    this.renderClients();
  },

  renderClients() {
    const tableContainer = document.getElementById('clients-table-container');
    const cardsContainer = document.getElementById('clients-cards-container');
    if (!tableContainer || !cardsContainer) return;

    const query = (this.state.clientSearchQuery || '').toLowerCase().trim();
    const curr = this.state.company.currency;
    const isCards = this.state.clientViewMode === 'cards';

    tableContainer.style.display = isCards ? 'none' : 'block';
    cardsContainer.style.display = isCards ? 'grid' : 'none';

    const list = this.state.clients.filter(c => {
      if (!query) return true;
      return c.name.toLowerCase().includes(query) ||
        (c.email || '').toLowerCase().includes(query) ||
        (c.phone || '').toLowerCase().includes(query);
    });

    if (isCards) {
      cardsContainer.innerHTML = '';
      if (list.length === 0) {
        cardsContainer.innerHTML = `<div style="grid-column: 1/-1; text-align: center; padding: 32px; color: var(--text-muted);">No clients found.</div>`;
        return;
      }
      list.forEach(c => {
        const clientInvs = this.state.invoices.filter(i => i.clientId === c.id);
        const totalSpend = clientInvs.filter(i => i.status === 'paid').reduce((sum, i) => sum + i.grandTotal, 0);

        const card = document.createElement('div');
        card.className = 'item-card';
        card.innerHTML = `
          <div>
            <div class="item-card-header">
              <div>
                <div class="item-card-title">${escapeHtml(c.name)}</div>
                <div class="item-card-desc">${escapeHtml(c.billingAddress || 'No address configured')}</div>
              </div>
              <span class="badge badge-sent">${clientInvs.length} Invoices</span>
            </div>
            <div style="font-size: 0.82rem; color: var(--text-muted); margin-top: 8px; display: flex; flex-direction: column; gap: 4px;">
              <div>📧 ${escapeHtml(c.email || 'No email')}</div>
              <div>📞 ${escapeHtml(c.phone || 'No phone')}</div>
            </div>
          </div>
          <div class="item-card-footer">
            <div>
              <div style="font-size: 0.72rem; color: var(--text-muted); text-transform: uppercase;">Total Spend</div>
              <div class="mono" style="font-weight: 800; color: var(--success);">${curr}${totalSpend.toFixed(2)}</div>
            </div>
            <div style="display: flex; gap: 4px;">
              ${c.phone ? `<a href="tel:${c.phone}" class="btn btn-outline btn-sm" title="Call">📞</a>` : ''}
              ${c.email ? `<a href="mailto:${c.email}" class="btn btn-outline btn-sm" title="Email">✉️</a>` : ''}
              <button class="btn btn-outline btn-sm rbac-write" onclick="App.openClientModal('${c.id}')">Edit</button>
            </div>
          </div>
        `;
        cardsContainer.appendChild(card);
      });
    } else {
      const tbody = document.getElementById('clients-tbody');
      tbody.innerHTML = '';
      if (list.length === 0) {
        tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 32px;">No clients found.</td></tr>`;
        return;
      }
      list.forEach(c => {
        const clientInvs = this.state.invoices.filter(i => i.clientId === c.id);
        const totalSpend = clientInvs.filter(i => i.status === 'paid').reduce((sum, i) => sum + i.grandTotal, 0);
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>
            <div style="font-weight: 800; font-size: 0.95rem;">${escapeHtml(c.name)}</div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">${escapeHtml(c.billingAddress || '')}</div>
          </td>
          <td>${escapeHtml(c.email || 'N/A')}</td>
          <td>${escapeHtml(c.phone || 'N/A')}</td>
          <td style="text-align: center;"><span class="badge badge-sent">${clientInvs.length}</span></td>
          <td class="mono" style="font-weight: 700;">${curr}${totalSpend.toFixed(2)}</td>
          <td>
            <div style="display: flex; gap: 6px;">
              <button class="btn btn-outline btn-sm rbac-write" onclick="App.openClientModal('${c.id}')">Edit</button>
              <button class="btn btn-outline btn-sm rbac-write" style="color: var(--danger);" onclick="App.deleteClient('${c.id}')">Delete</button>
            </div>
          </td>
        `;
        tbody.appendChild(tr);
      });
    }

    this.updateRBAC();
  },

  openClientModal(clientId = null) {
    if (this.state.currentRole === 'viewer') {
      this.showToast('Viewers cannot modify clients.', 'error');
      return;
    }

    const modal = document.getElementById('modal-client-form');
    document.getElementById('client-form-id').value = clientId || '';

    if (clientId) {
      const c = this.getClient(clientId);
      if (c) {
        document.getElementById('client-modal-title').innerText = 'Edit Client';
        document.getElementById('client-form-name').value = c.name;
        document.getElementById('client-form-email').value = c.email || '';
        document.getElementById('client-form-phone').value = c.phone || '';
        document.getElementById('client-form-billing').value = c.billingAddress || '';
        document.getElementById('client-form-shipping').value = c.shippingAddress || '';
      }
    } else {
      document.getElementById('client-modal-title').innerText = 'Add New Client';
      document.getElementById('client-form-name').value = '';
      document.getElementById('client-form-email').value = '';
      document.getElementById('client-form-phone').value = '';
      document.getElementById('client-form-billing').value = '';
      document.getElementById('client-form-shipping').value = '';
    }

    modal.classList.add('active');
  },

  saveClientForm() {
    const id = document.getElementById('client-form-id').value;
    const name = document.getElementById('client-form-name').value.trim();
    const email = document.getElementById('client-form-email').value.trim();
    const phone = document.getElementById('client-form-phone').value.trim();
    const billing = document.getElementById('client-form-billing').value.trim();
    const shipping = document.getElementById('client-form-shipping').value.trim();

    if (!name) {
      this.showToast('Client name is required.', 'error');
      return;
    }

    if (id) {
      const c = this.getClient(id);
      if (c) {
        c.name = name;
        c.email = email;
        c.phone = phone;
        c.billingAddress = billing;
        c.shippingAddress = shipping;
        this.showToast(`Updated client ${name}.`, 'success');
      }
    } else {
      const newClient = {
        id: 'c-' + Date.now(),
        name,
        email,
        phone,
        billingAddress: billing,
        shippingAddress: shipping
      };
      this.state.clients.push(newClient);
      this.showToast(`Added client ${name}.`, 'success');

      // If wizard is open, auto-select this new client
      const wizSel = document.getElementById('wiz-client');
      if (wizSel) {
        const opt = document.createElement('option');
        opt.value = newClient.id;
        opt.textContent = `${newClient.name} (${newClient.email})`;
        wizSel.appendChild(opt);
        wizSel.value = newClient.id;
      }
    }

    this.saveAll();
    this.closeModal('modal-client-form');
    this.renderClients();
  },

  deleteClient(clientId) {
    if (this.state.currentRole === 'viewer') {
      this.showToast('Viewers cannot delete clients.', 'error');
      return;
    }

    const c = this.getClient(clientId);
    if (!c) return;

    const hasInvoices = this.state.invoices.some(i => i.clientId === clientId);
    if (hasInvoices) {
      if (!confirm(`Client "${c.name}" has associated invoices. Deleting will unlink those records. Proceed?`)) return;
    } else {
      if (!confirm(`Delete client "${c.name}"?`)) return;
    }

    this.state.clients = this.state.clients.filter(item => item.id !== clientId);
    this.saveAll();
    this.renderClients();
    this.showToast(`Deleted client ${c.name}.`, 'info');
  },

  // ========================================================================
  // VIEW: INVENTORY / CATALOG (Parity: Category Tabs, Grid/Table, SKU Generator)
  // ========================================================================
  setProductViewMode(mode) {
    this.state.productViewMode = mode;
    document.getElementById('inventory-btn-table')?.classList.toggle('active', mode === 'table');
    document.getElementById('inventory-btn-cards')?.classList.toggle('active', mode === 'cards');
    this.renderInventory();
  },

  setProductCategoryFilter(category, btn) {
    this.state.productCategoryFilter = category;
    document.querySelectorAll('.prod-cat-tab').forEach(t => t.classList.remove('active'));
    if (btn) btn.classList.add('active');
    this.renderInventory();
  },

  // SKU Generation Engine (Rule 4.2 from LOGIC_EXPLANATION.md)
  generateProductSku(name, category, excludeId = null) {
    if (!name || !name.trim()) return '';

    const clean = (val) => val.toUpperCase().replace(/[^A-Z0-9 ]/g, ' ').trim();
    const words = clean(name).split(/\s+/).filter(Boolean);

    // Category Code (3 chars)
    let catCode = clean(category).slice(0, 3);
    if (catCode.length < 3) catCode = catCode.padEnd(3, 'X');

    // Product Code (8 chars)
    let prodCode = '';
    if (words.length > 1) {
      prodCode = words.slice(0, 3).map(w => w.slice(0, 3)).join('').slice(0, 8);
    } else if (words.length === 1) {
      prodCode = words[0].slice(0, 8);
    }
    if (prodCode.length < 8) prodCode = prodCode.padEnd(8, 'X');

    // Sequence (001-999) check
    let seq = 1;
    let candidate = '';
    const existingSkus = new Set(
      this.state.products
        .filter(p => p.id !== excludeId)
        .map(p => (p.sku || '').toUpperCase())
    );

    do {
      candidate = `${catCode}-${prodCode}-${String(seq).padStart(3, '0')}`;
      seq++;
    } while (existingSkus.has(candidate) && seq < 1000);

    return candidate;
  },

  renderInventory() {
    const tableContainer = document.getElementById('inventory-table-container');
    const cardsContainer = document.getElementById('inventory-cards-container');
    if (!tableContainer || !cardsContainer) return;

    const query = (this.state.productSearchQuery || '').toLowerCase().trim();
    const catFilter = this.state.productCategoryFilter;
    const curr = this.state.company.currency;
    const isCards = this.state.productViewMode === 'cards';

    tableContainer.style.display = isCards ? 'none' : 'block';
    cardsContainer.style.display = isCards ? 'grid' : 'none';

    // Render Category Tabs
    const tabsContainer = document.getElementById('inventory-category-tabs');
    if (tabsContainer) {
      const allCategories = ['All', 'Solar', 'IT', 'Hardware', 'Services', 'Software', 'General',
        ...new Set(this.state.products.map(p => p.category).filter(Boolean))
      ];
      const uniqueCats = [...new Set(allCategories)];
      tabsContainer.innerHTML = uniqueCats.map(cat => `
        <button class="filter-tab prod-cat-tab ${cat === catFilter ? 'active' : ''}" onclick="App.setProductCategoryFilter('${cat}', this)">${cat}</button>
      `).join('');
    }

    const list = this.state.products.filter(p => {
      const matchesCat = catFilter === 'All' || (p.category || '').toLowerCase() === catFilter.toLowerCase();
      if (!matchesCat) return false;
      if (!query) return true;
      return p.name.toLowerCase().includes(query) ||
        (p.sku || '').toLowerCase().includes(query) ||
        (p.description || '').toLowerCase().includes(query);
    });

    if (isCards) {
      cardsContainer.innerHTML = '';
      if (list.length === 0) {
        cardsContainer.innerHTML = `<div style="grid-column: 1/-1; text-align: center; padding: 32px; color: var(--text-muted);">No products found.</div>`;
        return;
      }
      list.forEach(p => {
        const isLowStock = typeof p.stock === 'number' && p.stock < 5;
        const card = document.createElement('div');
        card.className = 'item-card';
        card.innerHTML = `
          <div>
            <div class="item-card-header">
              <span class="mono" style="font-weight: 800; font-size: 0.8rem; background: var(--primary-light); color: var(--primary); padding: 3px 8px; border-radius: 4px;">${escapeHtml(p.sku || 'NO-SKU')}</span>
              <span class="badge badge-quote">${escapeHtml(p.category || 'General')}</span>
            </div>
            <div class="item-card-title">${escapeHtml(p.name)}</div>
            <div class="item-card-desc">${escapeHtml(p.description || 'No description provided')}</div>
          </div>
          <div class="item-card-footer">
            <div>
              <div class="mono" style="font-size: 1.25rem; font-weight: 800; color: var(--primary);">${curr}${p.unitPrice.toFixed(2)}</div>
              <div style="font-size: 0.72rem; color: var(--text-muted);">Tax: ${p.taxRate}% • Stock: <strong style="${isLowStock ? 'color: var(--danger);' : ''}">${p.stock !== undefined ? p.stock : 'N/A'}</strong></div>
            </div>
            <div style="display: flex; gap: 4px;">
              <button class="btn btn-outline btn-sm rbac-write" onclick="App.openProductModal('${p.id}')">Edit</button>
              <button class="btn btn-outline btn-sm rbac-write" style="color: var(--danger);" onclick="App.deleteProduct('${p.id}')">✕</button>
            </div>
          </div>
        `;
        cardsContainer.appendChild(card);
      });
    } else {
      const tbody = document.getElementById('inventory-tbody');
      tbody.innerHTML = '';
      if (list.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 32px;">No products in catalog.</td></tr>`;
        return;
      }
      list.forEach(p => {
        const isLowStock = typeof p.stock === 'number' && p.stock < 5;
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>
            <div style="font-weight: 800; font-size: 0.92rem;">${escapeHtml(p.name)}</div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">${escapeHtml(p.description || '')}</div>
          </td>
          <td class="mono" style="font-weight: 700;">${escapeHtml(p.sku || 'N/A')}</td>
          <td><span class="badge badge-quote">${escapeHtml(p.category || 'General')}</span></td>
          <td class="mono" style="font-weight: 700;">${curr}${p.unitPrice.toFixed(2)}</td>
          <td>${p.taxRate}%</td>
          <td>
            <span style="font-weight: 700; font-family: var(--mono); ${isLowStock ? 'color: var(--danger);' : ''}">${p.stock !== undefined ? p.stock : 'N/A'}</span>
            ${isLowStock ? '<span class="badge badge-overdue" style="font-size: 0.65rem; margin-left: 4px;">LOW</span>' : ''}
          </td>
          <td>
            <div style="display: flex; gap: 6px;">
              <button class="btn btn-outline btn-sm rbac-write" onclick="App.openProductModal('${p.id}')">Edit</button>
              <button class="btn btn-outline btn-sm rbac-write" style="color: var(--danger);" onclick="App.deleteProduct('${p.id}')">Delete</button>
            </div>
          </td>
        `;
        tbody.appendChild(tr);
      });
    }

    this.updateRBAC();
  },

  openProductModal(productId = null) {
    if (this.state.currentRole === 'viewer') {
      this.showToast('Viewers cannot modify catalog.', 'error');
      return;
    }

    const modal = document.getElementById('modal-product-form');
    document.getElementById('prod-form-id').value = productId || '';

    if (productId) {
      const p = this.state.products.find(item => item.id === productId);
      if (p) {
        document.getElementById('prod-modal-title').innerText = 'Edit Catalog Product';
        document.getElementById('prod-form-name').value = p.name;
        document.getElementById('prod-form-sku').value = p.sku || '';
        document.getElementById('prod-form-category').value = p.category || 'Solar';
        document.getElementById('prod-form-price').value = p.unitPrice;
        document.getElementById('prod-form-tax').value = p.taxRate;
        document.getElementById('prod-form-stock').value = p.stock !== undefined ? p.stock : 10;
        document.getElementById('prod-form-desc').value = p.description || '';
      }
    } else {
      document.getElementById('prod-modal-title').innerText = 'Add New Product';
      document.getElementById('prod-form-name').value = '';
      document.getElementById('prod-form-sku').value = '';
      document.getElementById('prod-form-category').value = 'Solar';
      document.getElementById('prod-form-price').value = '100.00';
      document.getElementById('prod-form-tax').value = '10.0';
      document.getElementById('prod-form-stock').value = '25';
      document.getElementById('prod-form-desc').value = '';
    }

    modal.classList.add('active');
  },

  onProductNameOrCategoryChange() {
    const id = document.getElementById('prod-form-id').value;
    const name = document.getElementById('prod-form-name').value;
    const cat = document.getElementById('prod-form-category').value;
    const skuInput = document.getElementById('prod-form-sku');

    // Generate candidate SKU automatically if user has not manually overridden or when adding new
    if (name.trim()) {
      skuInput.value = this.generateProductSku(name, cat, id);
    }
  },

  saveProductForm() {
    const id = document.getElementById('prod-form-id').value;
    const name = document.getElementById('prod-form-name').value.trim();
    const sku = document.getElementById('prod-form-sku').value.trim().toUpperCase();
    const category = document.getElementById('prod-form-category').value.trim();
    const price = parseFloat(document.getElementById('prod-form-price').value) || 0;
    const tax = parseFloat(document.getElementById('prod-form-tax').value) || 0;
    const stock = parseInt(document.getElementById('prod-form-stock').value, 10) || 0;
    const desc = document.getElementById('prod-form-desc').value.trim();

    if (!name) {
      this.showToast('Product title is required.', 'error');
      return;
    }

    const finalSku = sku || this.generateProductSku(name, category, id);

    if (id) {
      const p = this.state.products.find(item => item.id === id);
      if (p) {
        p.name = name;
        p.sku = finalSku;
        p.category = category;
        p.unitPrice = price;
        p.taxRate = tax;
        p.stock = stock;
        p.description = desc;
        this.showToast(`Updated product ${name}.`, 'success');
      }
    } else {
      const newProd = {
        id: 'p-' + Date.now(),
        name,
        sku: finalSku,
        category: category || 'General',
        unitPrice: price,
        taxRate: tax,
        stock,
        description: desc
      };
      this.state.products.push(newProd);
      this.showToast(`Added product ${name} (${finalSku}).`, 'success');
    }

    this.saveAll();
    this.closeModal('modal-product-form');
    this.renderInventory();
  },

  deleteProduct(productId) {
    if (this.state.currentRole === 'viewer') {
      this.showToast('Viewers cannot delete catalog items.', 'error');
      return;
    }

    const p = this.state.products.find(item => item.id === productId);
    if (!p) return;

    if (confirm(`Remove "${p.name}" from catalog?`)) {
      this.state.products = this.state.products.filter(item => item.id !== productId);
      this.saveAll();
      this.renderInventory();
      this.showToast(`Removed product ${p.name}.`, 'info');
    }
  },

  // ========================================================================
  // VIEW: SETTINGS (Parity: Logo Upload, Number Format Preview, Snapshots)
  // ========================================================================
  renderSettings() {
    const comp = this.state.company;
    const settings = this.state.settings;

    document.getElementById('settings-company-name').value = comp.name || '';
    document.getElementById('settings-company-tax').value = comp.taxId || '';
    document.getElementById('settings-company-currency').value = comp.currency || '$';
    document.getElementById('settings-company-email').value = comp.email || '';
    document.getElementById('settings-company-phone').value = comp.phone || '';
    document.getElementById('settings-company-address').value = comp.address || '';
    document.getElementById('settings-company-bank').value = comp.bankDetails || '';

    // Logo preview
    const logoImg = document.getElementById('settings-logo-preview');
    if (logoImg) {
      if (comp.logo) {
        logoImg.src = comp.logo;
        logoImg.style.display = 'block';
      } else {
        logoImg.style.display = 'none';
      }
    }

    document.getElementById('settings-invoice-format').value = settings.invoiceNumberFormat || 'INV-{YYYY}-{NNNN}';
    this.updateNumberFormatPreview();

    document.getElementById('settings-default-template').value = settings.pdfTemplate || 'Classic';
    document.getElementById('settings-api-url').value = this.session.apiUrl || 'http://localhost:3000';
    document.getElementById('settings-auto-sync').checked = settings.autoSync !== false;

    // Render snapshot ledger
    this.renderSnapshotLedger();
  },

  updateNumberFormatPreview() {
    const format = document.getElementById('settings-invoice-format')?.value || 'INV-{YYYY}-{NNNN}';
    const previewEl = document.getElementById('settings-format-preview');
    if (!previewEl) return;

    const year = new Date().getFullYear();
    const count = this.state.invoices.length + 1;
    const evaluated = format
      .replace('{YYYY}', year)
      .replace('{YY}', String(year).slice(-2))
      .replace('{MM}', String(new Date().getMonth() + 1).padStart(2, '0'))
      .replace('{NNNN}', String(count).padStart(4, '0'))
      .replace('{NNN}', String(count).padStart(3, '0'))
      .replace('{NN}', String(count).padStart(2, '0'));

    previewEl.innerText = `Evaluates to: ${evaluated}`;
  },

  handleLogoUpload(fileInput) {
    const file = fileInput.files[0];
    if (!file) return;

    if (file.size > 5 * 1024 * 1024) {
      this.showToast('Logo must be smaller than 5 MB.', 'error');
      return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
      this.state.company.logo = e.target.result;
      const preview = document.getElementById('settings-logo-preview');
      if (preview) {
        preview.src = e.target.result;
        preview.style.display = 'block';
      }
      this.saveAll();
      this.renderHeaderInfo();
      this.showToast('Logo updated! Reflected on all 5 PDF templates.', 'success');
    };
    reader.readAsDataURL(file);
    fileInput.value = '';
  },

  saveSettings() {
    if (this.state.currentRole !== 'admin') {
      this.showToast('Only Admin users can save company settings.', 'error');
      return;
    }

    this.state.company.name = document.getElementById('settings-company-name').value.trim() || 'My Company';
    this.state.company.taxId = document.getElementById('settings-company-tax').value.trim();
    this.state.company.currency = document.getElementById('settings-company-currency').value.trim() || '$';
    this.state.company.email = document.getElementById('settings-company-email').value.trim();
    this.state.company.phone = document.getElementById('settings-company-phone').value.trim();
    this.state.company.address = document.getElementById('settings-company-address').value.trim();
    this.state.company.bankDetails = document.getElementById('settings-company-bank').value.trim();

    this.state.settings.invoiceNumberFormat = document.getElementById('settings-invoice-format').value.trim() || 'INV-{YYYY}-{NNNN}';
    this.state.settings.pdfTemplate = document.getElementById('settings-default-template').value;
    this.state.settings.apiUrl = document.getElementById('settings-api-url').value.trim();
    this.state.settings.autoSync = document.getElementById('settings-auto-sync').checked;
    this.session.apiUrl = this.state.settings.apiUrl;

    this.saveAll();
    this.renderHeaderInfo();
    this.showToast('System preferences saved successfully!', 'success');
  },

  // Snapshot ledger (Rule 4.6 backup history)
  createBackupSnapshot() {
    const snapshot = {
      id: 'snap-' + Date.now(),
      timestamp: new Date().toLocaleString(),
      invoicesCount: this.state.invoices.length,
      clientsCount: this.state.clients.length,
      productsCount: this.state.products.length,
      data: {
        company: this.state.company,
        clients: this.state.clients,
        products: this.state.products,
        invoices: this.state.invoices,
        settings: this.state.settings
      }
    };

    this.state.snapshots.unshift(snapshot);
    if (this.state.snapshots.length > 10) this.state.snapshots.pop();

    this.saveAll(false);
    this.renderSnapshotLedger();
    this.showToast('Created historical workspace snapshot.', 'success');
  },

  restoreSnapshot(snapId) {
    const snap = this.state.snapshots.find(s => s.id === snapId);
    if (!snap) return;

    if (confirm(`Restore workspace from snapshot "${snap.timestamp}"? Current unsaved changes will be overwritten.`)) {
      const d = snap.data;
      if (d.company) this.state.company = d.company;
      if (d.clients) this.state.clients = d.clients;
      if (d.products) this.state.products = d.products;
      if (d.invoices) this.state.invoices = d.invoices;
      if (d.settings) this.state.settings = d.settings;

      this.saveAll();
      this.renderHeaderInfo();
      this.renderCurrentView();
      this.showToast(`Restored snapshot from ${snap.timestamp}.`, 'success');
    }
  },

  renderSnapshotLedger() {
    const list = document.getElementById('settings-snapshot-list');
    if (!list) return;

    if (this.state.snapshots.length === 0) {
      list.innerHTML = `<div style="text-align: center; color: var(--text-muted); padding: 16px; font-size: 0.85rem;">No snapshots recorded yet. Click "Create Snapshot Now" to create one.</div>`;
      return;
    }

    list.innerHTML = this.state.snapshots.map(s => `
      <div class="snapshot-item">
        <div class="snapshot-info">
          <strong>${s.timestamp}</strong>
          <span style="color: var(--text-muted); font-size: 0.78rem;">${s.invoicesCount} Invoices • ${s.clientsCount} Clients • ${s.productsCount} Products</span>
        </div>
        <button class="btn btn-outline btn-sm rbac-write" onclick="App.restoreSnapshot('${s.id}')">Restore</button>
      </div>
    `).join('');
  },

  exportWorkspaceJSON() {
    const exportData = {
      version: '1.0.0',
      exportedAt: new Date().toISOString(),
      company: this.state.company,
      clients: this.state.clients,
      products: this.state.products,
      invoices: this.state.invoices,
      users: this.state.users,
      settings: this.state.settings
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `Invoicey_${this.session.accountId}_${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
    this.showToast('Exported full workspace to JSON.', 'success');
  },

  importWorkspaceJSON(fileInput) {
    if (this.state.currentRole !== 'admin') {
      this.showToast('Only Admins can import workspace data.', 'error');
      return;
    }

    const file = fileInput.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = JSON.parse(e.target.result);
        if (!data.company || !data.clients || !data.invoices) {
          throw new Error('Invalid Invoicey backup schema.');
        }

        this.state.company = data.company;
        this.state.clients = data.clients || [];
        this.state.products = data.products || [];
        this.state.invoices = data.invoices || [];
        if (data.settings) this.state.settings = { ...this.state.settings, ...data.settings };

        this.saveAll();
        this.renderHeaderInfo();
        this.renderCurrentView();
        this.showToast('Workspace successfully restored from file!', 'success');
      } catch (err) {
        alert('Failed to import JSON: ' + err.message);
      }
    };
    reader.readAsText(file);
    fileInput.value = '';
  },

  // ========================================================================
  // Utilities & Event Listeners
  // ========================================================================
  getClient(clientId) {
    return this.state.clients.find(c => c.id === clientId) || null;
  },

  closeModal(modalId) {
    const m = document.getElementById(modalId);
    if (m) m.classList.remove('active');
  },

  openAccountModal() {
    document.getElementById('modal-account-sync').classList.add('active');
  },

  showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `<span>${escapeHtml(message)}</span>`;
    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      setTimeout(() => toast.remove(), 200);
    }, 3500);
  },

  initEventListeners() {
    document.getElementById('mobile-sidebar-toggle')?.addEventListener('click', () => {
      document.querySelector('aside.app-sidebar')?.classList.toggle('open');
    });

    document.querySelectorAll('.modal-overlay').forEach(overlay => {
      overlay.addEventListener('click', (e) => {
        if (e.target === overlay) overlay.classList.remove('active');
      });
    });

    window.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        document.querySelectorAll('.modal-overlay.active').forEach(m => m.classList.remove('active'));
      }
    });
  }
};

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

document.addEventListener('DOMContentLoaded', () => {
  App.init();
});
