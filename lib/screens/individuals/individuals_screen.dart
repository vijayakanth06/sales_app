import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../sale_entry/sale_entry_screen.dart';
import '../calculate/calculate_screen.dart';
import '../groups/group_detail_screen.dart';

class IndividualsScreen extends ConsumerWidget {
  const IndividualsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final individuals = ref.watch(individualsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(individualsProvider),
      child: individuals.when(
        data: (personList) {
          if (personList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(l10n.labelNoData, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                  const SizedBox(height: 24),
                  FloatingActionButton.extended(
                    onPressed: () => showPersonFormDialog(context, ref, null),
                    icon: const Icon(Icons.person_add),
                    label: Text(l10n.btnAddPerson),
                    heroTag: 'addIndividualEmpty',
                  ),
                ],
              ),
            );
          }
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: personList.length,
                itemBuilder: (context, index) {
                  final person = personList[index];
                  return _IndividualCard(person: person);
                },
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CalculateScreen())),
                      heroTag: 'calcIndividual',
                      mini: true,
                      child: const Icon(Icons.calculate),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.extended(
                      onPressed: () => showPersonFormDialog(context, ref, null),
                      icon: const Icon(Icons.person_add),
                      label: Text(l10n.btnAddPerson),
                      heroTag: 'addIndividual',
                    ),
                  ],
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
}

class _IndividualCard extends ConsumerWidget {
  final Person person;
  const _IndividualCard({required this.person});

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
            MaterialPageRoute(builder: (_) => SaleEntryScreen(person: person)),
          ).then((_) {
            ref.invalidate(individualsProvider);
            ref.invalidate(todayTransactionsProvider);
          });
        },
        onLongPress: () => showPersonActions(context, ref, person),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFF6F00).withValues(alpha: 0.1),
                child: Text(
                  person.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF6F00)),
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
                    if (person.age != null)
                      Text('Age: ${person.age}', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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
