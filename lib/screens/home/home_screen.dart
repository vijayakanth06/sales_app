import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../calculate/calculate_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final todayTx = ref.watch(todayTransactionsProvider);
    final today = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayTransactionsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Text(today, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),

            // Summary cards
            todayTx.when(
              data: (transactions) {
                double revenue = 0, collected = 0;
                int quickCount = 0;
                for (var tx in transactions) {
                  revenue += tx.totalAmount;
                  collected += tx.amountPaid;
                  if (tx.type == 'quick') quickCount++;
                }
                final balance = revenue - collected;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _SummaryCard(
                          title: l10n.labelTodayRevenue,
                          value: '₹${revenue.toStringAsFixed(0)}',
                          color: const Color(0xFF1565C0),
                          icon: Icons.trending_up,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _SummaryCard(
                          title: l10n.labelTodayCollected,
                          value: '₹${collected.toStringAsFixed(0)}',
                          color: const Color(0xFF2E7D32),
                          icon: Icons.account_balance_wallet,
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _SummaryCard(
                          title: l10n.labelTodayBalance,
                          value: '₹${balance.toStringAsFixed(0)}',
                          color: balance > 0 ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                          icon: Icons.account_balance,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _SummaryCard(
                          title: l10n.labelQuickSales,
                          value: '$quickCount',
                          color: const Color(0xFF6A1B9A),
                          icon: Icons.flash_on,
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Calculate button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CalculateScreen())),
                        icon: const Icon(Icons.calculate, size: 24),
                        label: Text(l10n.btnCalculate, style: const TextStyle(fontSize: 18)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Today's transactions
                    Text(l10n.labelTransactions,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),

                    if (transactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(l10n.labelNoData, style: TextStyle(color: Colors.grey[500], fontSize: 18)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...transactions.map((tx) => _TransactionCard(tx: tx)),
                  ],
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(64),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final SaleTransaction tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (tx.paymentStatus) {
      case 'paid':
        statusColor = const Color(0xFF2E7D32);
        statusText = 'Paid';
        break;
      case 'partial':
        statusColor = const Color(0xFFE65100);
        statusText = 'Partial';
        break;
      default:
        statusColor = const Color(0xFFC62828);
        statusText = 'Unpaid';
    }

    String customerName = tx.personName ?? 'Quick Sale';
    if (tx.type == 'quick') customerName = '⚡ Quick Sale';
    if (tx.type == 'bulk') customerName = '📦 Bulk Order';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${tx.groupName != null ? "${tx.groupName} • " : ""}${DateFormat('hh:mm a').format(tx.datetime)}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${tx.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusText,
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
