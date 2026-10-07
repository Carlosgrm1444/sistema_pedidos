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
        child: LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 18,
            runSpacing: 15,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Column(
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
              ),
              ?action,
            ],
          ),
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

Color statusColor(BuildContext context, Item status) {
  final raw = status.data['color'];
  if (raw is num) return Color(raw.toInt());
  return switch (status.id) {
    'pending' => const Color(0xFFFFB547),
    'preparing' => const Color(0xFF4C8DFF),
    'shipped' => const Color(0xFF9B7BFF),
    'delivered' => const Color(0xFF36C98F),
    _ => Theme.of(context).colorScheme.primary,
  };
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
    final units = counts.values.fold<int>(0, (sum, value) => sum + value);
    final average = visible.isEmpty ? 0 : (total / visible.length).round();
    final deliveryRate = visible.isEmpty ? 0.0 : delivered / visible.length;
    final activeClients = visible.map((order) => order.text('clientId')).toSet()
      ..remove('');
    final trend = List<int>.filled(7, 0);
    final today = DateTime.now();
    for (final order in visible) {
      final created = order.date('createdAt');
      if (created == null) continue;
      final age = DateTime(
        today.year,
        today.month,
        today.day,
      ).difference(DateTime(created.year, created.month, created.day)).inDays;
      if (age >= 0 && age < trend.length) trend[trend.length - age - 1]++;
    }
    final recent = [...visible]
      ..sort(
        (a, b) => (b.date('createdAt') ?? DateTime(1970)).compareTo(
          a.date('createdAt') ?? DateTime(1970),
        ),
      );
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final productRows = bestProducts.length < 6 ? bestProducts.length : 6;
    final breakdownRows = widget.statuses.length > productRows
        ? widget.statuses.length
        : productRows;
    final breakdownHeight = 118.0 + (breakdownRows * 44.0);

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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 874),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: narrow ? double.infinity : 260,
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
                          width: narrow ? double.infinity : 260,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            key: ValueKey('$userFilter-$clientFilter'),
                            initialValue: clientFilter,
                            decoration: const InputDecoration(
                              labelText: 'Cliente',
                            ),
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
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 874),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 700;
                      final columns = compact ? 2 : 4;
                      final metricWidth =
                          (constraints.maxWidth - (14 * (columns - 1))) /
                          columns;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          _metric(
                            context,
                            'Pedidos',
                            '${visible.length}',
                            Icons.receipt_long_outlined,
                            width: metricWidth,
                          ),
                          _metric(
                            context,
                            'Entregados',
                            '$delivered',
                            Icons.check_circle_outline,
                            width: metricWidth,
                          ),
                          _metric(
                            context,
                            'Pendientes',
                            '${visible.length - delivered}',
                            Icons.schedule,
                            width: metricWidth,
                          ),
                          _metric(
                            context,
                            'Importe total',
                            money(total),
                            Icons.payments_outlined,
                            width: metricWidth,
                          ),
                          _metric(
                            context,
                            'Promedio por pedido',
                            money(average),
                            Icons.stacked_line_chart_rounded,
                            width: metricWidth,
                          ),
                          _metric(
                            context,
                            'Tasa de entrega',
                            '${(deliveryRate * 100).round()}%',
                            Icons.speed_rounded,
                            width: metricWidth,
                          ),
                          _metric(
                            context,
                            'Clientes activos',
                            '${activeClients.length}',
                            Icons.groups_outlined,
                            width: metricWidth,
                          ),
                          _metric(
                            context,
                            'Unidades solicitadas',
                            '$units',
                            Icons.inventory_2_outlined,
                            width: metricWidth,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 874),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: narrow ? double.infinity : 430,
                        height: narrow ? null : 316,
                        child: PolishedCard(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Actividad de los últimos 7 días',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${visible.length} pedidos en el periodo seleccionado',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 142,
                                  child: CustomPaint(
                                    key: const ValueKey('orders-trend-chart'),
                                    painter: _TrendPainter(
                                      values: trend,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      gridColor: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(
                                    7,
                                    (index) => Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: index == 0
                                            ? Alignment.centerLeft
                                            : index == 6
                                            ? Alignment.centerRight
                                            : Alignment.center,
                                        child: Text(
                                          _dayLabel(
                                            today.subtract(
                                              Duration(days: 6 - index),
                                            ),
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: narrow ? double.infinity : 430,
                        height: narrow ? null : 316,
                        child: PolishedCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salud del flujo',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 18),
                                if (!narrow) const Spacer(),
                                Row(
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: deliveryRate),
                                      duration: motionDuration(context, 700),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, progress, _) => SizedBox(
                                        width: narrow ? 112 : 132,
                                        height: narrow ? 112 : 132,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox.expand(
                                              child: CircularProgressIndicator(
                                                value: progress,
                                                strokeWidth: narrow ? 12 : 14,
                                                strokeCap: StrokeCap.round,
                                                backgroundColor: Theme.of(
                                                  context,
                                                ).colorScheme.outlineVariant,
                                              ),
                                            ),
                                            Text(
                                              '${(progress * 100).round()}%',
                                              style:
                                                  (narrow
                                                          ? Theme.of(context)
                                                                .textTheme
                                                                .titleMedium
                                                          : Theme.of(context)
                                                                .textTheme
                                                                .headlineSmall)
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: -0.5,
                                                      ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: narrow ? 16 : 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$delivered de ${visible.length}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            delivered == 0
                                                ? 'Aún no hay pedidos entregados.'
                                                : 'Pedidos completados correctamente.',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (!narrow) const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 874),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: narrow ? double.infinity : 430,
                        height: narrow ? null : breakdownHeight,
                        child: PolishedCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pedidos por estado',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                        width: narrow ? double.infinity : 430,
                        height: narrow ? null : breakdownHeight,
                        child: PolishedCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Productos más solicitados',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 874),
                  child: PolishedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actividad reciente',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          if (recent.isEmpty)
                            const Text(
                              'Los pedidos recientes aparecerán aquí.',
                            ),
                          for (final order in recent.take(4))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.12),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                itemName(
                                  widget.clients,
                                  order.text('clientId'),
                                ),
                              ),
                              subtitle: Text(
                                '${itemName(widget.statuses, order.text('statusId'))} · ${orderLines(order).length} productos',
                              ),
                              trailing: Text(
                                money(order.number('totalCents')),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
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
    IconData icon, {
    required double width,
  }) => SizedBox(
    width: width,
    child: PolishedCard(
      child: Padding(
        padding: EdgeInsets.all(width < 180 ? 13 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: width < 180 ? 32 : 36,
              height: width < 180 ? 32 : 36,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: width < 180 ? 18 : 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: motionDuration(context, 230),
              child: Text(
                value,
                key: ValueKey(value),
                style:
                    (width < 180
                            ? Theme.of(context).textTheme.titleLarge
                            : Theme.of(context).textTheme.headlineSmall)
                        ?.copyWith(
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

String _dayLabel(DateTime date) => '${date.day}/${date.month}';

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });
  final List<int> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var row = 1; row < 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    final maxValue = values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    final max = maxValue == 0 ? 1 : maxValue;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final y = size.height - (values[index] / max) * (size.height - 14) - 7;
      points.add(Offset(x, y));
    }
    final area = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      area.lineTo(point.dx, point.dy);
    }
    area.lineTo(points.last.dx, size.height);
    area.close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.12));
    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final chartLine = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      chartLine.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(chartLine, line);
    final dot = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
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
    var selectedColor = item?.data['color'] is num
        ? (item!.data['color'] as num).toInt()
        : 0xFF4C8DFF;
    const palette = [
      0xFFFFB547,
      0xFF4C8DFF,
      0xFF9B7BFF,
      0xFF36C98F,
      0xFFEF6C78,
      0xFF22B8CF,
    ];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(item == null ? 'Nuevo estado' : 'Editar estado'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 18),
                const Text('Color del estado'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final color in palette)
                      InkWell(
                        onTap: () => update(() => selectedColor = color),
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: motionDuration(context, 180),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == color
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: selectedColor == color
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
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
                      color: selectedColor,
                    );
                  } else {
                    await Store.instance.saveStatus(
                      item.id,
                      name.text,
                      color: selectedColor,
                    );
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
                  backgroundColor: statusColor(
                    context,
                    statuses[index],
                  ).withValues(alpha: 0.16),
                  foregroundColor: statusColor(context, statuses[index]),
                  child: Text('${index + 1}'),
                ),
                title: Text(statuses[index].text('name')),
                subtitle: Text(
                  '${statuses[index].id == 'delivered' ? 'Entrega final · ' : ''}Ponderación ${statuses[index].number('rank')}',
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

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
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
  String statusFilter = '';

  Widget _statusFilterField(BuildContext context) => SizedBox(
    width: 250,
    child: DropdownButtonFormField<String>(
      isExpanded: true,
      key: ValueKey('status-$statusFilter-${widget.statuses.length}'),
      initialValue: statusFilter,
      decoration: const InputDecoration(labelText: 'Estado'),
      items: [
        const DropdownMenuItem(value: '', child: Text('Todos')),
        for (final status in widget.statuses)
          DropdownMenuItem(
            value: status.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusDot(color: statusColor(context, status)),
                const SizedBox(width: 8),
                Text(status.text('name')),
              ],
            ),
          ),
      ],
      onChanged: (value) => setState(() => statusFilter = value ?? ''),
    ),
  );

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
              (clientFilter.isEmpty ||
                  order.text('clientId') == clientFilter) &&
              (statusFilter.isEmpty || order.text('statusId') == statusFilter),
        )
        .toList();
    final statusColors = {
      for (final status in widget.statuses)
        status.id: statusColor(context, status),
    };
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
                    _statusFilterField(context),
                  ],
                ),
              ),
            if (!widget.admin)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _statusFilterField(context),
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
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color:
                            statusColors[order.text('statusId')] ??
                            Theme.of(context).colorScheme.primary,
                        width: 5,
                      ),
                    ),
                  ),
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                              Chip(
                                backgroundColor: statusColors['delivered']
                                    ?.withValues(alpha: 0.16),
                                label: const Text('Entregado'),
                                avatar: Icon(
                                  Icons.check_circle_outline,
                                  color: statusColors['delivered'],
                                ),
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
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _StatusDot(
                                            color: statusColors[status.id]!,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(status.text('name')),
                                        ],
                                      ),
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
