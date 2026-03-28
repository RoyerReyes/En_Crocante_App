import 'package:encrocante_app/screens/admin_dashboard_screen.dart';
import 'package:encrocante_app/screens/kitchen_screen.dart';
import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../services/auth_service.dart';
import 'platillos_screen.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key});

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String _username = ''; // CORRECCIÓN: Se revierte a _username
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // CORRECCIÓN: Se pasa _username al servicio
        final Usuario? user = await _authService.login(_username, _password); 
        
        if (mounted && user != null) {
          if (user.rol == 'admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          } else if (user.rol == 'cocina') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const KitchenScreen()),
            );
          }
          else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => PlatillosPage(userRole: user.rol, userName: user.nombre)),
            );
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                // CORRECCIÓN: La UI vuelve a pedir 'Usuario'
                decoration: const InputDecoration(
                  labelText: 'Usuario', 
                  prefixIcon: Icon(Icons.person), 
                ),
                keyboardType: TextInputType.emailAddress, // Se mantiene el teclado de email por conveniencia
                validator: (value) => value!.isEmpty ? 'Por favor, introduce tu nombre de usuario' : null, 
                onSaved: (value) => _username = value!,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock), 
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) => value!.isEmpty ? 'Por favor, introduce tu contraseña' : null,
                onSaved: (value) => _password = value!,
              ),
              const SizedBox(height: 32.0),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Entrar'),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
