import 'package:flutter/material.dart';
import 'package:encrocante_app/services/auth_service.dart'; // Importa el servicio de autenticación
import 'package:encrocante_app/screens/login_screen.dart'; // Importa la pantalla de login para navegar

// Definimos un modelo simple para cada item del menú para mantener el código limpio.
class DashboardItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  DashboardItem({required this.icon, required this.title, required this.onTap});
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Método para manejar el cierre de sesión
  Future<void> _logout(BuildContext context) async {
    final AuthService _authService = AuthService();
    await _authService.logout();
    // Navega a la pantalla de login y remueve todas las rutas anteriores
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lista de nuestros paneles. Por ahora, la navegación no hará nada.
    final List<DashboardItem> items = [
      DashboardItem(
        icon: Icons.fastfood,
        title: 'Platillos',
        onTap: () {
          // TODO: Navegar a la pantalla de gestión de platillos
          print('Navegando a Platillos...');
        },
      ),
      DashboardItem(
        icon: Icons.kitchen,
        title: 'Cocina',
        onTap: () {
          // TODO: Navegar a la pantalla de gestión de cocina
          print('Navegando a Cocina...');
        },
      ),
      DashboardItem(
        icon: Icons.history,
        title: 'Reportes',
        onTap: () {
          // TODO: Navegar a la pantalla de reportes
          print('Navegando a Reportes...');
        },
      ),
      DashboardItem(
        icon: Icons.settings,
        title: 'Configuración',
        onTap: () {
          // TODO: Navegar a la pantalla de configuración
          print('Navegando a Configuración...');
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        automaticallyImplyLeading: false, // Oculta el botón de regreso
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Icono de logout
            onPressed: () => _logout(context), // Llama al método de logout
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        // Define un grid de 2 columnas
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.2, // Ajusta la proporción de las tarjetas
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildDashboardCard(context, item);
        },
      ),
    );
  }

  // Widget helper para crear cada tarjeta del dashboard
  Widget _buildDashboardCard(BuildContext context, DashboardItem item) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(item.icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
