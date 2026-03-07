import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dio_client.dart'; // Importamos para reutilizar la URL base

class SocketService {
  // Patrón Singleton para asegurar una única instancia del servicio
  static final SocketService _instance = SocketService._internal();
  factory SocketService() {
    return _instance;
  }
  SocketService._internal();

  late IO.Socket socket;

  void connectToServer() {
    try {
      // Reutilizamos la URL base del cliente Dio para no tenerla duplicada.
      // La instancia 'dio' ya tiene la URL http://192.168.18.39:3000
      final baseUrl = dio.options.baseUrl;

      socket = IO.io(baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false, // Desactivamos la auto-conexión para controlar cuándo nos conectamos
      });

      // Solo intentamos conectar si no lo estamos ya.
      if (!socket.connected) {
        socket.connect();
      }

      socket.onConnect((_) {
        print('✅ Conectado al servidor de sockets');
      });

      // Escuchar el evento 'estadoPedidoActualizado'
      socket.on('estadoPedidoActualizado', (data) {
        print('📢 Estado del pedido actualizado: $data');
        
        // Aquí es donde en el futuro se actualizará el estado en la UI.
        // Por ejemplo, usando un Provider de Pedidos.
        // Ejemplo: context.read<PedidoProvider>().actualizarPedido(data);
      });

      socket.onDisconnect((_) => print('🔌 Desconectado del servidor de sockets'));
      socket.onError((err) => print('❌ Error de socket: $err'));

    } catch (e) {
      print(e.toString());
    }
  }

  void disconnect() {
    if (socket.connected) {
      socket.disconnect();
    }
  }
}
