import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'sign_up_screen.dart';
import '../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final containerColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Back button
              // Align(
              //   alignment: Alignment.topLeft,
              //   child: Padding(
              //     padding: const EdgeInsets.only(top: 16.0),
              //     child: IconButton(
              //       icon: Icon(Icons.arrow_back_ios, color: textColor?.withOpacity(0.6)),
              //       onPressed: () {
              //         Navigator.pop(context);
              //       },
              //     ),
              //   ),
              // ),
              
              const SizedBox(height: 40),
              
              // Sign in header
              Text(
                'Sign in now',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Please sign in to continue our app',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor?.withOpacity(0.6),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                  filled: true,
                  fillColor: containerColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                  filled: true,
                  fillColor: containerColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              
              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _showForgotPasswordDialog();
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // Validate inputs
                    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                      _showSnackBar('Please fill in all fields');
                      return;
                    }
                    
                    // Show loading dialog
                    _showLoadingDialog();
                    
                    try {
                      // Sign in with Firebase
                      print("Attempting to sign in with email: ${_emailController.text.trim()}");
                      final user = await authService.signInWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );
                      
                      // Check if sign-in was successful
                      if (user != null) {
                        print("Sign in successful: ${user.uid}");
                        print("User email: ${user.email}");
                        print("User display name: ${user.displayName}");
                        
                        // Dismiss loading dialog and navigate to home
                        if (context.mounted) {
                          Navigator.pop(context); // Dismiss loading dialog
                          print("Navigating to HomeScreen");
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                          );
                        }
                      } else {
                        // Something went wrong
                        if (context.mounted) {
                          Navigator.pop(context); // Dismiss loading dialog
                          _showSnackBar('Sign in failed. Please try again.');
                        }
                      }
                    } catch (e) {
                      print("Sign in error: $e");
                      // Dismiss loading dialog and show error
                      if (context.mounted) {
                        Navigator.pop(context); // Dismiss loading dialog
                        _showSnackBar(e.toString());
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(color: textColor?.withOpacity(0.6)),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to sign up page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Or connect divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey,
                      thickness: 0.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or connect',
                      style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey,
                      thickness: 0.5,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Social login buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Facebook
                  _socialLoginButton(
                    color: Colors.blue,
                    icon: Icons.facebook,
                    onPressed: () {
                      // TODO: Implement Facebook login
                    },
                  ),
                  const SizedBox(width: 24),
                  
                  // Instagram
                  _socialLoginButton(
                    icon: Icons.camera_alt,
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.pink, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onPressed: () {
                      // TODO: Implement Instagram login
                    },
                  ),
                  const SizedBox(width: 24),
                  
                  // Twitter
                  // _socialLoginButton(
                  //   color: Colors.lightBlue,
                  //   icon: Icons.twitter,
                  //   onPressed: () {
                  //     // TODO: Implement Twitter login
                  //   },
                  // ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Bottom indicator
              Container(
                width: 70,
                height: 5,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _socialLoginButton({
    Color? color,
    Gradient? gradient,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        gradient: gradient,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  void _showLoadingDialog() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text("Signing in...", style: TextStyle(color: textColor)),
            ],
          ),
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final containerColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Password', style: TextStyle(color: textColor)),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
              filled: true,
              fillColor: containerColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (emailController.text.isEmpty) {
                  Navigator.pop(context);
                  _showSnackBar('Please enter your email');
                  return;
                }
                
                try {
                  await authService.resetPassword(email: emailController.text.trim());
                  Navigator.pop(context);
                  _showSnackBar('Password reset email sent. Check your inbox.');
                } catch (e) {
                  Navigator.pop(context);
                  _showSnackBar(e.toString());
                }
              },
              child: Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
