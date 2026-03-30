import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salsa_provider.dart';
import '../providers/presa_provider.dart';

class AdminInsumosTab extends StatelessWidget {
  const AdminInsumosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSalsasSection(context),
          const SizedBox(height: 32),
          _buildPresasSection(context),
        ],
      ),
    );
  }

  Widget _buildSalsasSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gestión de Salsas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _mostrarDialogSalsa(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                )
              ],
            ),
            const Divider(),
            Consumer<SalsaProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.salsas.isEmpty) return const Text('No hay salsas registradas');
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.salsas.length,
                  itemBuilder: (context, index) {
                    final salsa = provider.salsas[index];
                    return ListTile(
                      title: Text(salsa.nombre),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: salsa.activo,
                            onChanged: (val) {
                              provider.toggleSalsa(salsa.id, val);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _mostrarDialogSalsa(context, salsa),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmarDeleteSalsa(context, salsa.id, provider),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresasSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gestión de Presas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _mostrarDialogPresa(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                )
              ],
            ),
            const Divider(),
            Consumer<PresaProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.presas.isEmpty) return const Text('No hay presas registradas');
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.presas.length,
                  itemBuilder: (context, index) {
                    final presa = provider.presas[index];
                    return ListTile(
                      title: Text(presa.nombre),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: presa.activo,
                            onChanged: (val) {
                              provider.togglePresa(presa.id, val);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _mostrarDialogPresa(context, presa),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmarDeletePresa(context, presa.id, provider),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogSalsa(BuildContext context, dynamic salsa) {
    final controller = TextEditingController(text: salsa?.nombre ?? '');
    bool isActive = salsa?.activo ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(salsa == null ? 'Nueva Salsa' : 'Editar Salsa'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Nombre de la Salsa'),
                  ),
                  SwitchListTile(
                    title: const Text('¿Está Activa?'),
                    value: isActive,
                    onChanged: (val) => setState(() => isActive = val),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (controller.text.isEmpty) return;
                    final provider = Provider.of<SalsaProvider>(context, listen: false);
                    Navigator.pop(ctx);
                    if (salsa == null) {
                      await provider.addSalsa(controller.text, isActive);
                    } else {
                      await provider.updateSalsa(salsa.id, controller.text, isActive);
                    }
                  },
                  child: const Text('Guardar'),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _mostrarDialogPresa(BuildContext context, dynamic presa) {
    final controller = TextEditingController(text: presa?.nombre ?? '');
    bool isActive = presa?.activo ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(presa == null ? 'Nueva Presa' : 'Editar Presa'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Nombre de Presa'),
                  ),
                  SwitchListTile(
                    title: const Text('¿Está Activa?'),
                    value: isActive,
                    onChanged: (val) => setState(() => isActive = val),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (controller.text.isEmpty) return;
                    final provider = Provider.of<PresaProvider>(context, listen: false);
                    Navigator.pop(ctx);
                    if (presa == null) {
                      await provider.addPresa(controller.text, isActive);
                    } else {
                      await provider.updatePresa(presa.id, controller.text, isActive);
                    }
                  },
                  child: const Text('Guardar'),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _confirmarDeleteSalsa(BuildContext context, int id, SalsaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Salsa'),
        content: const Text('¿Estás seguro de eliminar esta salsa? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteSalsa(id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  void _confirmarDeletePresa(BuildContext context, int id, PresaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Presa'),
        content: const Text('¿Estás seguro de eliminar esta presa? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deletePresa(id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }
}
