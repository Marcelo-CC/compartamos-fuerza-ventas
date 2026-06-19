import 'package:supabase_flutter/supabase_flutter.dart';

class SolicitudService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 📤 NUEVO / DEVUELTO: Guardar una nueva solicitud en la base de datos
  Future<void> registrarSolicitud({
    required String clienteId, 
    required double monto,
    required int plazo,
    required String proposito,
    required double cuotaEstimada,
  }) async {
    try {
      await _supabase.from('solicitudes').insert({
        'cliente_id': clienteId,
        'monto_solicitado': monto,
        'plazo_meses': plazo,
        'proposito': proposito,
        'cuota_estimada': cuotaEstimada,
        'estado': 'PENDIENTE',
      });
    } catch (e) {
      throw Exception("Error al guardar la solicitud en Supabase: $e");
    }
  }

  /// 📥 ESCUCHAR EN TIEMPO REAL (Para el StreamBuilder de la vista detalle)
  Stream<List<Map<String, dynamic>>> escucharSolicitudesPorVenta(String ventaId) {
    return _supabase
        .from('solicitudes')
        .stream(primaryKey: ['id'])
        .eq('cliente_id', ventaId)
        .order('fecha_creacion', ascending: false);
  }

  /// 📥 OBTENER HISTORIAL (Método clásico por si lo necesitas en otra vista)
  Future<List<Map<String, dynamic>>> obtenerSolicitudesPorVenta(String ventaId) async {
    try {
      final response = await _supabase
          .from('solicitudes')
          .select()
          .eq('cliente_id', ventaId)
          .order('fecha_creacion', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception("Error al obtener solicitudes: $e");
    }
  }

  /// ✔️ ACCIÓN: Registrar Aprobación Manual
  Future<void> aprobarSolicitud(String solicitudId) async {
    try {
      await _supabase
          .from('solicitudes')
          .update({'estado': 'APROBADO'})
          .eq('id', solicitudId);
    } catch (e) {
      throw Exception("Error al aprobar la solicitud: $e");
    }
  }

  /// ❌ ACCIÓN: Registrar Rechazo Manual
  Future<void> rechazarSolicitud(String solicitudId) async {
    try {
      await _supabase
          .from('solicitudes')
          .update({'estado': 'RECHAZADO'})
          .eq('id', solicitudId);
    } catch (e) {
      throw Exception("Error al rechazar la solicitud: $e");
    }
  }
}