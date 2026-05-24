import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getTeams() {
    return _db.collection('teams').snapshots();
  }

  Future<void> addTeam(Map<String, dynamic> team) async {
    await _db.collection('teams').add(team);
  }

  Future<void> deleteAllTeams() async {
    final snapshot = await _db.collection('teams').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPlayers() {
    return _db.collection('players').snapshots();
  }

  Future<void> addPlayer(Map<String, dynamic> player) async {
    await _db.collection('players').add(player);
  }

  Future<void> deleteAllPlayers() async {
    final snapshot = await _db.collection('players').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<List<String>> getPlayersOnce() async {
    final snapshot = await _db.collection('players').get();

    return snapshot.docs
        .map((doc) => (doc.data()['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMatches() {
    return _db.collection('matches').snapshots();
  }

  Future<void> addMatch(MatchModel match) async {
    await _db.collection('matches').add(match.toMap());
  }

  Future<void> updateMatch(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('matches').doc(id).update(data);
  }

  Future<void> deleteMatch(String id) async {
    await _db.collection('matches').doc(id).delete();
  }

  Future<void> deleteAllMatches() async {
    final snapshot = await _db.collection('matches').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  int _safeInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  Future<void> registerScoringEvent({
    required String matchId,
    required bool isTeamA,
    required String scorerName,
    required int points,
  }) async {
    final pts = points.clamp(0, 999);

    final matchRef = _db.collection('matches').doc(matchId);

    await _db.runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists) return;

      final matchData = matchSnap.data() as Map<String, dynamic>? ?? {};

      final currentScoreA = _safeInt(matchData['scoreA'], fallback: 0);
      final currentScoreB = _safeInt(matchData['scoreB'], fallback: 0);

      final scoreA = currentScoreA;
      final scoreB = currentScoreB;

      final newScoreA = isTeamA ? scoreA + pts : scoreA;
      final newScoreB = isTeamA ? scoreB : scoreB + pts;

      final existingScorersA = (matchData['scorersA'] as List?) ?? <dynamic>[];
      final existingScorersB = (matchData['scorersB'] as List?) ?? <dynamic>[];

      // scorersX: List<Map<String,dynamic>> e.g. {name:'Juan', points:3, createdAt: ...}
      final scorerEntry = <String, dynamic>{
        'name': scorerName,
        'points': pts,
        'createdAt': FieldValue.serverTimestamp(),
      };

      Map<String, dynamic>? normalizeScorerEntry(dynamic e) {
        if (e is Map) return e.cast<String, dynamic>();
        if (e is String && e.trim().isNotEmpty) {
          return {
            'name': e.trim(),
            'points': 0,
          };
        }
        return null;
      }

      final newScorersA = existingScorersA
          .map(normalizeScorerEntry)
          .whereType<Map<String, dynamic>>()
          .toList();
      final newScorersB = existingScorersB
          .map(normalizeScorerEntry)
          .whereType<Map<String, dynamic>>()
          .toList();

      if (isTeamA) {
        newScorersA.add(scorerEntry);
      } else {
        newScorersB.add(scorerEntry);
      }

      tx.update(matchRef, {
        'scoreA': newScoreA,
        'scoreB': newScoreB,
        'scorersA': newScorersA,
        'scorersB': newScorersB,
      });

      // Update player stats by name (same pattern already used elsewhere).
      final playersQuery = await _db
          .collection('players')
          .where('name', isEqualTo: scorerName)
          .get();

      for (final pDoc in playersQuery.docs) {
        final pData = pDoc.data();
        final currentPoints = _safeInt(pData['points'], fallback: 0);

        tx.update(pDoc.reference, {
          'points': currentPoints + pts,
        });
      }
    });
  }

  Future<void> assignMVP({
    required String matchId,
    required bool isTeamA,
    required String mvpName,
  }) async {
    final name = mvpName.trim();
    if (name.isEmpty) return;

    final matchRef = _db.collection('matches').doc(matchId);

    await _db.runTransaction((tx) async {
      tx.update(matchRef, {
        isTeamA ? 'mvpA' : 'mvpB': name,
      });

      final playersQuery = await _db
          .collection('players')
          .where('name', isEqualTo: name)
          .get();

      for (final pDoc in playersQuery.docs) {
        final pData = pDoc.data();
        final current = _safeInt(pData['mvps'], fallback: 0);
        tx.update(pDoc.reference, {
          'mvps': current + 1,
        });
      }
    });
  }

  Future<void> finalizeMatchStats({
    required String teamA,
    required String teamB,
    required int scoreA,
    required int scoreB,
    required List<Map<String, dynamic>> scorersA,
    required List<Map<String, dynamic>> scorersB,
    required String mvpA,
    required String mvpB,
  }) async {
    // IMPORTANT:
    // - player points/matchesPlayed are updated incrementally by registerScoringEvent
    // - player mvps are updated incrementally by assignMVP
    // So here we only finalize team stats.

    final teams = await _db.collection('teams').get();

    for (final doc in teams.docs) {
      final data = doc.data();
      final tName = (data['name'] ?? '').toString();

      if (tName != teamA && tName != teamB) continue;

      final isA = tName == teamA;

      final currentPlayed = _safeInt(data['played'], fallback: 0);
      final currentWins = _safeInt(data['wins'], fallback: 0);
      final currentLosses = _safeInt(data['losses'], fallback: 0);
      final currentPointsFor = _safeInt(data['pointsFor'], fallback: 0);
      final currentPointsAgainst = _safeInt(data['pointsAgainst'], fallback: 0);
      final currentTablePoints = _safeInt(data['tablePoints'], fallback: 0);

      final pf = currentPointsFor + (isA ? scoreA : scoreB);
      final pa = currentPointsAgainst + (isA ? scoreB : scoreA);

      final played = currentPlayed + 1;
      final won = isA ? scoreA > scoreB : scoreB > scoreA;

      await doc.reference.update({
        'played': played,
        'wins': currentWins + (won ? 1 : 0),
        'losses': currentLosses + (won ? 0 : 1),
        'pointsFor': pf,
        'pointsAgainst': pa,
        'diff': pf - pa,
        'tablePoints': currentTablePoints + (won ? 3 : 1),
      });
    }


    final allPlayers = await _db.collection('players').get();
    final teamPlayers = allPlayers.docs.where((pDoc) {
      final pData = pDoc.data();
      final pTeam = (pData['team'] ?? '').toString();
      return pTeam == teamA || pTeam == teamB;
    });

    for (final pDoc in teamPlayers) {
      final pData = pDoc.data();
      final currentMatchesPlayed = _safeInt(pData['matchesPlayed'], fallback: 0);
      await pDoc.reference.update({
        'matchesPlayed': currentMatchesPlayed + 1,
      });
    }

  }

  Future<void> migrateDatabase() async {
    print("INICIANDO MIGRACION");

    final players = await _db.collection('players').get();
    final teams = await _db.collection('teams').get();

    print("PLAYERS: ${players.docs.length}");
    print("TEAMS: ${teams.docs.length}");

    for (final doc in players.docs) {
      await doc.reference.set({
        ...doc.data(),
        'matchesPlayed': doc.data()['matchesPlayed'] ?? 0,
        'mvps': doc.data()['mvps'] ?? 0,
        'points': doc.data()['points'] ?? 0,
      }, SetOptions(merge: true));
    }

    for (final doc in teams.docs) {
      await doc.reference.set({
        'name': doc.data()['name'],
        'played': 0,
        'wins': 0,
        'losses': 0,
        'pointsFor': 0,
        'pointsAgainst': 0,
        'diff': 0,
        'tablePoints': 0,
      });
    }

    print("MIGRACION COMPLETA");
  }
}

