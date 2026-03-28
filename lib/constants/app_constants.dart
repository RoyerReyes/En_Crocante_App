import 'package:flutter/material.dart';

class AppConstants {
  // Límites
  static const int maxCantidadItem = 100;
  static const int maxLengthNota = 500;
  static const int maxLengthObservaciones = 1000;
  static const int minLengthNombreCliente = 3;
  static const int maxLengthNombreCliente = 100;
  static const int minNumeroMesa = 1;
  static const int maxNumeroMesa = 100;

  // Tiempos
  static const int searchDebounceMs = 300;
  static const int snackbarDurationMs = 2000;
  static const int socketReconnectDelayMs = 2000;
  static const int maxSocketReconnectAttempts = 5;

  // Mensajes de error
  static const String errorGenerico = 'Ocurrió un error. Inténtalo de nuevo.';
  static const String errorConexion = 'Error de conexión. Verifica tu internet.';
  static const String errorTimeout = 'La solicitud tardó demasiado. Intenta nuevamente.';
  static const String errorServidor = 'Error del servidor. Contacta con soporte.';
  static const String carritoVacio = 'El carrito está vacío';
  static const String nombreClienteRequerido = 'El nombre del cliente es obligatorio';
  static const String nombreClienteInvalido = 'Nombre inválido (mínimo 3 caracteres, solo letras)';
  
  // Validación
  static final RegExp nombreClienteRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');

  // Colores
  static const Color primaryColor = Color(0xFFFF6B35);
}
