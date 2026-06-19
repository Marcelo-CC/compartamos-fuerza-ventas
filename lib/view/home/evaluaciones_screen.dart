// lib/view/home/evaluaciones_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
 
class EvaluacionesScreen extends StatefulWidget {
  const EvaluacionesScreen({super.key});
 
  @override
  State<EvaluacionesScreen> createState() => _EvaluacionesScreenState();
}
 
class _EvaluacionesScreenState extends State<EvaluacionesScreen> {
  final _supabase = Supabase.instance.client;
 
  List<Map<String, dynamic>> _solicitudesPendientes = [];
  bool _cargando = true;
 
  // Variables para la evaluación interactiva del cliente seleccionado
  Map<String, dynamic>? _solicitudSeleccionada;
  int _plazoSeleccionado = 12; // Plazo inicial por defecto
  double _cuotaCalculada = 0.0;
  bool _procesandoAprobacion = false;
 
  @override
  void initState() {
    super.initState();
    _obtenerSolicitudesPendientes();
  }
 
  // 1. CARGAR SOLICITUDES PENDIENTES DESDE SUPABASE
  Future<void> _obtenerSolicitudesPendientes() async {
    setState(() => _cargando = true);
    try {
      final data = await _supabase
          .from('solicitudes')
          .select('*, clientes(nombre_completo, dni)')
          .eq('estado', 'PENDIENTE')
          .order('fecha_creacion', ascending: false);
 
      setState(() {
        _solicitudesPendientes = List<Map<String, dynamic>>.from(data);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarSnackBar('Error al cargar solicitudes: $e');
    }
  }
 
  // 2. CALCULAR CUOTA EN TIEMPO REAL
  void _recalcularCuota(double monto) {
    if (monto <= 0) return;
    setState(() {
      // (Monto solicitado + 15% interés base) / meses elegidos por el asesor
      _cuotaCalculada = (monto * 1.15) / _plazoSeleccionado;
    });
  }
 
  // 3. PROCESAR ACCIÓN (APROBAR O RECHAZAR)
  Future<void> _procesarDecision(String nuevoEstado) async {
    if (_solicitudSeleccionada == null) return;
 
    setState(() => _procesandoAprobacion = true);
 
    // CORRECCIÓN DE SEGURIDAD: Convertir ID a String de manera segura (.toString())
    final String solicitudId = _solicitudSeleccionada!['id'].toString();
    final String clienteId = _solicitudSeleccionada!['cliente_id'].toString();
    final double monto = (_solicitudSeleccionada!['monto_solicitado'] ?? 0.0).toDouble();
 
    try {
      // A. Si es APROBADO, buscamos la cuenta para inyectar fondos
      if (nuevoEstado == 'APROBADO') {
        final cuentaData = await _supabase
            .from('cuentas')
            .select('id, saldo')
            .eq('cliente_id', clienteId)
            .maybeSingle();
 
        if (cuentaData == null) {
          throw 'El cliente no tiene una cuenta activa para recibir el desembolso.';
        }
 
        final String cuentaId = cuentaData['id'].toString();
        final double saldoActual = (cuentaData['saldo'] ?? 0.0).toDouble();
 
        // Actualizamos saldo de cuenta
        await _supabase.from('cuentas').update({
          'saldo': saldoActual + monto,
        }).eq('id', cuentaId);
 
        // Registramos el movimiento bancario
        await _supabase.from('movimientos').insert({
          'cuenta_id': cuentaId,
          'monto': monto,
          'tipo': 'DEPOSITO',
          'descripcion': 'DESEMBOLSO CREDITO CAPITAL DE TRABAJO',
        });
      }
 
      // B. Actualizamos el estado, plazo final y cuota real calculada en la solicitud
      await _supabase.from('solicitudes').update({
        'estado': nuevoEstado,
        'plazo_meses': _plazoSeleccionado,
        'cuota_estimada': _cuotaCalculada,
      }).eq('id', solicitudId);
 
      _mostrarSnackBar('Solicitud procesada como $nuevoEstado con éxito.');
      
      setState(() {
        _solicitudSeleccionada = null; // Cerramos el panel derecho
      });
 
      _obtenerSolicitudesPendientes(); // Recargamos la lista
 
    } catch (e) {
      _mostrarSnackBar('Error al procesar: $e');
    } finally {
      setState(() => _procesandoAprobacion = false);
    }
  }
 
  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }
 
  @override
  Widget build(BuildContext context) {
    const Color colorCompartamos = Color(0xFFC71585);
 
    return Scaffold(
      appBar: AppBar(
        title: const Text("Evaluación de Créditos", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: colorCompartamos,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _obtenerSolicitudesPendientes,
          )
        ],
      ),
      backgroundColor: const Color(0xFFF9F6F8),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: colorCompartamos))
          : Row(
              children: [
                // PANEL IZQUIERDO: Lista de Clientes en Espera
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
                    child: _solicitudesPendientes.isEmpty
                        ? const Center(child: Text('No hay solicitudes pendientes.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _solicitudesPendientes.length,
                            itemBuilder: (context, index) {
                              final sol = _solicitudesPendientes[index];
                              final cliente = sol['clientes'] ?? {};
                              final double monto = (sol['monto_solicitado'] ?? 0.0).toDouble();
 
                              return ListTile(
                                selected: _solicitudSeleccionada?['id'] == sol['id'],
                                selectedTileColor: colorCompartamos.withOpacity(0.05),
                                leading: const Icon(Icons.person_search_outlined, color: Colors.orange),
                                title: Text(cliente['nombre_completo'] ?? 'Cliente Desconocido', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('DNI: ${cliente['dni'] ?? '-'} • S/ ${monto.toStringAsFixed(2)}'),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                onTap: () {
                                  setState(() {
                                    _solicitudSeleccionada = sol;
                                    _plazoSeleccionado = 12; // Resetea a 12 meses por defecto al cambiar de cliente
                                  });
                                  _recalcularCuota(monto);
                                },
                              );
                            },
                          ),
                  ),
                ),
 
                // PANEL DERECHO: Formulario de Evaluación Dinámica y Decisión
                Expanded(
                  flex: 1,
                  child: _solicitudSeleccionada == null
                      ? const Center(child: Text('Selecciona un cliente de la lista para evaluarlo.', style: TextStyle(color: Colors.grey)))
                      : Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ANÁLISIS Y CONDICIONES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorCompartamos)),
                                  const Divider(height: 24),
                                  
                                  Text('Cliente: ${_solicitudSeleccionada!['clientes']?['nombre_completo'] ?? 'Desconocido'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  Text('Monto Solicitado: S/ ${(_solicitudSeleccionada!['monto_solicitado'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Motivo del Crédito: ${_solicitudSeleccionada!['proposito'] ?? _solicitudSeleccionada!['motivo'] ?? 'Capital de Trabajo'}',
                                    style: const TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic),
                                  ),
                                  const Divider(height: 30),
 
                                  const Text('Definir Plazo de Cuotas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<int>(
                                    value: _plazoSeleccionado,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF9F6F8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    items: [3, 6, 12, 18, 24].map((int mes) {
                                      return DropdownMenuItem<int>(
                                        value: mes,
                                        child: Text('$mes Meses'),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _plazoSeleccionado = val;
                                        });
                                        _recalcularCuota((_solicitudSeleccionada!['monto_solicitado'] as num).toDouble());
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 20),
 
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: const Color(0xFFF9F6F8), borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Cuota Mensual Calculada:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        Text('S/ ${_cuotaCalculada.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorCompartamos)),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
 
                                  // Botones de Acción: ACEPTAR O RECHAZAR
                                  _procesandoAprobacion
                                      ? const Center(child: CircularProgressIndicator(color: colorCompartamos))
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
                                                onPressed: () => _procesarDecision('RECHAZADO'),
                                                icon: const Icon(Icons.cancel_outlined),
                                                label: const Text("RECHAZAR"),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
                                                onPressed: () => _procesarDecision('APROBADO'),
                                                icon: const Icon(Icons.check_circle_outline),
                                                label: const Text("ACEPTAR"),
                                              ),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}