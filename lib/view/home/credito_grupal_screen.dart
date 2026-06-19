import 'package:flutter/material.dart';

class CreditoGrupalScreen extends StatelessWidget {
  const CreditoGrupalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color colorCompartamos = Color(0xFFC71585);

    final List<Map<String, dynamic>> grupos = [
      {"nombre": "Las Emprendedoras de San Juan", "integrantes": 12, "monto": "S/ 24,000", "estado": "Por Desembolsar", "color": Colors.orange},
      {"nombre": "Mujeres Progresistas de Ate", "integrantes": 15, "monto": "S/ 35,500", "estado": "Aprobado", "color": Colors.green},
      {"nombre": "Unidas por el Éxito - V.E.S.", "integrantes": 10, "monto": "S/ 20,000", "estado": "En Evaluación", "color": Colors.blue},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crédito Grupal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: colorCompartamos,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Grupos Asignados (Crédito Súper Mujer)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text("Monitoreo de juntas y desembolsos grupales del día.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: grupos.length,
                itemBuilder: (context, index) {
                  final grupo = grupos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor: colorCompartamos.withValues(alpha: 0.1),
                        child: const Icon(Icons.group, color: colorCompartamos),
                      ),
                      title: Text(grupo["nombre"] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Integrantes: ${grupo["integrantes"]} • Monto: ${grupo["monto"]}"),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (grupo["color"] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              grupo["estado"] as String,
                              style: TextStyle(color: grupo["color"] as Color, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          )
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    ),
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