import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_screen.dart';
import '../widgets/custom_bottom_navbar.dart';
import 'edit_profile_screen.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 4; // Profile tab is selected by default
  Map<String, dynamic>? _userData;
  String _userInitials = 'U';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await authService.getUserData();
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
          if (userData != null) {
            final fullName = userData['fullName'] ?? 'User';
            _userInitials = _getInitials(fullName);
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String fullName) {
    final nameParts = fullName.split(' ');
    if (nameParts.isEmpty) return 'U';
    if (nameParts.length == 1) {
      return nameParts[0].isNotEmpty
          ? nameParts[0].substring(0, 1).toUpperCase()
          : 'U';
    }
    return (nameParts[0].isNotEmpty && nameParts[1].isNotEmpty)
        ? (nameParts[0].substring(0, 1) + nameParts[1].substring(0, 1))
            .toUpperCase()
        : 'U';
  }

  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildProfileImageWidget() {
    final photoURL = _userData?['photoURL'];

    if (photoURL == null || photoURL.toString().isEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.pink.shade100,
        child: Text(
          _userInitials,
          style: const TextStyle(
            fontSize: 36,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    try {
      // Handle data URL format base64
      if (photoURL.toString().startsWith('data:image/')) {
        final base64String = photoURL.toString().split(',').last;
        return CircleAvatar(
          radius: 60,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          onBackgroundImageError: (error, stackTrace) {
            print('Error loading base64 profile image: $error');
          },
        );
      }
      // Handle network URLs
      else if (photoURL.toString().startsWith('http://') ||
          photoURL.toString().startsWith('https://')) {
        return CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(photoURL.toString()),
          onBackgroundImageError: (error, stackTrace) {
            print('Error loading network profile image: $error');
          },
        );
      }
      // Handle pure base64
      else if (_isBase64(photoURL.toString())) {
        return CircleAvatar(
          radius: 60,
          backgroundImage: MemoryImage(base64Decode(photoURL.toString())),
          onBackgroundImageError: (error, stackTrace) {
            print('Error loading base64 profile image: $error');
          },
        );
      }
    } catch (e) {
      print('Error creating profile image: $e');
    }

    // Fallback to initials
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.pink.shade100,
      child: Text(
        _userInitials,
        style: const TextStyle(
          fontSize: 36,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) => _loadUserData()); // Refresh data after edit
            },
          ),
        ],
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Profile Image
                  Center(
                    child: Stack(
                      children: [
                        _buildProfileImageWidget(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User Name
                  Text(
                    _userData?['fullName'] ??
                        FirebaseAuth.instance.currentUser?.displayName ??
                        'User',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // User Email
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'No email',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Profile Options
                  // _buildOption(
                  //   icon: Icons.person_outline,
                  //   title: 'Profile',
                  //   onTap: () {
                  //     // Already on profile screen
                  //   },
                  // ),

                  _buildOption(
                    icon: Icons.favorite_border,
                    title: 'Favorites',
                    onTap: () {
                      Navigator.pushNamed(context, '/favorites');
                    },
                  ),

                  _buildOption(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      // TODO: Navigate to settings
                    },
                  ),

                  _buildOption(
                    icon: Icons.info_outline,
                    title: 'Version',
                    subtitle: '1.0.0',
                    onTap: () {
                      // Show version info
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('App Version'),
                          content: const Text('Travel Journal v1.0.0'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  _buildOption(
                    icon: Icons.nightlight_outlined,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: Provider.of<ThemeProvider>(context).isDarkMode,
                      onChanged: (value) {
                        Provider.of<ThemeProvider>(context, listen: false)
                            .toggleTheme();
                      },
                      activeColor: Colors.blue,
                    ),
                    onTap: () {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme();
                    },
                  ),

                  const SizedBox(height: 20),

                  // Sign Out Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await authService.signOut();
                          if (mounted) {
                            // Navigate back to sign in screen
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const SignInScreen()),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          print('Error signing out: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error signing out: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Sign Out',
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index != _selectedIndex) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Helper method to build profile image
  ImageProvider? _buildProfileImage(String? imageSource) {
    if (imageSource == null || imageSource.isEmpty) {
      return null;
    }

    try {
      // Handle data URL format
      if (imageSource.startsWith('data:image/')) {
        final base64String = imageSource.split(',').last;
        return MemoryImage(base64Decode(base64String));
      }
      // Handle network URLs
      else if (imageSource.startsWith('http://') ||
          imageSource.startsWith('https://')) {
        return NetworkImage(imageSource);
      }
      // Handle pure base64
      else if (_isBase64(imageSource)) {
        return MemoryImage(base64Decode(imageSource));
      }
    } catch (e) {
      print('Error building profile image: $e');
    }

    return null;
  }
}
