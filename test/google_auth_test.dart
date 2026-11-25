import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nalara/google_auth.dart';

class FakeGoogle extends Fake implements GoogleSignIn {
  int initializations = 0;
  int authentications = 0;
  int signOuts = 0;
  String? token = 'google-id-token';
  GoogleSignInException? failure;

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {
    initializations++;
  }

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const [],
  }) async {
    authentications++;
    if (failure != null) throw failure!;
    return FakeGoogleAccount(token);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
  }
}

class FakeGoogleAccount extends Fake implements GoogleSignInAccount {
  FakeGoogleAccount(this.token);
  final String? token;

  @override
  GoogleSignInAuthentication get authentication =>
      GoogleSignInAuthentication(idToken: token);
}

class FakeAuth extends Fake implements FirebaseAuth {
  final credentials = <AuthCredential>[];

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    credentials.add(credential);
    return FakeCredential();
  }
}

class FakeCredential extends Fake implements UserCredential {}

void main() {
  test(
    'Repeated login initializes once and passes the Google token to Firebase',
    () async {
      final google = FakeGoogle();
      final auth = FakeAuth();
      final service = GoogleAuth(google: google, auth: auth);
      await service.signIn();
      await service.signOut();
      await service.signIn();
      expect(google.initializations, 1);
      expect(google.authentications, 2);
      expect(google.signOuts, 1);
      expect(auth.credentials, hasLength(2));
      expect(auth.credentials.first.providerId, 'google.com');
      expect(
        (auth.credentials.first as OAuthCredential).idToken,
        'google-id-token',
      );
    },
  );

  test(
    'Cancellation is visible and a subsequent attempt can succeed',
    () async {
      final google = FakeGoogle()
        ..failure = const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        );
      final auth = FakeAuth();
      final service = GoogleAuth(google: google, auth: auth);
      await expectLater(
        service.signIn(),
        throwsA(isA<GoogleSignInException>()),
      );
      expect(googleAuthMessage(google.failure!), contains('SHA-1/SHA-256'));
      expect(auth.credentials, isEmpty);
      google.failure = null;
      await service.signIn();
      expect(auth.credentials, hasLength(1));
      expect(google.initializations, 1);
    },
  );

  test('A missing ID token never signs into Firebase', () async {
    final google = FakeGoogle()..token = null;
    final auth = FakeAuth();
    await expectLater(
      GoogleAuth(google: google, auth: auth).signIn(),
      throwsStateError,
    );
    expect(auth.credentials, isEmpty);
  });
}
