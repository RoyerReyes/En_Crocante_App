import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:encrocante_app/models/platillo_model.dart';
import 'package:encrocante_app/services/platillo_service.dart';
import 'package:encrocante_app/widgets/dish_avatar.dart'; // Added
import 'package:encrocante_app/constants/api_constants.dart'; // Added

class AdminPlatilloManagementScreen extends StatefulWidget {
  const AdminPlatilloManagementScreen({super.key});

  @override
  State<AdminPlatilloManagementScreen> createState() => _AdminPlatilloManagementScreenState();
}

class _AdminPlatilloManagementScreenState extends State<AdminPlatilloManagementScreen> {
  final PlatilloService _platilloService = PlatilloService();
  List<Platillo> _platillos = [];
  List<Map<String, dynamic>> _categorias = []; // Store fetched categories
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch ALL platillos, including inactive ones
      final platillos = await _platilloService.getPlatillos(includeInactive: true);
      final categorias = await _platilloService.getCategorias();
      
      setState(() {
        _platillos = platillos;
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _togglePlatilloActivo(Platillo platillo, bool newValue) async {
    // Optimistic update
    final index = _platillos.indexWhere((p) => p.id == platillo.id);
    if (index != -1) {
      setState(() {
         // Create a copy with the new active status
         // We need to implement copyWith in Platillo model ideally, or just re-fetch
         // For now, let's just trigger the API and reload to be safe and simple
      });
    }

    try {
      await _platilloService.updatePlatillo(platillo.id, {'activo': newValue});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Platillo ${newValue ? "activado" : "desactivado"}'),
          duration: const Duration(seconds: 1),
        )
      );
      _loadData(); // Reload to reflect changes
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    }
  }

  Future<void> _deletePlatillo(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de eliminar este platillo? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _platilloService.deletePlatillo(id);
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Platillo eliminado')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _showEditDialog({Platillo? platillo}) {
    final isEditing = platillo != null;
    final nameController = TextEditingController(text: platillo?.nombre);
    final descController = TextEditingController(text: platillo?.descripcion);
    final priceController = TextEditingController(text: platillo?.precio.toString());
    
    // Reset image file for new dialog
    _imageFile = null;
    
    // Default to first category if available, else 1
    int categoryId = platillo?.categoria.id ?? (_categorias.isNotEmpty ? _categorias.first['id'] : 1);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder( // Needed to update image preview inside dialog
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Platillo' : 'Nuevo Platillo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descripción')),
                    TextField(
                      controller: priceController, 
                      decoration: const InputDecoration(labelText: 'Precio'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 15),
                    
                    // Image Picker UI
                    GestureDetector(
                      onTap: () async {
                        final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setStateDialog(() { // Update dialog state
                             _imageFile = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : (platillo?.imagenUrl != null && platillo!.imagenUrl!.isNotEmpty)
                              ? Image.network(ApiConstants.getImageUrl(platillo.imagenUrl!), fit: BoxFit.cover)
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                                    Text('Toca para seleccionar imagen'),
                                  ],
                                ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    
                    DropdownButtonFormField<int>(
                      value: categoryId,
                      items: _categorias.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat['id'],
                          child: Text(cat['nombre'].toString()),
                        );
                      }).toList(), 
                      onChanged: (val) => categoryId = val ?? categoryId,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final data = {
                        'nombre': nameController.text,
                        'descripcion': descController.text,
                        'precio': double.tryParse(priceController.text) ?? 0.0,
                        'categoria_id': categoryId,
                        'activo': true
                      };

                      if (isEditing) {
                        await _platilloService.updatePlatillo(platillo.id, data, imageFile: _imageFile);
                      } else {
                        await _platilloService.createPlatillo(data, imageFile: _imageFile);
                      }
                      
                      if (mounted) Navigator.pop(ctx);
                      _loadData();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: Text(isEditing ? 'Guardar' : 'Crear'),
                ),
              ],
              actionsAlignment: MainAxisAlignment.spaceEvenly, // Fix 1: Spread buttons
              actionsOverflowButtonSpacing: 8.0, // Fix 2: Handle overflow
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Platillos'),
        automaticallyImplyLeading: false, // Quitar flecha de retroceso
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
            itemCount: _platillos.length,
            itemBuilder: (context, index) {
              final p = _platillos[index];
              return ListTile(
                leading: DishAvatar(
                  imageUrl: p.imagenUrl,
                  isActive: p.activo,
                  radius: 28,
                ),
                title: Text(
                  p.nombre,
                  style: TextStyle(
                    color: p.activo ? Colors.black : Colors.grey,
                    decoration: p.activo ? null : TextDecoration.lineThrough,
                  ),
                ),
                subtitle: Text('S/${p.precio.toStringAsFixed(2)} - ${p.categoria.nombre}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle Switch for Active/Inactive
                    Switch(
                      value: p.activo,
                      onChanged: (val) => _togglePlatilloActivo(p, val),
                      activeColor: Colors.green,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDialog(platillo: p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePlatillo(p.id),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
