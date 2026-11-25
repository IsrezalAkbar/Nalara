import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/subscriptions.dart';

void main() {
  test('Demo activation persists 30 days and does not extend an active period',
      () async {
    final ref = FakeFirebaseFirestore()
        .collection('users').doc('owner')
        .collection('subscription').doc('current');
    final expiresAt = await activateDemoSubscription(ref);
    final data = (await ref.get()).data()!;
    expect(data['source'], 'demo');
    expect(data['periodDays'], 30);
    expect(expiresAt.difference((data['startedAt'] as Timestamp).toDate()),
        const Duration(days: 30));
    expect(await activateDemoSubscription(ref), expiresAt);
    expect((await ref.get()).data(), data);
    // A new session derives the same expiry from persisted data.
    final access = PremiumAccess()..setExpiry(subscriptionExpiry(data));
    addTearDown(access.dispose);
    expect(access.value, isTrue);
    expect(access.expiresAt, expiresAt);
  });

  test('An expired demo can start a new period', () async {
    final ref = FakeFirebaseFirestore()
        .collection('users').doc('owner')
        .collection('subscription').doc('current');
    await ref.set({
      'source': 'demo',
      'status': 'active',
      'periodDays': 30,
      'startedAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 31)),
      ),
    });
    final expiresAt = await activateDemoSubscription(ref);
    expect(expiresAt.isAfter(DateTime.now().add(const Duration(days: 29))), isTrue);
  });

  test('An active existing subscription is preserved', () async {
    final ref = FakeFirebaseFirestore()
        .collection('users').doc('owner')
        .collection('subscription').doc('current');
    final original = {
      'status': 'active',
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 60))),
    };
    await ref.set(original);
    expect(await activateDemoSubscription(ref), subscriptionExpiry(original));
    expect((await ref.get()).data(), original);
  });

  testWidgets('Premium expires while the app stays open', (tester) async {
    var now = DateTime(2026, 10, 20, 12);
    final access = PremiumAccess(now: () => now);
    addTearDown(access.dispose);
    final expiry = now.add(const Duration(seconds: 10));
    access.setExpiry(expiry);
    expect(access.value, isTrue);
    now = expiry;
    await tester.pump(const Duration(seconds: 10));
    expect(access.value, isFalse);
    expect(access.expiresAt, expiry);
  });

  test('Resume/restart recomputes expiry and clearing a session removes access', () {
    var now = DateTime(2026, 10, 20);
    final access = PremiumAccess(now: () => now);
    addTearDown(access.dispose);
    final expiry = now.add(const Duration(days: 30));
    access.setExpiry(expiry);
    now = expiry.add(const Duration(seconds: 1));
    access.refresh();
    expect(access.value, isFalse);
    final restored = PremiumAccess(now: () => now)..setExpiry(expiry);
    addTearDown(restored.dispose);
    expect(restored.value, isFalse);
    access.setExpiry(now.add(const Duration(days: 30)));
    expect(access.value, isTrue);
    access.setExpiry(null);
    expect(access.value, isFalse);
    expect(access.expiresAt, isNull);
  });
}
