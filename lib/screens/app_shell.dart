import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'home/home_screen.dart';
import 'groups/groups_screen.dart';
import 'individuals/individuals_screen.dart';
import 'quick_sale/quick_sale_screen.dart';
import 'settings/settings_screen.dart';
import 'bulk_orders/bulk_orders_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    GroupsScreen(),
    IndividualsScreen(),
    QuickSaleScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delivery_dining, size: 28),
            tooltip: l10n.labelBulkOrders,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BulkOrdersScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_rounded, size: 28), label: l10n.navHome),
          BottomNavigationBarItem(icon: const Icon(Icons.business, size: 28), label: l10n.navGroups),
          BottomNavigationBarItem(icon: const Icon(Icons.person, size: 28), label: l10n.navPersons),
          BottomNavigationBarItem(icon: const Icon(Icons.flash_on, size: 28), label: l10n.navQuick),
          BottomNavigationBarItem(icon: const Icon(Icons.settings, size: 28), label: l10n.navSettings),
        ],
      ),
    );
  }
}
