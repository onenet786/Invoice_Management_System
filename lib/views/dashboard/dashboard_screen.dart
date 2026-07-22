import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../models/invoice_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedClientId;
  InvoiceStatus? _selectedStatus;
  int _selectedYear = 2026;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    final currency = state.company.currency;
    final formatter = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    // Apply quick filters to compute custom visual metrics if filtered
    List<InvoiceModel> filteredInvoices = state.invoices;
    if (_selectedClientId != null) {
      filteredInvoices = filteredInvoices
          .where((inv) => inv.clientId == _selectedClientId)
          .toList();
    }
    if (_selectedStatus != null) {
      filteredInvoices = filteredInvoices
          .where((inv) => inv.status == _selectedStatus)
          .toList();
    }

    double localRevenue = filteredInvoices
        .where((inv) => inv.status == InvoiceStatus.paid)
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);

    double localPending = filteredInvoices
        .where(
          (inv) =>
              inv.status == InvoiceStatus.sent ||
              inv.status == InvoiceStatus.partiallyPaid,
        )
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);

    double localOverdue = filteredInvoices
        .where((inv) => inv.status == InvoiceStatus.overdue)
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);

    int localTotalCount = filteredInvoices.length;

    // Monthly data calculations
    Map<int, double> monthlySales = {for (var i = 1; i <= 12; i++) i: 0.0};
    for (var inv in filteredInvoices) {
      if (inv.issueDate.year == _selectedYear &&
          inv.status != InvoiceStatus.draft) {
        final m = inv.issueDate.month;
        monthlySales[m] = (monthlySales[m] ?? 0.0) + inv.grandTotal;
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard header
              LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Analytics',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Overview of your company\'s cash flow, sales trends, and balances.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  );
                  if (constraints.maxWidth < 650) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        heading,
                        const SizedBox(height: 16),
                        _buildFilterResetButton(),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: 20),
                      _buildFilterResetButton(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Filter Controls Card
              _buildFilterCard(state, theme),
              const SizedBox(height: 24),

              // Stats Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 1100
                      ? 4
                      : (constraints.maxWidth > 600 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.2,
                    children: [
                      _buildStatCard(
                        title: 'Total Revenue (Paid)',
                        value: formatter.format(localRevenue),
                        icon: Icons.attach_money_rounded,
                        color: Colors.green,
                        theme: theme,
                      ),
                      _buildStatCard(
                        title: 'Pending Payments',
                        value: formatter.format(localPending),
                        icon: Icons.hourglass_empty_rounded,
                        color: Colors.amber.shade700,
                        theme: theme,
                      ),
                      _buildStatCard(
                        title: 'Overdue Balance',
                        value: formatter.format(localOverdue),
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red.shade600,
                        theme: theme,
                      ),
                      _buildStatCard(
                        title: 'Invoice Volume',
                        value: '$localTotalCount Invoices',
                        icon: Icons.receipt_long_rounded,
                        color: Colors.indigo,
                        theme: theme,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Charts Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 950) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildSalesLineChartCard(monthlySales, theme),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: _buildStatusPieChartCard(
                            filteredInvoices,
                            theme,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildSalesLineChartCard(monthlySales, theme),
                        const SizedBox(height: 24),
                        _buildStatusPieChartCard(filteredInvoices, theme),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterResetButton() {
    if (_selectedClientId == null &&
        _selectedStatus == null &&
        _selectedYear == 2026) {
      return const SizedBox.shrink();
    }
    return TextButton.icon(
      icon: const Icon(Icons.clear_all),
      label: const Text('Reset Filters'),
      onPressed: () {
        setState(() {
          _selectedClientId = null;
          _selectedStatus = null;
          _selectedYear = 2026;
        });
      },
    );
  }

  Widget _buildFilterCard(AppStateProvider state, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_list, size: 20, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Quick Filters:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // Client Dropdown
            DropdownButton<String>(
              value: _selectedClientId,
              isExpanded: true,
              hint: const Text('All Clients'),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Clients'),
                ),
                ...state.clients.map(
                  (c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedClientId = val;
                });
              },
            ),
            // Status Dropdown
            DropdownButton<InvoiceStatus>(
              value: _selectedStatus,
              isExpanded: true,
              hint: const Text('All Statuses'),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem<InvoiceStatus>(
                  value: null,
                  child: Text('All Statuses'),
                ),
                DropdownMenuItem<InvoiceStatus>(
                  value: InvoiceStatus.paid,
                  child: Text('Paid'),
                ),
                DropdownMenuItem<InvoiceStatus>(
                  value: InvoiceStatus.sent,
                  child: Text('Sent'),
                ),
                DropdownMenuItem<InvoiceStatus>(
                  value: InvoiceStatus.overdue,
                  child: Text('Overdue'),
                ),
                DropdownMenuItem<InvoiceStatus>(
                  value: InvoiceStatus.partiallyPaid,
                  child: Text('Partially Paid'),
                ),
                DropdownMenuItem<InvoiceStatus>(
                  value: InvoiceStatus.draft,
                  child: Text('Draft'),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedStatus = val;
                });
              },
            ),
            // Year Dropdown
            DropdownButton<int>(
              value: _selectedYear,
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem<int>(value: 2025, child: Text('Year 2025')),
                DropdownMenuItem<int>(value: 2026, child: Text('Year 2026')),
                DropdownMenuItem<int>(value: 2027, child: Text('Year 2027')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedYear = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesLineChartCard(
    Map<int, double> monthlySales,
    ThemeData theme,
  ) {
    List<FlSpot> spots = [];
    for (int m = 1; m <= 12; m++) {
      spots.add(FlSpot(m.toDouble(), monthlySales[m] ?? 0.0));
    }

    // Determine max value for nice formatting
    double maxVal = monthlySales.values.fold(1000.0, (m, v) => v > m ? v : m);
    // Add 15% margin
    maxVal = maxVal * 1.15;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Sales Trend - $_selectedYear',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.show_chart, color: theme.hintColor),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec',
                          ];
                          int idx = value.toInt() - 1;
                          if (idx >= 0 && idx < 12) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                months[idx],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.hintColor,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          if (value >= 1000) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '\$${(value / 1000).toStringAsFixed(1)}k',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: theme.hintColor,
                                ),
                              ),
                            );
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '\$${value.toInt()}',
                              style: TextStyle(
                                fontSize: 9,
                                color: theme.hintColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 1,
                  maxX: 12,
                  minY: 0,
                  maxY: maxVal,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.indigo,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.indigo.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPieChartCard(
    List<InvoiceModel> filteredInvoices,
    ThemeData theme,
  ) {
    int paid = 0;
    int pending = 0;
    int overdue = 0;
    int draft = 0;

    for (var inv in filteredInvoices) {
      switch (inv.status) {
        case InvoiceStatus.paid:
          paid++;
          break;
        case InvoiceStatus.sent:
        case InvoiceStatus.partiallyPaid:
          pending++;
          break;
        case InvoiceStatus.overdue:
          overdue++;
          break;
        case InvoiceStatus.draft:
          draft++;
          break;
      }
    }

    final total = paid + pending + overdue + draft;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (total == 0)
              const SizedBox(
                height: 200,
                child: Center(
                  child: Text('No invoice matches current filters.'),
                ),
              )
            else ...[
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: [
                      if (paid > 0)
                        PieChartSectionData(
                          color: Colors.green,
                          value: paid.toDouble(),
                          title:
                              '${((paid / total) * 100).toStringAsFixed(0)}%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (pending > 0)
                        PieChartSectionData(
                          color: Colors.amber.shade700,
                          value: pending.toDouble(),
                          title:
                              '${((pending / total) * 100).toStringAsFixed(0)}%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (overdue > 0)
                        PieChartSectionData(
                          color: Colors.red.shade600,
                          value: overdue.toDouble(),
                          title:
                              '${((overdue / total) * 100).toStringAsFixed(0)}%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (draft > 0)
                        PieChartSectionData(
                          color: Colors.grey.shade600,
                          value: draft.toDouble(),
                          title:
                              '${((draft / total) * 100).toStringAsFixed(0)}%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem('Paid ($paid)', Colors.green),
                  _buildLegendItem('Pending ($pending)', Colors.amber.shade700),
                  _buildLegendItem('Overdue ($overdue)', Colors.red.shade600),
                  _buildLegendItem('Draft ($draft)', Colors.grey.shade600),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
