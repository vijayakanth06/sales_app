import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // ==================== PRODUCTS ====================
  Future<List<Product>> fetchProducts({bool activeOnly = true}) async {
    var query = client.from('products').select();
    if (activeOnly) query = query.eq('active', true);
    final data = await query.order('name');
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<void> saveProduct(Product p) async {
    if (p.id.isEmpty) {
      await client.from('products').insert(p.toJson());
    } else {
      await client.from('products').update(p.toJson()).eq('id', p.id);
    }
  }

  // ==================== GROUPS ====================
  Future<List<Group>> fetchGroups({bool activeOnly = true}) async {
    var query = client.from('groups').select();
    if (activeOnly) query = query.eq('active', true);
    final data = await query.order('name');
    final groups = (data as List).map((e) => Group.fromJson(e)).toList();
    
    // Get person counts
    for (var g in groups) {
      final count = await client
          .from('persons')
          .select()
          .eq('group_id', g.id)
          .eq('active', true);
      g.personCount = (count as List).length;
    }
    return groups;
  }

  Future<void> saveGroup(Group g) async {
    if (g.id.isEmpty) {
      await client.from('groups').insert(g.toJson());
    } else {
      await client.from('groups').update(g.toJson()).eq('id', g.id);
    }
  }

  // ==================== PERSONS ====================
  Future<List<Person>> fetchPersonsByGroup(String groupId) async {
    final data = await client
        .from('persons')
        .select()
        .eq('group_id', groupId)
        .eq('active', true)
        .order('name');
    return (data as List).map((e) => Person.fromJson(e)).toList();
  }

  Future<List<Person>> fetchIndividuals() async {
    final data = await client
        .from('persons')
        .select()
        .isFilter('group_id', null)
        .eq('active', true)
        .order('name');
    return (data as List).map((e) => Person.fromJson(e)).toList();
  }

  Future<List<Person>> fetchAllPersons() async {
    final data = await client
        .from('persons')
        .select()
        .eq('active', true)
        .order('name');
    return (data as List).map((e) => Person.fromJson(e)).toList();
  }

  Future<void> savePerson(Person p) async {
    if (p.id.isEmpty) {
      await client.from('persons').insert(p.toJson());
    } else {
      await client.from('persons').update(p.toJson()).eq('id', p.id);
    }
  }

  // ==================== TRANSACTIONS ====================
  Future<void> saveTransaction(SaleTransaction t, List<TransactionItem> items) async {
    final txData = t.toJson();
    final result = await client.from('transactions').insert(txData).select().single();
    final txId = result['id'] as String;
    
    for (var item in items) {
      final itemData = item.toJson();
      itemData['transaction_id'] = txId;
      await client.from('transaction_items').insert(itemData);
    }
  }

  Future<List<SaleTransaction>> fetchTodayTransactions() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final data = await client
        .from('transactions')
        .select()
        .gte('datetime', startOfDay.toIso8601String())
        .lt('datetime', endOfDay.toIso8601String())
        .order('datetime', ascending: false);
    
    final transactions = (data as List).map((e) => SaleTransaction.fromJson(e)).toList();
    
    // Fetch person names
    for (var tx in transactions) {
      if (tx.personId != null) {
        try {
          final p = await client.from('persons').select('name').eq('id', tx.personId!).single();
          tx.personName = p['name'] as String;
        } catch (_) {}
      }
      if (tx.groupId != null) {
        try {
          final g = await client.from('groups').select('name').eq('id', tx.groupId!).single();
          tx.groupName = g['name'] as String;
        } catch (_) {}
      }
    }
    return transactions;
  }

  Future<List<SaleTransaction>> fetchTransactionsByPerson(String personId, DateTime from, DateTime to) async {
    final data = await client
        .from('transactions')
        .select()
        .eq('person_id', personId)
        .gte('datetime', from.toIso8601String())
        .lte('datetime', to.toIso8601String())
        .order('datetime', ascending: false);
    return (data as List).map((e) => SaleTransaction.fromJson(e)).toList();
  }

  Future<List<SaleTransaction>> fetchTransactionsByGroup(String groupId, DateTime from, DateTime to) async {
    final data = await client
        .from('transactions')
        .select()
        .eq('group_id', groupId)
        .gte('datetime', from.toIso8601String())
        .lte('datetime', to.toIso8601String())
        .order('datetime', ascending: false);
    return (data as List).map((e) => SaleTransaction.fromJson(e)).toList();
  }

  Future<List<TransactionItem>> fetchTransactionItems(String transactionId) async {
    final data = await client
        .from('transaction_items')
        .select('*, products(name)')
        .eq('transaction_id', transactionId);
    return (data as List).map((e) {
      final item = TransactionItem.fromJson(e);
      if (e['products'] != null) {
        item.productName = e['products']['name'] as String;
      }
      return item;
    }).toList();
  }

  // ==================== PAYMENTS ====================
  Future<void> savePayment(Payment p) async {
    await client.from('payments').insert(p.toJson());
  }

  Future<List<Payment>> fetchPaymentsByPerson(String personId, DateTime from, DateTime to) async {
    final data = await client
        .from('payments')
        .select()
        .eq('person_id', personId)
        .gte('datetime', from.toIso8601String())
        .lte('datetime', to.toIso8601String())
        .order('datetime', ascending: false);
    return (data as List).map((e) => Payment.fromJson(e)).toList();
  }

  // ==================== BULK ORDERS ====================
  Future<List<BulkOrder>> fetchBulkOrders() async {
    final data = await client
        .from('bulk_orders')
        .select()
        .order('order_datetime', ascending: false);
    return (data as List).map((e) => BulkOrder.fromJson(e)).toList();
  }

  Future<void> saveBulkOrder(BulkOrder o, List<BulkOrderItem> items) async {
    final result = await client.from('bulk_orders').insert(o.toJson()).select().single();
    final orderId = result['id'] as String;
    
    for (var item in items) {
      final itemData = item.toJson();
      itemData['bulk_order_id'] = orderId;
      await client.from('bulk_order_items').insert(itemData);
    }
  }

  Future<void> updateBulkOrder(BulkOrder o) async {
    await client.from('bulk_orders').update(o.toJson()).eq('id', o.id);
  }

  // ==================== CALCULATIONS (fetch data for compute on device) ====================
  Future<double> getOutstandingBalance(String personId) async {
    final txData = await client
        .from('transactions')
        .select('total_amount, amount_paid')
        .eq('person_id', personId);
    
    final payData = await client
        .from('payments')
        .select('amount')
        .eq('person_id', personId);
    
    double totalAmount = 0;
    double totalPaid = 0;
    double totalSettled = 0;
    
    for (var tx in (txData as List)) {
      totalAmount += (tx['total_amount'] as num).toDouble();
      totalPaid += (tx['amount_paid'] as num).toDouble();
    }
    
    for (var pay in (payData as List)) {
      totalSettled += (pay['amount'] as num).toDouble();
    }
    
    return totalAmount - totalPaid - totalSettled;
  }

  Future<double> getGroupOutstandingBalance(String groupId) async {
    final persons = await fetchPersonsByGroup(groupId);
    double total = 0;
    for (var p in persons) {
      total += await getOutstandingBalance(p.id);
    }
    return total;
  }

  // ==================== DELETE OPERATIONS ====================
  Future<void> deleteBulkOrder(String id) async {
    await client.from('bulk_order_items').delete().eq('bulk_order_id', id);
    await client.from('bulk_orders').delete().eq('id', id);
  }

  Future<void> deletePerson(String id) async {
    await client.from('persons').delete().eq('id', id);
  }

  Future<void> deleteGroup(String id) async {
    // Move all persons in this group to individuals (set group_id = null)
    await client.from('persons').update({'group_id': null}).eq('group_id', id);
    await client.from('groups').delete().eq('id', id);
  }

  // ==================== MOVE PERSON ====================
  Future<void> updatePersonGroup(String personId, String? groupId) async {
    await client.from('persons').update({'group_id': groupId}).eq('id', personId);
  }

  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }
}
