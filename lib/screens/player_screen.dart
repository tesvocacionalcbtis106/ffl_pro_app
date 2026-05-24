import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/firestore_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final service = FirestoreService();
  final nameController = TextEditingController();
  String? selectedTeam;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.guinda,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jugadores")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder(
              stream: service.getTeams(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.dorado),
                  );
                }

                final teams = snapshot.data!.docs;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.negroElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grisOscuro),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Selecciona equipo", style: TextStyle(color: AppColors.gris)),
                      value: selectedTeam,
                      dropdownColor: AppColors.negroElevated,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.dorado),
                      style: const TextStyle(color: AppColors.blanco),
                      items: teams.map<DropdownMenuItem<String>>((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: data['name'],
                          child: Text(data['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedTeam = value),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nombre del jugador",
                prefixIcon: Icon(Icons.person, color: AppColors.dorado),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, color: AppColors.dorado),
                onPressed: () {
                  if (nameController.text.isEmpty || selectedTeam == null) {
                    _showMessage("Completa todos los campos");
                    return;
                  }

                  service.addPlayer({
                    'name': nameController.text.trim(),
                    'team': selectedTeam,
                    'points': 0,
                  });

                  nameController.clear();
                  setState(() => selectedTeam = null);
                  _showMessage("Jugador agregado exitosamente");
                },
                label: const Text("Agregar Jugador"),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_sweep, color: AppColors.gris),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.negroElevated),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('Eliminar todo'),
                        content: const Text('¿Seguro que deseas eliminar TODOS los jugadores?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.guinda),
                            child: const Text('Sí, eliminar'),
                          ),
                        ],
                      );
                    },
                  );

                  if (ok != true) return;

                  await service.deleteAllPlayers();
                  nameController.clear();
                  setState(() => selectedTeam = null);
                  _showMessage('Jugadores eliminados');
                },
                label: const Text('Eliminar todo'),
              ),
            ),
            const Divider(height: 24),

            Expanded(
              child: StreamBuilder(
                stream: service.getPlayers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.dorado),
                    );
                  }

                  final players = snapshot.data!.docs;

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

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.guinda,
                            child: const Icon(Icons.person, color: AppColors.dorado),
                          ),
                          title: Text(
                            data['name'] ?? "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${data['team']} | ${data['points'] ?? 0} pts",
                            style: const TextStyle(color: AppColors.gris),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.dorado.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${data['points'] ?? 0} pts",
                              style: const TextStyle(
                                color: AppColors.dorado,
                                fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }
}

