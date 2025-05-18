import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/screens/home_screen.dart';
import 'package:campus_care/screens/login_screen.dart';
import 'package:campus_care/screens/staff/staff_dashboard.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
    
    // Check authentication status
    _checkAuthStatus();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Try to restore session
    await authProvider.checkAndRestoreSession();
    
    // Wait for a moment to show the animation
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (!mounted) return;
    
    // Navigate based on auth status
    if (authProvider.isAuthenticated) {
      if (authProvider.isStaff) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StaffDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = kIsWeb || size.width > 900;
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFFFEC62B);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              primaryColor.withAlpha(220),
              primaryColor.withAlpha(180),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: isDesktop ? 160 : 120,
                          height: isDesktop ? 160 : 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.restaurant_menu,
                              size: isDesktop ? 90 : 70,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(height: isDesktop ? 50 : 40),
                        
                        // App name
                        Column(
                          children: [
                            Text(
                              'Campus Care',
                              style: TextStyle(
                                fontSize: isDesktop ? 48 : 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(50),
                                    offset: const Offset(1, 1),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isDesktop ? 16 : 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(60), 
                                  width: 1
                                ),
                              ),
                              child: Text(
                                'Your Campus Food Delivery',
                                style: TextStyle(
                                  fontSize: isDesktop ? 20 : 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: isDesktop ? 80 : 60),
                        
                        // Loading indicator
                        Column(
                          children: [
                            SizedBox(
                              width: isDesktop ? 80 : 60,
                              height: isDesktop ? 80 : 60,
                              child: Lottie.network(
                                'https://assets5.lottiefiles.com/packages/lf20_p8bfn5to.json',
                                repeat: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Loading...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        // Food icons at the bottom
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: isDesktop ? 30 : 20),
                              child: Wrap(
                                spacing: isDesktop ? 16 : 8,
                                children: [
                                  _buildFoodIcon(Icons.local_pizza, theme),
                                  _buildFoodIcon(Icons.coffee, theme),
                                  _buildFoodIcon(Icons.fastfood, theme),
                                  _buildFoodIcon(Icons.local_dining, theme),
                                  _buildFoodIcon(Icons.icecream, theme),
                                ],
                              ),
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
      ),
    );
  }
  
  Widget _buildFoodIcon(IconData icon, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(200),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: const Color(0xFFFEC62B),
        size: 28,
      ),
    );
  }
}
