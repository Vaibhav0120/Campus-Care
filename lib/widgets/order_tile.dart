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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ensures column takes minimum space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Payment Method: ${order.paymentMethod.toUpperCase()}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const Divider(),
            // Use Column instead of ListView for better layout control
            Column(
              mainAxisSize: MainAxisSize.min, // Ensures column takes minimum space
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x ${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
            if (isStaff && order.isPending)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16, bottom: 0), // No bottom margin
                child: ElevatedButton(
                  onPressed: onMarkCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50), // Fixed height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Restored rounded corners
                    ),
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
          ],
        ),
      ),
    );
  }
}