import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_store.dart';

enum ProductStockStatus { safe, low, empty }

class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.cost,
    required this.stock,
    required this.minimumStock,
    this.category = 'Minuman',
    this.active = true,
    this.favorite = false,
    this.sold = 0,
    this.assetPath,
    this.photo,
    this.photoUrl,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final int price;
  final int cost;
  final int stock;
  final int minimumStock;
  final String category;
  final bool active;
  final bool favorite;
  final int sold;
  final String? assetPath;
  final Uint8List? photo;
  final String? photoUrl;
  final DateTime updatedAt;
  ProductStockStatus get stockStatus => stock <= 0
      ? ProductStockStatus.empty
      : stock <= minimumStock
      ? ProductStockStatus.low
      : ProductStockStatus.safe;

  IconData get icon =>
      category == 'Minuman' ? Icons.local_cafe : Icons.inventory_2;

  // Pembaruan stok membuat objek baru agar detail ikut diperbarui oleh notifier.
  Product withStock(int value) => Product(
    id: id,
    name: name,
    price: price,
    cost: cost,
    stock: value,
    minimumStock: minimumStock,
    category: category,
    active: active,
    favorite: favorite,
    sold: sold,
    assetPath: assetPath,
    photo: photo,
    photoUrl: photoUrl,
  );

  factory Product.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      id: doc.id,
      name: data['name'] as String,
      price: (data['price'] as num).toInt(),
      cost: (data['cost'] as num).toInt(),
      stock: (data['stock'] as num).toInt(),
      minimumStock: (data['minimumStock'] as num?)?.toInt() ?? 0,
      category: data['category'] as String? ?? '',
      active: data['active'] != false,
      favorite: data['favorite'] == true,
      sold: (data['sold'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ProductCatalog extends ChangeNotifier {
  ProductCatalog({this._account});
  final DocumentReference<Map<String, dynamic>>? _account;
  DocumentReference<Map<String, dynamic>> get _ref => _account ?? accountRef;
  static final instance = ProductCatalog();

  final List<Product> _items = [];
  List<Product> get items => List.unmodifiable(_items);
  Product byId(String id) => _items.firstWhere((item) => item.id == id);
  void replace(List<Product> items) {
    _items
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  Future<void> save(Product product, {Product? previous}) async {
    if (product.name.trim().isEmpty ||
        product.price <= 0 ||
        product.cost < 0 ||
        product.stock < 0 ||
        product.minimumStock < 0) {
      throw StateError('Data produk tidak valid.');
    }
    final ref = _ref.collection('products').doc(product.id);
    String? photoUrl = product.photoUrl;
    if (product.photo != null) {
      final bytes = product.photo!;
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('Ukuran foto maksimal 5 MB.');
      }
      final mime = bytes.length > 3 && bytes[0] == 0xff && bytes[1] == 0xd8
          ? 'image/jpeg'
          : bytes.length > 3 && bytes[0] == 0x89
          ? 'image/png'
          : 'image/webp';
      final storage = FirebaseStorage.instance.ref(
        'users/${accountRef.id}/products/${product.id}/${DateTime.now().microsecondsSinceEpoch}',
      );
      await storage.putData(bytes, SettableMetadata(contentType: mime));
      photoUrl = await storage.getDownloadURL();
    }
    await ref.firestore.runTransaction((transaction) async {
      final current = await transaction.get(ref);
      final data = current.data();
      if (previous != null && data == null) {
        throw StateError('Produk sudah dihapus.');
      }
      if (previous != null &&
          (data!['updatedAt'] as Timestamp?)?.toDate() != previous.updatedAt) {
        throw StateError(
          'Produk berubah di perangkat lain. Buka ulang form sebelum menyimpan.',
        );
      }
      transaction.set(ref, {
        'name': product.name,
        'price': product.price,
        'cost': product.cost,
        'stock': product.stock,
        'minimumStock': product.minimumStock,
        'category': product.category,
        'active': product.active,
        'favorite': product.favorite,
        'sold': data?['sold'] ?? 0,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> addStock(String id, int quantity) async {
    if (quantity <= 0) throw StateError('Jumlah stok harus lebih dari nol.');
    final ref = _ref.collection('products').doc(id);
    final movement = _ref.collection('stockMovements').doc();
    await ref.firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('Produk tidak ditemukan.');
      final stock = (snapshot.data()!['stock'] as num).toInt();
      transaction.update(ref, {
        'stock': stock + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(movement, {
        'productId': id,
        'quantity': quantity,
        'date': FieldValue.serverTimestamp(),
      });
    });
  }
}

// Format nominal dipakai oleh daftar, detail, dan form tanpa package tambahan.
String productRupiah(int value) =>
    'Rp${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]}.')}';

// Foto berasal dari perangkat atau Storage; ikon digunakan jika belum diisi.
class ProductPhoto extends StatelessWidget {
  const ProductPhoto({super.key, required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: const Color(0xFFEFF6FF),
      child: Center(
        child: Icon(product.icon, size: 40, color: const Color(0xFF1E3A8A)),
      ),
    );
    if (product.photo != null) {
      return Image.memory(
        product.photo!,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stack) => fallback,
      );
    }
    if (product.photoUrl != null) {
      return Image.network(
        product.photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stack) => fallback,
      );
    }
    if (product.assetPath != null) {
      return Image.asset(
        product.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stack) => fallback,
      );
    }
    return fallback;
  }
}
