import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key, required this.user});
  final User user;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _question = TextEditingController();
  Map<String, Object?>? _data;
  String? _loadError;
  bool _loading = true;
  bool _coachLoading = false;
  bool _completing = false;
  String? _coachReply;
  String? _rewardMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final d = await loadToday();
      if (!mounted) return;
      setState(() => _data = d);
    } catch (e) {
      debugPrint('Load failed: $e');
      if (mounted) setState(() => _loadError = "Could not load today's quest.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hint() async {
    if (_question.text.trim().isEmpty) {
      setState(() => _coachReply = 'Type a question first.');
      return;
    }
    setState(() => _coachLoading = true);
    try {
      final reply = await getQuestHint(_question.text);
      if (!mounted) return;
      setState(() => _coachReply = reply);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Quest Coach request failed: ${e.code}');
      if (!mounted) return;
      setState(() => _coachReply = 'The coach is unavailable. Try again.');
    } finally {
      if (mounted) setState(() => _coachLoading = false);
    }
  }

  Future<void> _complete() async {
    setState(() => _completing = true);
    try {
      final r = await completeChallenge();
      if (!mounted) return;
      setState(() {
        _rewardMessage = r['alreadyCompleted'] == true
            ? 'Already completed. You have ${r['points']} points and the ${r['badgeId']} badge.'
            : 'Quest complete! +${r['points']} points and the ${r['badgeId']} badge.';
      });
      await _load();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Complete failed: ${e.code}');
      if (mounted) {
        setState(() => _rewardMessage = 'Could not complete the quest. Try again.');
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _data?['challenge'] as Map<String, Object?>?;
    final progress = _data?['progress'] as Map<String, Object?>?;
    final done = progress?['completed'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: logOut,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Signed in as ${widget.user.email ?? widget.user.uid}'),
            const SizedBox(height: 16),
            Text("Today's challenge",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(challenge?['title']?.toString() ?? 'No challenge found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(challenge?['prompt']?.toString() ?? ''),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(done ? Icons.emoji_events : Icons.flag),
                title: Text(done ? 'Completed' : 'Not completed yet'),
                subtitle: Text(done
                    ? '${progress?['points']} points, badge: ${progress?['badgeId']}'
                    : 'Finish the quest to earn 10 points and a badge.'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _completing ? null : _complete,
              child: Text(_completing ? 'Completing...' : 'Complete challenge'),
            ),
            if (_rewardMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_rewardMessage!),
              ),
            const Divider(height: 32),
            TextField(
              controller: _question,
              maxLength: 300,
              decoration: const InputDecoration(
                  labelText: 'Ask the Quest Coach for a hint'),
            ),
            OutlinedButton(
              onPressed: _coachLoading ? null : _hint,
              child: Text(_coachLoading ? 'Thinking...' : 'Get hint'),
            ),
            if (_coachReply != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_coachReply!),
              ),
          ],
        ),
      ),
    );
  }
}