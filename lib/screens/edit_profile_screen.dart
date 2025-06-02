import 'package:flutter/material.dart';
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

      // Upload new image if selected
      if (_selectedImage != null) {
        // Convert to base64 for storage
        final bytes = await _selectedImage!.readAsBytes();
        photoURL = base64Encode(bytes);
      }

      // // Format phone number with country code if present
      // String phoneNumber = _phoneController.text.trim();
      // if (phoneNumber.isNotEmpty && _selectedCountryCode != null) {
      //   phoneNumber = '$_selectedCountryCode $phoneNumber';
      // }

      // Update profile in Firestore and Auth
      await authService.updateUserProfile(
        displayName: _nameController.text.trim(),
        photoURL: photoURL,
        // location: _locationController.text.trim(),
        // phoneNumber: phoneNumber,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context); // Go back to profile screen
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
                              : _currentPhotoUrl != null
                                  ? CircleAvatar(
                                      radius: 60,
                                      backgroundImage:
                                          _buildProfileImage(_currentPhotoUrl),
                                    )
                                  : CircleAvatar(
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
                                    ),

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
  ImageProvider _buildProfileImage(String? imageSource) {
    try {
      if (imageSource == null) {
        return const AssetImage('assets/images/default_avatar.png');
      }

      if (imageSource.startsWith('data:image') ||
          RegExp(r'^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{4})$')
              .hasMatch(imageSource)) {
        // It's base64, decode it
        return MemoryImage(base64Decode(imageSource.split(',').last));
      } else {
        // Assume it's a network URL
        return NetworkImage(imageSource);
      }
    } catch (e) {
      print('Error loading profile image: $e');
      return const AssetImage('assets/images/default_avatar.png');
    }
  }
}
