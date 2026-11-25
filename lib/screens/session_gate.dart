import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../session.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'store_setup_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> with WidgetsBindingObserver {
  late final StreamSubscription<User?> _auth;
  User? _user;
  bool _waiting = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth = FirebaseAuth.instance.userChanges().listen((user) {
      StoreSession.instance.bind(user);
      setState(() {
        _user = user;
        _waiting = false;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      StoreSession.instance.premium.refresh();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: StoreSession.instance,
    builder: (context, _) {
      final session = StoreSession.instance;
      if (_waiting || (_user != null && session.loading)) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (_user == null) return const AuthScreen();
      if (session.error != null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(session.error!, textAlign: TextAlign.center),
                  FilledButton(
                    onPressed: () => session.bind(_user),
                    child: const Text('Coba lagi'),
                  ),
                  TextButton(
                    onPressed: session.signOut,
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // A separate navigator is discarded on logout, including every protected route.
      return Navigator(
        key: ValueKey(_user!.uid),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => session.storeName.isEmpty
              ? const StoreSetupScreen()
              : const HomeScreen(),
        ),
      );
    },
  );
}
