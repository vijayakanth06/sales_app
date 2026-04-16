import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class QuickSaleScreen extends ConsumerStatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  ConsumerState<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends ConsumerState<QuickSaleScreen> {
  final Map<String, int> _selectedProducts = {};
  String _paymentMethod = 'cash';
  final _otherMethodController = TextEditingController();
  bool _saving = false;
  int _todayCount = 0;
  double _todayRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayStats();
  }

  void _loadTodayStats() {
    ref.read(todayTransactionsProvider.future).then((txs) {
      if (mounted) {
        setState(() {
          final quickTxs = txs.where((t) => t.type == 'quick');
          _todayCount = quickTxs.length;
          _todayRevenue = quickTxs.fold(0.0, (sum, t) => sum + t.totalAmount);
        });
      }
    });
  }

  @override
  void dispose() {
    _otherMethodController.dispose();
    super.dispose();
  }

  double _calculateTotal(List<Product> products) {
    double total = 0;
    _selectedProducts.forEach((id, qty) {
      final product = products.firstWhere((p) => p.id == id);
      total += product.sellingPrice * qty;
    });
    return total;
  }

  Future<void> _save(List<Product> products) async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.msgNoProducts)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final total = _calculateTotal(products);
      String method = _paymentMethod;
      if (_paymentMethod == 'other') {
        method = _otherMethodController.text.trim().isEmpty ? 'other' : _otherMethodController.text.trim();
      }

      final tx = SaleTransaction(
        id: '',
        type: 'quick',
        personId: null,
        groupId: null,
        totalAmount: total,
        amountPaid: total,
        balance: 0,
        paymentMethod: method,
        paymentStatus: 'paid',
      );

      final items = _selectedProducts.entries.map((entry) {
        final product = products.firstWhere((p) => p.id == entry.key);
        return TransactionItem(
          id: '',
          transactionId: '',
          productId: product.id,
          quantity: entry.value,
          sellingPriceAtSale: product.sellingPrice,
          costPriceAtSale: product.costPrice,
        );
      }).toList();

      await SupabaseService().saveTransaction(tx, items);

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.msgSaveSuccess),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        // Reset form
        setState(() {
          _selectedProducts.clear();
          _paymentMethod = 'cash';
          _otherMethodController.clear();
          _todayCount++;
          _todayRevenue += total;
        });
        ref.invalidate(todayTransactionsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) => Column(
        children: [
          // Today's quick sale stats
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF6A1B9A).withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.flash_on, color: Color(0xFF6A1B9A), size: 28),
                const SizedBox(width: 12),
                Text('$_todayCount ${l10n.labelQuickSales}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('₹${_todayRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
              ],
            ),
          ),

          // Product grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final qty = _selectedProducts[product.id] ?? 0;
                final isSelected = qty > 0;

                return Card(
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2.5)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      _selectedProducts[product.id] = qty + 1;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(product.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text('₹${product.sellingPrice.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
                          if (isSelected) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _QtyButton(icon: Icons.remove, onTap: () {
                                  setState(() {
                                    if (qty <= 1) {
                                      _selectedProducts.remove(product.id);
                                    } else {
                                      _selectedProducts[product.id] = qty - 1;
                                    }
                                  });
                                }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('$qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                                _QtyButton(icon: Icons.add, onTap: () {
                                  setState(() => _selectedProducts[product.id] = qty + 1);
                                }),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.labelTotalAmount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('₹${_calculateTotal(products).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ],
                ),
                const SizedBox(height: 8),

                // Payment method
                Row(
                  children: [
                    _MethodChip(label: l10n.labelCash, value: 'cash', selected: _paymentMethod,
                      onTap: () => setState(() => _paymentMethod = 'cash')),
                    const SizedBox(width: 8),
                    _MethodChip(label: l10n.labelGpay, value: 'gpay', selected: _paymentMethod,
                      onTap: () => setState(() => _paymentMethod = 'gpay')),
                    const SizedBox(width: 8),
                    _MethodChip(label: l10n.labelOther, value: 'other', selected: _paymentMethod,
                      onTap: () => setState(() => _paymentMethod = 'other')),
                  ],
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(products),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.btnSave, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _MethodChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.primary),
          ),
          alignment: Alignment.center,
          child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
