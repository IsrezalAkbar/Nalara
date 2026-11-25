import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/user_profile.dart';

void main() {
  test('Google login creates a profile with email and name', () async {
    final ref = FakeFirebaseFirestore().collection('users').doc('google-user');
    await syncUserProfile(ref, email: 'owner@example.com', name: 'Pemilik');
    final profile = (await ref.get()).data()!;
    expect(profile['email'], 'owner@example.com');
    expect(profile['name'], 'Pemilik');
    expect(profile['updatedAt'], isNotNull);
  });

  test('Login backfills email without replacing the edited profile', () async {
    final ref = FakeFirebaseFirestore().collection('users').doc('existing');
    await ref.set({
      'name': 'Nama pilihan',
      'storeName': 'Toko Saya',
      'notifications': true,
    });
    await syncUserProfile(ref, email: 'owner@example.com', name: 'Nama Google');
    final first = (await ref.get()).data()!;
    expect(first['name'], 'Nama pilihan');
    expect(first['storeName'], 'Toko Saya');
    expect(first['notifications'], isTrue);
    expect(first['email'], 'owner@example.com');

    await syncUserProfile(ref, email: 'owner@example.com', name: 'Nama Google');
    expect((await ref.get()).data(), first);
  });

  test(
    'Email registration can sync before display name is available',
    () async {
      final ref = FakeFirebaseFirestore().collection('users').doc('email-user');
      await syncUserProfile(ref, email: 'owner@example.com', name: null);
      await syncUserProfile(
        ref,
        email: 'owner@example.com',
        name: 'Nama Daftar',
      );
      expect((await ref.get()).data()!['name'], 'Nama Daftar');
      await syncUserProfile(
        ref,
        email: 'updated@example.com',
        name: 'Nama Daftar',
      );
      expect((await ref.get()).data()!['email'], 'updated@example.com');
    },
  );
}
