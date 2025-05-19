import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:campus_care/models/order_model.dart';

class OrderTile extends StatelessWidget {
  final OrderModel order;
  final bool isStaff;
  final VoidCallback? onMarkCompleted;
  
  const OrderTile({
    Key? key,
    required this.order,
    this.isStaff = false,
    this.onMarkCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fixed button height
    const double buttonHeight = 50.0;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // Content area with padding at the bottom for the button
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16, 
                right: 16, 
                top: 16, 
                // Add padding at the bottom to make space for the button
                bottom: isStaff && order.isPending ? buttonHeight + 16 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: order.isPending ? Colors.orange : Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('MMM dd, yyyy hh:mm a').format(order.createdAt)}',
                    style: TextStyle(
                      color: isDarkMode ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payment Method: ${order.paymentMethod.toUpperCase()}',
                    style: TextStyle(
                      color: isDarkMode ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Divider(color: theme.dividerTheme.color),
                  // Items list
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} x ${item.quantity}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  Divider(color: theme.dividerTheme.color),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '₹${order.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Button positioned at the bottom
          if (isStaff && order.isPending)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: onMarkCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mark as Completed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
