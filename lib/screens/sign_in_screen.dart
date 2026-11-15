import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(
      Future<UserCredential> Function(String, String) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(_email.text.trim(), _password.text);
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error: ${e.code}');
      if (mounted) {
        setState(() => _error = 'Auth error: ${e.code} | ${e.message}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Quest')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Sign in to start your quest',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : () => _run(signIn),
              child: Text(_busy ? 'Working...' : 'Sign in'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : () => _run(register),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}