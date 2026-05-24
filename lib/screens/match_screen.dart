import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/match.dart';
import '../services/firestore_service.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final service = FirestoreService();

  String? teamA;
  String? teamB;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  Future<void> _createMatch() async {
    if (teamA == null || teamB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona ambos equipos"),
        ),
      );
      return;
    }

    if (teamA == teamB) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Los equipos no pueden ser iguales"),
        ),
      );
      return;
    }

    final createdAt = DateTime.now().millisecondsSinceEpoch;

    await service.addMatch(
      MatchModel(
        teamA: teamA!,
        teamB: teamB!,
        scoreA: 0,
        scoreB: 0,
        status: "pendiente",
        createdAt: createdAt,
        scorersA: const [],
        scorersB: const [],
        mvpA: '',
        mvpB: '',
        period: 1,
        timeLeft: 1200,
        timeoutA: 0,
        timeoutB: 0,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Partido creado correctamente"),
      ),
    );

    setState(() {
      teamA = null;
      teamB = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Partidos"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder(
              stream: service.getTeams(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final teams = snapshot.data!.docs
                    .map((doc) => doc['name'].toString())
                    .toList();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Crear Partido",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dorado,
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: teamA,
                          decoration: const InputDecoration(
                            labelText: "Equipo Local",
                          ),
                          items: teams
                              .map(
                                (team) => DropdownMenuItem(
                                  value: team,
                                  child: Text(team),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => teamA = value);
                          },
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: teamB,
                          decoration: const InputDecoration(
                            labelText: "Equipo Visitante",
                          ),
                          items: teams
                              .map(
                                (team) => DropdownMenuItem(
                                  value: team,
                                  child: Text(team),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => teamB = value);
                          },
                        ),

                        const SizedBox(height: 12),

                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );

                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Text(
                            "Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                          ),
                        ),

                        const SizedBox(height: 12),

                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );

                            if (picked != null) {
                              setState(() {
                                selectedTime = picked;
                              });
                            }
                          },
                          child: Text(
                            "Hora: ${selectedTime.format(context)}",
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.add,
                              color: AppColors.dorado,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.guinda,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onPressed: _createMatch,
                            label: const Text(
                              "Crear Partido",
                              style: TextStyle(
                                color: AppColors.blanco,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Eliminar todo"),
                      content: const Text(
                        "¿Seguro que deseas eliminar TODOS los partidos?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancelar"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Eliminar"),
                        ),
                      ],
                    ),
                  );

                  if (ok == true) {
                    await service.deleteAllMatches();
                  }
                },
                label: const Text("Eliminar todos"),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder(
                stream: service.getMatches(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final matches = snapshot.data!.docs;

                  if (matches.isEmpty) {
                    return const Center(
                      child: Text("No hay partidos"),
                    );
                  }

                  return ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final data = matches[index].data()
                          as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(
                            "${data['teamA']} vs ${data['teamB']}",
                          ),
                          subtitle: Text(
                            "${data['scoreA']} - ${data['scoreB']}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data['status'] ?? 'pendiente',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final ok =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text(
                                        "Eliminar partido",
                                      ),
                                      content: const Text(
                                        "¿Seguro que deseas eliminar este partido?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text(
                                            "Cancelar",
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            "Eliminar",
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (ok == true) {
                                    await service.deleteMatch(
                                      matches[index].id,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

