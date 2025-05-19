import 'package:flutter/material.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/models/cart_item.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final CartItem? cartItem;
  final VoidCallback onAddToCart;
  final VoidCallback? onIncreaseQuantity;
  final VoidCallback? onDecreaseQuantity;
  final bool isSmallMobile;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const ItemCard({
    Key? key,
    required this.item,
    this.cartItem,
    required this.onAddToCart,
    this.onIncreaseQuantity,
    this.onDecreaseQuantity,
    this.isSmallMobile = false,
    this.isMobile = false,
    this.isTablet = false,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final inCart = cartItem != null && cartItem!.quantity > 0;
    
    // Adjust sizes based on screen dimensions
    final double priceFontSize = isSmallMobile ? 12 : isTablet ? 16 : 14;
    final double titleFontSize = isSmallMobile ? 12 : isTablet ? 16 : 14;
    final double descriptionFontSize = isSmallMobile ? 10 : isTablet ? 14 : 12;
    final double buttonFontSize = isSmallMobile ? 11 : isTablet ? 15 : 13;
    final double buttonHeight = isSmallMobile ? 32 : isTablet ? 40 : 36;
    final double iconSize = isSmallMobile ? 14 : isTablet ? 20 : 16;
    final double borderRadius = isSmallMobile ? 12 : isTablet ? 20 : 16;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image - using Expanded to take available space
              Expanded(
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
                                    size: isSmallMobile ? 30 : isTablet ? 50 : 40,
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
                                size: isSmallMobile ? 30 : isTablet ? 50 : 40,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                    // Price tag with enhanced design
                    Positioned(
                      top: isSmallMobile ? 4 : 8,
                      right: isSmallMobile ? 4 : 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallMobile ? 6 : 10,
                          vertical: isSmallMobile ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(isSmallMobile ? 16 : 20),
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
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: priceFontSize,
                          ),
                        ),
                      ),
                    ),
                    // Availability badge
                    if (!item.availableToday)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
                          child: Center(
                            child: Text(
                              'Not Available Today',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallMobile ? 12 : isTablet ? 18 : 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Item details - fixed height content
              Container(
                padding: EdgeInsets.only(
                  left: isSmallMobile ? 6 : 8,
                  right: isSmallMobile ? 6 : 8,
                  top: isSmallMobile ? 6 : 8,
                  bottom: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item name
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: titleFontSize,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Small space
                    SizedBox(height: isSmallMobile ? 2 : 4),
                    
                    // Item description
                    if (item.description != null && item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: TextStyle(
                          color: isDarkMode ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey[600],
                          fontSize: descriptionFontSize,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    // Space before button
                    SizedBox(height: isSmallMobile ? 6 : 8),
                  ],
                ),
              ),
              
              // Button - attached directly to the bottom with NO margins or padding
              if (item.availableToday)
                inCart
                    ? _buildQuantityControls(theme, buttonHeight, iconSize, buttonFontSize)
                    : _buildAddToCartButton(theme, buttonHeight, buttonFontSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(ThemeData theme, double height, double fontSize) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onAddToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.black87,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // No border radius on the button
          ),
          elevation: 0, // No elevation
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          'Add to Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(ThemeData theme, double height, double iconSize, double fontSize) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.zero, // No border radius
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease button
          InkWell(
            onTap: onDecreaseQuantity,
            child: Container(
              width: height,
              height: height,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.8),
              ),
              child: Icon(
                Icons.remove,
                color: Colors.black87,
                size: iconSize,
              ),
            ),
          ),
          
          // Quantity
          Text(
            '${cartItem?.quantity ?? 0}',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
          
          // Increase button
          InkWell(
            onTap: onIncreaseQuantity,
            child: Container(
              width: height,
              height: height,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.8),
              ),
              child: Icon(
                Icons.add,
                color: Colors.black87,
                size: iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
