import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/providers/auth_provider.dart';
import 'package:campus_care/screens/home_screen.dart';
import 'package:campus_care/utils/validators.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _signupWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await authProvider.signInWithGoogle();
    
    // Note: The actual navigation will happen after the OAuth redirect
    // is handled and the session is restored
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: BoxConstraints(maxWidth: isDesktop ? 450 : double.infinity),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo or App Icon
                    Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(height: 24),
                    // App Name
                    Text(
                      'Campus Care',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    Text(
                      'Order food from your campus cafeteria',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Signup Form
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign up to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Enter your email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: Validators.validateEmail,
                              ),
                              const SizedBox(height: 16),
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Create a password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                validator: Validators.validatePassword,
                              ),
                              const SizedBox(height: 16),
                              // Confirm Password Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  hintText: 'Confirm your password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _signup(),
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              // Error Message
                              if (authProvider.error != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Text(
                                    authProvider.error!,
                                    style: TextStyle(color: Colors.red[700]),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              if (authProvider.error != null)
                                const SizedBox(height: 16),
                              // Signup Button
                              ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _signup,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              // OR Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Google Signup Button
                              OutlinedButton.icon(
                                onPressed: authProvider.isLoading ? null : _signupWithGoogle,
                                icon: const FaIcon(
                                  FontAwesomeIcons.google,
                                  size: 18,
                                ),
                                label: const Text('Continue with Google'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account?',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
