import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../constants/api_constants.dart';

class CartItemTile extends StatefulWidget {
  final CartItem item;

  const CartItemTile({Key? key, required this.item}) : super(key: key);

  @override
  State<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<CartItemTile> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notas);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Hero(
            tag: 'platillo_${widget.item.platillo.id}',
            child: CircleAvatar(
              radius: 25,
              backgroundImage: (widget.item.platillo.imagenUrl != null &&
                      widget.item.platillo.imagenUrl!.isNotEmpty)
                  ? NetworkImage(ApiConstants.getImageUrl(widget.item.platillo.imagenUrl!))
                  : null,
              child: (widget.item.platillo.imagenUrl == null ||
                      widget.item.platillo.imagenUrl!.isEmpty)
                  ? Text(widget.item.platillo.nombre[0].toUpperCase())
                  : null,
            ),
          ),
          title: Text(
            widget.item.platillo.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'S/ ${widget.item.platillo.precio.toStringAsFixed(2)} c/u',
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 28),
            onPressed: () => cart.removeItemByUniqueId(widget.item.uniqueId),
            color: Colors.red.shade700,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notas para el producto (opcional)',
              hintText: 'Ej: Sin cebolla',
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 1,
            maxLength: 100,
            onChanged: (value) {
              cart.updateItemNotes(
                widget.item.uniqueId,
                value.isEmpty ? null : value,
              );
            },
          ),
        ),
        const Divider(),
      ],
    );
  }
}
