import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/providers/theme_provider.dart';
import 'package:campus_care/screens/home_screen.dart';
import 'package:campus_care/screens/auth/signup_screen.dart';
import 'package:campus_care/screens/staff/staff_dashboard.dart';
import 'package:campus_care/utils/validators.dart';
import 'package:campus_care/widgets/theme_toggle_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
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
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
    
    // Check if we need to handle a redirect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForRedirect();
    });
  }
  
  // Check if we need to handle a redirect from OAuth
  Future<void> _checkForRedirect() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // If we're already authenticated, navigate to the appropriate screen
    if (authProvider.isAuthenticated) {
      _navigateAfterLogin(authProvider);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (success && mounted) {
        _navigateAfterLogin(authProvider);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await authProvider.signInWithGoogle();
    
    // For web, the navigation will happen after the OAuth redirect
    // For mobile, we'll check the session in the splash screen
    if (!kIsWeb && authProvider.isAuthenticated && mounted) {
      _navigateAfterLogin(authProvider);
    }
  }

  void _navigateAfterLogin(AuthProvider authProvider) {
    if (authProvider.isStaff) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StaffDashboard()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Responsive breakpoints - FIXED to use only width, not kIsWeb
    final isSmallMobile = size.width < 360;
    final isTablet = size.width >= 600 && size.width < 900;
    final isDesktop = size.width >= 900;
    
    // Adjust font sizes based on screen size
    final double logoSize = isSmallMobile ? 60 : isTablet ? 90 : 80;
    final double titleSize = isSmallMobile ? 28 : isTablet ? 40 : 36;
    final double taglineSize = isSmallMobile ? 14 : 16;
    final double headerSize = isSmallMobile ? 20 : 24;
    final double buttonHeight = isSmallMobile ? 48 : 56;
    
    // Adjust padding based on screen size
    final double horizontalPadding = isSmallMobile ? 16 : isTablet ? 32 : 24;
    final double verticalPadding = isSmallMobile ? 16 : 24;
    
    // Layout for desktop (side-by-side)
    if (isDesktop) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              // Left side - Brand section (1/2 of screen)
              Expanded(
                flex: 5,
                child: Container(
                  color: isDarkMode ? theme.scaffoldBackgroundColor.withOpacity(0.7) : theme.primaryColor.withOpacity(0.1),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with enhanced design
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: isDarkMode ? theme.primaryColor.withOpacity(0.1) : theme.primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              size: logoSize * 1.5,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // App Name with enhanced typography
                          Text(
                            'Campus Care',
                            style: TextStyle(
                              fontSize: titleSize * 1.2,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          // Tagline with enhanced design
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? theme.primaryColor.withOpacity(0.1) : theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: theme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Order food from your campus cafeteria',
                              style: TextStyle(
                                fontSize: taglineSize * 1.2,
                                color: isDarkMode ? theme.colorScheme.onSurface : Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Additional information or features for desktop
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildFeatureCard(
                                icon: Icons.restaurant,
                                title: 'Campus Menu',
                                description: 'Browse daily specials and regular items',
                                isDarkMode: isDarkMode,
                                theme: theme,
                              ),
                              _buildFeatureCard(
                                icon: Icons.delivery_dining,
                                title: 'Quick Pickup',
                                description: 'Skip the line with pre-orders',
                                isDarkMode: isDarkMode,
                                theme: theme,
                              ),
                              _buildFeatureCard(
                                icon: Icons.payments_outlined,
                                title: 'Easy Payments',
                                description: 'Pay with UPI or cash on delivery',
                                isDarkMode: isDarkMode,
                                theme: theme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Right side - Login form (1/2 of screen)
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildLoginForm(
                                authProvider: authProvider,
                                headerSize: headerSize,
                                buttonHeight: buttonHeight,
                                horizontalPadding: horizontalPadding,
                                verticalPadding: verticalPadding,
                                isDarkMode: isDarkMode,
                                theme: theme,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Theme toggle button in the top right corner
                    const Positioned(
                      top: 16,
                      right: 16,
                      child: Card(
                        elevation: 4,
                        shape: CircleBorder(),
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: ThemeToggleButton(showLabel: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Mobile and tablet layout (vertical)
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(horizontalPadding),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 600 : double.infinity,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo with enhanced design
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(isSmallMobile ? 15 : 20),
                              decoration: BoxDecoration(
                                color: isDarkMode ? theme.primaryColor.withOpacity(0.1) : theme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                size: logoSize,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallMobile ? 16 : 24),
                          
                          // App Name with enhanced typography
                          Text(
                            'Campus Care',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallMobile ? 4 : 8),
                          
                          // Tagline with enhanced design
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallMobile ? 12 : 16,
                              vertical: isSmallMobile ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode ? theme.primaryColor.withOpacity(0.1) : theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Order food from your campus cafeteria',
                              style: TextStyle(
                                fontSize: taglineSize,
                                color: isDarkMode ? theme.colorScheme.onSurface : Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: isSmallMobile ? 32 : isTablet ? 64 : 48),
                          
                          // Login Form
                          _buildLoginForm(
                            authProvider: authProvider,
                            headerSize: headerSize,
                            buttonHeight: buttonHeight,
                            horizontalPadding: horizontalPadding,
                            verticalPadding: verticalPadding,
                            isDarkMode: isDarkMode,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Theme toggle button in the top right corner
            const Positioned(
              top: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: ThemeToggleButton(showLabel: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDarkMode,
    required ThemeData theme,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoginForm({
    required AuthProvider authProvider,
    required double headerSize,
    required double buttonHeight,
    required double horizontalPadding,
    required double verticalPadding,
    required bool isDarkMode,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(verticalPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome text with enhanced design
              Container(
                padding: EdgeInsets.only(bottom: verticalPadding * 0.75),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? theme.dividerTheme.color! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: headerSize,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to your account',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: verticalPadding),
              
              // Email Field with enhanced design
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: theme.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? theme.inputDecorationTheme.fillColor : Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.validateEmail,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              
              // Password Field with enhanced design
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: theme.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? theme.inputDecorationTheme.fillColor : Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: isDarkMode ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                validator: Validators.validatePassword,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              SizedBox(height: verticalPadding),
              
              // Error Message with enhanced design
              if (authProvider.error != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.red.withOpacity(0.2) : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDarkMode ? Colors.red[700]! : Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: isDarkMode ? Colors.red[300] : Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authProvider.error!,
                          style: TextStyle(color: isDarkMode ? Colors.red[300] : Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              if (authProvider.error != null)
                const SizedBox(height: 16),
              
              // Login Button with enhanced design
              SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black87,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // OR Divider with enhanced design
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDarkMode ? theme.dividerTheme.color : Colors.grey[300],
                      thickness: 1,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? theme.cardTheme.color!.withOpacity(0.3) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: isDarkMode ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDarkMode ? theme.dividerTheme.color : Colors.grey[300],
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Google Login Button with enhanced design
              SizedBox(
                height: buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: authProvider.isLoading ? null : _loginWithGoogle,
                  icon: authProvider.isLoading 
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDarkMode ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey[600],
                          ),
                        )
                      : const FaIcon(
                          FontAwesomeIcons.google,
                          size: 18,
                        ),
                  label: Text(authProvider.isLoading ? 'Please wait...' : 'Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: isDarkMode ? theme.dividerTheme.color! : Colors.grey[300]!),
                    foregroundColor: theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Sign Up Link with enhanced design
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: TextStyle(color: isDarkMode ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
