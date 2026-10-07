import 'package:flutter/material.dart';

import 'data.dart';
import 'design.dart';
import 'feedback.dart';

void showProblem(BuildContext context, Object error) {
  AppFeedback.instance.error();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(error.toString())),
        ],
      ),
    ),
  );
}

Future<void> saveAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    AppFeedback.instance.success();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Cambios guardados'),
            ],
          ),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) showProblem(context, error);
  }
}

Widget panelHeader(String title, String subtitle, {Widget? action}) => Builder(
  builder: (context) {
    final theme = Theme.of(context);
    return MotionReveal(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
        child: Wrap(
          spacing: 18,
          runSpacing: 15,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESPACIO DE TRABAJO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            ?action,
          ],
        ),
      ),
    );
  },
);

String itemName(List<Item> items, String id) {
  for (final item in items) {
    if (item.id == id) return item.text('name');
  }
  return 'Sin asignar';
}

class OverviewPanel extends StatefulWidget {
  const OverviewPanel({
    required this.orders,
    required this.products,
    required this.clients,
    required this.statuses,
    required this.users,
    required this.admin,
    super.key,
  });
  final List<Item> orders, products, clients, statuses, users;
  final bool admin;
  @override
  State<OverviewPanel> createState() => _OverviewPanelState();
}

class _OverviewPanelState extends State<OverviewPanel> {
  String userFilter = '';
  String clientFilter = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.orders
        .where(
          (order) =>
              (userFilter.isEmpty || order.text('assignedUid') == userFilter) &&
              (clientFilter.isEmpty || order.text('clientId') == clientFilter),
        )
        .toList();
    final total = visible.fold<int>(
      0,
      (sum, order) => sum + order.number('totalCents'),
    );
    final delivered = visible
        .where((order) => order.text('statusId') == 'delivered')
        .length;
    final counts = <String, int>{};
    for (final order in visible) {
      for (final line in orderLines(order)) {
        counts.update(
          line.name,
          (value) => value + line.quantity,
          ifAbsent: () => line.quantity,
        );
      }
    }
    final bestProducts = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxProduct = bestProducts.isEmpty ? 1 : bestProducts.first.value;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: ListView(
          children: [
            panelHeader(
              'Indicadores',
              'Información real de los pedidos registrados.',
            ),
            if (widget.admin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: userFilter,
                        decoration: const InputDecoration(
                          labelText: 'Colaborador',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Todos'),
                          ),
                          for (final user in widget.users.where(
                            (u) => u.text('role') == 'collaborator',
                          ))
                            DropdownMenuItem(
                              value: user.id,
                              child: Text(user.text('name')),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          userFilter = value ?? '';
                          clientFilter = '';
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        key: ValueKey('$userFilter-$clientFilter'),
                        initialValue: clientFilter,
                        decoration: const InputDecoration(labelText: 'Cliente'),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Todos'),
                          ),
                          for (final client in widget.clients.where(
                            (c) =>
                                userFilter.isEmpty ||
                                c.text('assignedUid') == userFilter,
                          ))
                            DropdownMenuItem(
                              value: client.id,
                              child: Text(client.text('name')),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => clientFilter = value ?? ''),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _metric(
                    context,
                    'Pedidos',
                    '${visible.length}',
                    Icons.receipt_long_outlined,
                  ),
                  _metric(
                    context,
                    'Entregados',
                    '$delivered',
                    Icons.check_circle_outline,
                  ),
                  _metric(
                    context,
                    'Pendientes',
                    '${visible.length - delivered}',
                    Icons.schedule,
                  ),
                  _metric(
                    context,
                    'Importe total',
                    money(total),
                    Icons.payments_outlined,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 430,
                    child: PolishedCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedidos por estado',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            if (widget.statuses.isEmpty)
                              const Text('Aún no hay estados.'),
                            for (final status in widget.statuses) ...[
                              Text(
                                '${status.text('name')} · ${visible.where((o) => o.text('statusId') == status.id).length}',
                              ),
                              const SizedBox(height: 5),
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: visible.isEmpty
                                      ? 0
                                      : visible
                                                .where(
                                                  (o) =>
                                                      o.text('statusId') ==
                                                      status.id,
                                                )
                                                .length /
                                            visible.length,
                                ),
                                duration: motionDuration(context, 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, progress, _) =>
                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 7,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 430,
                    child: PolishedCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Productos más solicitados',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            if (bestProducts.isEmpty)
                              const Text('Aún no hay datos.'),
                            for (final product in bestProducts.take(6)) ...[
                              Text(
                                '${product.key} · ${product.value} unidades',
                              ),
                              const SizedBox(height: 5),
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: product.value / maxProduct,
                                ),
                                duration: motionDuration(context, 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, progress, _) =>
                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 7,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) => SizedBox(
    width: 225,
    child: PolishedCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: motionDuration(context, 230),
              child: Text(
                value,
                key: ValueKey(value),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CategoriesPanel extends StatelessWidget {
  const CategoriesPanel({required this.categories, super.key});
  final List<Item> categories;

  Future<void> _edit(BuildContext context, [Item? item]) async {
    final controller = TextEditingController(text: item?.text('name') ?? '');
    var active = item?.active ?? true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(item == null ? 'Nueva categoría' : 'Editar categoría'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                SwitchListTile(
                  title: const Text('Activa'),
                  value: active,
                  onChanged: (value) => update(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                try {
                  await Store.instance.saveCategory(
                    id: item?.id,
                    name: controller.text,
                    active: active,
                  );
                  AppFeedback.instance.success();
                  if (context.mounted) Navigator.pop(context);
                } catch (error) {
                  if (context.mounted) showProblem(context, error);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: ListView(
        children: [
          panelHeader(
            'Categorías',
            'Cada categoría se asigna al producto.',
            action: FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add),
              label: const Text('Nueva categoría'),
            ),
          ),
          if (categories.isEmpty)
            const EmptyState(
              icon: Icons.category_outlined,
              title: 'Sin categorías todavía',
              message:
                  'Crea la primera categoría para organizar tus productos.',
            ),
          for (final item in categories)
            PolishedCard(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: ListTile(
                leading: const CatalogIcon(Icons.category_outlined),
                title: Text(item.text('name')),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ActiveBadge(item.active),
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(context, item),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class ProductsPanel extends StatelessWidget {
  const ProductsPanel({
    required this.products,
    required this.categories,
    super.key,
  });
  final List<Item> products, categories;

  Future<void> _edit(BuildContext context, [Item? item]) async {
    final name = TextEditingController(text: item?.text('name') ?? '');
    final price = TextEditingController(
      text: item == null
          ? ''
          : (item.number('priceCents') / 100).toStringAsFixed(2),
    );
    var categoryId = item?.text('categoryId') ?? '';
    var active = item?.active ?? true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(item == null ? 'Nuevo producto' : 'Editar producto'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: categoryId.isEmpty ? null : categoryId,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      for (final category in categories.where(
                        (c) => c.active || c.id == categoryId,
                      ))
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.text('name')),
                        ),
                    ],
                    onChanged: (value) =>
                        update(() => categoryId = value ?? ''),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$',
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Activo'),
                    value: active,
                    onChanged: (value) => update(() => active = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final cents = parsePrice(price.text);
                if (name.text.trim().isEmpty ||
                    categoryId.isEmpty ||
                    cents == null) {
                  showProblem(
                    context,
                    'Completa nombre, categoría y precio válido.',
                  );
                  return;
                }
                try {
                  await Store.instance.saveProduct(
                    id: item?.id,
                    name: name.text,
                    categoryId: categoryId,
                    priceCents: cents,
                    active: active,
                  );
                  AppFeedback.instance.success();
                  if (context.mounted) Navigator.pop(context);
                } catch (error) {
                  if (context.mounted) showProblem(context, error);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    price.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: ListView(
        children: [
          panelHeader(
            'Productos',
            'Precio y categoría pertenecen al catálogo de productos.',
            action: FilledButton.icon(
              onPressed: categories.isEmpty ? null : () => _edit(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo producto'),
            ),
          ),
          if (categories.isEmpty)
            const EmptyState(
              icon: Icons.category_outlined,
              title: 'Primero crea una categoría',
              message: 'Los productos necesitan una categoría activa.',
            ),
          if (products.isEmpty && categories.isNotEmpty)
            const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Sin productos todavía',
              message: 'Añade productos con su precio para crear pedidos.',
            ),
          for (final item in products)
            PolishedCard(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: ListTile(
                leading: const CatalogIcon(Icons.inventory_2_outlined),
                title: Text(item.text('name')),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(itemName(categories, item.text('categoryId'))),
                      ActiveBadge(item.active),
                    ],
                  ),
                ),
                trailing: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      money(item.number('priceCents')),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(context, item),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class ClientsPanel extends StatelessWidget {
  const ClientsPanel({required this.clients, required this.users, super.key});
  final List<Item> clients, users;

  Future<void> _edit(BuildContext context, [Item? item]) async {
    final name = TextEditingController(text: item?.text('name') ?? '');
    var assignedUid = item?.text('assignedUid') ?? '';
    var active = item?.active ?? true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(item == null ? 'Nuevo cliente' : 'Editar cliente'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del cliente',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: assignedUid,
                  decoration: const InputDecoration(
                    labelText: 'Asignar a colaborador',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Sin asignar'),
                    ),
                    for (final user in users.where(
                      (u) => u.text('role') == 'collaborator',
                    ))
                      DropdownMenuItem(
                        value: user.id,
                        child: Text(user.text('name')),
                      ),
                  ],
                  onChanged: (value) => update(() => assignedUid = value ?? ''),
                ),
                SwitchListTile(
                  title: const Text('Activo'),
                  value: active,
                  onChanged: (value) => update(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  showProblem(context, 'Escribe el nombre.');
                  return;
                }
                try {
                  await Store.instance.saveClient(
                    id: item?.id,
                    name: name.text,
                    assignedUid: assignedUid,
                    active: active,
                  );
                  AppFeedback.instance.success();
                  if (context.mounted) Navigator.pop(context);
                } catch (error) {
                  if (context.mounted) showProblem(context, error);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: ListView(
        children: [
          panelHeader(
            'Clientes',
            'Solo el administrador puede dar de alta y asignar clientes.',
            action: FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo cliente'),
            ),
          ),
          if (clients.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Sin clientes todavía',
              message: 'Registra un cliente y asígnalo a un colaborador.',
            ),
          for (final item in clients)
            PolishedCard(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: ListTile(
                leading: const CatalogIcon(Icons.groups_outlined),
                title: Text(item.text('name')),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(itemName(users, item.text('assignedUid'))),
                      ActiveBadge(item.active),
                    ],
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(context, item),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class StatusesPanel extends StatelessWidget {
  const StatusesPanel({required this.statuses, super.key});
  final List<Item> statuses;

  Future<void> _edit(BuildContext context, [Item? item]) async {
    final name = TextEditingController(text: item?.text('name') ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item == null ? 'Nuevo estado' : 'Editar estado'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              try {
                if (item == null) {
                  await Store.instance.addStatus(
                    name.text,
                    (statuses.lastOrNull?.number('rank') ?? 0) + 10,
                  );
                } else {
                  await Store.instance.saveStatus(item.id, name.text);
                }
                AppFeedback.instance.success();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (error) {
                if (dialogContext.mounted) showProblem(dialogContext, error);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    name.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: ListView(
        children: [
          panelHeader(
            'Estados',
            'La ponderación determina el orden de avance del pedido.',
            action: FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo estado'),
            ),
          ),
          for (var index = 0; index < statuses.length; index++)
            PolishedCard(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.10),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  child: Text('${index + 1}'),
                ),
                title: Text(statuses[index].text('name')),
                subtitle: Text(
                  statuses[index].id == 'delivered'
                      ? 'Entrega final: solo administrador'
                      : 'Ponderación ${statuses[index].number('rank')}',
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Subir',
                      onPressed: index == 0
                          ? null
                          : () => saveAction(
                              context,
                              () => Store.instance.swapStatusRank(
                                statuses[index],
                                statuses[index - 1],
                              ),
                            ),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: 'Bajar',
                      onPressed: index == statuses.length - 1
                          ? null
                          : () => saveAction(
                              context,
                              () => Store.instance.swapStatusRank(
                                statuses[index],
                                statuses[index + 1],
                              ),
                            ),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: () => _edit(context, statuses[index]),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class UsersPanel extends StatelessWidget {
  const UsersPanel({required this.users, required this.currentUid, super.key});
  final List<Item> users;
  final String currentUid;

  static int _nameOrder(Item a, Item b) =>
      a.text('name').toLowerCase().compareTo(b.text('name').toLowerCase());

  Widget _sectionLabel(BuildContext context, String title, int count) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 10),
            Chip(
              label: Text('$count'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      );

  Widget _permissionField(BuildContext context, Item user) =>
      DropdownButtonFormField<String>(
        isExpanded: true,
        key: ValueKey('${user.id}-${user.text('role')}'),
        initialValue: user.text('role'),
        decoration: const InputDecoration(labelText: 'Permiso', isDense: true),
        items: const [
          DropdownMenuItem(value: 'pending', child: Text('Sin permiso')),
          DropdownMenuItem(value: 'collaborator', child: Text('Colaborador')),
          DropdownMenuItem(value: 'admin', child: Text('Administrador')),
        ],
        onChanged: user.id == currentUid
            ? null
            : (role) {
                if (role != null) {
                  saveAction(
                    context,
                    () => Store.instance.setRole(user.id, role),
                  );
                }
              },
      );

  Widget _userIdentity(BuildContext context, Item user) => Row(
    children: [
      CircleAvatar(
        child: Text(
          user.text('name').isEmpty ? 'U' : user.text('name')[0].toUpperCase(),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.text('name'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(
              user.text('email'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _userCard(BuildContext context, Item user) => PolishedCard(
    margin: const EdgeInsets.fromLTRB(20, 5, 20, 5),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 560;
        return Padding(
          padding: const EdgeInsets.all(14),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _userIdentity(context, user),
                    const SizedBox(height: 14),
                    _permissionField(context, user),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _userIdentity(context, user)),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 175,
                      child: _permissionField(context, user),
                    ),
                  ],
                ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: ListView(
        children: [
          panelHeader(
            'Usuarios',
            'Al ingresar por primera vez quedan sin permisos.',
          ),
          if (users.isEmpty)
            const EmptyState(
              icon: Icons.person_add_alt_outlined,
              title: 'Sin usuarios todavía',
              message: 'Los integrantes aparecerán aquí al iniciar sesión.',
            ),
          ..._sections(context),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );

  List<Widget> _sections(BuildContext context) {
    final pending =
        users.where((user) => user.text('role') == 'pending').toList()
          ..sort(_nameOrder);
    final permitted =
        users.where((user) => user.text('role') != 'pending').toList()
          ..sort((a, b) {
            final roleA = a.text('role') == 'admin' ? 0 : 1;
            final roleB = b.text('role') == 'admin' ? 0 : 1;
            return roleA == roleB ? _nameOrder(a, b) : roleA.compareTo(roleB);
          });
    return [
      if (pending.isNotEmpty) ...[
        _sectionLabel(context, 'Sin permisos asignados', pending.length),
        for (final user in pending) _userCard(context, user),
      ],
      if (permitted.isNotEmpty) ...[
        if (pending.isNotEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Divider(),
          ),
        _sectionLabel(context, 'Usuarios con permisos', permitted.length),
        for (final user in permitted) _userCard(context, user),
      ],
    ];
  }
}

class OrdersPanel extends StatefulWidget {
  const OrdersPanel({
    required this.orders,
    required this.products,
    required this.categories,
    required this.clients,
    required this.statuses,
    required this.admin,
    required this.users,
    super.key,
  });
  final List<Item> orders, products, categories, clients, statuses, users;
  final bool admin;
  @override
  State<OrdersPanel> createState() => _OrdersPanelState();
}

class _OrdersPanelState extends State<OrdersPanel> {
  String userFilter = '';
  String clientFilter = '';

  Future<void> _confirmDelivery(Item order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar entrega'),
        content: Text(
          '¿Confirmas que el pedido de ${order.text('clientName')} fue entregado? '
          'Esta acción registrará tu usuario y la fecha de entrega.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar entrega'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await saveAction(context, () => Store.instance.deliverOrder(order.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCategoryIds = widget.categories
        .where((category) => category.active)
        .map((category) => category.id)
        .toSet();
    final canCreate =
        widget.clients.any((client) => client.active) &&
        widget.products.any(
          (product) =>
              product.active &&
              activeCategoryIds.contains(product.text('categoryId')),
        ) &&
        widget.statuses.any((status) => status.id != 'delivered');
    final visible = widget.orders
        .where(
          (order) =>
              (userFilter.isEmpty || order.text('assignedUid') == userFilter) &&
              (clientFilter.isEmpty || order.text('clientId') == clientFilter),
        )
        .toList();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: ListView(
          children: [
            panelHeader(
              'Pedidos',
              'Selecciona clientes y productos de los catálogos.',
              action: FilledButton.icon(
                onPressed: !canCreate
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (context) => OrderEditor(
                          products: widget.products,
                          categories: widget.categories,
                          clients: widget.clients,
                          statuses: widget.statuses,
                        ),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo pedido'),
              ),
            ),
            if (widget.admin)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: userFilter,
                        decoration: const InputDecoration(
                          labelText: 'Colaborador',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Todos'),
                          ),
                          for (final user in widget.users.where(
                            (u) => u.text('role') == 'collaborator',
                          ))
                            DropdownMenuItem(
                              value: user.id,
                              child: Text(user.text('name')),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          userFilter = value ?? '';
                          clientFilter = '';
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        key: ValueKey('$userFilter-$clientFilter'),
                        initialValue: clientFilter,
                        decoration: const InputDecoration(labelText: 'Cliente'),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Todos'),
                          ),
                          for (final client in widget.clients.where(
                            (c) =>
                                userFilter.isEmpty ||
                                c.text('assignedUid') == userFilter,
                          ))
                            DropdownMenuItem(
                              value: client.id,
                              child: Text(client.text('name')),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => clientFilter = value ?? ''),
                      ),
                    ),
                  ],
                ),
              ),
            if (visible.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Sin pedidos para mostrar',
                message: widget.clients.isEmpty
                    ? 'Primero registra o asigna un cliente.'
                    : 'Cuando crees un pedido, aparecerá aquí.',
              ),
            for (final order in visible)
              PolishedCard(
                margin: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.text('clientName'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Creado ${_date(order.date('createdAt'))} · '
                                '${itemName(widget.users, order.text('assignedUid'))}',
                              ),
                            ],
                          ),
                          Text(
                            money(order.number('totalCents')),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (order.text('statusId') == 'delivered')
                            const Chip(
                              label: Text('Entregado'),
                              avatar: Icon(Icons.check_circle_outline),
                            )
                          else
                            DropdownButton<String>(
                              value:
                                  widget.statuses.any(
                                    (s) => s.id == order.text('statusId'),
                                  )
                                  ? order.text('statusId')
                                  : null,
                              hint: const Text('Estado'),
                              items: [
                                for (final status in widget.statuses.where(
                                  (s) => s.id != 'delivered',
                                ))
                                  DropdownMenuItem(
                                    value: status.id,
                                    child: Text(status.text('name')),
                                  ),
                              ],
                              onChanged: (statusId) {
                                if (statusId != null) {
                                  saveAction(
                                    context,
                                    () => Store.instance.setOrderStatus(
                                      order.id,
                                      statusId,
                                    ),
                                  );
                                }
                              },
                            ),
                          if (widget.admin &&
                              order.text('statusId') != 'delivered')
                            FilledButton.icon(
                              onPressed: () => _confirmDelivery(order),
                              icon: const Icon(Icons.verified_outlined),
                              label: const Text('Confirmar entrega'),
                            ),
                          if (order.date('deliveredAt') != null)
                            Text(
                              'Entregado ${_date(order.date('deliveredAt'))}',
                            ),
                        ],
                      ),
                      ExpansionTile(
                        title: Text('${orderLines(order).length} productos'),
                        tilePadding: EdgeInsets.zero,
                        children: [
                          for (final line in orderLines(order))
                            ListTile(
                              dense: true,
                              title: Text('${line.quantity} × ${line.name}'),
                              subtitle: Text(
                                '${line.categoryName} · ${money(line.unitPriceCents)} c/u',
                              ),
                              trailing: Text(money(line.subtotalCents)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _date(DateTime? date) => date == null
      ? 'hoy'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class OrderEditor extends StatefulWidget {
  const OrderEditor({
    required this.products,
    required this.categories,
    required this.clients,
    required this.statuses,
    super.key,
  });
  final List<Item> products, categories, clients, statuses;
  @override
  State<OrderEditor> createState() => _OrderEditorState();
}

class _OrderEditorState extends State<OrderEditor> {
  String? clientId;
  String? productId;
  final quantity = TextEditingController(text: '1');
  final List<OrderLine> lines = [];
  bool saving = false;

  @override
  void dispose() {
    quantity.dispose();
    super.dispose();
  }

  void _addLine() {
    final count = int.tryParse(quantity.text);
    if (productId == null || count == null || count < 1) {
      showProblem(
        context,
        'Selecciona un producto y una cantidad mayor que cero.',
      );
      return;
    }
    final product = widget.products.firstWhere((item) => item.id == productId);
    setState(() {
      lines.add(
        OrderLine(
          productId: product.id,
          name: product.text('name'),
          categoryName: itemName(widget.categories, product.text('categoryId')),
          unitPriceCents: product.number('priceCents'),
          quantity: count,
        ),
      );
      productId = null;
      quantity.text = '1';
    });
    AppFeedback.instance.select();
  }

  Future<void> _save() async {
    if (clientId == null || lines.isEmpty) {
      showProblem(context, 'Selecciona un cliente y agrega productos.');
      return;
    }
    final client = widget.clients.firstWhere((item) => item.id == clientId);
    setState(() => saving = true);
    try {
      await Store.instance.createOrder(
        client: client,
        lines: lines,
        statusId: widget.statuses.any((s) => s.id == 'pending')
            ? 'pending'
            : widget.statuses.firstWhere((s) => s.id != 'delivered').id,
      );
      AppFeedback.instance.success();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showProblem(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeClients = widget.clients.where((item) => item.active).toList();
    final activeProducts = widget.products
        .where(
          (item) =>
              item.active &&
              widget.categories.any(
                (category) =>
                    category.id == item.text('categoryId') && category.active,
              ),
        )
        .toList();
    final total = lines.fold<int>(0, (sum, line) => sum + line.subtotalCents);
    final selectedProduct = widget.products
        .where((p) => p.id == productId)
        .firstOrNull;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 590,
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Nuevo pedido',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: clientId,
                decoration: const InputDecoration(labelText: 'Cliente'),
                items: [
                  for (final client in activeClients)
                    DropdownMenuItem(
                      value: client.id,
                      child: Text(client.text('name')),
                    ),
                ],
                onChanged: (value) => setState(() => clientId = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey(productId),
                initialValue: productId,
                decoration: const InputDecoration(labelText: 'Producto'),
                items: [
                  for (final product in activeProducts)
                    DropdownMenuItem(
                      value: product.id,
                      child: Text(
                        '${product.text('name')} · ${money(product.number('priceCents'))}',
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => productId = value),
              ),
              if (selectedProduct != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Categoría: ${itemName(widget.categories, selectedProduct.text('categoryId'))}',
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add),
                label: const Text('Agregar producto'),
              ),
              const SizedBox(height: 18),
              for (var index = 0; index < lines.length; index++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${lines[index].quantity} × ${lines[index].name}',
                  ),
                  subtitle: Text(lines[index].categoryName),
                  trailing: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(money(lines[index].subtotalCents)),
                      IconButton(
                        tooltip: 'Quitar',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => lines.removeAt(index));
                          AppFeedback.instance.select();
                        },
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Text(
                'Total: ${money(total)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed:
                        saving ||
                            widget.statuses
                                .where((s) => s.id != 'delivered')
                                .isEmpty
                        ? null
                        : _save,
                    child: Text(saving ? 'Guardando…' : 'Guardar pedido'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
