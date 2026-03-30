import 'package:encrocante_app/screens/admin_dashboard_screen.dart';
import 'package:encrocante_app/screens/kitchen_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // ADDED for JSON encoding
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

  String _username = ''; 
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Map<String, String> _savedAccounts = {}; // ADDED para almacenar {usuario: contraseña}

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      
      String? accountsJson = prefs.getString('saved_accounts');
      if (accountsJson != null) {
        _savedAccounts = Map<String, String>.from(json.decode(accountsJson));
      }

      if (_rememberMe) {
        _usernameController.text = prefs.getString('saved_username') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  Future<void> _saveCredentials(String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    
    if (_rememberMe) {
      _savedAccounts[user] = pass;
      await prefs.setString('saved_accounts', json.encode(_savedAccounts));
      await prefs.setString('saved_username', user);
      await prefs.setString('saved_password', pass);
    } else {
      _savedAccounts.remove(user);
      await prefs.setString('saved_accounts', json.encode(_savedAccounts));
      await prefs.remove('saved_username');
      await prefs.remove('saved_password');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final Usuario? user = await _authService.login(_username, _password); 
        
        if (mounted && user != null) {
          await _saveCredentials(_username, _password);
          
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
              // Autocomplete widget replaced the TextFormField
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _savedAccounts.keys.toList();
                  }
                  return _savedAccounts.keys.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  }).toList();
                },
                onSelected: (String selection) {
                  _usernameController.text = selection;
                  _passwordController.text = _savedAccounts[selection] ?? '';
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  // Bind the external controller if not bound 
                  // Autocomplete uses its own controller internally, so we ensure sync
                  controller.addListener(() {
                    _usernameController.text = controller.text;
                  });
                  // If we already have something in _usernameController, set it (only on first build)
                  if (_usernameController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = _usernameController.text;
                  }

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Usuario', 
                      prefixIcon: Icon(Icons.person), 
                    ),
                    keyboardType: TextInputType.emailAddress, 
                    validator: (value) => value!.isEmpty ? 'Por favor, introduce tu nombre de usuario' : null, 
                    onSaved: (value) => _username = value!,
                  );
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
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
              const SizedBox(height: 8.0),
              CheckboxListTile(
                title: const Text('Recordar Credenciales', style: TextStyle(fontSize: 14)),
                value: _rememberMe,
                onChanged: (bool? value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFFFF6B35),
              ),
              const SizedBox(height: 24.0),
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
