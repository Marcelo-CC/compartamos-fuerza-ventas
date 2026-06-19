import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  // Instancia del cliente de Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  bool loading = false;
  bool success = false;
  String error = '';

  // Convertimos la función a async
  Future<void> login(String user, String pass) async {
    loading = true;
    success = false; // Reiniciamos el estado por si acaso
    error = '';
    notifyListeners();

    try {
      // Supabase por defecto pide Email. Como en los bancos se usa DNI o Usuario,
      // puedes ingresar usando un correo ficticio temporal (ej: 12345678@compartamos.com.pe)
      String email = user.contains('@') ? user : '$user@compartamos.com.pe';

      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: pass,
      );

      // Si la respuesta tiene un usuario válido, el login fue exitoso
      if (response.user != null) {
        success = true;
      } else {
        error = "No se pudo iniciar sesión comercial";
      }
    } on AuthException catch (e) {
      // Captura errores específicos de Supabase (ej: contraseña incorrecta)
      if (e.message.contains('Invalid login credentials')) {
        error = "Credenciales incorrectas";
      } else {
        error = e.message;
      }
    } catch (e) {
      // Captura cualquier otro error de conexión o del sistema
      error = "Error de conexión: No se pudo conectar al servidor corporativo";
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}