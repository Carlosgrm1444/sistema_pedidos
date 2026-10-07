import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

const bootstrapAdminEmail = 'carlosgabrielrm1444@gmail.com';

String money(int cents) {
  final amount = (cents / 100).toStringAsFixed(2);
  final parts = amount.split('.');
  final integer = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$integer.${parts.last}';
}

int? parsePrice(String value) {
  final number = double.tryParse(value.trim().replaceAll(',', ''));
  if (number == null || !number.isFinite || number < 0) return null;
  return (number * 100).round();
}

class Item {
  const Item(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;

  String text(String key) => (data[key] ?? '').toString();
  int number(String key) => (data[key] as num?)?.toInt() ?? 0;
  bool get active => data['active'] != false;
  DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();

  static Item fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Item(doc.id, doc.data() ?? {});
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.categoryName,
    required this.unitPriceCents,
    required this.quantity,
  });
  final String productId;
  final String name;
  final String categoryName;
  final int unitPriceCents;
  final int quantity;
  int get subtotalCents => unitPriceCents * quantity;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'categoryName': categoryName,
    'unitPriceCents': unitPriceCents,
    'quantity': quantity,
  };

  factory OrderLine.fromMap(Map<String, dynamic> map) => OrderLine(
    productId: (map['productId'] ?? '').toString(),
    name: (map['name'] ?? '').toString(),
    categoryName: (map['categoryName'] ?? '').toString(),
    unitPriceCents: (map['unitPriceCents'] as num?)?.toInt() ?? 0,
    quantity: (map['quantity'] as num?)?.toInt() ?? 0,
  );
}

List<OrderLine> orderLines(Item order) =>
    ((order.data['lines'] as List<dynamic>?) ?? [])
        .map(
          (value) => OrderLine.fromMap(Map<String, dynamic>.from(value as Map)),
        )
        .toList();

class Store {
  Store._();
  static final instance = Store._();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get users => db.collection('users');
  CollectionReference<Map<String, dynamic>> get categories =>
      db.collection('categories');
  CollectionReference<Map<String, dynamic>> get products =>
      db.collection('products');
  CollectionReference<Map<String, dynamic>> get clients =>
      db.collection('clients');
  CollectionReference<Map<String, dynamic>> get statuses =>
      db.collection('statuses');
  CollectionReference<Map<String, dynamic>> get orders =>
      db.collection('orders');

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await auth.signInWithPopup(GoogleAuthProvider());
      return;
    }
    // GoogleSignIn provides the native account selector on Android, iOS and macOS.
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await GoogleSignIn.instance.initialize();
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      await auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
      return;
    }
    // Firebase Auth supports the provider flow on Windows.
    await auth.signInWithProvider(GoogleAuthProvider());
  }

  Future<void> ensureProfile(User user) async {
    final doc = users.doc(user.uid);
    if ((await doc.get()).exists) return;
    await doc.set({
      'email': user.email ?? '',
      'name': user.displayName ?? user.email ?? 'Usuario',
      'role': user.email?.toLowerCase() == bootstrapAdminEmail
          ? 'admin'
          : 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Item?> profile(String uid) => users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? Item.fromDoc(doc) : null);

  Stream<List<Item>> watch(CollectionReference<Map<String, dynamic>> ref) =>
      ref.snapshots().map((snap) => snap.docs.map(Item.fromDoc).toList());

  Stream<List<Item>> watchUsers() => watch(users);
  Stream<List<Item>> watchCategories() => watch(categories);
  Stream<List<Item>> watchProducts() => watch(products);
  Stream<List<Item>> watchStatuses() => watch(statuses).map((items) {
    items.sort((a, b) => a.number('rank').compareTo(b.number('rank')));
    return items;
  });
  Stream<List<Item>> watchClients({required bool admin, required String uid}) =>
      (admin ? clients : clients.where('assignedUid', isEqualTo: uid))
          .snapshots()
          .map((snap) => snap.docs.map(Item.fromDoc).toList());
  Stream<List<Item>> watchOrders({required bool admin, required String uid}) =>
      (admin ? orders : orders.where('assignedUid', isEqualTo: uid))
          .snapshots()
          .map((snap) {
            final items = snap.docs.map(Item.fromDoc).toList();
            items.sort(
              (a, b) => (b.date('createdAt') ?? DateTime(1970)).compareTo(
                a.date('createdAt') ?? DateTime(1970),
              ),
            );
            return items;
          });

  Future<void> seedStatuses() async {
    if ((await statuses.limit(1).get()).docs.isNotEmpty) return;
    final batch = db.batch();
    for (final entry in <(String, String, int)>[
      ('pending', 'En espera', 10),
      ('preparing', 'En preparación', 20),
      ('shipped', 'Enviado', 30),
      ('delivered', 'Entregado', 40),
    ]) {
      batch.set(statuses.doc(entry.$1), {
        'name': entry.$2,
        'rank': entry.$3,
        'color': switch (entry.$1) {
          'pending' => 0xFFFFB547,
          'preparing' => 0xFF4C8DFF,
          'shipped' => 0xFF9B7BFF,
          _ => 0xFF36C98F,
        },
      });
    }
    await batch.commit();
  }

  Future<void> setRole(String uid, String role) =>
      users.doc(uid).update({'role': role});
  Future<void> saveCategory({
    String? id,
    required String name,
    bool active = true,
  }) => id == null
      ? categories.add({'name': name.trim(), 'active': active}).then((_) {})
      : categories.doc(id).update({'name': name.trim(), 'active': active});
  Future<void> saveProduct({
    String? id,
    required String name,
    required String categoryId,
    required int priceCents,
    bool active = true,
  }) async {
    final data = {
      'name': name.trim(),
      'categoryId': categoryId,
      'priceCents': priceCents,
      'active': active,
    };
    if (id == null) {
      await products.add(data);
    } else {
      await products.doc(id).update(data);
    }
  }

  Future<void> saveClient({
    String? id,
    required String name,
    required String assignedUid,
    bool active = true,
  }) async {
    final data = {
      'name': name.trim(),
      'assignedUid': assignedUid,
      'active': active,
    };
    if (id == null) {
      await clients.add(data);
    } else {
      final ref = clients.doc(id);
      final previous = await ref.get();
      if (previous.data()?['name'] == data['name'] &&
          previous.data()?['assignedUid'] == assignedUid) {
        await ref.update(data);
        return;
      }
      // Keep old orders with the client when an administrator reassigns it.
      final linked = await orders.where('clientId', isEqualTo: id).get();
      if (linked.docs.isEmpty) {
        await ref.update(data);
        return;
      }
      for (var start = 0; start < linked.docs.length; start += 400) {
        final end = (start + 400).clamp(0, linked.docs.length);
        final batch = db.batch();
        for (final order in linked.docs.sublist(start, end)) {
          batch.update(order.reference, {
            'assignedUid': assignedUid,
            'clientName': data['name'],
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        if (end == linked.docs.length) batch.update(ref, data);
        await batch.commit();
      }
    }
  }

  Future<void> saveStatus(String id, String name, {required int color}) =>
      statuses.doc(id).update({'name': name.trim(), 'color': color});
  Future<void> addStatus(String name, int rank, {required int color}) async {
    await statuses.add({'name': name.trim(), 'rank': rank, 'color': color});
  }

  Future<void> swapStatusRank(Item first, Item second) async {
    final batch = db.batch();
    batch.update(statuses.doc(first.id), {'rank': second.number('rank')});
    batch.update(statuses.doc(second.id), {'rank': first.number('rank')});
    await batch.commit();
  }

  Future<void> createOrder({
    required Item client,
    required List<OrderLine> lines,
    required String statusId,
  }) async {
    if (lines.isEmpty) throw StateError('Agrega un producto al pedido.');
    await orders.add({
      'clientId': client.id,
      'clientName': client.text('name'),
      'assignedUid': client.text('assignedUid'),
      'createdByUid': auth.currentUser!.uid,
      'statusId': statusId,
      'lines': lines.map((line) => line.toMap()).toList(),
      'totalCents': lines.fold<int>(
        0,
        (total, line) => total + line.subtotalCents,
      ),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deliveredAt': null,
    });
  }

  Future<void> setOrderStatus(String id, String statusId) =>
      orders.doc(id).update({
        'statusId': statusId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deliverOrder(String id) async {
    final ref = orders.doc(id);
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists || snapshot.data()?['deliveredAt'] != null) {
        throw StateError('El pedido ya fue entregado o no existe.');
      }
      transaction.update(ref, {
        'statusId': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'deliveredBy': auth.currentUser!.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
