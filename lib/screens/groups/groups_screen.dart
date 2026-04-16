import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groups = ref.watch(groupsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupsProvider),
      child: groups.when(
        data: (groupList) {
          if (groupList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(l10n.labelNoData, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                  const SizedBox(height: 24),
                  FloatingActionButton.extended(
                    onPressed: () => _showAddGroupDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.btnAddGroup),
                    heroTag: 'addGroupEmpty',
                  ),
                ],
              ),
            );
          }
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: groupList.length,
                itemBuilder: (context, index) {
                  final group = groupList[index];
                  return _GroupCard(group: group);
                },
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddGroupDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.btnAddGroup),
                  heroTag: 'addGroup',
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, WidgetRef ref) {
    _showGroupFormDialog(context, ref, null);
  }

  static void _showGroupFormDialog(BuildContext context, WidgetRef ref, Group? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String selectedType = existing?.type ?? 'factory';
    final l10n = AppLocalizations.of(context)!;
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? '${l10n.btnEdit} ${l10n.labelGroup}' : l10n.btnAddGroup,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '${l10n.labelGroupName} *',
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(builder: (context, setState) {
              return DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'factory', child: Text(l10n.labelFactory)),
                  DropdownMenuItem(value: 'site', child: Text(l10n.labelSite)),
                  DropdownMenuItem(value: 'shop', child: Text(l10n.labelShop)),
                  DropdownMenuItem(value: 'other', child: Text(l10n.labelOtherType)),
                ],
                onChanged: (v) => setState(() => selectedType = v!),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  await SupabaseService().saveGroup(Group(
                    id: existing?.id ?? '',
                    name: nameController.text.trim(),
                    type: selectedType,
                  ));
                  ref.invalidate(groupsProvider);
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
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final Group group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(groupOutstandingBalanceProvider(group.id));

    String typeIcon;
    switch (group.type) {
      case 'factory':
        typeIcon = '🏭';
        break;
      case 'site':
        typeIcon = '🏗️';
        break;
      case 'shop':
        typeIcon = '🏪';
        break;
      default:
        typeIcon = '📍';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
          ).then((_) => ref.invalidate(groupsProvider));
        },
        onLongPress: () => _showActions(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(typeIcon, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${group.personCount} persons',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
                            style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold, fontSize: 16)),
                      )
                    : const SizedBox(),
                loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 28),
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
            Text(group.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1565C0)),
              title: Text(l10n.btnEdit),
              onTap: () {
                Navigator.pop(ctx);
                GroupsScreen._showGroupFormDialog(context, ref, group);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Color(0xFFC62828)),
              title: Text(l10n.btnDelete, style: const TextStyle(color: Color(0xFFC62828))),
              subtitle: const Text('Persons will become individuals'),
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
        content: Text('Delete "${group.name}"? All persons in this group will become individuals.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.btnCancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService().deleteGroup(group.id);
                ref.invalidate(groupsProvider);
                ref.invalidate(individualsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group deleted'), backgroundColor: Color(0xFF2E7D32)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting group: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(l10n.btnDelete, style: const TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
  }
}
