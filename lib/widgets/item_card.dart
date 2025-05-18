import 'package:flutter/material.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/models/cart_item.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final CartItem? cartItem;
  final VoidCallback onAddToCart;
  final VoidCallback? onIncreaseQuantity;
  final VoidCallback? onDecreaseQuantity;

  const ItemCard({
    Key? key,
    required this.item,
    this.cartItem,
    required this.onAddToCart,
    this.onIncreaseQuantity,
    this.onDecreaseQuantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inCart = cartItem != null && cartItem!.quantity > 0;
    
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // Use LayoutBuilder to get the card's constraints
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate proportional heights
          final totalHeight = constraints.maxHeight;
          final imageHeight = totalHeight * 0.65; // 65% for image
          final detailsHeight = totalHeight * 0.35; // 35% for details
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image with fixed proportional height
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  child: Center(
                                    child: Icon(
                                      Icons.fastfood,
                                      size: 40,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: theme.primaryColor.withOpacity(0.1),
                              child: Center(
                                child: Icon(
                                  Icons.fastfood,
                                  size: 40,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                      // Price tag with enhanced design
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      // Availability badge
                      if (!item.availableToday)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.6),
                            child: const Center(
                              child: Text(
                                'Not Available Today',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Item details with fixed proportional height
              SizedBox(
                height: detailsHeight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
                    children: [
                      // Item name - fixed height
                      SizedBox(
                        height: detailsHeight * 0.25, // 25% of details area
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      
                      // Item description - fixed height
                      if (item.description != null && item.description!.isNotEmpty)
                        SizedBox(
                          height: detailsHeight * 0.25, // 25% of details area
                          child: Text(
                            item.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      
                      // Spacer with fixed height
                      SizedBox(height: detailsHeight * 0.05), // 5% of details area
                      
                      // Add to cart button or quantity controls - fixed height
                      if (item.availableToday)
                        SizedBox(
                          height: detailsHeight * 0.35, // Reduced from 0.45 to 0.35
                          child: inCart
                              ? _buildQuantityControls(theme)
                              : _buildAddToCartButton(theme),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddToCartButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 30, // Reduced from 36 to 30
      child: ElevatedButton(
        onPressed: onAddToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0), // Reduced padding
          minimumSize: const Size.fromHeight(30), // Ensure minimum height
          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap target size
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Add to Cart',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12, // Reduced font size
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 30, // Reduced from 36 to 30
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease button
          InkWell(
            onTap: onDecreaseQuantity,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            child: Container(
              width: 30, // Reduced from 36 to 30
              height: 30, // Reduced from 36 to 30
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: const Icon(
                Icons.remove,
                color: Colors.black87,
                size: 16, // Reduced from 20 to 16
              ),
            ),
          ),
          
          // Quantity
          Text(
            '${cartItem?.quantity ?? 0}',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14, // Reduced from 16 to 14
            ),
          ),
          
          // Increase button
          InkWell(
            onTap: onIncreaseQuantity,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: Container(
              width: 30, // Reduced from 36 to 30
              height: 30, // Reduced from 36 to 30
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.black87,
                size: 16, // Reduced from 20 to 16
              ),
            ),
          ),
        ],
      ),
    );
  }
}