import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:appbanco_compartamos_venta/model/venta_model.dart';
import 'package:appbanco_compartamos_venta/services/solicitud_service.dart';

class DetalleVentaScreen extends StatefulWidget {
  final dynamic argumentos;
  final VentaModel? venta;
  final Map<String, dynamic>? clienteData;

  const DetalleVentaScreen({
    super.key, 
    this.argumentos,
    this.venta,
    this.clienteData,
  });

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  final SolicitudService _solicitudService = SolicitudService();

  String _idSolicitud = '';
  String _idVenta = '';

  String _nombreCompleto = 'Cliente Desconocido';
  String _dni = '---';
  String _giroNegocio = 'SERV';
  String _zonaUbicacion = 'RUR';

  double _montoEvaluado = 0.0;          
  double _montoSolicitadoActivo = 0.0;  
  double _ingresoMensual = 0.0;
  double _gastosMensuales = 0.0;
  double _deudaTotalSistema = 0.0;
  double _cuotaDeudaEst = 0.0;

  String _estadoSolicitud = ''; 
  int _plazoSeleccionado = 12; 
  double _cuotaMensualSimulada = 0.0;
  bool _procesandoAccion = false;
  bool _cargandoHistorial = true;
  List<Map<String, dynamic>> _historialSolicitudes = [];
  
  // NUEVO: Variables para capturar el motivo que viene de la app cliente y el sustento del asesor
  String _propositoCliente = 'No especificado';
  final _sustentoAsesorController = TextEditingController();

  final List<int> _plazosPermitidos = [6, 12, 18, 24, 36];
  final double _factorInteres = 1.08611;

  @override
  void initState() {
    super.initState();
    _inicializarYHomologarDatosBase();
    _cargarHistorialYVincularSolicitudActiva();
  }

  @override
  void dispose() {
    _sustentoAsesorController.dispose();
    super.dispose();
  }

  void _inicializarYHomologarDatosBase() {
    final args = widget.argumentos ?? widget.venta ?? widget.clienteData;
    if (args == null) return;

    if (args is VentaModel) {
      _idVenta = args.id ?? '';
      _nombreCompleto = args.nombreCompleto ?? 'Cliente Desconocido';
      _dni = args.dni ?? '---';
      _giroNegocio = args.tipoNegocio ?? 'SERV'; 
      _zonaUbicacion = args.zona ?? 'RUR'; 
      
      _ingresoMensual = (args.ingresoMensual ?? 0.0).toDouble();
      _gastosMensuales = (args.gastoMensual ?? 0.0).toDouble();
      _deudaTotalSistema = (args.deudactual ?? 0.0).toDouble(); 
      
      _montoEvaluado = (args.montoMaximo ?? 0.0).toDouble(); 
      _montoSolicitadoActivo = _montoEvaluado; 
      
      _estadoSolicitud = ''; 
      _plazoSeleccionado = 12; 
      _propositoCliente = 'No especificado';
    } else if (args is Map<String, dynamic>) {
      _idSolicitud = (args['id'] ?? '').toString();
      _idVenta = (args['venta_id'] ?? args['id'] ?? '').toString();
      _estadoSolicitud = args['estado'] ?? '';
      
      final cliente = args['clientes'] ?? args;
      _nombreCompleto = cliente['nombre_completo'] ?? cliente['nombre'] ?? 'Cliente Desconocido';
      _dni = cliente['dni'] ?? '---';
      _giroNegocio = cliente['tipo_negocio'] ?? cliente['giro'] ?? 'SERV';
      _zonaUbicacion = cliente['zona'] ?? 'RUR';

      final rawMontoMax = cliente['monto_maximo'] ?? cliente['montoMaximo'] ?? args['monto_maximo'] ?? 0.0;
      _montoEvaluado = (rawMontoMax as num).toDouble();

      final rawMontoSol = args['monto_solicitand'] ?? args['monto_solicitado'] ?? args['monto'] ?? _montoEvaluado;
      _montoSolicitadoActivo = (rawMontoSol as num).toDouble();
      
      final dynamic plazoRaw = args['plazo_meses'] ?? args['plazo'];
      int plazoParseado = 12;
      if (plazoRaw != null) {
        if (plazoRaw is num) {
          plazoParseado = plazoRaw.toInt();
        } else {
          plazoParseado = int.tryParse(plazoRaw.toString()) ?? 12;
        }
      }
      _plazoSeleccionado = _plazosPermitidos.contains(plazoParseado) ? plazoParseado : 12;

      final rawIngreso = cliente['ingreso_mensual'] ?? cliente['ingresoMensual'] ?? 0.0;
      _ingresoMensual = (rawIngreso as num).toDouble();

      final rawGasto = cliente['gasto_mensual'] ?? cliente['gastoMensual'] ?? 0.0;
      _gastosMensuales = (rawGasto as num).toDouble();

      final rawDeuda = cliente['deudactual'] ?? cliente['deuda_actual'] ?? 0.0;
      _deudaTotalSistema = (rawDeuda as num).toDouble();
      
      // Mapeamos el propósito guardado por el cliente
      _propositoCliente = args['proposito'] ?? cliente['proposito'] ?? 'No especificado';
    }

    _cuotaDeudaEst = _deudaTotalSistema * 0.10;
    _recalcularCuotaSimulada();
  }

  Future<void> _cargarHistorialYVincularSolicitudActiva() async {
    if (_idVenta.isEmpty) {
      setState(() => _cargandoHistorial = false);
      return;
    }

    try {
      final solicitudes = await _solicitudService.obtenerSolicitudesPorVenta(_idVenta);
      if (!mounted) return; 

      setState(() {
        _historialSolicitudes = solicitudes;
        _cargandoHistorial = false;

        final solicitudesPendientes = solicitudes.where((sol) => sol['estado'] == 'PENDIENTE');

        if (solicitudesPendientes.isNotEmpty) {
          final solicitudActiva = solicitudesPendientes.first; 
          _idSolicitud = (solicitudActiva['id'] ?? '').toString();
          _estadoSolicitud = 'PENDIENTE'; 
          
          final rawMontoSol = solicitudActiva['monto_solicitado'] ?? _montoEvaluado;
          _montoSolicitadoActivo = (rawMontoSol as num).toDouble();
          
          // Rescatamos el propósito también desde la recarga del stream/historial activo
          _propositoCliente = solicitudActiva['proposito'] ?? 'No especificado';
          
          final dynamic plazoBdRaw = solicitudActiva['plazo_meses'] ?? solicitudActiva['plazo'];
          int plazoBd = 12;
          if (plazoBdRaw != null) {
            plazoBd = plazoBdRaw is num ? plazoBdRaw.toInt() : (int.tryParse(plazoBdRaw.toString()) ?? 12);
          }
          _plazoSeleccionado = _plazosPermitidos.contains(plazoBd) ? plazoBd : 12;
        } else {
          _estadoSolicitud = ''; 
          _montoSolicitadoActivo = _montoEvaluado;
        }
      });
      
      _recalcularCuotaSimulada();
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoHistorial = false);
    }
  }

  void _recalcularCuotaSimulada() {
    if (_montoSolicitadoActivo <= 0 || _plazoSeleccionado <= 0) {
      setState(() {
        _cuotaMensualSimulada = 0.0;
      });
      return;
    }
    setState(() {
      _cuotaMensualSimulada = (_montoSolicitadoActivo * _factorInteres) / _plazoSeleccionado;
    });
  }

  Future<void> _procesarDecisionAsesor(String nuevoEstado) async {
    if (_idSolicitud.isEmpty || _idSolicitud == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: No se encontró un ID de solicitud válido."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final sustento = _sustentoAsesorController.text.trim();
    if (sustento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, ingresa el sustento o respuesta para el cliente."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _procesandoAccion = true);

    try {
      // Guardamos la decisión completa incluyendo el sustento del asesor
      await Supabase.instance.client
          .from('solicitudes')
          .update({
            'estado': nuevoEstado,
            'plazo_meses': nuevoEstado == 'APROBADO' ? _plazoSeleccionado : 0,
            'cuota_estimada': nuevoEstado == 'APROBADO' ? _cuotaMensualSimulada : 0.0,
            'sustento_asesor': sustento,
          })
          .eq('id', _idSolicitud);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Solicitud enviada como: $nuevoEstado"),
          backgroundColor: nuevoEstado == 'APROBADO' ? Colors.green : Colors.red,
        ),
      );

      _sustentoAsesorController.clear();
      await _cargarHistorialYVincularSolicitudActiva();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $error"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _procesandoAccion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color colorCompartamos = Theme.of(context).primaryColor;
    
    final double ingresos = _ingresoMensual;
    final double gastos = _gastosMensuales;
    final double cuotaDeuda = _cuotaDeudaEst;
    final double excedenteNeto = ingresos - gastos - cuotaDeuda;

    final solicitudesParaHistorial = _historialSolicitudes;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorCompartamos,
        title: Text(_nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF9F6F8),
      body: _procesandoAccion
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección 1: Datos de Identificación
                  Text("Información de la Venta / Solicitante", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorCompartamos)),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          ListTile(
                            dense: true, 
                            horizontalTitleGap: 8,
                            leading: const Icon(Icons.badge_outlined, color: Colors.grey, size: 22),
                            title: const Text("DNI", style: TextStyle(color: Colors.grey, fontSize: 11)), 
                            subtitle: Text(_dni, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14))
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            dense: true, 
                            horizontalTitleGap: 8,
                            leading: const Icon(Icons.storefront_outlined, color: Colors.grey, size: 22),
                            title: const Text("Giro de Negocio", style: TextStyle(color: Colors.grey, fontSize: 11)), 
                            subtitle: Text(_giroNegocio.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14))
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            dense: true, 
                            horizontalTitleGap: 8,
                            leading: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 22),
                            title: const Text("Zona / Ubicación", style: TextStyle(color: Colors.grey, fontSize: 11)), 
                            subtitle: Text(_zonaUbicacion.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14))
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sección 2: Análisis Financiero
                  Text("Análisis Financiero de Ventas", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorCompartamos)),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildRowFinanciero("Ingreso Mensual:", "S/ ${ingresos.toStringAsFixed(2)}", Colors.green),
                          _buildRowFinanciero("Gastos Mensuales:", "S/ ${gastos.toStringAsFixed(2)}", Colors.red),
                          _buildRowFinanciero("Deuda Total Sistema:", "S/ ${_deudaTotalSistema.toStringAsFixed(2)}", Colors.orange.shade800),
                          _buildRowFinanciero("Cuota Mensual Est. (Deuda):", "S/ ${cuotaDeuda.toStringAsFixed(2)}", Colors.orange.shade900),
                          const Divider(),
                          _buildRowFinanciero(
                            "Excedente Neto:", 
                            excedenteNeto < 0 ? "- S/ ${excedenteNeto.abs().toStringAsFixed(2)}" : "S/ ${excedenteNeto.toStringAsFixed(2)}", 
                            excedenteNeto < 0 ? Colors.red : Colors.green.shade700, 
                            esNegrita: true
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recuadro de Capacidad de Pago
                  if (excedenteNeto < 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red)),
                      child: const Column(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                          SizedBox(height: 4),
                          Text("EXCEDENTE INSUFICIENTE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          Text("Monto Máximo Sugerido: S/ 0.00", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 30),
                          const SizedBox(height: 4),
                          const Text("CAPACIDAD DE PAGO POSITIVA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Text("Monto Máximo Sugerido: S/ ${_montoEvaluado.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Sección 3: Panel de Evaluación Activa
                  if (_estadoSolicitud == 'PENDIENTE') ...[
                    _buildPanelEvaluacionPendiente(colorCompartamos),
                    const SizedBox(height: 25),
                  ],

                  // Sección 4: Historial de Solicitudes
                  Text("Historial de Solicitudes de Venta", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorCompartamos)),
                  const SizedBox(height: 10),
                  _cargandoHistorial
                      ? const Center(child: CircularProgressIndicator())
                      : solicitudesParaHistorial.isEmpty
                          ? const Card(
                              elevation: 0,
                              color: Color(0xFFF2ECEF),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.folder_open_outlined, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text("No se registran solicitudes anteriores.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(), 
                              itemCount: solicitudesParaHistorial.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final sol = solicitudesParaHistorial[index];
                                final double mnt = (sol['monto_solicitado'] as num? ?? 0.0).toDouble();
                                final int meses = sol['plazo_meses'] ?? 12;
                                final String estado = (sol['estado'] ?? 'PENDIENTE').toUpperCase();
                                
                                Color colorBadge;
                                Color colorTextoBadge;
                                IconData iconoEstado;

                                switch (estado) {
                                  case 'APROBADO':
                                    colorBadge = const Color(0xFFE8F5E9);
                                    colorTextoBadge = Colors.green.shade700;
                                    iconoEstado = Icons.check_circle_rounded;
                                    break;
                                  case 'RECHAZADO':
                                    colorBadge = const Color(0xFFFFEBEE);
                                    colorTextoBadge = Colors.red.shade700;
                                    iconoEstado = Icons.cancel_rounded;
                                    break;
                                  default: 
                                    colorBadge = const Color(0xFFFFF3E0);
                                    colorTextoBadge = Colors.orange.shade800;
                                    iconoEstado = Icons.pending_rounded;
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        spreadRadius: 1,
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                    border: Border.all(color: Colors.grey.shade200)
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: CircleAvatar(
                                      backgroundColor: colorBadge.withOpacity(0.6),
                                      child: Icon(Icons.monetization_on_outlined, color: colorTextoBadge),
                                    ),
                                    title: Text(
                                      "S/ ${mnt.toStringAsFixed(2)}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Text("Plazo: $meses meses", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                            ],
                                          ),
                                          if (sol['proposito'] != null) ...[
                                            const SizedBox(height: 2),
                                            Text("Motivo: ${sol['proposito']}", style: const TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic)),
                                          ]
                                        ],
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: colorBadge,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(iconoEstado, size: 14, color: colorTextoBadge),
                                          const SizedBox(width: 4),
                                          Text(
                                            estado,
                                            style: TextStyle(color: colorTextoBadge, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildPanelEvaluacionPendiente(Color colorCompartamos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade800)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "EVALUACIÓN PENDIENTE - S/ ${_montoSolicitadoActivo.toStringAsFixed(2)}", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)
            )
          ),
          const Divider(height: 24),
          
          // MOSTRAR EL MOTIVO ENVIADO POR EL CLIENTE
          const Text("Destino / Motivo del Crédito del Cliente:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _propositoCliente,
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 16),
          
          const Text("Seleccionar Plazo Financiero:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400)
              ),
              child: DropdownButton<int>(
                value: _plazoSeleccionado,
                isExpanded: true,
                dropdownColor: Colors.white,
                items: _plazosPermitidos.map((int mes) {
                  return DropdownMenuItem<int>(
                    value: mes, 
                    child: Text("$mes Meses", style: const TextStyle(fontSize: 14))
                  );
                }).toList(),
                onChanged: (int? nuevoPlazo) {
                  if (nuevoPlazo != null) {
                    setState(() {
                      _plazoSeleccionado = nuevoPlazo;
                    });
                    _recalcularCuotaSimulada();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cuota Mensual Estimada:"),
              Text("S/ ${_cuotaMensualSimulada.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: colorCompartamos)),
            ],
          ),
          const SizedBox(height: 16),
          
          // CAMPO PARA QUE EL ASESOR INGRESE SU RESPUESTA / SUSTENTO
          const Text("Sustento / Comentarios del Asesor:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _sustentoAsesorController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: "Ej: Cliente cumple con el excedente requerido. Campaña escolar aprobada.",
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => _procesarDecisionAsesor('RECHAZADO'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("RECHAZAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => _procesarDecisionAsesor('APROBADO'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("APROBAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRowFinanciero(String label, String valor, Color colorValor, {bool esNegrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: esNegrita ? FontWeight.bold : FontWeight.normal)),
          Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorValor)),
        ],
      ),
    );
  }
}