import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../services/weather_service.dart';

class SaleEntryScreen extends ConsumerStatefulWidget {
  final Person person;
  final Group? group;

  const SaleEntryScreen({super.key, required this.person, this.group});

  @override
  ConsumerState<SaleEntryScreen> createState() => _SaleEntryScreenState();
}

class _SaleEntryScreenState extends ConsumerState<SaleEntryScreen> {
  final Map<String, int> _selectedProducts = {};
  String _paymentStatus = 'paid';
  String _paymentMethod = 'cash';
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();
  final _otherMethodController = TextEditingController();
  bool _saving = false;
  bool _recordLocation = true;
  bool _recordTimeNow = true;
  DateTime _customDateTime = DateTime.now();

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _customDateTime,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (!mounted || date == null) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_customDateTime),
    );
    if (!mounted || time == null) return;
    setState(() {
      _customDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    _notesController.dispose();
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
      double amountPaid;
      double balance;

      if (_paymentStatus == 'paid') {
        amountPaid = total;
        balance = 0;
      } else if (_paymentStatus == 'partial') {
        amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
        balance = total - amountPaid;
      } else {
        amountPaid = 0;
        balance = total;
      }

      String method = _paymentMethod;
      if (_paymentMethod == 'other') {
        method = _otherMethodController.text.trim().isEmpty ? 'other' : _otherMethodController.text.trim();
      }

      // Capture weather + location only if user toggled ON
      WeatherInfo? weather;
      if (_recordLocation) {
        try {
          weather = await WeatherService.getCurrentWeather();
        } catch (_) {
          // Silently ignore — don't block the sale
        }
      }

      // Use current time or user-picked custom time
      final saleTime = _recordTimeNow ? DateTime.now() : _customDateTime;

      final tx = SaleTransaction(
        id: '',
        type: widget.group != null ? 'group' : 'individual',
        personId: widget.person.id,
        groupId: widget.group?.id,
        datetime: saleTime,
        locationName: weather?.locationName,
        gpsLat: weather?.lat,
        gpsLong: weather?.lon,
        weatherDesc: weather?.description,
        weatherTemp: weather?.temperature,
        totalAmount: total,
        amountPaid: amountPaid,
        balance: balance,
        paymentMethod: (_paymentStatus == 'unpaid') ? null : method,
        paymentStatus: _paymentStatus,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
        Navigator.pop(context);
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
    final balance = ref.watch(outstandingBalanceProvider(widget.person.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.person.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.group != null)
              Text(widget.group!.name, style: const TextStyle(fontSize: 13)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: productsAsync.when(
        data: (products) => Column(
          children: [
            // Outstanding balance warning
            balance.when(
              data: (bal) => bal > 0
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFFE65100).withOpacity(0.15),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Color(0xFFE65100)),
                          const SizedBox(width: 8),
                          Text('${l10n.labelOutstanding}: ₹${bal.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    )
                  : const SizedBox(),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
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
                  // Selected items chips
                  if (_selectedProducts.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _selectedProducts.entries.map((e) {
                          final product = products.firstWhere((p) => p.id == e.key);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text('${product.name} ×${e.value}', style: const TextStyle(fontSize: 13)),
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Total
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.labelTotalAmount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        Text('₹${_calculateTotal(products).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                      ],
                    ),
                  ),

                  // Payment status
                  Row(
                    children: [
                      _PaymentToggle(label: l10n.labelPaid, value: 'paid', selected: _paymentStatus,
                        color: const Color(0xFF2E7D32), onTap: () => setState(() => _paymentStatus = 'paid')),
                      const SizedBox(width: 8),
                      _PaymentToggle(label: l10n.labelPartial, value: 'partial', selected: _paymentStatus,
                        color: const Color(0xFFE65100), onTap: () => setState(() => _paymentStatus = 'partial')),
                      const SizedBox(width: 8),
                      _PaymentToggle(label: l10n.labelUnpaid, value: 'unpaid', selected: _paymentStatus,
                        color: const Color(0xFFC62828), onTap: () => setState(() => _paymentStatus = 'unpaid')),
                    ],
                  ),

                  // Partial payment amount
                  if (_paymentStatus == 'partial') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountPaidController,
                      decoration: InputDecoration(
                        labelText: l10n.labelAmountPaid,
                        border: const OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],

                  // Payment method
                  if (_paymentStatus != 'unpaid') ...[
                    const SizedBox(height: 8),
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
                    if (_paymentMethod == 'other') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otherMethodController,
                        decoration: const InputDecoration(
                          labelText: 'Method name',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],

                  const SizedBox(height: 12),

                  // Location & Time toggle row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _recordLocation = !_recordLocation),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _recordLocation ? const Color(0xFF1565C0) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_recordLocation ? Icons.location_on : Icons.location_off,
                                  size: 18, color: _recordLocation ? Colors.white : Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(_recordLocation ? '📍 Location ON' : '📍 Location OFF',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: _recordLocation ? Colors.white : Colors.grey[600])),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _recordTimeNow = !_recordTimeNow;
                            if (!_recordTimeNow) _customDateTime = DateTime.now();
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _recordTimeNow ? const Color(0xFF1565C0) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_recordTimeNow ? Icons.access_time_filled : Icons.edit_calendar,
                                  size: 18, color: _recordTimeNow ? Colors.white : Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(_recordTimeNow ? '🕐 Time NOW' : '🕐 Custom Time',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: _recordTimeNow ? Colors.white : Colors.grey[600])),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Custom time picker when Record Time is OFF
                  if (!_recordTimeNow) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDateTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: Color(0xFF1565C0)),
                            const SizedBox(width: 12),
                            Text(
                              '${_customDateTime.day}/${_customDateTime.month}/${_customDateTime.year}  '
                              '${_customDateTime.hour.toString().padLeft(2, '0')}:${_customDateTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Text('Tap to change', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Save button
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
      ),
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

class _PaymentToggle extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Color color;
  final VoidCallback onTap;

  const _PaymentToggle({required this.label, required this.value, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
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
