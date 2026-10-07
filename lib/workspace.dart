import 'dart:async';

import 'package:flutter/material.dart';

import 'data.dart';
import 'design.dart';
import 'feedback.dart';
import 'panels.dart';

class Workspace extends StatefulWidget {
  const Workspace({
    required this.profile,
    required this.mode,
    required this.onToggleTheme,
    super.key,
  });
  final Item profile;
  final ThemeMode mode;
  final VoidCallback onToggleTheme;

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  final List<StreamSubscription<List<Item>>> _subscriptions = [];
  List<Item> categories = [];
  List<Item> products = [];
  List<Item> clients = [];
  List<Item> statuses = [];
  List<Item> orders = [];
  List<Item> users = [];
  String? error;
  int section = 0;
  bool initialLoading = true;

  bool get admin => widget.profile.text('role') == 'admin';

  @override
  void initState() {
    super.initState();
    final store = Store.instance;
    void bind(Stream<List<Item>> stream, void Function(List<Item>) set) {
      _subscriptions.add(
        stream.listen(
          (items) {
            if (mounted) {
              setState(() {
                set(items);
                initialLoading = false;
              });
            }
          },
          onError: (Object problem) {
            if (mounted) {
              setState(() {
                error = problem.toString();
                initialLoading = false;
              });
            }
          },
        ),
      );
    }

    bind(store.watchCategories(), (value) => categories = value);
    bind(store.watchProducts(), (value) => products = value);
    bind(
      store.watchClients(admin: admin, uid: widget.profile.id),
      (value) => clients = value,
    );
    bind(store.watchStatuses(), (value) => statuses = value);
    bind(
      store.watchOrders(admin: admin, uid: widget.profile.id),
      (value) => orders = value,
    );
    if (admin) bind(store.watchUsers(), (value) => users = value);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = <({String label, IconData icon})>[
      (label: 'Resumen', icon: Icons.space_dashboard_outlined),
      (label: 'Pedidos', icon: Icons.receipt_long_outlined),
      (label: 'Productos', icon: Icons.inventory_2_outlined),
      (label: 'Categorías', icon: Icons.category_outlined),
      if (admin) (label: 'Clientes', icon: Icons.groups_outlined),
      if (admin) (label: 'Estados', icon: Icons.low_priority_outlined),
      if (admin) (label: 'Usuarios', icon: Icons.admin_panel_settings_outlined),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final compactRail = MediaQuery.sizeOf(context).width < 1180;
    final theme = Theme.of(context);

    void selectSection(int index, {bool fromDrawer = false}) {
      if (section != index) {
        AppFeedback.instance.select();
        setState(() => section = index);
      }
      if (fromDrawer) Navigator.pop(context);
    }

    Widget navigation({
      required bool compact,
      bool drawer = false,
    }) => Container(
      width: compact ? 88 : 226,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 13 : 20,
                23,
                compact ? 13 : 20,
                22,
              ),
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/brand/mark.png',
                    width: compact ? 42 : 45,
                    height: compact ? 42 : 45,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PEDIDOS',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'Espacio de trabajo',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: sections.length,
                itemBuilder: (context, index) => _NavigationItem(
                  icon: sections[index].icon,
                  label: sections[index].label,
                  selected: section == index,
                  compact: compact,
                  onTap: () => selectSection(index, fromDrawer: drawer),
                ),
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Padding(
              padding: EdgeInsets.all(compact ? 12 : 18),
              child: compact
                  ? Tooltip(
                      message: widget.profile.text('name'),
                      child: CircleAvatar(
                        child: Text(
                          widget.profile.text('name').isEmpty
                              ? 'U'
                              : widget.profile.text('name')[0].toUpperCase(),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          child: Text(
                            widget.profile.text('name').isEmpty
                                ? 'U'
                                : widget.profile.text('name')[0].toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.profile.text('name'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                admin ? 'Administrador' : 'Colaborador',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (drawer)
                          IconButton(
                            tooltip: 'Cerrar sesión',
                            onPressed: () => Store.instance.auth.signOut(),
                            icon: const Icon(Icons.logout_rounded),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );

    Widget content() {
      if (initialLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (error != null) {
        return Center(
          child: EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudieron cargar los datos',
            message: error!,
          ),
        );
      }
      switch (sections[section].label) {
        case 'Resumen':
          return OverviewPanel(
            orders: orders,
            products: products,
            clients: clients,
            statuses: statuses,
            users: users,
            admin: admin,
          );
        case 'Pedidos':
          return OrdersPanel(
            orders: orders,
            products: products,
            categories: categories,
            clients: clients,
            statuses: statuses,
            admin: admin,
            users: users,
          );
        case 'Productos':
          return ProductsPanel(products: products, categories: categories);
        case 'Categorías':
          return CategoriesPanel(categories: categories);
        case 'Clientes':
          return ClientsPanel(clients: clients, users: users);
        case 'Estados':
          return StatusesPanel(statuses: statuses);
        case 'Usuarios':
          return UsersPanel(users: users, currentUid: widget.profile.id);
        default:
          return const SizedBox.shrink();
      }
    }

    return Scaffold(
      drawer: wide
          ? null
          : Drawer(width: 254, child: navigation(compact: false, drawer: true)),
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sections[section].label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (wide)
              Text(
                admin ? 'Vista de administrador' : 'Mi espacio de trabajo',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.mode == ThemeMode.dark
                ? 'Tema claro'
                : 'Tema oscuro',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Sonidos',
            onPressed: () => AppFeedback.instance.toggle(),
            icon: AnimatedBuilder(
              animation: AppFeedback.instance,
              builder: (context, _) => Icon(
                AppFeedback.instance.soundsEnabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
              ),
            ),
          ),
          if (wide)
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () => Store.instance.auth.signOut(),
              icon: const Icon(Icons.logout_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (wide) navigation(compact: compactRail),
          Expanded(
            child: AnimatedSwitcher(
              duration: motionDuration(context, 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.015, 0.025),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(sections[section].label),
                child: content(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatefulWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<_NavigationItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.selected;
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(13),
            child: AnimatedContainer(
              duration: motionDuration(context, 200),
              curve: Curves.easeOutCubic,
              height: 48,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 0 : 14,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.11)
                    : hovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.045)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisAlignment: widget.compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(widget.icon, color: color, size: 23),
                  if (!widget.compact) ...[
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return widget.compact ? Tooltip(message: widget.label, child: tile) : tile;
  }
}
