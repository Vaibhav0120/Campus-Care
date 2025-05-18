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
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return Container(
      width: double.infinity,
      height: 140, // Reduced height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.recommend,
                  color: widget.theme.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  'Recommended for you',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // Add scroll indicators
                if (widget.recommendedItems.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.swipe,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: widget.recommendedItems.isEmpty
                ? Center(
                    child: Text(
                      'Loading recommendations...',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: widget.recommendedItems.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = widget.recommendedItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // Item image
                                Hero(
                                  tag: 'recommendation-${item.id}',
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(9),
                                      bottomLeft: Radius.circular(9),
                                    ),
                                    child: SizedBox(
                                      width: isDesktop ? 120 : 100, // Wider on desktop
                                      height: double.infinity,
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
                                                      size: 30,
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
                                                  size: 30,
                                                  color: widget.theme.primaryColor,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                // Item details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10), // Reduced padding
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.description != null && item.description!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2), // Reduced padding
                                            child: Text(
                                              item.description!,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₹${item.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: widget.theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: widget.theme.primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Add to Cart',
                                                style: TextStyle(
                                                  color: widget.theme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
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
              padding: const EdgeInsets.only(bottom: 4), // Reduced padding
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
                        width: isActive ? 16 : 6, // Slightly smaller
                        height: 6, // Slightly smaller
                        margin: const EdgeInsets.symmetric(horizontal: 3), // Reduced margin
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
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