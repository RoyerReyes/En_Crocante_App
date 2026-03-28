import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../services/user_service.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  final UserService _userService = UserService();
  late Future<List<Usuario>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  Future<List<Usuario>> _loadUsers() async {
    try {
      return await _userService.getUsers();
    } catch (e) {
      print('Error al cargar usuarios: $e');
      // Optionally show a SnackBar or AlertDialog
      rethrow;
    }
  }

  // Function to show a form for editing user roles
  void _showEditUserDialog(Usuario user) {
    String? selectedRole = user.rol;
    final List<String> roles = ['admin', 'mesero', 'cocina']; // Define available roles

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Usuario: ${user.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID: ${user.id}'),
            Text('Usuario: ${user.usuario}'),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedRole != null && selectedRole != user.rol) {
                try {
                  await _userService.updateUserRole(user.id, selectedRole!);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rol de usuario actualizado.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar rol: ${e.toString()}')),
                  );
                } finally { // ADDED: Always refresh the list
                  setState(() {
                    _usersFuture = _loadUsers();
                  });
                }
              } else {
                Navigator.of(context).pop(); // Close dialog if no change
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Function to confirm and delete a user
  void _confirmDeleteUser(Usuario user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar al usuario ${user.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.deleteUser(user.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuario eliminado correctamente.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar usuario: ${e.toString()}')),
                );
              } finally { // ADDED: Always refresh the list
                setState(() {
                  _usersFuture = _loadUsers();
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // New function to show a form for creating a new user
  void _showCreateUserDialog() {
    final _formKey = GlobalKey<FormState>();
    String _nombre = '';
    String _usuario = '';
    String _password = '';
    String _rol = 'mesero'; // Default role

    final List<String> roles = ['admin', 'mesero', 'cocina'];
    bool _isLoading = false; // Local loading state

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while loading
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Crear Nuevo Usuario'),
              content: _isLoading 
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          validator: (value) => value!.isEmpty ? 'Ingrese un nombre' : null,
                          onSaved: (value) => _nombre = value!,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Usuario'),
                          validator: (value) => value!.isEmpty ? 'Ingrese un nombre de usuario' : null,
                          onSaved: (value) => _usuario = value!,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Contraseña'),
                          obscureText: true,
                          validator: (value) => value!.isEmpty ? 'Ingrese una contraseña' : null,
                          onSaved: (value) => _password = value!,
                        ),
                        DropdownButtonFormField<String>(
                          value: _rol,
                          decoration: const InputDecoration(labelText: 'Rol'),
                          items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              _rol = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              actions: _isLoading ? null : [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      setStateDialog(() => _isLoading = true); // Show loading
                      try {
                        await _userService.createUser(_nombre, _usuario, _password, _rol);
                        if (context.mounted) Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Usuario creado correctamente.')),
                        );
                      } catch (e) {
                        setStateDialog(() => _isLoading = false); // Hide loading on error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al crear usuario: ${e.toString()}')),
                        );
                      } finally {
                         // Refresh list in parent
                         // Note: If success, dialog closed. If error, dialog stays.
                         // We always refresh main list if success, handled by context.mounted logic check or strict flow
                         if (!_isLoading) {
                           // If we are here it means we are still in dialog due to error
                         } else {
                           // Dialog closed? No, we closed it manually.
                           // Actually, we should refresh list regardless of dialog state if operation succeeded.
                           // But here context.mounted check handles 'pop'. 
                           // Let's just refresh the future in the parent widget.
                           setState(() {
                             _usersFuture = _loadUsers();
                           });
                         }
                      }
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateUserDialog(), // Modified to call _showCreateUserDialog
            icon: const Icon(Icons.person_add),
            label: const Text('Crear Nuevo Usuario'),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Usuario>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay usuarios registrados.'));
              } else {
                final users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(user.nombre[0])),
                        title: Text(user.nombre),
                        subtitle: Text('${user.usuario} - Rol: ${user.rol}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditUserDialog(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _confirmDeleteUser(user),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
