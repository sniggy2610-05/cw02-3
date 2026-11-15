import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Auth
Future<UserCredential> register(String email, String password) => FirebaseAuth
    .instance
    .createUserWithEmailAndPassword(email: email, password: password);

Future<UserCredential> signIn(String email, String password) => FirebaseAuth
    .instance
    .signInWithEmailAndPassword(email: email, password: password);

Future<void> logOut() => FirebaseAuth.instance.signOut();

// Challenge + progress
Future<Map<String, Object?>> loadToday() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    throw StateError('Sign in before loading learner progress.');
  }
  final db = FirebaseFirestore.instance;
  final challenge = await db.collection('challenges').doc('today').get();
  final progress = await db
      .collection('users')
      .doc(uid)
      .collection('progress')
      .doc('today')
      .get();
  return {'challenge': challenge.data(), 'progress': progress.data()};
}

// Reward
Future<Map<String, dynamic>> completeChallenge() async {
  final result = await FirebaseFunctions.instance
      .httpsCallable('completeToday')
      .call<Map<String, dynamic>>({'challengeId': 'today'});
  return Map<String, dynamic>.from(result.data);
}

// Coach
Future<String> getQuestHint(String question) async {
  final trimmed = question.trim();
  final safe = trimmed.length > 300 ? trimmed.substring(0, 300) : trimmed;
  final result = await FirebaseFunctions.instance
      .httpsCallable('askQuestCoach')
      .call<Map<String, dynamic>>({'question': safe});
  return result.data['reply'] as String;
}