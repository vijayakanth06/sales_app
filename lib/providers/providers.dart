import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider((ref) => SupabaseService());

// Products
final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.read(supabaseServiceProvider).fetchProducts();
});

// Groups
final groupsProvider = FutureProvider<List<Group>>((ref) async {
  return ref.read(supabaseServiceProvider).fetchGroups();
});

// Persons by group
final personsByGroupProvider = FutureProvider.family<List<Person>, String>((ref, groupId) async {
  return ref.read(supabaseServiceProvider).fetchPersonsByGroup(groupId);
});

// Individuals (no group)
final individualsProvider = FutureProvider<List<Person>>((ref) async {
  return ref.read(supabaseServiceProvider).fetchIndividuals();
});

// All persons
final allPersonsProvider = FutureProvider<List<Person>>((ref) async {
  return ref.read(supabaseServiceProvider).fetchAllPersons();
});

// Today's transactions
final todayTransactionsProvider = FutureProvider<List<SaleTransaction>>((ref) async {
  return ref.read(supabaseServiceProvider).fetchTodayTransactions();
});

// Bulk orders
final bulkOrdersProvider = FutureProvider<List<BulkOrder>>((ref) async {
  return ref.read(supabaseServiceProvider).fetchBulkOrders();
});

// Outstanding balance for a person
final outstandingBalanceProvider = FutureProvider.family<double, String>((ref, personId) async {
  return ref.read(supabaseServiceProvider).getOutstandingBalance(personId);
});

// Outstanding balance for a group
final groupOutstandingBalanceProvider = FutureProvider.family<double, String>((ref, groupId) async {
  return ref.read(supabaseServiceProvider).getGroupOutstandingBalance(groupId);
});

// Language preference
final languageProvider = StateProvider<String>((ref) => 'ta');
