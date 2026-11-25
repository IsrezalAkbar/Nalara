import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_store.dart';
import 'google_auth.dart';
import 'products.dart';
import 'subscriptions.dart';
import 'transactions.dart';
import 'user_profile.dart';

class StoreSession extends ChangeNotifier {
  static final instance = StoreSession();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Map<String, dynamic> profile = {};
  final premium = PremiumAccess();
  String? error;
  bool loading = true;
  String? _uid;
  User? _user;
  int _generation = 0;

  String get name => profile['name'] as String? ?? _user?.displayName ?? '';
  String get email => _user?.email ?? '';
  String get storeName => profile['storeName'] as String? ?? '';
  bool get notifications => profile['notifications'] == true;
  Map<String, bool> get methods => {
    'Tunai': (profile['paymentMethods'] as Map?)?['Tunai'] != false,
    'QRIS': (profile['paymentMethods'] as Map?)?['QRIS'] != false,
  };

  Future<void> bind(User? user) async {
    final generation = ++_generation;
    _uid = user?.uid;
    _user = user;
    final previousSubscriptions = List.of(_subscriptions);
    _subscriptions.clear();
    profile = {};
    premium.setExpiry(null);
    error = null;
    loading = user != null;
    ProductCatalog.instance.replace([]);
    TransactionHistory.instance.replace([]);
    notifyListeners();
    await Future.wait(
      previousSubscriptions.map((subscription) => subscription.cancel()),
    );
    if (generation != _generation) return;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final ready = <String>{};
    void received(String key) {
      if (generation != _generation) return;
      ready.add(key);
      loading = error == null && ready.length < 4;
      notifyListeners();
    }

    void failed(Object failure) {
      if (generation != _generation) return;
      error = firebaseMessage(failure);
      loading = false;
      notifyListeners();
    }

    // Finish identity persistence before leaving the loading screen. Failures
    // remain visible in SessionGate even after AuthScreen has been disposed.
    try {
      await syncUserProfile(
        ref,
        email: user.email,
        name: user.displayName,
      ).timeout(const Duration(seconds: 15));
    } catch (failure) {
      failed(
        StateError(
          'Akun sudah masuk, tetapi profil belum tersimpan. '
          '${firebaseMessage(failure)}',
        ),
      );
      return;
    }
    if (generation != _generation) return;

    _subscriptions.add(
      ref.snapshots().listen((snapshot) {
        if (generation != _generation) return;
        profile = snapshot.data() ?? {};
        received('profile');
      }, onError: failed),
    );
    _subscriptions.add(
      ref.collection('products').snapshots().listen((snapshot) {
        if (generation != _generation) return;
        try {
          ProductCatalog.instance.replace(
            snapshot.docs.map(Product.fromDocument).toList(),
          );
          received('products');
        } catch (failure) {
          failed(failure);
        }
      }, onError: failed),
    );
    _subscriptions.add(
      ref
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots()
          .listen((snapshot) {
            if (generation != _generation) return;
            try {
              TransactionHistory.instance.replace(
                snapshot.docs
                    .where(
                      (doc) =>
                          !doc.metadata.hasPendingWrites &&
                          doc.data()['date'] is Timestamp,
                    )
                    .map(SaleTransaction.fromDocument)
                    .toList(),
              );
              received('transactions');
            } catch (failure) {
              failed(failure);
            }
          }, onError: failed),
    );
    _subscriptions.add(
      ref.collection('subscription').doc('current').snapshots().listen((
        snapshot,
      ) {
        if (generation != _generation) return;
        if (snapshot.metadata.hasPendingWrites) return;
        premium.setExpiry(subscriptionExpiry(snapshot.data()));
        received('subscription');
      }, onError: failed),
    );
    _subscriptions.add(
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        if (generation != _generation || !notifications) return;
        try {
          await ref.collection('devices').doc(token).set({
            'token': token,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {
          /* Next preference update retries token registration. */
        }
      }),
    );
  }

  Future<void> saveProfile(Map<String, dynamic> values) => accountRef.set({
    ...values,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<void> activatePremiumDemo() async {
    final uid = _uid;
    if (uid == null) throw StateError('Silakan masuk kembali.');
    final expiresAt = await activateDemoSubscription(
      accountRef.collection('subscription').doc('current'),
    ).timeout(const Duration(seconds: 20));
    if (uid != _uid) return;
    premium.setExpiry(expiresAt);
  }

  Future<void> setNotifications(bool enabled) async {
    final messaging = FirebaseMessaging.instance;
    if (enabled) {
      final permission = await messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        throw StateError(
          'Izin notifikasi ditolak. Aktifkan melalui pengaturan perangkat.',
        );
      }
      final token = await messaging.getToken();
      if (token == null) {
        throw StateError('Token notifikasi belum tersedia. Coba lagi.');
      }
      await accountRef.collection('devices').doc(token).set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final token = await messaging.getToken();
      if (token != null) {
        await accountRef.collection('devices').doc(token).delete();
      }
      await messaging.deleteToken();
    }
    await saveProfile({'notifications': enabled});
  }

  Future<void> signOut() async {
    if (_uid != null) {
      // Remove the device association before another account uses this device.
      try {
        final token = await FirebaseMessaging.instance.getToken().timeout(
          const Duration(seconds: 5),
        );
        if (token != null) {
          await accountRef
              .collection('devices')
              .doc(token)
              .delete()
              .timeout(const Duration(seconds: 5));
        }
        await FirebaseMessaging.instance.deleteToken().timeout(
          const Duration(seconds: 5),
        );
      } catch (_) {
        /* Authentication logout must remain possible offline. */
      }
    }
    try {
      await GoogleAuth.instance.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Firebase logout must remain available if Google is offline.
    } finally {
      await FirebaseAuth.instance.signOut();
    }
  }
}
