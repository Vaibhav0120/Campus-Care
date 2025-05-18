import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/models/cart_item.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/providers/cart_provider.dart';

class RecommendationCarousel extends StatefulWidget {
  final List<ItemModel> recommendedItems;
  final ThemeData theme;

  const RecommendationCarousel({
    Key? key,
    required this.recommendedItems,
    required this.theme,
  }) : super(key: key);

  @override
  State<RecommendationCarousel> createState() => _RecommendationCarouselState();
}

class _RecommendationCarouselState extends State<RecommendationCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Auto-scroll the recommendations
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _startAutoScroll();
      }
    });
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _pageController.hasClients && widget.recommendedItems.length > 1) {
        final nextPage = (_pageController.page?.toInt() ?? 0) + 1;
        _pageController.animateToPage(
          nextPage % widget.recommendedItems.length,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        ).then((_) {
          if (mounted) {
            _startAutoScroll();
          }
        });
      } else if (mounted) {
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final size = MediaQuery.of(context).size;
    
    // Responsive breakpoints
    final isSmallMobile = size.width < 360;
    final isTablet = size.width >= 600 && size.width < 900;
    final isDesktop = size.width >= 900;
    
    // Adjust sizes based on screen dimensions
    // Make carousel significantly larger on desktop
    final double carouselHeight = isDesktop ? 200 : isTablet ? 180 : isSmallMobile ? 140 : 160;
    final double imageWidth = isDesktop ? 160 : isTablet ? 140 : isSmallMobile ? 80 : 100;
    final double titleFontSize = isDesktop ? 18 : isTablet ? 18 : isSmallMobile ? 14 : 16;
    final double descriptionFontSize = isDesktop ? 14 : isTablet ? 14 : isSmallMobile ? 10 : 12;
    final double priceFontSize = isDesktop ? 16 : isTablet ? 16 : isSmallMobile ? 12 : 14;
    final double buttonFontSize = isDesktop ? 14 : isTablet ? 14 : isSmallMobile ? 10 : 12;
    final double headerFontSize = isDesktop ? 16 : isTablet ? 16 : isSmallMobile ? 12 : 14;
    final double iconSize = isDesktop ? 20 : isTablet ? 20 : isSmallMobile ? 14 : 18;
    final double padding = isDesktop ? 16 : isTablet ? 16 : isSmallMobile ? 8 : 12;
    
    return Container(
      width: double.infinity,
      height: carouselHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with enhanced design
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: padding, 
              vertical: isSmallMobile ? 6 : 8
            ),
            decoration: BoxDecoration(
              color: widget.theme.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.recommend,
                  color: widget.theme.primaryColor,
                  size: iconSize,
                ),
                SizedBox(width: isSmallMobile ? 4 : 6),
                Text(
                  'Recommended for you',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontSize: headerFontSize,
                  ),
                ),
                const Spacer(),
                // Add scroll indicators with animation
                if (widget.recommendedItems.isNotEmpty)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.7, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Row(
                          children: [
                            Icon(
                              Icons.swipe,
                              size: isSmallMobile ? 12 : 14,
                              color: Colors.grey[400],
                            ),
                            SizedBox(width: isSmallMobile ? 2 : 4),
                            Text(
                              'Swipe',
                              style: TextStyle(
                                fontSize: isSmallMobile ? 10 : 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onEnd: () {
                      // Repeat the animation
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          
          // Carousel content
          Expanded(
            child: widget.recommendedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.theme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loading recommendations...',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isSmallMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: widget.recommendedItems.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = widget.recommendedItems[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding, 
                          vertical: isSmallMobile ? 4 : 6
                        ),
                        child: GestureDetector(
                          onTap: () {
                            // Find if this item is in the cart
                            final cartItem = cartProvider.cartItems.firstWhere(
                              (cartItem) => cartItem.itemId == item.id,
                              orElse: () => CartItem(
                                id: '',
                                userId: '',
                                itemId: item.id,
                                quantity: 0,
                                item: item,
                              ),
                            );
                            
                            if (cartItem.quantity <= 0) {
                              cartProvider.addToCart(
                                Provider.of<AuthProvider>(context, listen: false).user!.id,
                                item,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} added to cart'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // Item image with enhanced design
                                Hero(
                                  tag: 'recommendation-${item.id}',
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(11),
                                      bottomLeft: Radius.circular(11),
                                    ),
                                    child: Container(
                                      width: imageWidth,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(2, 0),
                                          ),
                                        ],
                                      ),
                                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                          ? Image.network(
                                              item.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: widget.theme.primaryColor.withOpacity(0.1),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.fastfood,
                                                      size: isSmallMobile ? 24 : 30,
                                                      color: widget.theme.primaryColor,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: widget.theme.primaryColor.withOpacity(0.1),
                                              child: Center(
                                                child: Icon(
                                                  Icons.fastfood,
                                                  size: isSmallMobile ? 24 : 30,
                                                  color: widget.theme.primaryColor,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                
                                // Item details with enhanced layout
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallMobile ? 8 : 10,
                                      vertical: isSmallMobile ? 4 : 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Item name with enhanced typography
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: titleFontSize,
                                            color: Colors.grey[800],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        
                                        // Item description with enhanced typography
                                        if (item.description != null && item.description!.isNotEmpty)
                                          Padding(
                                            padding: EdgeInsets.only(top: isSmallMobile ? 2 : 4),
                                            child: Text(
                                              item.description!,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: descriptionFontSize,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          
                                        SizedBox(height: isSmallMobile ? 2 : 4),
                                        
                                        // Price and add to cart button with enhanced design
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            // If we have limited width, stack the price and button vertically
                                            if (constraints.maxWidth < (isSmallMobile ? 180 : isDesktop ? 280 : 220)) {
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Price with enhanced typography
                                                  Container(
                                                    margin: const EdgeInsets.only(bottom: 4),
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: isSmallMobile ? 6 : 8,
                                                      vertical: isSmallMobile ? 2 : 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: widget.theme.primaryColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '₹${item.price.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: widget.theme.primaryColor,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: priceFontSize,
                                                      ),
                                                    ),
                                                  ),
                                                  
                                                  // Add to cart button with enhanced design - MADE BIGGER
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton.icon(
                                                      onPressed: () {
                                                        final cartItem = cartProvider.cartItems.firstWhere(
                                                          (cartItem) => cartItem.itemId == item.id,
                                                          orElse: () => CartItem(
                                                            id: '',
                                                            userId: '',
                                                            itemId: item.id,
                                                            quantity: 0,
                                                            item: item,
                                                          ),
                                                        );
                                                        
                                                        if (cartItem.quantity <= 0) {
                                                          cartProvider.addToCart(
                                                            Provider.of<AuthProvider>(context, listen: false).user!.id,
                                                            item,
                                                          );
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('${item.name} added to cart'),
                                                              duration: const Duration(seconds: 2),
                                                              behavior: SnackBarBehavior.floating,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      icon: Icon(
                                                        Icons.add_shopping_cart,
                                                        color: Colors.white,
                                                        size: isSmallMobile ? 12 : isDesktop ? 16 : 14,
                                                      ),
                                                      label: Text(
                                                        'Add to Cart',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: buttonFontSize,
                                                        ),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: widget.theme.primaryColor,
                                                        foregroundColor: Colors.white,
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: isSmallMobile ? 8 : isDesktop ? 16 : 12,
                                                          vertical: isSmallMobile ? 0 : isDesktop ? 6 : 2,
                                                        ),
                                                        minimumSize: Size(0, isSmallMobile ? 24 : isDesktop ? 32 : 28),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            } else {
                                              // If we have enough width, keep them in a row
                                              return Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  // Price with enhanced typography
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: isSmallMobile ? 6 : 8,
                                                      vertical: isSmallMobile ? 2 : 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: widget.theme.primaryColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '₹${item.price.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: widget.theme.primaryColor,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: priceFontSize,
                                                      ),
                                                    ),
                                                  ),
                                                  
                                                  // Add to cart button with enhanced design - MADE BIGGER
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      final cartItem = cartProvider.cartItems.firstWhere(
                                                        (cartItem) => cartItem.itemId == item.id,
                                                        orElse: () => CartItem(
                                                          id: '',
                                                          userId: '',
                                                          itemId: item.id,
                                                          quantity: 0,
                                                          item: item,
                                                        ),
                                                      );
                                                      
                                                      if (cartItem.quantity <= 0) {
                                                        cartProvider.addToCart(
                                                          Provider.of<AuthProvider>(context, listen: false).user!.id,
                                                          item,
                                                        );
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('${item.name} added to cart'),
                                                            duration: const Duration(seconds: 2),
                                                            behavior: SnackBarBehavior.floating,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    icon: Icon(
                                                      Icons.add_shopping_cart,
                                                      color: Colors.white,
                                                      size: isSmallMobile ? 12 : isDesktop ? 16 : 14,
                                                    ),
                                                    label: Text(
                                                      'Add to Cart',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: buttonFontSize,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: widget.theme.primaryColor,
                                                      foregroundColor: Colors.white,
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: isSmallMobile ? 8 : isDesktop ? 16 : 12,
                                                        vertical: isSmallMobile ? 0 : isDesktop ? 6 : 2,
                                                      ),
                                                      minimumSize: Size(0, isSmallMobile ? 24 : isDesktop ? 32 : 28),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Enhanced page indicator dots with animation
          if (widget.recommendedItems.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: isSmallMobile ? 4 : 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.recommendedItems.length,
                  (index) => AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, _) {
                      final currentPage = _pageController.hasClients
                          ? _pageController.page ?? 0
                          : 0;
                      final isActive = index == currentPage.round();
                      final distance = (index - currentPage).abs();
                      final opacity = 1.0 - (distance * 0.3).clamp(0.0, 0.7);
                      
                      return Container(
                        width: isActive ? (isSmallMobile ? 12 : 16) : (isSmallMobile ? 4 : 6),
                        height: isSmallMobile ? 4 : 6,
                        margin: EdgeInsets.symmetric(horizontal: isSmallMobile ? 2 : 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(isSmallMobile ? 2 : 3),
                          color: widget.theme.primaryColor.withOpacity(opacity),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}