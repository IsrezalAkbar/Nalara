import 'package:cloud_firestore/cloud_firestore.dart';

/// Backfills identity for new and existing accounts without replacing store data.
Future<void> syncUserProfile(
  DocumentReference<Map<String, dynamic>> ref, {
  required String? email,
  required String? name,
}) => ref.firestore.runTransaction((transaction) async {
  final snapshot = await transaction.get(ref);
  final profile = snapshot.data() ?? {};
  final changes = <String, dynamic>{};
  if (email != null && profile['email'] != email) {
    changes['email'] = email;
  }
  if ((profile['name'] as String? ?? '').isEmpty &&
      name != null &&
      name.isNotEmpty) {
    changes['name'] = name;
  }
  if (changes.isNotEmpty) {
    final data = {...changes, 'updatedAt': FieldValue.serverTimestamp()};
    if (snapshot.exists) {
      transaction.update(ref, data);
    } else {
      transaction.set(ref, data);
    }
  }
});
