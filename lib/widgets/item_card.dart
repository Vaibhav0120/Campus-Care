import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/providers/cart_provider.dart';
import 'package:campus_care/providers/auth_provider.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;

  const ItemCard({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.fastfood,
                            color: theme.primaryColor.withOpacity(0.5),
                            size: 40,
                          ),
                        ),
                      ),
              ),
              // Price tag
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Item Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Item Description
                  if (item.description != null && item.description!.isNotEmpty)
                    Expanded(
                      child: Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  // Add to Cart Button
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: cartProvider.isLoading
                          ? null
                          : () {
                              cartProvider.addToCart(
                                authProvider.user!.id,
                                item,
                              );
                            },
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
