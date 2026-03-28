import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class UpdateDialog extends StatelessWidget {
  final String updateUrl;
  final String remoteVersion;

  const UpdateDialog({
    Key? key,
    required this.updateUrl,
    required this.remoteVersion,
  }) : super(key: key);

  static void show(BuildContext context, String url, String version, bool force) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => !force,
          child: UpdateDialog(updateUrl: url, remoteVersion: version),
        );
      },
    );
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(updateUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Colors.deepOrange, size: 28),
          SizedBox(width: 10),
          Text('¡Actualización Disponible!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Una nueva versión de la aplicación (v$remoteVersion) está lista para instalarse.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'Para continuar procesando órdenes de manera segura, es necesario actualizar presionando el siguiente botón.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton.icon(
          onPressed: _launchUrl,
          icon: const Icon(Icons.download),
          label: const Text('Descargar e Instalar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
