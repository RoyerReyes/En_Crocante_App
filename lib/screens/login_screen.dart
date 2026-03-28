import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import '../providers/theme_provider.dart';
import 'login_form_screen.dart';
import 'registration_screen.dart'; 
import '../constants/app_constants.dart'; 
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/update_dialog.dart';
import '../providers/config_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppVersion();
    });
  }

  Future<void> _checkAppVersion() async {
    try {
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      await configProvider.fetchRemoteConfig();
      
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; 
      final remoteVersion = configProvider.otaVersion;
      
      final currentParts = currentVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final remoteParts = remoteVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      
      bool isOutdated = false;
      for (int i = 0; i < 3; i++) {
        final c = currentParts.length > i ? currentParts[i] : 0;
        final r = remoteParts.length > i ? remoteParts[i] : 0;
        if (r > c) {
          isOutdated = true;
          break;
        } else if (r < c) {
          break;
        }
      }

      if (isOutdated && mounted) {
        UpdateDialog.show(
          context,
          configProvider.otaUrl,
          remoteVersion,
          configProvider.otaForceUpdate,
        );
      }
    } catch (e) {
      debugPrint("OTA Check Error: $e");
    }
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
                alignment: Alignment.topCenter, // Move animation up
              ),
            ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1), // Lighter top
                    Colors.black.withOpacity(0.8), // Darker bottom for text
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const Spacer(flex: 8), // Push content further down
                            const Text(
                              'Bienvenido a\nEn Crocante',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
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
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const LoginFormScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Iniciar Sesión",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                                );                    
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                "Registrarse",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(flex: 1), // Decrease bottom padding
                            // Theme toggle inside scrollable area or kept absolute?
                            // Keeping it absolute in Stack (outside this builder) is better, 
                            // but if we want it to scroll with content it should be here.
                            // The original code had it in the Stack, separate from Column.
                            // I will keep the Column clean and leave the Theme Toggle outside, 
                            // but wait, the original code had Stack > Children > [Padding(Column), Positioned(ThemeToggle)].
                            // I am replacing the SafeArea child.
                            // I should preserve the Theme Toggle.
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Theme Toggle Positioned (Moved outside SafeArea/LayoutBuilder to stay fixed or inside?)
          // If it stays fixed, it might overlap content on small screens.
          // Better to keep it Positioned on top of everything.
          Positioned(
            top: MediaQuery.of(context).padding.top + 16, // Adjust for SafeArea
            right: 16,
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return IconButton(
                  icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
                  onPressed: () {
                    themeProvider.toggleTheme(!themeProvider.isDarkMode);
                  },
                );
              },
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
