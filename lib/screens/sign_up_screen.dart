import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'sign_in_screen.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final containerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;

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

              const SizedBox(height: 30),

              // Sign up header
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Please fill the details to create an account',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor?.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 30),

              // Name field
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                  filled: true,
                  fillColor: containerColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                  filled: true,
                  fillColor: containerColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                  filled: true,
                  fillColor: containerColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
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

              const SizedBox(height: 16),

              // Confirm Password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                  filled: true,
                  fillColor: containerColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign up button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // Validate form
                    if (_nameController.text.isEmpty ||
                        _emailController.text.isEmpty ||
                        _passwordController.text.isEmpty ||
                        _confirmPasswordController.text.isEmpty) {
                      _showSnackBar('Please fill in all fields');
                      return;
                    }

                    // Validate password match
                    if (_passwordController.text !=
                        _confirmPasswordController.text) {
                      _showSnackBar('Passwords do not match');
                      return;
                    }

                    // Show loading indicator
                    _showLoadingDialog();

                    try {
                      // Register user with Firebase
                      final user = await authService.signUpWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                        fullName: _nameController.text.trim(),
                      );

                      // Check if registration was successful
                      if (user != null) {
                        print("Sign up successful: ${user.uid}");

                        // Give Firebase some time to update the user profile
                        await Future.delayed(
                            const Duration(milliseconds: 1000));

                        // Dismiss loading dialog and navigate to home
                        if (context.mounted) {
                          Navigator.pop(context); // Dismiss loading dialog

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account created successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Navigate to home screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignInScreen()),
                          );
                        }
                      } else {
                        // Something went wrong
                        if (context.mounted) {
                          Navigator.pop(context); // Dismiss loading dialog
                          _showSnackBar(
                              'Registration failed. Please try again.');
                        }
                      }
                    } catch (e) {
                      print("Sign up error: $e");
                      // Dismiss loading dialog and show error
                      if (context.mounted) {
                        Navigator.pop(context); // Dismiss loading dialog

                        // Handle the special case where account was created but profile setup failed
                        if (e.toString().contains(
                            'Account was created but profile setup failed')) {
                          // Show alert dialog with option to continue
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Account Created'),
                              content: const Text(
                                  'Your account was created successfully, but there was an issue setting up your profile. '
                                  'You can still sign in with your credentials.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Dismiss dialog
                                    // Navigate to sign in screen
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SignInScreen()),
                                    );
                                  },
                                  child: const Text('Sign In'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Dismiss dialog
                                    // Try to navigate to home if user is signed in
                                    if (authService.currentUser != null) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const HomeScreen()),
                                      );
                                    }
                                  },
                                  child: const Text('Continue'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Show regular error
                          _showSnackBar(e.toString());
                        }
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
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(color: textColor?.withOpacity(0.6)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignInScreen()),
                      );
                    },
                    child: const Text(
                      'Sign in',
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
                      'Or connect with',
                      style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
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
                  color:
                      isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
              Text("Creating account...", style: TextStyle(color: textColor)),
            ],
          ),
        );
      },
    );
  }
}
