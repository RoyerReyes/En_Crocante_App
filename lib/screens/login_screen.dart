import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/getwidget.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'login_form_screen.dart';
import 'registration_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Artboard? _riveArtboard;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    print("🔎 Intentando cargar el archivo de Rive...");
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final file = await RiveFile.asset('assets/animations/608-1177-food-loading-animation.riv');
      final artboard = file.mainArtboard;

      print("📋 Animaciones disponibles en el archivo:");
      for (var anim in artboard.animations) {
        print("   - ${anim.name}");
      }
      print("📋 State Machines disponibles:");
      for (var sm in artboard.stateMachines) {
        print("   - ${sm.name}");
      }

      StateMachineController? controller;

      controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
      if (controller != null) {
        print("✅ State Machine 'State Machine 1' encontrada y cargada.");
        artboard.addController(controller);
      } else {
        print("⚠️ No se encontró 'State Machine 1'. Intentando con la primera disponible...");
        if (artboard.stateMachines.isNotEmpty) {
          final firstSM = artboard.stateMachines.first;
          controller = StateMachineController.fromArtboard(artboard, firstSM.name);
          if (controller != null) {
            artboard.addController(controller);
            print("✅ State Machine '${firstSM.name}' cargada con éxito.");
          }
        }
      }

      if (controller == null && artboard.animations.isNotEmpty) {
        print("⚠️ No se encontraron State Machines. Usando animación simple.");
        final firstAnim = artboard.animations.first;
        artboard.addController(SimpleAnimation(firstAnim.name));
        print("✅ Animación simple '${firstAnim.name}' cargada.");
      } else if (controller == null) {
        print("❌ No se encontraron ni State Machines ni animaciones simples.");
        throw Exception("El archivo Rive no contiene elementos reproducibles.");
      }

      setState(() {
        _riveArtboard = artboard;
      });

    } catch (e) {
      print("❌ ERROR al cargar el archivo de Rive: $e");
      setState(() {
        _errorMessage = "Error al cargar la animación";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_riveArtboard != null)
            Positioned.fill(
              child: Rive(
                artboard: _riveArtboard!,
                fit: BoxFit.cover,
              ),
            ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Spacer(flex: 5), // <--- CAMBIADO DE 3 A 5 PARA BAJAR EL CONTENIDO
                  const Text(
                    'Bienvenido a\nEn Crocante',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'La mejor comida, a un solo toque de distancia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48.0),
                  GFButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const LoginFormScreen()),
                      );
                    },
                    text: "Iniciar Sesión",
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),          
                    type: GFButtonType.solid,
                    shape: GFButtonShape.pills,
                    size: GFSize.LARGE,
                    blockButton: true,
                    color: const Color(0xFFFF6B35),
                  ),
                  const SizedBox(height: 16.0),
                  GFButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                      );                    
                    },
                    text: "Registrarse",
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),                    
                    type: GFButtonType.outline,
                    shape: GFButtonShape.pills,
                    size: GFSize.LARGE,
                    blockButton: true,
                    color: Colors.white,
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),

          if (_isLoading || _errorMessage != null)
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
