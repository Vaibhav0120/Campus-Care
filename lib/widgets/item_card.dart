import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/providers/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  
  const ItemCard({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: 120,
            width: double.infinity,
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.image_not_supported),
                    ),
                  )
                : Image.asset(
                    'assets/images/placeholder_food.png',
                    fit: BoxFit.cover,
                  ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.description != null)
                  Text(
                    item.description!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: cartProvider.isLoading
                          ? null
                          : () async {
                              if (authProvider.isAuthenticated) {
                                final success = await cartProvider.addToCart(
                                  authProvider.user!.id,
                                  item,
                                );
                                
                                if (success) {
                                  Fluttertoast.showToast(
                                    msg: "Added to cart",
                                    toastLength: Toast.LENGTH_SHORT,
                                  );
                                } else {
                                  Fluttertoast.showToast(
                                    msg: "Failed to add to cart",
                                    toastLength: Toast.LENGTH_SHORT,
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}