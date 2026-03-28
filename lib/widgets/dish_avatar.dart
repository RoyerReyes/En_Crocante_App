import 'package:flutter/material.dart';
import 'package:encrocante_app/constants/api_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DishAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool isActive;

  const DishAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24.0, // Default CircleAvatar radius is 20, but let's make it slightly larger or customizable
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = ApiConstants.getImageUrl(imageUrl);
    debugPrint('DishAvatar: raw=$imageUrl, full=$fullUrl'); // Debug log
    final hasImage = fullUrl.isNotEmpty;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.grey[200] : Colors.grey,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipOval(
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: fullUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) {
                  return Icon(Icons.broken_image, size: radius, color: Colors.grey);
                },
              )
            : Icon(
                Icons.restaurant_menu,
                size: radius,
                color: isActive ? Colors.orange : Colors.white54,
              ),
      ),
    );
  }
}
