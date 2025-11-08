import 'package:flutter/material.dart';
import 'package:encrocante_app/screens/login_screen.dart'; // Importa tu pantalla de login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'En Crocante App',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange, // Usamos un color naranja como primario
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF6B35), // Color de AppBar
          foregroundColor: Colors.white, // Color del texto de AppBar
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35), // Color de los botones elevados
            foregroundColor: Colors.white, // Color del texto de los botones
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0), // Botones redondeados
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2.0),
          ),
          labelStyle: const TextStyle(color: Color(0xFFFF6B35)),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)), // <-- ¡Aquí está la corrección!
          ),
        ),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
