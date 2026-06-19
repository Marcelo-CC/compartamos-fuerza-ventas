import 'package:flutter/material.dart';
import 'package:appbanco_compartamos_venta/model/venta_model.dart';
import 'package:appbanco_compartamos_venta/services/solicitud_service.dart';

class NuevaSolicitudScreen extends StatefulWidget {
  const NuevaSolicitudScreen({super.key});

  @override
  State<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

class _NuevaSolicitudScreenState extends State<NuevaSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();
  final SolicitudService _solicitudService = SolicitudService();

  // Controladores de texto para capturar lo que escribe el asesor
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _plazoController = TextEditingController();
  final TextEditingController _propositoController = TextEditingController();

  double _cuotaCalculada = 0.0;
  bool _guardando = false;

  // 🧮 Función matemática para calcular la cuota estimada en tiempo real
  void _calcularCuota(double montoMaximo) {
    final double monto = double.tryParse(_montoController.text) ?? 0.0;
    final int plazo = int.tryParse(_plazoController.text) ?? 0;

    if (monto > 0 && plazo > 0) {
      // Regla de negocio: Usamos una tasa de interés simulada del 2% mensual (0.02)
      const double tasaMensual = 0.02;
      
      // Fórmula simple de cuota nivelada (Interés + Capital amortizado de forma directa)
      setState(() {
        _cuotaCalculada = (monto / plazo) + (monto * tasaMensual);
      });
    } else {
      setState(() {
        _cuotaCalculada = 0.0;
      });
    }
  }

  Future<void> _enviarSolicitud(String ventaId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      await _solicitudService.registrarSolicitud(
        clienteId: ventaId, // Se mantiene el parámetro que espera el servicio
        monto: double.parse(_montoController.text),
        plazo: int.parse(_plazoController.text),
        proposito: _propositoController.text.trim(),
        cuotaEstimada: _cuotaCalculada,
      );

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Solicitud registrada con éxito en Supabase"),
            backgroundColor: Colors.green,
          ),
        );
        // Regresa a la pantalla anterior
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ El sistema falló: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recibe los argumentos de la venta pre-aprobada
    final venta = ModalRoute.of(context)!.settings.arguments as VentaModel;
    const Color colorCompartamos = Color(0xFFC71585);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorCompartamos,
        title: const Text("Nueva Solicitud", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _guardando
          ? const Center(child: CircularProgressIndicator(color: colorCompartamos))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ficha resumen de la venta superior
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(venta.nombreCompleto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("DNI: ${venta.dni}  •  Línea Máxima: S/ ${venta.montoMaximo.toStringAsFixed(0)}", 
                               style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo: Monto
                    TextFormField(
                      controller: _montoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Monto Solicitado (S/)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                      ),
                      onChanged: (_) => _calcularCuota(venta.montoMaximo),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Ingresa un monto";
                        final monto = double.tryParse(value);
                        if (monto == null || monto <= 0) return "Monto no válido";
                        if (monto > venta.montoMaximo) return "Supera la línea máxima autorizada de S/ ${venta.montoMaximo.toStringAsFixed(0)}";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo: Plazo
                    TextFormField(
                      controller: _plazoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Plazo en Meses",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      onChanged: (_) => _calcularCuota(venta.montoMaximo),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Ingresa el plazo";
                        final meses = int.tryParse(value);
                        if (meses == null || meses <= 0) return "Plazo no válido";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo: Propósito
                    TextFormField(
                      controller: _propositoController,
                      decoration: const InputDecoration(
                        labelText: "Destino / Propósito del Crédito",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment),
                        hintText: "Ej. Compra de mercadería para campaña"
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Ingresa el propósito del crédito";
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),

                    // Tarjeta de Cuota Estimada Dinámica
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Column(
                        children: [
                          const Text("CUOTA MENSUAL ESTIMADA", style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "S/ ${_cuotaCalculada.toStringAsFixed(2)}",
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Botón enviar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorCompartamos,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _enviarSolicitud(venta.id),
                        child: const Text("Enviar Solicitud a Evaluación", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}