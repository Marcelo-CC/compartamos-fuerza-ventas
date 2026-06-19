import 'package:flutter/material.dart';
import 'package:appbanco_compartamos_venta/model/venta_model.dart';
import 'package:appbanco_compartamos_venta/services/venta_service.dart';

class VentaViewModel extends ChangeNotifier {
  final VentaService _ventaService = VentaService();

  List<VentaModel> _ventas = [];          // Lista maestra original de Supabase
  List<VentaModel> _ventasFiltradas = [];  // Lista que se muestra en la pantalla de la cartera
  
  bool _loading = false;
  String _error = '';

  // Getter expone la lista filtrada a la interfaz del listado comercial
  List<VentaModel> get ventas => _ventasFiltradas;
  bool get loading => _loading;
  String get error => _error;

  // Método que llama al servicio de Supabase y refresca la pantalla
  Future<void> cargarCartera() async {
    _loading = true;
    _error = '';
    notifyListeners(); 

    try {
      _ventas = await _ventaService.obtenerVentas();
      _ventasFiltradas = List.from(_ventas); // Al cargar, mostramos todos por defecto
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _bottomNotifyListeners(); 
    }
  }

  // Filtra la lista localmente por Nombre o DNI sin golpear nuevamente la base de datos
  void filtrarVentas(String query) {
    if (query.isEmpty) {
      _ventasFiltradas = List.from(_ventas); // Si el buscador está vacío, muestra todos
    } else {
      final lowercaseQuery = query.toLowerCase();
      _ventasFiltradas = _ventas.where((venta) {
        final coincideNombre = venta.nombreCompleto.toLowerCase().contains(lowercaseQuery);
        final coincideDni = venta.dni.contains(lowercaseQuery);
        return coincideNombre || coincideDni;
      }).toList();
    }
    notifyListeners(); // Redibuja la pantalla de ventas con los resultados que calzan
  }

  // Helper interno para evitar duplicar código de notificación
  void _bottomNotifyListeners() {
    notifyListeners();
  }
}