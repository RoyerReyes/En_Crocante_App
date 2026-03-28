import 'package:flutter/material.dart';

import '../models/cliente_model.dart';

class OrderDetailsProvider with ChangeNotifier {
  String _nombreCliente = '';
  int _numeroMesa = 1; // Valor por defecto
  Cliente? _clienteSeleccionado;
  String _tipoAtencion = 'mesa'; // 'mesa', 'llevar', 'delivery'
  bool _esDelivery = false;

  String get nombreCliente => _nombreCliente;
  int get numeroMesa => _numeroMesa;
  Cliente? get clienteSeleccionado => _clienteSeleccionado;
  String get tipoAtencion => _tipoAtencion;
  bool get esDelivery => _esDelivery;

  void setNombreCliente(String name) {
    _nombreCliente = name;
    // Si cambiamos nombre manualmente y teníamos un cliente seleccionado que no coincide, podríamos deseleccionarlo.
    // Pero por flexibilidad, permitimos editar el nombre libremente o seleccionarlo.
    notifyListeners();
  }

  void setNumeroMesa(int tableNumber) {
    _numeroMesa = tableNumber;
    notifyListeners();
  }
  
  void setCliente(Cliente? cliente) {
    _clienteSeleccionado = cliente;
    if (cliente != null) {
      _nombreCliente = cliente.nombre; // Auto-fill nombre
    }
    notifyListeners();
  }

  void setTipoAtencion(String tipo) {
    _tipoAtencion = tipo;
    // Si cambia a mesa, forzamos desactivar delivery y su costo.
    if (tipo == 'mesa') {
      _esDelivery = false;
    }
    notifyListeners();
  }

  void setEsDelivery(bool value) {
    _esDelivery = value;
    if (value) {
      _tipoAtencion = 'delivery';
    } else if (_tipoAtencion == 'delivery') {
       _tipoAtencion = 'llevar';
    }
    notifyListeners();
  }

  // Método para reiniciar los datos del cliente/mesa si es necesario
  void resetClientDetails() {
    _nombreCliente = '';
    _numeroMesa = 1;
    _clienteSeleccionado = null;
    _tipoAtencion = 'mesa';
    _esDelivery = false;
    notifyListeners();
  }
}
