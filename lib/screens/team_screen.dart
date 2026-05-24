import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/firestore_service.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final service = FirestoreService();
  final controller = TextEditingController();

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
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Equipos")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Nombre del equipo",
                prefixIcon: Icon(Icons.group, color: AppColors.dorado),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, color: AppColors.dorado),
                onPressed: () {
                  if (controller.text.isEmpty) {
                    _showMessage("Ingresa un nombre de equipo");
                    return;
                  }

                  service.addTeam({
                    'name': controller.text.trim(),
                    'pj': 0,
                    'pg': 0,
                    'pp': 0,
                    'pf': 0,
                    'pc': 0,
                    'pts': 0,
                  });

                  controller.clear();
                  _showMessage("Equipo agregado exitosamente");
                },
                label: const Text("Agregar Equipo"),
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
                        content: const Text('¿Seguro que deseas eliminar TODOS los equipos?'),
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

                  await service.deleteAllTeams();
                  controller.clear();
                  _showMessage('Equipos eliminados');
                },
                label: const Text('Eliminar todo'),
              ),
            ),
            const Divider(height: 24),

            Expanded(
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
                        "No hay equipos registrados",
                        style: TextStyle(color: AppColors.gris),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final data = teams[index].data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.guinda,
                            child: const Icon(Icons.shield, color: AppColors.dorado),
                          ),
                          title: Text(
                            data['name'] ?? "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "PJ: ${data['pj'] ?? 0}",
                            style: const TextStyle(color: AppColors.gris),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.dorado.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${data['pts'] ?? 0} pts",
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
          ],
        ),
      ),
    );
  }
}

