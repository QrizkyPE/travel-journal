import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _userInitials = 'U';
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  String? _currentPhotoUrl;
  String? _selectedCountryCode = '+88'; // Default country code
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await authService.getUserData();
      if (mounted && userData != null) {
        setState(() {
          _userData = userData;
          _nameController.text = userData['fullName'] ?? '';
          _locationController.text = userData['location'] ?? '';
          _phoneController.text = userData['phoneNumber'] ?? '';
          _currentPhotoUrl = userData['photoURL'];

          final fullName = userData['fullName'] ?? 'User';
          _userInitials = _getInitials(fullName);

          // Extract country code if available
          final phoneNumber = userData['phoneNumber'] ?? '';
          if (phoneNumber.isNotEmpty && phoneNumber.startsWith('+')) {
            final parts = phoneNumber.split(' ');
            if (parts.length > 1) {
              _selectedCountryCode = parts[0];
              _phoneController.text = parts.sublist(1).join(' ');
            }
          }

          _isLoading = false;
        });
      } else {
        // If no user data, try to get from Firebase Auth
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && mounted) {
          setState(() {
            _nameController.text = user.displayName ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
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

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? photoURL = _currentPhotoUrl;

      // Upload new image if selected with heavy compression
      if (_selectedImage != null) {
        photoURL = await _compressAndEncodeImage(_selectedImage!);
        if (photoURL == null) {
          throw Exception('Failed to process image');
        }
      }

      // Update profile in Firestore and Auth
      await authService.updateUserProfile(
        displayName: _nameController.text.trim(),
        photoURL: photoURL,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<String?> _compressAndEncodeImage(File imageFile) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();

      // Decode image
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        throw Exception('Could not decode image');
      }

      // VERY aggressive sizing for APK - max 100x100 pixels
      const maxSize = 100;
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (originalImage.width > maxSize || originalImage.height > maxSize) {
        final ratio = maxSize /
            (originalImage.width > originalImage.height
                ? originalImage.width
                : originalImage.height);
        newWidth = (originalImage.width * ratio).round();
        newHeight = (originalImage.height * ratio).round();
      }

      // Resize image to very small size
      final resized = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear, // Faster compression
      );

      // VERY aggressive compression - quality 10
      final compressedBytes = img.encodeJpg(resized, quality: 10);

      // Check final size - must be under 10KB for APK
      if (compressedBytes.length > 10000) {
        // If still too large, make it tiny (50x50)
        final tinyResized = img.copyResize(
          originalImage,
          width: 100,
          height: 100,
          interpolation: img.Interpolation.linear,
        );
        final tinyBytes = img.encodeJpg(tinyResized, quality: 10);

        // Final check - if STILL too large, give up
        if (tinyBytes.length > 10000) {
          print(
              'Image too large even after extreme compression: ${tinyBytes.length} bytes');
          return null;
        }

        final base64String = base64Encode(tinyBytes);
        print(
            'Final compressed image size: ${tinyBytes.length} bytes, Base64 length: ${base64String.length}');
        return 'data:image/jpeg;base64,$base64String';
      }

      final base64String = base64Encode(compressedBytes);
      print(
          'Compressed image size: ${compressedBytes.length} bytes, Base64 length: ${base64String.length}');
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              'Done',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          // Profile picture
                          _selectedImage != null
                              ? CircleAvatar(
                                  radius: 60,
                                  backgroundImage: FileImage(_selectedImage!),
                                )
                              : _buildProfileImageWidget(),

                          // Edit overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Change profile picture button
                    GestureDetector(
                      onTap: _pickImage,
                      child: Text(
                        'Change Profile Picture',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Full Name field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your full name',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Location field
                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     const Text(
                    //       'Location',
                    //       style: TextStyle(
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.bold,
                    //         color: Colors.black87,
                    //       ),
                    //     ),
                    //     const SizedBox(height: 8),
                    //     Container(
                    //       decoration: BoxDecoration(
                    //         color: Colors.grey.shade100,
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       padding: const EdgeInsets.symmetric(horizontal: 16),
                    //       child: TextField(
                    //         controller: _locationController,
                    //         decoration: const InputDecoration(
                    //           hintText: 'Enter your location',
                    //           border: InputBorder.none,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),

                    const SizedBox(height: 24),

                    // Phone Number field with country code
                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     const Text(
                    //       'Mobile Number',
                    //       style: TextStyle(
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.bold,
                    //         color: Colors.black87,
                    //       ),
                    //     ),
                    //     const SizedBox(height: 8),
                    //     Row(
                    //       children: [
                    //         // Country code dropdown
                    //         Container(
                    //           decoration: BoxDecoration(
                    //             color: Colors.grey.shade100,
                    //             borderRadius: BorderRadius.circular(10),
                    //           ),
                    //           padding:
                    //               const EdgeInsets.symmetric(horizontal: 8),
                    //           child: DropdownButton<String>(
                    //             value: _selectedCountryCode,
                    //             underline: const SizedBox(),
                    //             items: const [
                    //               DropdownMenuItem(
                    //                 value: '+88',
                    //                 child: Text('+88'),
                    //               ),
                    //               DropdownMenuItem(
                    //                 value: '+1',
                    //                 child: Text('+1'),
                    //               ),
                    //               DropdownMenuItem(
                    //                 value: '+44',
                    //                 child: Text('+44'),
                    //               ),
                    //               DropdownMenuItem(
                    //                 value: '+62',
                    //                 child: Text('+62'),
                    //               ),
                    //             ],
                    //             onChanged: (value) {
                    //               setState(() {
                    //                 _selectedCountryCode = value;
                    //               });
                    //             },
                    //           ),
                    //         ),
                    //         const SizedBox(width: 8),
                    //         // Phone number field
                    //         Expanded(
                    //           child: Container(
                    //             decoration: BoxDecoration(
                    //               color: Colors.grey.shade100,
                    //               borderRadius: BorderRadius.circular(10),
                    //             ),
                    //             padding:
                    //                 const EdgeInsets.symmetric(horizontal: 16),
                    //             child: TextField(
                    //               controller: _phoneController,
                    //               keyboardType: TextInputType.phone,
                    //               decoration: const InputDecoration(
                    //                 hintText: 'Enter your phone number',
                    //                 border: InputBorder.none,
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    // ],
                    // ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper method to build profile image
  ImageProvider? _buildProfileImage(String? imageSource) {
    if (imageSource == null || imageSource.isEmpty) {
      return null; // Return null to show initials instead
    }

    try {
      // Handle data URL format base64
      if (imageSource.startsWith('data:image/')) {
        final base64String = imageSource.split(',').last;
        return MemoryImage(base64Decode(base64String));
      }
      // Handle network URLs
      else if (imageSource.startsWith('http://') ||
          imageSource.startsWith('https://')) {
        return NetworkImage(imageSource);
      }
      // Handle pure base64 string
      else if (_isBase64(imageSource)) {
        return MemoryImage(base64Decode(imageSource));
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }

    return null; // Return null to show initials fallback
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
    final profileImage = _buildProfileImage(_currentPhotoUrl);

    if (profileImage != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: profileImage,
        onBackgroundImageError: (error, stackTrace) {
          print('Error loading profile image: $error');
        },
      );
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
}
