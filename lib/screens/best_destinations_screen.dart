import 'package:flutter/material.dart';
import '../models/travel_post.dart';
import '../services/travel_post_service.dart';
import '../services/auth_service.dart';
import 'detail_screen.dart';
import 'dart:convert';

class BestDestinationsScreen extends StatefulWidget {
  const BestDestinationsScreen({super.key});

  @override
  State<BestDestinationsScreen> createState() => _BestDestinationsScreenState();
}

class _BestDestinationsScreenState extends State<BestDestinationsScreen> {
  List<TravelPost> _allDestinations = [];
  bool _isLoading = true;
  Map<String, Map<String, dynamic>?> _userDataCache = {};

  @override
  void initState() {
    super.initState();
    _loadBestDestinations();
  }

  Future<void> _loadBestDestinations() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Get all posts from Firestore
      final posts = await travelPostService.getRecentPosts();

      // Sort posts by like count in descending order
      posts.sort((a, b) => b.likeCount.compareTo(a.likeCount));

      if (mounted) {
        setState(() {
          _allDestinations = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading best destinations: $e");

      if (mounted) {
        setState(() {
          _allDestinations = [];
          _isLoading = false;
        });

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't load destinations: $e")),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _getUserDataForPost(String userId) async {
    // Check if we already have this user's data in cache
    if (_userDataCache.containsKey(userId)) {
      return _userDataCache[userId];
    }

    try {
      final userData = await authService.getUserDataById(userId);
      // Cache the result
      _userDataCache[userId] = userData;
      return userData;
    } catch (e) {
      print("Error loading user data for post: $e");
      return null;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Best Destinations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allDestinations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_city_outlined,
                        size: 80,
                        color: isDarkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No destinations found',
                        style: TextStyle(
                          fontSize: 18,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allDestinations.length,
                  itemBuilder: (context, index) {
                    return _buildDestinationCard(_allDestinations[index]);
                  },
                ),
    );
  }

  Widget _buildDestinationCard(TravelPost post) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final cardColor = theme.cardColor;

    // Check if this is the current user's post
    final isUserPost = post.userId == authService.currentUser?.uid;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(postId: post.id),
          ),
        ).then((_) => _loadBestDestinations());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post image with rankings overlay
            Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: post.imageUrl != null
                      ? _buildImage(post.imageUrl!)
                      : Container(
                          height: 180,
                          width: double.infinity,
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),

                // Ranking badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rank #${_allDestinations.indexOf(post) + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Like count
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // User's own post indicator
                if (isUserPost)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Your Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Post details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author info
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _getUserDataForPost(post.userId),
                    builder: (context, snapshot) {
                      final userData = snapshot.data;

                      return userData != null
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  _buildUserAvatar(userData),
                                  const SizedBox(width: 8),
                                  Text(
                                    userData['fullName'] ?? 'User',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  ),

                  // Title
                  Text(
                    post.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.location,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // View Details button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(postId: post.id),
                          ),
                        ).then((_) {
                          if (mounted) {
                            _loadBestDestinations();
                          }
                        });
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildImage(String imageSource) {
    if (imageSource.isEmpty) {
      return _buildPlaceholderImage();
    }

    try {
      // Handle data URL base64 (data:image/jpeg;base64,...)
      if (imageSource.startsWith('data:image/')) {
        final base64String = imageSource.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorImage('Base64 decode failed'),
        );
      }

      // Handle network URLs
      if (imageSource.startsWith('http')) {
        return Image.network(
          imageSource,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingImage();
          },
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorImage('Network error'),
        );
      }

      // Handle asset images
      if (imageSource.startsWith('assets/')) {
        return Image.asset(
          imageSource,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorImage('Asset not found'),
        );
      }

      // Try as pure base64 string
      if (_looksLikeBase64(imageSource)) {
        return Image.memory(
          base64Decode(imageSource),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorImage('Invalid base64'),
        );
      }

      // Unknown format
      return _buildErrorImage(
          'Unknown format: ${imageSource.substring(0, 20)}...');
    } catch (e) {
      print('Image loading error: $e');
      return _buildErrorImage('Loading failed');
    }
  }

// Helper methods
  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey, size: 40),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorImage(String error) {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.red, size: 30),
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(fontSize: 10, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _looksLikeBase64(String str) {
    if (str.length < 100) return false;
    return RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(str);
  }

  Widget _buildUserAvatar(Map<String, dynamic>? userData) {
    final userInitials =
        userData != null ? _getInitials(userData['fullName'] ?? 'User') : 'U';

    // Default avatar widget
    Widget defaultAvatar = CircleAvatar(
      radius: 16,
      backgroundColor: Colors.blue,
      child: Text(
        userInitials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // If no user data, return default
    if (userData == null) return defaultAvatar;

    final photoURL = userData['photoURL'];
    if (photoURL == null || photoURL.toString().isEmpty) {
      return defaultAvatar;
    }

    // Use FutureBuilder for better loading states
    return FutureBuilder<ImageProvider?>(
      future: _getAvatarImageProvider(photoURL.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return CircleAvatar(
            radius: 16,
            backgroundImage: snapshot.data!,
            backgroundColor: Colors.blue,
            onBackgroundImageError: (error, stackTrace) {
              print('Avatar image error: $error');
            },
          );
        }

        // Fallback to initials
        return defaultAvatar;
      },
    );
  }

// Helper to get image provider
  Future<ImageProvider?> _getAvatarImageProvider(String photoURL) async {
    try {
      // Handle data URL base64
      if (photoURL.startsWith('data:image/')) {
        final base64String = photoURL.split(',').last;
        return MemoryImage(base64Decode(base64String));
      }

      // Handle network URLs
      if (photoURL.startsWith('http')) {
        return NetworkImage(photoURL);
      }

      // Handle pure base64
      if (_looksLikeBase64(photoURL)) {
        return MemoryImage(base64Decode(photoURL));
      }

      return null;
    } catch (e) {
      print('Error getting avatar image provider: $e');
      return null;
    }
  }
}
