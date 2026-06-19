import 'package:flutter/material.dart';
import 'package:appbanco_compartamos_venta/view/home/dashboard_screen.dart';
import 'package:appbanco_compartamos_venta/view/home/credito_grupal_screen.dart';
import 'package:appbanco_compartamos_venta/view/home/evaluaciones_screen.dart';
import 'package:appbanco_compartamos_venta/view/home/perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Lista ordenada de los 4 módulos de ventas en producción
  final List<Widget> _pantallas = [
    const DashboardScreen(),     // Pestaña 0
    const CreditoGrupalScreen(), // Pestaña 1
    const EvaluacionesScreen(),  // Pestaña 2
    const PerfilScreen(),        // Pestaña 3
  ];

  @override
  Widget build(BuildContext context) {
    final Color colorCompartamos = Theme.of(context).primaryColor;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pantallas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: colorCompartamos,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Ventas'),
          BottomNavigationBarItem(icon: Icon(Icons.group_add), label: 'Crédito Grupal'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Evaluaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi Perfil'),
        ],
      ),
    );
  }
}