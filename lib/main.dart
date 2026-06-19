import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importaciones con rutas absolutas actualizadas al módulo de ventas
import 'package:appbanco_compartamos_venta/viewmodel/auth_viewmodel.dart';
import 'package:appbanco_compartamos_venta/viewmodel/home_viewmodel.dart';
import 'package:appbanco_compartamos_venta/viewmodel/venta_viewmodel.dart'; 
import 'package:appbanco_compartamos_venta/navigation/app_routes.dart';
import 'package:appbanco_compartamos_venta/ui/theme/app_theme.dart';

void main() async {
  // 1. Obligatorio antes de inicializar servicios nativos o externos en Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializamos Supabase con las credenciales de producción para ventas
  await Supabase.initialize(
    url: 'https://vnlegvqusovnvtbeamtf.supabase.co',
    anonKey: 'sb_publishable_artaXq2zUmGWACNx0n4tWg_J3ZmLZ2m',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(),
        ),
        // Solucionado: Ahora provee correctamente el nuevo VentaViewModel globalizado
        ChangeNotifierProvider(
          create: (_) => VentaViewModel(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: AppRoutes.login,
        // Carga las rutas del diccionario comercial optimizado
        routes: AppRoutes.getRoutes(),
      ),
    );
  }
}