import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:appbanco_compartamos_venta/model/venta_model.dart';

class VentaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Método para obtener todas las ventas de la base de datos de Supabase
  Future<List<VentaModel>> obtenerVentas() async {
    try {
      final response = await _supabase
          .from('clientes') // Nombre de la tabla en Supabase
          .select()
          .order('nombre_completo', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => VentaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar la cartera de ventas: $e');
    }
  }
}