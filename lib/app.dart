import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/challenge_screen.dart';
import 'screens/sign_in_screen.dart';

class CloudQuestApp extends StatelessWidget {
  const CloudQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Quest',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          return user == null
              ? const SignInScreen()
              : ChallengeScreen(key: ValueKey(user.uid), user: user);
        },
      ),
    );
  }
}