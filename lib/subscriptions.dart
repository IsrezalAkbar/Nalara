import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

const demoSubscriptionPeriod = Duration(days: 30);

DateTime? subscriptionExpiry(Map<String, dynamic>? data) {
  if (data?['status'] != 'active') return null;
  if (data?['source'] == 'demo') {
    final startedAt = data?['startedAt'];
    if (startedAt is! Timestamp || data?['periodDays'] != 30) return null;
    return startedAt.toDate().add(demoSubscriptionPeriod);
  }
  final expiresAt = data?['expiresAt'];
  return expiresAt is Timestamp ? expiresAt.toDate() : null;
}

/// The server timestamp starts the period; repeated taps do not extend it.
Future<DateTime> activateDemoSubscription(
  DocumentReference<Map<String, dynamic>> ref,
) async {
  await ref.firestore.runTransaction((transaction) async {
    final current = await transaction.get(ref);
    final expiresAt = subscriptionExpiry(current.data());
    if (expiresAt != null && expiresAt.isAfter(DateTime.now())) return;
    transaction.set(ref, {
      'source': 'demo',
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
      'periodDays': demoSubscriptionPeriod.inDays,
    });
  });
  // Only grant access after the activation has been acknowledged by Firestore.
  final saved = await ref.get(const GetOptions(source: Source.server));
  final expiresAt = subscriptionExpiry(saved.data());
  if (expiresAt == null || !expiresAt.isAfter(DateTime.now())) {
    throw StateError('Premium belum aktif. Silakan coba lagi.');
  }
  return expiresAt;
}

/// Expires access while the app stays open, as well as after a restart/resume.
class PremiumAccess extends ValueNotifier<bool> {
  PremiumAccess({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(false);

  final DateTime Function() _now;
  Timer? _expiryTimer;
  DateTime? _expiresAt;
  DateTime? get expiresAt => _expiresAt;

  void setExpiry(DateTime? expiresAt) {
    final previous = _expiresAt;
    final wasActive = value;
    _expiresAt = expiresAt;
    refresh();
    if (previous != expiresAt && wasActive == value) notifyListeners();
  }

  void refresh() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    final remaining = _expiresAt?.difference(_now()) ?? Duration.zero;
    value = remaining > Duration.zero;
    if (value) _expiryTimer = Timer(remaining, refresh);
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
