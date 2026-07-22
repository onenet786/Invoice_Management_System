import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/user_model.dart';
import 'dashboard/dashboard_screen.dart';
import 'invoices/invoice_list_screen.dart';
import 'clients/client_list_screen.dart';
import 'inventory/product_list_screen.dart';
import 'settings/settings_screen.dart';

class ShellNavigation extends StatefulWidget {
  const ShellNavigation({super.key});

  @override
  State<ShellNavigation> createState() => _ShellNavigationState();
}

class _ShellNavigationState extends State<ShellNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const InvoiceListScreen(),
    const ClientListScreen(),
    const ProductListScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final user = state.currentUser;
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    // Redirect to login if user is null (fallback check)
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Colors.indigo, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'INVOICEY',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // User role indicator badge
          _buildRoleBadge(user.role),
          const SizedBox(width: 12),
          // Theme Switcher
          IconButton(
            icon: Icon(
              state.themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: state.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              state.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, state),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _screens[_currentIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.indigo,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description_outlined),
                  activeIcon: Icon(Icons.description),
                  label: 'Invoices',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Clients',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'Inventory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color badgeColor;
    String label;
    switch (role) {
      case UserRole.admin:
        badgeColor = Colors.red.shade600;
        label = 'ADMIN';
        break;
      case UserRole.manager:
        badgeColor = Colors.amber.shade700;
        label = 'MANAGER';
        break;
      case UserRole.viewer:
        badgeColor = Colors.grey.shade600;
        label = 'VIEWER';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AppStateProvider state) {
    final theme = Theme.of(context);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        color: theme.cardColor,
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // User Details Panel
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              child: Text(
                state.currentUser?.name[0].toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            title: Text(
              state.currentUser?.name ?? 'Guest User',
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              state.currentUser?.email ?? '',
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          _sidebarItem(
            0,
            Icons.dashboard_outlined,
            Icons.dashboard,
            'Dashboard',
          ),
          _sidebarItem(
            1,
            Icons.description_outlined,
            Icons.description,
            'Invoices',
          ),
          _sidebarItem(2, Icons.people_outline, Icons.people, 'Clients'),
          _sidebarItem(
            3,
            Icons.inventory_2_outlined,
            Icons.inventory_2,
            'Inventory',
          ),
          _sidebarItem(4, Icons.settings_outlined, Icons.settings, 'Settings'),
          const Spacer(),
          // Powered by branding
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Invoicey Management v1.0',
              style: TextStyle(
                fontSize: 11,
                color: theme.hintColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String title,
  ) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.indigo.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected
                    ? Colors.indigo
                    : theme.iconTheme.color?.withValues(alpha: 0.7),
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.indigo
                      : theme.textTheme.bodyLarge?.color?.withValues(
                          alpha: 0.8,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
