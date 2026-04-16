import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class CalculateScreen extends ConsumerStatefulWidget {
  final String? preselectedGroupId;
  const CalculateScreen({super.key, this.preselectedGroupId});

  @override
  ConsumerState<CalculateScreen> createState() => _CalculateScreenState();
}

class _CalculateScreenState extends ConsumerState<CalculateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Person mode
  String? _selectedPersonId;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  
  // Group mode
  String? _selectedGroupId;
  List<Person> _groupPersons = [];
  Set<String> _selectedPersonIds = {};
  bool _groupTotalMode = true;
  
  // Results
  bool _calculating = false;
  Map<String, dynamic>? _personResult;
  List<Map<String, dynamic>>? _groupResults;
  Map<String, dynamic>? _groupTotalResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.preselectedGroupId != null) {
      _selectedGroupId = widget.preselectedGroupId;
      _tabController.index = 1;
      _loadGroupPersons();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupPersons() async {
    if (_selectedGroupId == null) return;
    final persons = await SupabaseService().fetchPersonsByGroup(_selectedGroupId!);
    setState(() {
      _groupPersons = persons;
      _selectedPersonIds = persons.map((p) => p.id).toSet();
    });
  }

  Future<Map<String, dynamic>> _calculateForPerson(String personId) async {
    final svc = SupabaseService();
    final transactions = await svc.fetchTransactionsByPerson(personId, _fromDate, _toDate);
    final payments = await svc.fetchPaymentsByPerson(personId, _fromDate, _toDate);
    
    double totalRevenue = 0;
    double totalCost = 0;
    double paidAtSale = 0;
    List<Map<String, dynamic>> productBreakdown = [];
    Map<String, Map<String, dynamic>> productMap = {};

    for (var tx in transactions) {
      totalRevenue += tx.totalAmount;
      paidAtSale += tx.amountPaid;
      
      final items = await svc.fetchTransactionItems(tx.id);
      for (var item in items) {
        totalCost += item.costPriceAtSale * item.quantity;
        final key = item.productId;
        if (productMap.containsKey(key)) {
          productMap[key]!['qty'] = (productMap[key]!['qty'] as int) + item.quantity;
          productMap[key]!['amount'] = (productMap[key]!['amount'] as double) + (item.sellingPriceAtSale * item.quantity);
        } else {
          productMap[key] = {
            'name': item.productName ?? 'Product',
            'qty': item.quantity,
            'amount': item.sellingPriceAtSale * item.quantity,
          };
        }
      }
    }

    double totalSettled = payments.fold(0.0, (sum, p) => sum + p.amount);
    
    productBreakdown = productMap.values.toList();

    return {
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'paidAtSale': paidAtSale,
      'totalSettled': totalSettled,
      'totalPaid': paidAtSale + totalSettled,
      'netBalance': totalRevenue - paidAtSale - totalSettled,
      'grossProfit': totalRevenue - totalCost,
      'products': productBreakdown,
      'txCount': transactions.length,
    };
  }

  Future<void> _calculatePerson() async {
    if (_selectedPersonId == null) return;
    setState(() => _calculating = true);
    try {
      final result = await _calculateForPerson(_selectedPersonId!);
      setState(() => _personResult = result);
    } finally {
      setState(() => _calculating = false);
    }
  }

  Future<void> _calculateGroup() async {
    if (_selectedGroupId == null) return;
    setState(() => _calculating = true);
    try {
      if (_groupTotalMode) {
        double totalRevenue = 0, totalCost = 0, totalPaid = 0, totalSettled = 0;
        for (var pid in _selectedPersonIds) {
          final r = await _calculateForPerson(pid);
          totalRevenue += r['totalRevenue'] as double;
          totalCost += r['totalCost'] as double;
          totalPaid += r['paidAtSale'] as double;
          totalSettled += r['totalSettled'] as double;
        }
        setState(() {
          _groupTotalResult = {
            'totalRevenue': totalRevenue,
            'totalPaid': totalPaid + totalSettled,
            'netBalance': totalRevenue - totalPaid - totalSettled,
            'grossProfit': totalRevenue - totalCost,
          };
          _groupResults = null;
        });
      } else {
        List<Map<String, dynamic>> results = [];
        for (var person in _groupPersons) {
          if (_selectedPersonIds.contains(person.id)) {
            final r = await _calculateForPerson(person.id);
            r['personName'] = person.name;
            results.add(r);
          }
        }
        setState(() {
          _groupResults = results;
          _groupTotalResult = null;
        });
      }
    } finally {
      setState(() => _calculating = false);
    }
  }

  String _formatResult() {
    final df = DateFormat('dd/MM/yyyy');
    final buf = StringBuffer();
    buf.writeln('📊 HomeSales Report');
    buf.writeln('${df.format(_fromDate)} - ${df.format(_toDate)}');
    buf.writeln('---');
    
    if (_personResult != null) {
      final r = _personResult!;
      buf.writeln('Total Bought: ₹${(r['totalRevenue'] as double).toStringAsFixed(0)}');
      buf.writeln('Total Paid: ₹${(r['totalPaid'] as double).toStringAsFixed(0)}');
      buf.writeln('Balance: ₹${(r['netBalance'] as double).toStringAsFixed(0)}');
    }
    
    if (_groupTotalResult != null) {
      final r = _groupTotalResult!;
      buf.writeln('Group Total: ₹${(r['totalRevenue'] as double).toStringAsFixed(0)}');
      buf.writeln('Paid: ₹${(r['totalPaid'] as double).toStringAsFixed(0)}');
      buf.writeln('Balance: ₹${(r['netBalance'] as double).toStringAsFixed(0)}');
    }
    
    if (_groupResults != null) {
      for (var r in _groupResults!) {
        buf.writeln('${r['personName']}: ₹${(r['totalRevenue'] as double).toStringAsFixed(0)} | Bal: ₹${(r['netBalance'] as double).toStringAsFixed(0)}');
      }
    }
    
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allPersons = ref.watch(allPersonsProvider);
    final groups = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labelCalculate),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: l10n.labelPerson),
            Tab(text: l10n.labelGroup),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PERSON TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Person dropdown
                allPersons.when(
                  data: (persons) => DropdownButtonFormField<String>(
                    value: _selectedPersonId,
                    decoration: InputDecoration(
                      labelText: l10n.labelPerson,
                      border: const OutlineInputBorder(),
                    ),
                    items: persons.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, style: const TextStyle(fontSize: 18)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedPersonId = v),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 16),

                // Date range
                Row(
                  children: [
                    Expanded(child: _DatePickerField(
                      label: l10n.labelDateFrom,
                      date: _fromDate,
                      onPicked: (d) => setState(() => _fromDate = d),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _DatePickerField(
                      label: l10n.labelDateTo,
                      date: _toDate,
                      onPicked: (d) => setState(() => _toDate = d),
                    )),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _calculating ? null : _calculatePerson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _calculating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.btnCalculate, style: const TextStyle(fontSize: 18)),
                  ),
                ),

                if (_personResult != null) ...[
                  const SizedBox(height: 24),
                  _ResultCard(result: _personResult!),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Share.share(_formatResult()),
                          icon: const Icon(Icons.share),
                          label: Text(l10n.labelShare),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRecordPaymentDialog(context),
                          icon: const Icon(Icons.payment),
                          label: Text(l10n.labelRecordPayment),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // GROUP TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group dropdown
                groups.when(
                  data: (groupList) => DropdownButtonFormField<String>(
                    value: _selectedGroupId,
                    decoration: InputDecoration(
                      labelText: l10n.labelGroup,
                      border: const OutlineInputBorder(),
                    ),
                    items: groupList.map((g) => DropdownMenuItem(
                      value: g.id,
                      child: Text(g.name, style: const TextStyle(fontSize: 18)),
                    )).toList(),
                    onChanged: (v) {
                      setState(() => _selectedGroupId = v);
                      _loadGroupPersons();
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 16),

                // Person checkboxes
                if (_groupPersons.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.labelPersons, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedPersonIds.length == _groupPersons.length) {
                              _selectedPersonIds.clear();
                            } else {
                              _selectedPersonIds = _groupPersons.map((p) => p.id).toSet();
                            }
                          });
                        },
                        child: Text(
                          _selectedPersonIds.length == _groupPersons.length
                              ? l10n.labelDeselectAll
                              : l10n.labelSelectAll,
                        ),
                      ),
                    ],
                  ),
                  ..._groupPersons.map((p) => CheckboxListTile(
                    title: Text(p.name, style: const TextStyle(fontSize: 16)),
                    value: _selectedPersonIds.contains(p.id),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedPersonIds.add(p.id);
                        } else {
                          _selectedPersonIds.remove(p.id);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 8),
                  // Toggle: group total vs individual
                  SwitchListTile(
                    title: Text(l10n.labelGroupTotal),
                    value: _groupTotalMode,
                    onChanged: (v) => setState(() => _groupTotalMode = v),
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _DatePickerField(
                      label: l10n.labelDateFrom,
                      date: _fromDate,
                      onPicked: (d) => setState(() => _fromDate = d),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _DatePickerField(
                      label: l10n.labelDateTo,
                      date: _toDate,
                      onPicked: (d) => setState(() => _toDate = d),
                    )),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _calculating ? null : _calculateGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _calculating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.btnCalculate, style: const TextStyle(fontSize: 18)),
                  ),
                ),

                if (_groupTotalResult != null) ...[
                  const SizedBox(height: 24),
                  _GroupTotalCard(result: _groupTotalResult!),
                ],

                if (_groupResults != null) ...[
                  const SizedBox(height: 24),
                  ..._groupResults!.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(r['personName'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Total: ₹${(r['totalRevenue'] as double).toStringAsFixed(0)}'),
                      trailing: Text('Bal: ₹${(r['netBalance'] as double).toStringAsFixed(0)}',
                        style: TextStyle(
                          color: (r['netBalance'] as double) > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )),
                ],

                if (_groupTotalResult != null || _groupResults != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Share.share(_formatResult()),
                      icon: const Icon(Icons.share),
                      label: Text(l10n.labelShare),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    String method = 'cash';
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.labelRecordPayment, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: l10n.labelAmountPaid,
                  border: const OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: method,
                decoration: InputDecoration(labelText: l10n.labelPaymentMethod, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'cash', child: Text(l10n.labelCash)),
                  DropdownMenuItem(value: 'gpay', child: Text(l10n.labelGpay)),
                  DropdownMenuItem(value: 'other', child: Text(l10n.labelOther)),
                ],
                onChanged: (v) => setState(() => method = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) return;
                  await SupabaseService().savePayment(Payment(
                    id: '',
                    personId: _selectedPersonId,
                    amount: amount,
                    paymentMethod: method,
                  ));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment recorded!'), backgroundColor: Color(0xFF2E7D32)),
                    );
                    _calculatePerson(); // Recalculate
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.btnSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPicked;
  const _DatePickerField({required this.label, required this.date, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (d != null) onPicked(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final products = result['products'] as List<Map<String, dynamic>>;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...products.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${p['name']} × ${p['qty']}', style: const TextStyle(fontSize: 15)),
                  Text('₹${(p['amount'] as double).toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
            const Divider(height: 24),
            _ResultRow('Total Sale', '₹${(result['totalRevenue'] as double).toStringAsFixed(0)}', const Color(0xFF1565C0)),
            _ResultRow('Paid at Sale', '₹${(result['paidAtSale'] as double).toStringAsFixed(0)}', const Color(0xFF2E7D32)),
            _ResultRow('Settlements', '₹${(result['totalSettled'] as double).toStringAsFixed(0)}', const Color(0xFF2E7D32)),
            _ResultRow('Total Paid', '₹${(result['totalPaid'] as double).toStringAsFixed(0)}', const Color(0xFF2E7D32)),
            const Divider(),
            _ResultRow('Net Balance', '₹${(result['netBalance'] as double).toStringAsFixed(0)}',
              (result['netBalance'] as double) > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32)),
            _ResultRow('Gross Profit', '₹${(result['grossProfit'] as double).toStringAsFixed(0)}', const Color(0xFF1565C0)),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _GroupTotalCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _GroupTotalCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group Total', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _ResultRow('Total Revenue', '₹${(result['totalRevenue'] as double).toStringAsFixed(0)}', const Color(0xFF1565C0)),
            _ResultRow('Total Paid', '₹${(result['totalPaid'] as double).toStringAsFixed(0)}', const Color(0xFF2E7D32)),
            _ResultRow('Net Balance', '₹${(result['netBalance'] as double).toStringAsFixed(0)}',
              (result['netBalance'] as double) > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32)),
            _ResultRow('Gross Profit', '₹${(result['grossProfit'] as double).toStringAsFixed(0)}', const Color(0xFF1565C0)),
          ],
        ),
      ),
    );
  }
}
