import 'package:flutter/material.dart';
import '../view/auth/login_screen.dart';
import '../view/home/home_screen.dart';
import '../view/home/dashboard_screen.dart';
import '../view/home/detalle_venta_screen.dart';
import '../screen/nueva_solicitud_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String detalleVenta = '/detalle';
  static const String nuevaSolicitud = '/nueva_solicitud';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      home: (context) => const HomeScreen(), 
      dashboard: (context) => const DashboardScreen(),
      detalleVenta: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        // Pasamos los argumentos de forma dinámica para mapearlos internamente en la pantalla
        return DetalleVentaScreen(argumentos: args);
      },
      nuevaSolicitud: (context) => const NuevaSolicitudScreen(),
    };
  }
}