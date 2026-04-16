import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class BulkOrdersScreen extends ConsumerWidget {
  const BulkOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final orders = ref.watch(bulkOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labelBulkOrders),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(bulkOrdersProvider),
        child: orders.when(
          data: (orderList) {
            if (orderList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delivery_dining, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(l10n.labelNoData, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orderList.length,
              itemBuilder: (context, index) {
                final order = orderList[index];
                return _BulkOrderCard(order: order);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BulkOrderFormScreen()));
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.btnAdd),
        heroTag: 'addBulkOrder',
      ),
    );
  }
}

class _BulkOrderCard extends ConsumerWidget {
  final BulkOrder order;
  const _BulkOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    switch (order.status) {
      case 'delivered':
        statusColor = const Color(0xFF2E7D32);
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = const Color(0xFFE65100);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => BulkOrderFormScreen(existingOrder: order)));
        },
        onLongPress: () => _showActions(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(order.customerName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(order.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDatetime),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              if (order.deliveryAddress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('📍 ${order.deliveryAddress}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  Text('Paid: ₹${order.amountPaid.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Tap to edit  •  Long press for options',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(order.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1565C0)),
              title: Text(l10n.btnEdit),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BulkOrderFormScreen(existingOrder: order)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping, color: Color(0xFF2E7D32)),
              title: const Text('Mark Delivered'),
              onTap: () async {
                Navigator.pop(ctx);
                await SupabaseService().updateBulkOrder(BulkOrder(
                  id: order.id, customerName: order.customerName,
                  phone: order.phone, deliveryAddress: order.deliveryAddress,
                  orderDatetime: order.orderDatetime, deliveryDatetime: DateTime.now(),
                  totalAmount: order.totalAmount, amountPaid: order.amountPaid,
                  paymentStatus: order.paymentStatus, status: 'delivered',
                  locationName: order.locationName, gpsLat: order.gpsLat, gpsLong: order.gpsLong,
                  notes: order.notes,
                ));
                ref.invalidate(bulkOrdersProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: Text(l10n.labelCancelled),
              onTap: () async {
                Navigator.pop(ctx);
                await SupabaseService().updateBulkOrder(BulkOrder(
                  id: order.id, customerName: order.customerName,
                  phone: order.phone, deliveryAddress: order.deliveryAddress,
                  orderDatetime: order.orderDatetime, deliveryDatetime: order.deliveryDatetime,
                  totalAmount: order.totalAmount, amountPaid: order.amountPaid,
                  paymentStatus: order.paymentStatus, status: 'cancelled',
                  locationName: order.locationName, gpsLat: order.gpsLat, gpsLong: order.gpsLong,
                  notes: order.notes,
                ));
                ref.invalidate(bulkOrdersProvider);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Color(0xFFC62828)),
              title: Text(l10n.btnDelete, style: const TextStyle(color: Color(0xFFC62828))),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.msgConfirmDelete),
        content: Text('Delete order for "${order.customerName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.btnCancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService().deleteBulkOrder(order.id);
              ref.invalidate(bulkOrdersProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleted'), backgroundColor: Color(0xFFC62828)),
                );
              }
            },
            child: Text(l10n.btnDelete, style: const TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
  }
}

class BulkOrderFormScreen extends ConsumerStatefulWidget {
  final BulkOrder? existingOrder;
  const BulkOrderFormScreen({super.key, this.existingOrder});

  @override
  ConsumerState<BulkOrderFormScreen> createState() => _BulkOrderFormScreenState();
}

class _BulkOrderFormScreenState extends ConsumerState<BulkOrderFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final Map<String, int> _selectedProducts = {};
  String _paymentStatus = 'unpaid';
  String _status = 'pending';
  bool _saving = false;

  bool get _isEditing => widget.existingOrder != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final o = widget.existingOrder!;
      _nameController.text = o.customerName;
      _phoneController.text = o.phone ?? '';
      _addressController.text = o.deliveryAddress ?? '';
      _notesController.text = o.notes ?? '';
      _paymentStatus = o.paymentStatus;
      _status = o.status;
      if (o.paymentStatus == 'partial') {
        _amountPaidController.text = o.amountPaid.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _amountPaidController.dispose();
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
    if (_nameController.text.trim().isEmpty) return;

    if (_isEditing) {
      // For edit mode, we update the order details without requiring products
      setState(() => _saving = true);
      try {
        double totalAmount = widget.existingOrder!.totalAmount;
        if (_selectedProducts.isNotEmpty) {
          totalAmount = _calculateTotal(products);
        }
        double amountPaid = 0;
        if (_paymentStatus == 'paid') {
          amountPaid = totalAmount;
        } else if (_paymentStatus == 'partial') {
          amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
        }

        await SupabaseService().updateBulkOrder(BulkOrder(
          id: widget.existingOrder!.id,
          customerName: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          orderDatetime: widget.existingOrder!.orderDatetime,
          deliveryDatetime: widget.existingOrder!.deliveryDatetime,
          totalAmount: totalAmount,
          amountPaid: amountPaid,
          paymentStatus: _paymentStatus,
          status: _status,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ));
        ref.invalidate(bulkOrdersProvider);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.msgSaveSuccess), backgroundColor: const Color(0xFF2E7D32)),
          );
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
      return;
    }

    // Create mode
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.msgNoProducts)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final total = _calculateTotal(products);
      double amountPaid = 0;
      if (_paymentStatus == 'paid') {
        amountPaid = total;
      } else if (_paymentStatus == 'partial') {
        amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
      }

      final order = BulkOrder(
        id: '',
        customerName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        deliveryAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        totalAmount: total,
        amountPaid: amountPaid,
        paymentStatus: _paymentStatus,
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final items = _selectedProducts.entries.map((entry) {
        final product = products.firstWhere((p) => p.id == entry.key);
        return BulkOrderItem(
          id: '',
          bulkOrderId: '',
          productId: product.id,
          quantity: entry.value,
          sellingPriceAtSale: product.sellingPrice,
          costPriceAtSale: product.costPrice,
        );
      }).toList();

      await SupabaseService().saveBulkOrder(order, items);
      ref.invalidate(bulkOrdersProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.msgSaveSuccess), backgroundColor: const Color(0xFF2E7D32)),
        );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '${l10n.btnEdit} ${l10n.labelBulkOrders}' : '${l10n.btnAdd} ${l10n.labelBulkOrders}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: productsAsync.when(
        data: (products) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${l10n.labelCustomerName} *',
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: l10n.labelPhone, border: const OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: l10n.labelDeliveryAddress, border: const OutlineInputBorder()),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),

              Text(l10n.labelProducts, style: Theme.of(context).textTheme.titleMedium),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text('Select products to update items (leave empty to keep existing)',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ),
              const SizedBox(height: 8),
              // Product grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final qty = _selectedProducts[product.id] ?? 0;
                  final isSelected = qty > 0;

                  return Card(
                    elevation: isSelected ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: isSelected
                          ? BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedProducts[product.id] = qty + 1),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('₹${product.sellingPrice.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.secondary)),
                            if (isSelected)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () {
                                    setState(() {
                                      if (qty <= 1) {
                                        _selectedProducts.remove(product.id);
                                      } else {
                                        _selectedProducts[product.id] = qty - 1;
                                      }
                                    });
                                  }),
                                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () {
                                    setState(() => _selectedProducts[product.id] = qty + 1);
                                  }),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Total
              if (_selectedProducts.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.labelTotalAmount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('₹${_calculateTotal(products).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ],
                ),
              if (_isEditing && _selectedProducts.isEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.labelTotalAmount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('₹${widget.existingOrder!.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ],
                ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(labelText: l10n.labelStatus, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'pending', child: Text(l10n.labelPending)),
                  DropdownMenuItem(value: 'delivered', child: Text(l10n.labelDelivered)),
                  DropdownMenuItem(value: 'cancelled', child: Text(l10n.labelCancelled)),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 12),

              // Payment status
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(labelText: 'Payment', border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'paid', child: Text(l10n.labelPaid)),
                  DropdownMenuItem(value: 'partial', child: Text(l10n.labelPartial)),
                  DropdownMenuItem(value: 'unpaid', child: Text(l10n.labelUnpaid)),
                ],
                onChanged: (v) => setState(() => _paymentStatus = v!),
              ),

              if (_paymentStatus == 'partial') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _amountPaidController,
                  decoration: InputDecoration(
                    labelText: l10n.labelAmountPaid, border: const OutlineInputBorder(), prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18),
                ),
              ],

              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(labelText: l10n.labelNotes, border: const OutlineInputBorder()),
                maxLines: 2,
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _save(products),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.btnSave, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
