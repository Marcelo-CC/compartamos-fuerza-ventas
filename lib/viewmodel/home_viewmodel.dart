import 'package:flutter/material.dart';
import 'package:appbanco_compartamos_venta/model/usuario.dart';

class HomeViewModel extends ChangeNotifier {
  // Entidad de usuario dinámico adaptada al módulo de Fuerza de Ventas
  Usuario usuario = Usuario(
    nombre: "Marcelo Giovanni",
    saldo: 4500.80,
    deuda: 1200.00,
  );

  // Permite actualizar el estado del asesor logueado desde la vista de login
  void actualizarUsuario(Usuario nuevoUsuario) {
    usuario = nuevoUsuario;
    notifyListeners();
  }
}