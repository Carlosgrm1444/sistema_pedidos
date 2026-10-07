import 'dart:async';

import 'package:flutter/material.dart';

import 'data.dart';
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
    Widget content() {
      if (initialLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudieron cargar los datos: $error',
              textAlign: TextAlign.center,
            ),
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
          : Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Image.asset('assets/brand/mark.png', width: 72, height: 72),
                    const SizedBox(height: 12),
                    const Text('Sistema de pedidos'),
                    const Divider(height: 32),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sections.length,
                        itemBuilder: (context, index) => ListTile(
                          selected: section == index,
                          leading: Icon(sections[index].icon),
                          title: Text(sections[index].label),
                          onTap: () {
                            setState(() => section = index);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      appBar: AppBar(
        title: Text(sections[section].label),
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
            tooltip: 'Cerrar sesión',
            onPressed: () => Store.instance.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: section,
              onDestinationSelected: (index) => setState(() => section = index),
              extended: MediaQuery.sizeOf(context).width >= 1180,
              minExtendedWidth: 210,
              labelType: MediaQuery.sizeOf(context).width >= 1180
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Image.asset(
                  'assets/brand/mark.png',
                  width: 56,
                  height: 56,
                ),
              ),
              destinations: [
                for (final item in sections)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
          Expanded(child: content()),
        ],
      ),
    );
  }
}
