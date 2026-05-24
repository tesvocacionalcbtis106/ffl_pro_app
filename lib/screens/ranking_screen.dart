import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/firestore_service.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  Color _getMedalColor(int index) {
    if (index == 0) return AppColors.dorado;
    if (index == 1) return const Color(0xFFC0C0C0); // Plata
    if (index == 2) return const Color(0xFFCD7F32); // Bronce
    return AppColors.guinda;
  }

  Color _getMedalTextColor(int index) {
    if (index == 0) return AppColors.negro;
    if (index == 1) return AppColors.negro;
    if (index == 2) return AppColors.blanco;
    return AppColors.dorado;
  }

  int _safeInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Ranking de Jugadores")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder(
          stream: service.getPlayers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.dorado),
              );
            }

            final players = snapshot.data!.docs;

            players.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;

              final pointsA = _safeInt(dataA['points'], fallback: 0);
              final pointsB = _safeInt(dataB['points'], fallback: 0);

              if (pointsB != pointsA) return pointsB.compareTo(pointsA);

              final mvpsA = _safeInt(dataA['mvps'], fallback: 0);
              final mvpsB = _safeInt(dataB['mvps'], fallback: 0);

              if (mvpsB != mvpsA) return mvpsB.compareTo(mvpsA);

              // matchesPlayed ASC
              final mpA = _safeInt(dataA['matchesPlayed'], fallback: 0);
              final mpB = _safeInt(dataB['matchesPlayed'], fallback: 0);
              return mpA.compareTo(mpB);
            });

            if (players.isEmpty) {
              return const Center(
                child: Text(
                  "No hay jugadores registrados",
                  style: TextStyle(color: AppColors.gris),
                ),
              );
            }

            return ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final data = players[index].data() as Map<String, dynamic>;
                final medalColor = _getMedalColor(index);
                final medalTextColor = _getMedalTextColor(index);
                final bool isTop3 = index < 3;

                final points = _safeInt(data['points'], fallback: 0);

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: medalColor,
                      radius: isTop3 ? 22 : 18,
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: medalTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isTop3 ? 16 : 14,
                        ),
                      ),
                    ),
                    title: Text(
                      data['name']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      data['team']?.toString() ?? '',
                      style: const TextStyle(color: AppColors.gris),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.dorado.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$points pts",
                        style: const TextStyle(
                          color: AppColors.dorado,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

