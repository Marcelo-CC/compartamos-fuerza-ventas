import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appbanco_compartamos_venta/viewmodel/home_viewmodel.dart';
import 'package:appbanco_compartamos_venta/navigation/app_routes.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color colorCompartamos = Color(0xFFC71585);
    final homeVm = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: colorCompartamos,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 50,
              backgroundColor: colorCompartamos.withValues(alpha: 0.1),
              child: Text(
                homeVm.usuario.nombre.isNotEmpty ? homeVm.usuario.nombre[0].toUpperCase() : "A",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: colorCompartamos),
              ),
            ),
            const SizedBox(height: 16),
            // Nombre del asesor desde la BD
            Text(
              homeVm.usuario.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text(
              "asesor.movil@compartamos.com.pe",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Chip(
              label: const Text("Asesor de Negocios - Fuerza de Ventas"),
              backgroundColor: colorCompartamos.withValues(alpha: 0.08),
              labelStyle: const TextStyle(color: colorCompartamos, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 10),
            
            _buildInfoRow(Icons.business, "Agencia", "Agencia Central - Lima"),
            _buildInfoRow(Icons.phone_android, "Dispositivo Vinculado", "Terminal Biométrico V4"),
            _buildInfoRow(Icons.verified_user, "Permisos de Aplicación", "Fuerza de Ventas"),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Cerrar Sesión Seguro", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
        ],
      ),
    );
  }
}