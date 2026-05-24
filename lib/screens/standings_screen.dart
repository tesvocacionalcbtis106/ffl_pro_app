import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/firestore_service.dart';

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  int _safeInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Tabla de posiciones")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder(
          stream: service.getTeams(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.dorado),
              );
            }

            final teams = snapshot.data!.docs;

            if (teams.isEmpty) {
              return const Center(
                child: Text(
                  "No hay equipos",
                  style: TextStyle(color: AppColors.gris, fontSize: 16),
                ),
              );
            }

            // Order:
            // 1) tablePoints DESC
            // 2) diff DESC
            // 3) pointsFor DESC
            teams.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;

              final ptsA = _safeInt(dataA['tablePoints'], fallback: 0);
              final ptsB = _safeInt(dataB['tablePoints'], fallback: 0);
              if (ptsB != ptsA) return ptsB.compareTo(ptsA);

              final diffA = _safeInt(dataA['diff'], fallback: 0);
              final diffB = _safeInt(dataB['diff'], fallback: 0);
              if (diffB != diffA) return diffB.compareTo(diffA);

              final pfA = _safeInt(dataA['pointsFor'], fallback: 0);
              final pfB = _safeInt(dataB['pointsFor'], fallback: 0);
              return pfB.compareTo(pfA);
            });

            return ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final data = teams[index].data() as Map<String, dynamic>;
                final bool isTop3 = index < 3;

                final name = data['name']?.toString() ?? '';

                final pj = _safeInt(data['played'], fallback: 0);
                final g = _safeInt(data['wins'], fallback: 0);
                final p = _safeInt(data['losses'], fallback: 0);

                final pf = _safeInt(data['pointsFor'], fallback: 0);
                final pc = _safeInt(data['pointsAgainst'], fallback: 0);
                final dif = _safeInt(data['diff'], fallback: 0);

                final pts = _safeInt(data['tablePoints'], fallback: 0);

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTop3 ? AppColors.dorado : AppColors.guinda,
                      child: Text(
                        "#${index + 1}",
                        style: TextStyle(
                          color: isTop3 ? AppColors.negro : AppColors.dorado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "PJ: $pj | G: $g | P: $p\nPF: $pf | PC: $pc | DIF: $dif",
                      style: const TextStyle(color: AppColors.gris, fontSize: 12),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isTop3
                            ? AppColors.dorado.withOpacity(0.2)
                            : AppColors.guinda.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTop3 ? AppColors.dorado : AppColors.guinda,
                        ),
                      ),
                      child: Text(
                        "$pts PTS",
                        style: TextStyle(
                          color: isTop3 ? AppColors.dorado : AppColors.doradoClaro,
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

