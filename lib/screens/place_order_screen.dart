import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/providers/cart_provider.dart';
import 'package:campus_care/services/order_service.dart';
import 'package:campus_care/screens/home_screen.dart';
import 'package:lottie/lottie.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({Key? key}) : super(key: key);

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late Razorpay _razorpay;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'cash'; // 'cash' or 'upi'
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
    
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _animationController.dispose();
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
        // Clear the cart after successful order
        await cartProvider.clearCart(authProvider.user!.id);
        
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
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        elevation: 0,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Use Lottie animation for processing state
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Lottie.network(
                      'https://assets10.lottiefiles.com/packages/lf20_p8bfn5to.json',
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Processing your order...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we confirm your payment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: isDesktop
                    ? _buildDesktopLayout(cartProvider, theme, isDarkMode)
                    : _buildMobileLayout(cartProvider, theme, isDarkMode),
              ),
            ),
    );
  }

  Widget _buildDesktopLayout(CartProvider cartProvider, ThemeData theme, bool isDarkMode) {
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
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Items list with enhanced design
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        ...cartProvider.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            children: [
                              // Item image with enhanced design
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: item.item.imageUrl != null && item.item.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          item.item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: theme.primaryColor.withOpacity(0.1),
                                              child: Icon(
                                                Icons.fastfood,
                                                color: theme.primaryColor,
                                                size: 30,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: theme.primaryColor.withOpacity(0.1),
                                          child: Icon(
                                            Icons.fastfood,
                                            color: theme.primaryColor,
                                            size: 30,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              
                              // Item details with enhanced design
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '₹${item.item.price.toStringAsFixed(2)} x ${item.quantity}',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Item total with enhanced design
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '₹${item.totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                        
                        Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                        
                        // Total with enhanced design
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Payment options (right side) with enhanced design
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? theme.cardTheme.color : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payment,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Payment options with enhanced design
                _buildPaymentOptions(theme, isDarkMode),
                
                const Spacer(),
                
                // Place order button with enhanced design
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
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: theme.primaryColor.withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedPaymentMethod == 'upi'
                              ? Icons.account_balance_wallet
                              : Icons.shopping_bag,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedPaymentMethod == 'upi'
                              ? 'Pay with UPI'
                              : 'Place Order',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildMobileLayout(CartProvider cartProvider, ThemeData theme, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary title with enhanced design
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Items list with enhanced design
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartProvider.cartItems.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey[200],
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                final item = cartProvider.cartItems[index];
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Item image with enhanced design
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: item.item.imageUrl != null && item.item.imageUrl!.isNotEmpty
                              ? Image.network(
                                  item.item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: theme.primaryColor.withOpacity(0.1),
                                      child: Icon(
                                        Icons.fastfood,
                                        color: theme.primaryColor,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.fastfood,
                                    color: theme.primaryColor,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Item details with enhanced design
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '₹${item.item.price.toStringAsFixed(2)} x ${item.quantity}',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Item total with enhanced design
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '₹${item.totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Total with enhanced design
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? theme.cardTheme.color : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
              ),
            ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment method with enhanced design
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payment,
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Payment options with enhanced design
          _buildPaymentOptions(theme, isDarkMode),
          
          const SizedBox(height: 32),
          
          // Place order button with enhanced design
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
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: theme.primaryColor.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedPaymentMethod == 'upi'
                        ? Icons.account_balance_wallet
                        : Icons.shopping_bag,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedPaymentMethod == 'upi'
                        ? 'Pay with UPI'
                        : 'Place Order',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

Widget _buildPaymentOptions(ThemeData theme, bool isDarkMode) {
  return Column(
    children: [
      // Cash option with enhanced design
      InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = 'cash';
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedPaymentMethod == 'cash'
                ? theme.primaryColor.withOpacity(0.1)
                : isDarkMode ? theme.cardTheme.color : Colors.white,
            border: Border.all(
              color: _selectedPaymentMethod == 'cash'
                  ? theme.primaryColor
                  : Colors.grey[300]!,
              width: _selectedPaymentMethod == 'cash' ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _selectedPaymentMethod == 'cash'
                ? [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash on Delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _selectedPaymentMethod == 'cash'
                            ? theme.primaryColor
                            : isDarkMode ? theme.colorScheme.onSurface : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pay when you receive your order',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.payments_outlined,
                color: _selectedPaymentMethod == 'cash'
                    ? theme.primaryColor
                    : isDarkMode ? Colors.grey[400] : Colors.grey[600],
                size: 28,
              ),
            ],
          ),
        ),
      ),
      
      const SizedBox(height: 16),
      
      // UPI option with enhanced design
      InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = 'upi';
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedPaymentMethod == 'upi'
                ? theme.primaryColor.withOpacity(0.1)
                : isDarkMode ? theme.cardTheme.color : Colors.white,
            border: Border.all(
              color: _selectedPaymentMethod == 'upi'
                  ? theme.primaryColor
                  : Colors.grey[300]!,
              width: _selectedPaymentMethod == 'upi' ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _selectedPaymentMethod == 'upi'
                ? [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPI Payment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _selectedPaymentMethod == 'upi'
                            ? theme.primaryColor
                            : isDarkMode ? theme.colorScheme.onSurface : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pay using UPI apps like Google Pay, PhonePe',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: _selectedPaymentMethod == 'upi'
                    ? theme.primaryColor
                    : isDarkMode ? Colors.grey[400] : Colors.grey[600],
                size: 28,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
}