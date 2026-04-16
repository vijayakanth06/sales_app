import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../sale_entry/sale_entry_screen.dart';
import '../calculate/calculate_screen.dart';

class GroupDetailScreen extends ConsumerWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final persons = ref.watch(personsByGroupProvider(group.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate, size: 28),
            tooltip: l10n.btnCalculate,
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => CalculateScreen(preselectedGroupId: group.id))),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(personsByGroupProvider(group.id)),
        child: persons.when(
          data: (personList) {
            if (personList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(l10n.labelNoData, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: personList.length,
              itemBuilder: (context, index) {
                final person = personList[index];
                return _PersonCard(person: person, group: group);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPersonDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.btnAddPerson),
        heroTag: 'addPersonToGroup',
      ),
    );
  }

  void _showAddPersonDialog(BuildContext context, WidgetRef ref) {
    showPersonFormDialog(context, ref, null, groupId: group.id);
  }
}

/// Shared person form dialog — used by GroupDetail and Individuals screens
void showPersonFormDialog(BuildContext context, WidgetRef ref, Person? existing, {String? groupId}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final phoneController = TextEditingController(text: existing?.phone ?? '');
  final ageController = TextEditingController(text: existing?.age?.toString() ?? '');
  final l10n = AppLocalizations.of(context)!;
  final isEdit = existing != null;
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? '${l10n.btnEdit} ${l10n.labelPerson}' : l10n.btnAddPerson,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '${l10n.labelPersonName} *',
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Name is required';
                if (value.trim().length < 2) return 'Name must be at least 2 characters';
                if (!RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(value.trim())) return 'Name can only contain letters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: l10n.labelPhone,
                border: const OutlineInputBorder(),
                hintText: '10 digit number',
              ),
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 18),
              maxLength: 10,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                    return 'Enter a valid 10-digit phone number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ageController,
              decoration: InputDecoration(
                labelText: l10n.labelAge,
                border: const OutlineInputBorder(),
                hintText: '1 - 120',
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18),
              maxLength: 3,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final age = int.tryParse(value.trim());
                  if (age == null) return 'Enter a valid number';
                  if (age < 1 || age > 120) return 'Age must be between 1 and 120';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  await SupabaseService().savePerson(Person(
                    id: existing?.id ?? '',
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    age: ageController.text.trim().isEmpty ? null : int.tryParse(ageController.text.trim()),
                    groupId: existing?.groupId ?? groupId,
                  ));
                  _invalidateAllPersonProviders(ref, groupId);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.btnSave),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _invalidateAllPersonProviders(WidgetRef ref, String? groupId) {
  ref.invalidate(individualsProvider);
  ref.invalidate(allPersonsProvider);
  ref.invalidate(groupsProvider);
  if (groupId != null) {
    ref.invalidate(personsByGroupProvider(groupId));
  }
}

/// Show move-to-group dialog
void showMoveToGroupDialog(BuildContext context, WidgetRef ref, Person person) {
  final l10n = AppLocalizations.of(context)!;
  final groups = ref.read(groupsProvider);

  groups.whenData((groupList) {
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
            Text('Move "${person.name}" to...', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Individual option
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFFFF6F00)),
              title: Text(l10n.labelIndividual),
              subtitle: const Text('Remove from group'),
              selected: person.groupId == null,
              onTap: () async {
                Navigator.pop(ctx);
                await SupabaseService().updatePersonGroup(person.id, null);
                _invalidateAllPersonProviders(ref, person.groupId);
              },
            ),
            const Divider(),
            // Group options
            ...groupList.map((g) => ListTile(
              leading: const Icon(Icons.business, color: Color(0xFF1565C0)),
              title: Text(g.name),
              subtitle: Text(g.type),
              selected: person.groupId == g.id,
              onTap: () async {
                Navigator.pop(ctx);
                final oldGroupId = person.groupId;
                await SupabaseService().updatePersonGroup(person.id, g.id);
                _invalidateAllPersonProviders(ref, oldGroupId);
                if (oldGroupId != g.id) {
                  ref.invalidate(personsByGroupProvider(g.id));
                }
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  });
}

/// Show person actions bottom sheet
void showPersonActions(BuildContext context, WidgetRef ref, Person person, {Group? group}) {
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
          Text(person.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (person.phone != null)
            Text(person.phone!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFF1565C0)),
            title: Text(l10n.btnEdit),
            onTap: () {
              Navigator.pop(ctx);
              showPersonFormDialog(context, ref, person, groupId: person.groupId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Color(0xFF6A1B9A)),
            title: const Text('Move to Group / Individual'),
            onTap: () {
              Navigator.pop(ctx);
              showMoveToGroupDialog(context, ref, person);
            },
          ),
          if (person.groupId != null)
            ListTile(
              leading: const Icon(Icons.person_remove, color: Color(0xFFE65100)),
              title: const Text('Remove from Group'),
              subtitle: const Text('Becomes an individual'),
              onTap: () async {
                Navigator.pop(ctx);
                final oldGroupId = person.groupId;
                await SupabaseService().updatePersonGroup(person.id, null);
                _invalidateAllPersonProviders(ref, oldGroupId);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Color(0xFFC62828)),
            title: Text(l10n.btnDelete, style: const TextStyle(color: Color(0xFFC62828))),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDeletePerson(context, ref, person);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _confirmDeletePerson(BuildContext context, WidgetRef ref, Person person) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.msgConfirmDelete),
      content: Text('Delete "${person.name}"? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.btnCancel)),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final groupId = person.groupId;
            await SupabaseService().deletePerson(person.id);
            _invalidateAllPersonProviders(ref, groupId);
          },
          child: Text(l10n.btnDelete, style: const TextStyle(color: Color(0xFFC62828))),
        ),
      ],
    ),
  );
}

class _PersonCard extends ConsumerWidget {
  final Person person;
  final Group group;
  const _PersonCard({required this.person, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(outstandingBalanceProvider(person.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SaleEntryScreen(
              person: person,
              group: group,
            )),
          ).then((_) {
            ref.invalidate(personsByGroupProvider(group.id));
            ref.invalidate(todayTransactionsProvider);
          });
        },
        onLongPress: () => showPersonActions(context, ref, person, group: group),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  person.name[0].toUpperCase(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    if (person.phone != null)
                      Text(person.phone!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              balance.when(
                data: (bal) => bal > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('₹${bal.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                      )
                    : const SizedBox(),
                loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
