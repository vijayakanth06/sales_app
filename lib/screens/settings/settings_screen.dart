import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(languageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Products Section
          _SettingsSection(
            title: l10n.labelProducts,
            icon: Icons.inventory_2,
            child: _ProductsSection(),
          ),
          const SizedBox(height: 12),

          // Language Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, size: 28),
              title: Text(l10n.labelLanguage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              subtitle: Text(lang == 'ta' ? 'தமிழ்' : 'English'),
              trailing: Switch(
                value: lang == 'en',
                onChanged: (v) {
                  ref.read(languageProvider.notifier).state = v ? 'en' : 'ta';
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // App Info
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, size: 28),
              title: Text(l10n.labelAppInfo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              subtitle: const Text('v1.0.0 • Supabase Connected'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SettingsSection({required this.title, required this.icon, required this.child});

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(widget.icon, size: 28),
            title: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) widget.child,
        ],
      ),
    );
  }
}

class _ProductsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final products = ref.watch(productsProvider);

    return products.when(
      data: (productList) => Column(
        children: [
          ...productList.map((p) => ListTile(
            title: Text(p.name, style: const TextStyle(fontSize: 16)),
            subtitle: Text('Sell: ₹${p.sellingPrice.toStringAsFixed(0)} | Cost: ₹${p.costPrice.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditProductDialog(context, ref, p),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 20, color: Colors.red[400]),
                  onPressed: () => _confirmDeleteProduct(context, ref, p),
                ),
              ],
            ),
          )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showAddProductDialog(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.btnAddProduct),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ),
        ],
      ),
      loading: () => const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
      error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e')),
    );
  }

  void _confirmDeleteProduct(BuildContext context, WidgetRef ref, Product product) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.msgConfirmDelete),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.btnCancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService().deleteProduct(product.id);
              ref.invalidate(productsProvider);
            },
            child: Text(l10n.btnDelete, style: const TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final sellingPriceController = TextEditingController();
    final costPriceController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.btnAddProduct, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: '${l10n.labelProductName} *', border: const OutlineInputBorder()),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(
                  controller: sellingPriceController,
                  decoration: InputDecoration(labelText: l10n.labelSellingPrice, border: const OutlineInputBorder(), prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextField(
                  controller: costPriceController,
                  decoration: InputDecoration(labelText: l10n.labelCostPrice, border: const OutlineInputBorder(), prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18),
                )),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final sell = double.tryParse(sellingPriceController.text);
                  final cost = double.tryParse(costPriceController.text);
                  if (name.isEmpty || sell == null || cost == null || sell <= 0 || cost <= 0) return;
                  await SupabaseService().saveProduct(Product(id: '', name: name, sellingPrice: sell, costPrice: cost));
                  ref.invalidate(productsProvider);
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

  void _showEditProductDialog(BuildContext context, WidgetRef ref, Product product) {
    final nameController = TextEditingController(text: product.name);
    final sellingPriceController = TextEditingController(text: product.sellingPrice.toStringAsFixed(0));
    final costPriceController = TextEditingController(text: product.costPrice.toStringAsFixed(0));
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.btnEdit, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.labelProductName, border: const OutlineInputBorder()),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(
                  controller: sellingPriceController,
                  decoration: InputDecoration(labelText: l10n.labelSellingPrice, border: const OutlineInputBorder(), prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextField(
                  controller: costPriceController,
                  decoration: InputDecoration(labelText: l10n.labelCostPrice, border: const OutlineInputBorder(), prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18),
                )),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final sell = double.tryParse(sellingPriceController.text);
                  final cost = double.tryParse(costPriceController.text);
                  if (name.isEmpty || sell == null || cost == null) return;
                  await SupabaseService().saveProduct(Product(
                    id: product.id, name: name,
                    sellingPrice: sell, costPrice: cost,
                    active: product.active,
                  ));
                  ref.invalidate(productsProvider);
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
