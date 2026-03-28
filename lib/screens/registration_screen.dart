import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String _name = '';
  String _username = ''; // Cambiado de _email a _username
  String _password = '';
  String _selectedRole = 'mesero';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _authService.register({
          'nombre': _name,
          'usuario': _username, // Usamos _username aquí
          'password': _password,
          'rol': _selectedRole,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Registro exitoso! Ya puedes iniciar sesión.')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        String displayMessage = 'Error al registrar usuario.';
        if (e is Exception) {
          displayMessage = e.toString().replaceAll('Exception: ', '');
        }
        if (mounted) {
          setState(() {
            _errorMessage = displayMessage;
          });
        }
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
        title: const Text('Registro de Usuario'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Crea tu cuenta para empezar a disfrutar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person),
                  ),
                  keyboardType: TextInputType.name,
                  validator: (value) => value!.isEmpty ? 'Por favor, ingresa tu nombre' : null,
                  onSaved: (value) => _name = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Usuario', // Cambiado de 'Email' a 'Usuario'
                    prefixIcon: Icon(Icons.person_outline), // Cambiado el icono para diferenciarlo del email
                  ),
                  keyboardType: TextInputType.text, // Cambiado de emailAddress a text
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Por favor, ingresa un nombre de usuario'; // Mensaje de validación actualizado
                    }
                    return null;
                  },
                  onSaved: (value) => _username = value!, // Ahora guarda en _username
                ),
                const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.work),
                    ),
                    value: _selectedRole,
                    items: const [
                       DropdownMenuItem(value: 'mesero', child: Text('Mesero')),
                       DropdownMenuItem(value: 'cocinero', child: Text('Cocinero')),
                       DropdownMenuItem(value: 'admin', child: Text('Administrador (Demo)')),
                    ],
                    onChanged: (value) {
                      setState(() {
                         _selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                    onSaved: (value) => _password = value!,
                  ),
                const SizedBox(height: 32),
                
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _register,
                    child: const Text('Registrarse'),
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
      ),
    );
  }
}
