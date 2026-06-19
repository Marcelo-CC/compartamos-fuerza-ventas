import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Rutas absolutas actualizadas al nuevo paquete de ventas
import 'package:appbanco_compartamos_venta/viewmodel/home_viewmodel.dart';
import 'package:appbanco_compartamos_venta/viewmodel/venta_viewmodel.dart';
import 'package:appbanco_compartamos_venta/navigation/app_routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Al entrar a la pantalla, cargamos automáticamente la cartera desde Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VentaViewModel>().cargarCartera();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final ventaVm = context.watch<VentaViewModel>();

    const Color colorCompartamos = Color(0xFFC71585); // Magenta Institucional

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorCompartamos,
        elevation: 2,
        title: const Text(
          "Gestión de Cartera de Ventas",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.login,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo personalizado al asesor fuera del scroll
            Text(
              "¡Hola, ${homeVm.usuario.nombre}!",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              "Aquí tienes tus solicitudes asignadas para hoy.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 🔍 Buscador integrado enlazado al VentaViewModel
            TextField(
              onChanged: (value) {
                // Filtra localmente en memoria cada vez que el asesor teclea una letra
                context.read<VentaViewModel>().filtrarVentas(value);
              },
              decoration: InputDecoration(
                hintText: "Buscar venta por nombre o DNI...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: const BorderSide(color: colorCompartamos, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // El RefreshIndicator envuelve únicamente la zona de contenido dinámico
            Expanded(
              child: RefreshIndicator(
                color: colorCompartamos,
                onRefresh: () async {
                  await context.read<VentaViewModel>().cargarCartera();
                },
                child: ventaVm.loading
                    ? const Center(
                        child: CircularProgressIndicator(color: colorCompartamos),
                      )
                    : ventaVm.error.isNotEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Text(
                                  "Ocurrió un error: ${ventaVm.error}",
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : ventaVm.ventas.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                  const Center(
                                    child: Text(
                                      "No se encontraron ventas coincidentes.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: ventaVm.ventas.length,
                                itemBuilder: (context, index) {
                                  final venta = ventaVm.ventas[index];

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: colorCompartamos.withValues(alpha: 0.1),
                                          child: Text(
                                            venta.nombreCompleto.isNotEmpty ? venta.nombreCompleto[0] : 'V',
                                            style: const TextStyle(
                                              color: colorCompartamos,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          venta.nombreCompleto,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text("DNI: ${venta.dni} • Negocio: ${venta.tipoNegocio.toUpperCase()}"),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    "Score: ${venta.score}",
                                                    style: TextStyle(
                                                      color: Colors.green.shade700,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: colorCompartamos.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    "Máx: S/ ${venta.montoMaximo.toStringAsFixed(0)}",
                                                    style: const TextStyle(
                                                      color: colorCompartamos,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.detalleVenta, // Nombre de ruta actualizado
                                            arguments: venta,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}