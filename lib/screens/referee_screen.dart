import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/firestore_service.dart';

class RefereeScreen extends StatefulWidget {
  const RefereeScreen({super.key});

  @override
  State<RefereeScreen> createState() => _RefereeScreenState();
}

class _RefereeScreenState extends State<RefereeScreen> {
  final FirestoreService service = FirestoreService();

  Timer? _timer;

  int _timeLeft = 1200;
  int _period = 1;

  int _timeoutA = 2;
  int _timeoutB = 2;

  bool _running = false;
  String? _selectedMatchId;

  final mvpA = TextEditingController();
  final mvpB = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    mvpA.dispose();
    mvpB.dispose();
    super.dispose();
  }

  int _safeInt(Map<String, dynamic> d, String k, {int fallback = 0}) {
    final v = d[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  void _startTimer() {
    if (_running || _selectedMatchId == null) return;

    _running = true;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) async {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);

          await service.updateMatch(_selectedMatchId!, {
            'timeLeft': _timeLeft,
            'period': _period,
          });
        } else {
          _stopTimer();

          if (_period == 1) {
            setState(() {
              _period = 2;
              _timeLeft = 600;
              _timeoutA = 2;
              _timeoutB = 2;
            });

            await service.updateMatch(_selectedMatchId!, {
              'period': _period,
              'timeLeft': _timeLeft,
              'timeoutA': _timeoutA,
              'timeoutB': _timeoutB,
            });
          }
        }
      },
    );
  }

  void _resetTimer() {
    _stopTimer();

    setState(() {
      _timeLeft = 1200;
      _period = 1;
      _timeoutA = 2;
      _timeoutB = 2;
    });
  }

  Future<String?> _openRegisterDialog() async {
    final players = await service.getPlayersOnce();

    String query = '';
    String? selected;

    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setLocal) {
            final filtered = players
                .where((p) =>
                    p.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return AlertDialog(
              title: const Text('Selecciona jugador'),
              content: SizedBox(
                width: 500,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Buscar jugador',
                      ),
                      onChanged: (v) {
                        setLocal(() => query = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final name = filtered[i];

                          return ListTile(
                            title: Text(name),
                            selected: selected == name,
                            trailing: selected == name
                                ? const Icon(Icons.check,
                                    color: Colors.green)
                                : null,
                            onTap: () {
                              setLocal(() {
                                selected = name;
                              });
                            },
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(ctx, selected),
                  child: const Text('Confirmar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleDeltaPositive({
    required String matchId,
    required bool isTeamA,
    required int deltaPoints,
  }) async {
    final scorer = await _openRegisterDialog();

    if (scorer == null || scorer.isEmpty) return;

    await service.registerScoringEvent(
      matchId: matchId,
      isTeamA: isTeamA,
      scorerName: scorer,
      points: deltaPoints,
    );
  }

  Future<void> _handleDeltaNegative({
    required String matchId,
    required bool isTeamA,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .get();

    final d = doc.data()!;

    if (isTeamA) {
      await service.updateMatch(matchId, {
        'scoreA': (_safeInt(d, 'scoreA') - 1).clamp(0, 999)
      });
    } else {
      await service.updateMatch(matchId, {
        'scoreB': (_safeInt(d, 'scoreB') - 1).clamp(0, 999)
      });
    }
  }


  List<String> _extractScorerNames(dynamic rawScorers) {
    if (rawScorers is! List) return const [];

    return rawScorers.map((e) {
      if (e is String) return e;
      if (e is Map) {
        final name = e['name'];
        return name?.toString() ?? '';
      }
      return '';
    }).where((name) => name.isNotEmpty).cast<String>().toList();
  }

  Future<void> _finalizeMatch(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(id)
        .get();

    final d = doc.data();
    if (d == null) return;

    final teamAName = (d['teamA'] ?? '').toString();
    final teamBName = (d['teamB'] ?? '').toString();
    final scoreA = _safeInt(d, 'scoreA');
    final scoreB = _safeInt(d, 'scoreB');
    final scorersA = (d['scorersA'] as List?)?.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() ?? <Map<String, dynamic>>[];
    final scorersB = (d['scorersB'] as List?)?.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() ?? <Map<String, dynamic>>[];
    final mvpAText = mvpA.text.trim();
    final mvpBText = mvpB.text.trim();

    final alreadyFinalized = (d['status'] ?? '').toString() == 'finalizado';

    if (!alreadyFinalized) {
      await service.finalizeMatchStats(
        teamA: teamAName,
        teamB: teamBName,
        scoreA: scoreA,
        scoreB: scoreB,
        scorersA: scorersA,
        scorersB: scorersB,
        mvpA: mvpAText,
        mvpB: mvpBText,
      );
    }

    await service.updateMatch(id, {
      'status': 'finalizado',
      'mvpA': mvpAText,
      'mvpB': mvpBText,
    });

    _stopTimer();

    setState(() {
      _selectedMatchId = null;
      mvpA.clear();
      mvpB.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Árbitro')),
      body: StreamBuilder(
        stream: service.getMatches(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final matches = snapshot.data!.docs;

          if (_selectedMatchId == null) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: matches.map((m) {
                final d = m.data() as Map<String, dynamic>;

                return Card(
                  child: ListTile(
                    title:
                        Text('${d['teamA']} vs ${d['teamB']}'),
                    subtitle:
                        Text(d['status'] ?? ''),
                    onTap: () {
                      setState(() {
                        _selectedMatchId = m.id;
                      });
                    },
                  ),
                );
              }).toList(),
            );
          }

          final match = matches.firstWhere(
            (m) => m.id == _selectedMatchId,
          );

          final d = match.data() as Map<String, dynamic>;

          final scoreA = _safeInt(d, 'scoreA');
          final scoreB = _safeInt(d, 'scoreB');

          final scorersA = _extractScorerNames(d['scorersA']);
          final scorersB = _extractScorerNames(d['scorersB']);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  formatTime(_timeLeft),
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  '${d['teamA']}  $scoreA - $scoreB  ${d['teamB']}',
                  style: const TextStyle(fontSize: 28),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _TeamScorePanel(
                        teamName: d['teamA'],
                        score: scoreA,
                        scorers: scorersA,
                        onDeltaPositive: (p) =>
                            _handleDeltaPositive(
                          matchId: match.id,
                          isTeamA: true,
                          deltaPoints: p,
                        ),
                        onDeltaNegative: () =>
                            _handleDeltaNegative(
                          matchId: match.id,
                          isTeamA: true,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _TeamScorePanel(
                        teamName: d['teamB'],
                        score: scoreB,
                        scorers: scorersB,
                        onDeltaPositive: (p) =>
                            _handleDeltaPositive(
                          matchId: match.id,
                          isTeamA: false,
                          deltaPoints: p,
                        ),
                        onDeltaNegative: () =>
                            _handleDeltaNegative(
                          matchId: match.id,
                          isTeamA: false,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _startTimer,
                        child: const Text('Iniciar'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _stopTimer,
                        child: const Text('Pausar'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetTimer,
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: mvpA,
                  decoration: const InputDecoration(
                    labelText: 'MVP A',
                  ),
                ),

                TextField(
                  controller: mvpB,
                  decoration: const InputDecoration(
                    labelText: 'MVP B',
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () =>
                      _finalizeMatch(match.id),
                  child: const Text('FINALIZAR'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeamScorePanel extends StatelessWidget {
  final String teamName;
  final int score;
  final List<String> scorers;

  final Future<void> Function(int) onDeltaPositive;
  final Future<void> Function() onDeltaNegative;

  const _TeamScorePanel({
    required this.teamName,
    required this.score,
    required this.scorers,
    required this.onDeltaPositive,
    required this.onDeltaNegative,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(teamName),
        Text('$score',
            style: const TextStyle(fontSize: 40)),

        Text(
          scorers.isEmpty
              ? '-'
              : scorers.take(3).join(', '),
        ),

        Wrap(
          spacing: 8,
          children: [
            _btn('+1', () => onDeltaPositive(1)),
            _btn('+2', () => onDeltaPositive(2)),
            _btn('+3', () => onDeltaPositive(3)),
            _btn('+6', () => onDeltaPositive(6)),
            _btn('-1', onDeltaNegative),
          ],
        )
      ],
    );
  }

  Widget _btn(
    String txt,
    Future<void> Function() fn,
  ) {
    return ElevatedButton(
      onPressed: fn,
      child: Text(txt),
    );
  }
}