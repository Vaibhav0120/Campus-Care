import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/providers/cart_provider.dart';
import 'package:campus_care/services/order_service.dart';
import 'package:campus_care/screens/home_screen.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({Key? key}) : super(key: key);

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final OrderService _orderService = OrderService();
  late Razorpay _razorpay;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'cash'; // 'cash' or 'upi'

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Payment successful, create order
    await _createOrder('upi');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
    });
    
    Fluttertoast.showToast(
      msg: "Payment failed: ${response.message}",
      toastLength: Toast.LENGTH_LONG,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "External wallet selected: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> _createOrder(String paymentMethod) async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      final order = await _orderService.createOrder(
        authProvider.user!.id,
        cartProvider.cartItems,
        cartProvider.totalPrice,
        paymentMethod,
      );
      
      if (order != null && mounted) {
        Fluttertoast.showToast(
          msg: "Order placed successfully!",
          toastLength: Toast.LENGTH_LONG,
        );
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Failed to place order. Please try again.",
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _startRazorpayPayment() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    var options = {
      'key': dotenv.env['RAZORPAY_KEY_ID'],
      'amount': (cartProvider.totalPrice * 100).toInt(), // Amount in paise
      'name': 'Campus Care',
      'description': 'Food Order',
      'prefill': {
        'contact': '',
        'email': authProvider.user?.email ?? '',
      }
    };
    
    try {
      _razorpay.open(options);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Processing your order...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          : isDesktop
              ? _buildDesktopLayout(cartProvider, theme)
              : _buildMobileLayout(cartProvider, theme),
    );
  }

  Widget _buildDesktopLayout(CartProvider cartProvider, ThemeData theme) {
    return Row(
      children: [
        // Order summary (left side)
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Items list
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ...cartProvider.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              // Item image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: item.item.imageUrl != null && item.item.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          item.item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.fastfood,
                                                color: theme.primaryColor.withOpacity(0.5),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.fastfood,
                                            color: theme.primaryColor.withOpacity(0.5),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Item details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹${item.item.price.toStringAsFixed(2)} x ${item.quantity}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Item total
                              Text(
                                '₹${item.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                        
                        const Divider(),
                        
                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
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
        
        // Payment options (right side)
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Payment options
                _buildPaymentOptions(theme),
                
                const Spacer(),
                
                // Place order button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            if (_selectedPaymentMethod == 'upi') {
                              _startRazorpayPayment();
                            } else {
                              _createOrder('cash');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selectedPaymentMethod == 'upi'
                          ? 'Pay with UPI'
                          : 'Place Order',
                      style: const TextStyle(
                        fontSize: 16,
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
    );
  }

  Widget _buildMobileLayout(CartProvider cartProvider, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Items list
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartProvider.cartItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = cartProvider.cartItems[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: item.item.imageUrl != null && item.item.imageUrl!.isNotEmpty
                          ? Image.network(
                              item.item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.fastfood,
                                    color: theme.primaryColor.withOpacity(0.5),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.fastfood,
                                color: theme.primaryColor.withOpacity(0.5),
                              ),
                            ),
                    ),
                  ),
                  title: Text(item.item.name),
                  subtitle: Text('₹${item.item.price.toStringAsFixed(2)} x ${item.quantity}'),
                  trailing: Text(
                    '₹${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          
          // Total
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment method
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Payment options
          _buildPaymentOptions(theme),
          
          const SizedBox(height: 32),
          
          // Place order button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      if (_selectedPaymentMethod == 'upi') {
                        _startRazorpayPayment();
                      } else {
                        _createOrder('cash');
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedPaymentMethod == 'upi'
                    ? 'Pay with UPI'
                    : 'Place Order',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions(ThemeData theme) {
    return Column(
      children: [
        // Cash option
        InkWell(
          onTap: () {
            setState(() {
              _selectedPaymentMethod = 'cash';
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedPaymentMethod == 'cash'
                    ? theme.primaryColor
                    : Colors.grey[300]!,
                width: _selectedPaymentMethod == 'cash' ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedPaymentMethod == 'cash'
                          ? theme.primaryColor
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: _selectedPaymentMethod == 'cash'
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash on Delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Pay when you receive your order',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.payments_outlined,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // UPI option
        InkWell(
          onTap: () {
            setState(() {
              _selectedPaymentMethod = 'upi';
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedPaymentMethod == 'upi'
                    ? theme.primaryColor
                    : Colors.grey[300]!,
                width: _selectedPaymentMethod == 'upi' ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedPaymentMethod == 'upi'
                          ? theme.primaryColor
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: _selectedPaymentMethod == 'upi'
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPI Payment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Pay using UPI apps like Google Pay, PhonePe',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
