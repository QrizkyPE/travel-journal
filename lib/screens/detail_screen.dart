import 'package:flutter/material.dart';
import '../models/travel_post.dart';
import '../services/travel_post_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import '../widgets/custom_bottom_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_view_screen.dart';

class DetailScreen extends StatefulWidget {
  final String? postId;

  // If postId is null, we show all posts instead of a specific one
  const DetailScreen({super.key, this.postId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  TravelPost? _post;
  List<TravelPost> _allPosts = [];
  bool _isLoading = true;
  int _selectedIndex = 3; // Detail tab is selected by default

  // Store user data for post
  Map<String, dynamic>? _userData;
  String _userInitials = 'U';
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    if (_post != null) {
      _loadUserData();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      if (widget.postId != null) {
        // Load a specific post
        final post = await travelPostService.getPostById(widget.postId!);
        if (mounted) {
          setState(() {
            _post = post;
            _isLoading = false;
          });

          // Load user data for this post
          if (post != null) {
            _loadUserData();
          }
        }
      } else {
        // Load all posts for the listing view
        final posts = await travelPostService.getRecentPosts();
        if (mounted) {
          setState(() {
            _allPosts = posts;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't load data: $e")),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      if (_post != null && _post?.userId != null) {
        // Force fresh data retrieval
        final userData = await AuthService().getUserDataById(_post!.userId!);
        if (mounted) {
          setState(() {
            _userData = userData;
            if (userData != null && userData['fullName'] != null) {
              _userName = userData['fullName'];
              _userInitials = _getInitials(_userName);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
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

  // Check if the post belongs to the current user
  bool _isCurrentUserPost() {
    if (_post?.userId == null) return false;
    final currentUserId = authService.currentUser?.uid;
    return _post?.userId == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.postId != null ? 'Detail Screen' : 'All Travel Notes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: textColor,
          ),
        ),
        centerTitle: true,
        // Only show back button if accessing a specific post
        leading: widget.postId != null
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 20, color: textColor),
                onPressed: () {
                  // Use the custom back navigation
                  Navigator.pop(context);
                },
              )
            : null,
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.postId != null
              ? _post == null
                  ? Center(
                      child: Text('Post not found',
                          style: TextStyle(color: textColor)))
                  : _buildPostDetail()
              : _buildPostsList(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  // Show all posts in a list
  Widget _buildPostsList() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: RichText(
          //     text: TextSpan(
          //       style: TextStyle(
          //         fontSize: 24,
          //         fontWeight: FontWeight.bold,
          //         color: textColor,
          //       ),
          //       children: [
          //         TextSpan(text: 'Awali Barumu dengan '),
          //         TextSpan(
          //           text: 'Liburan',
          //           style: const TextStyle(
          //             color: Colors.amber,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          const SizedBox(height: 10),

          // Post list
          _allPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      Icon(
                        Icons.photo_album_outlined,
                        size: 80,
                        color: iconColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No travel notes yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _allPosts.length,
                  itemBuilder: (context, index) {
                    return _buildPostCard(_allPosts[index], context);
                  },
                ),
        ],
      ),
    );
  }

  // Build a card for each post in the list
  Widget _buildPostCard(TravelPost post, BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final containerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return GestureDetector(
      onTap: () {
        _navigateForward(DetailScreen(postId: post.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
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
            // Image with category tag overlay
            Stack(
              children: [
                // Image
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: post.imageUrl != null
                        ? _buildImage(post.imageUrl!, context)
                        : Center(
                            child: Icon(
                              Icons.photo,
                              size: 50,
                              color: iconColor,
                            ),
                          ),
                  ),
                ),

                // Category tag overlay
                if (post.category != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        post.category!,
                        style: TextStyle(
                          color: Colors.blue.shade800,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info (conditional)
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _getUserDataForPost(post.userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 0);
                      }

                      final userData = snapshot.data;
                      if (userData == null) {
                        return const SizedBox(height: 0);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue,
                              backgroundImage: _buildUserAvatarImage(userData),
                              child: _buildUserAvatarImage(userData) == null
                                  ? Text(
                                      _getInitials(
                                          userData['fullName'] ?? 'User'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userData['fullName'] ?? 'User',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Title
                  Text(
                    post.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

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
                        child: GestureDetector(
                          onTap: () {
                            // Navigate to map if coordinates available
                            if (post.latitude != null &&
                                post.longitude != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MapViewScreen(post: post),
                                ),
                              );
                            } else {
                              // Show snackbar if no coordinates
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'No location coordinates available for this post'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Text(
                            post.location,
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(post.date),
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Notes (Description) preview
                  Text(
                    "Note:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor?.withOpacity(0.8),
                      fontSize: 14,
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

  // Show a single post detail
  Widget _buildPostDetail() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final containerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          if (_post?.imageUrl != null) ...[
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: containerColor,
              ),
              child: _buildImage(_post!.imageUrl!, context),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              height: 200,
              color: containerColor,
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 80,
                  color: iconColor,
                ),
              ),
            ),
          ],

          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post author info
                Row(
                  children: [
                    // Author photo
                    _userData != null
                        ? CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue,
                            backgroundImage: _buildUserAvatarImage(_userData),
                            child: _buildUserAvatarImage(_userData) == null
                                ? Text(
                                    _userInitials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          )
                        : const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                    const SizedBox(width: 12),

                    // Author name and post date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Posted on ${_formatDate(_post?.date ?? DateTime.now())}',
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Like button
                    _buildLikeButton(),
                  ],
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  _post?.title ?? 'No title',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 8),

                // Category chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.blue.shade900.withOpacity(0.5)
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _post?.category ?? 'No category',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.blue.shade100
                          : Colors.blue.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _post?.description ?? 'No description',
                  style: TextStyle(
                    color: textColor?.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Map preview if location data exists
                if (_post?.latitude != null && _post?.longitude != null) ...[
                  Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapViewScreen(
                            post: _post!,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map,
                              size: 64,
                              color: iconColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'View on Map',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Handle share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Sharing not implemented yet')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    // Only show delete button if post belongs to current user
                    if (_isCurrentUserPost()) ...[
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Post?',
                                  style: TextStyle(color: textColor)),
                              content: Text(
                                'Are you sure you want to delete this post? This action cannot be undone.',
                                style: TextStyle(
                                    color: textColor?.withOpacity(0.8)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            try {
                              await travelPostService.deletePost(_post!.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Post deleted successfully')),
                                );
                                _navigateBack(refresh: true);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error deleting post: $e')),
                                );
                              }
                            }
                          }
                        },
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build image from base64 or URL
  Widget _buildImage(String imageSource, BuildContext context) {
    try {
      // Check if it's a base64 image (data URL format)
      if (imageSource.startsWith('data:image/')) {
        final base64String = imageSource.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading base64 image: $error');
            return _buildErrorImage();
          },
        );
      }
      // Check if it's a pure base64 string (without data URL prefix)
      else if (_isBase64(imageSource)) {
        return Image.memory(
          base64Decode(imageSource),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading base64 image: $error');
            return _buildErrorImage();
          },
        );
      }
      // Check if it's an asset
      else if (imageSource.startsWith('assets/')) {
        return Image.asset(
          imageSource,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading asset image: $error');
            return _buildErrorImage();
          },
        );
      }
      // Check if it's a network URL
      else if (imageSource.startsWith('http://') ||
          imageSource.startsWith('https://')) {
        return Image.network(
          imageSource,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image: $error');
            return _buildErrorImage();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey.shade200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              ),
            );
          },
        );
      }
      // If none of the above, show error
      else {
        print('Unknown image format: $imageSource');
        return _buildErrorImage();
      }
    } catch (e) {
      print('Error displaying image: $e');
      return _buildErrorImage();
    }
  }

// Add these helper methods:
  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildErrorImage() {
    return Container(
      height: 200,
      color: Colors.grey.shade300,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text('Image not available', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Add method to load user data for a specific post by userId
  Future<Map<String, dynamic>?> _getUserDataForPost(String? userId) async {
    if (userId == null) return null;

    try {
      // Check if we already have cached data for this user
      // This is important for base64 images to avoid reloading them
      return await AuthService().getUserDataById(userId);
    } catch (e) {
      print('Error loading user data for post: $e');
      return null;
    }
  }

  ImageProvider? _buildUserAvatarImage(Map<String, dynamic>? userData) {
    if (userData == null || userData['photoURL'] == null) {
      return null;
    }

    final photoURL = userData['photoURL'].toString();

    if (photoURL.isEmpty) return null;

    try {
      // Handle data URL format
      if (photoURL.startsWith('data:image/')) {
        final base64String = photoURL.split(',').last;
        return MemoryImage(base64Decode(base64String));
      }
      // Handle network URLs
      else if (photoURL.startsWith('http://') ||
          photoURL.startsWith('https://')) {
        return NetworkImage(photoURL);
      }
      // Handle pure base64
      else if (_isBase64(photoURL)) {
        return MemoryImage(base64Decode(photoURL));
      }
    } catch (e) {
      print('Error building user avatar image: $e');
    }

    return null;
  }

  // Build like button for the post detail
  Widget _buildLikeButton() {
    return FutureBuilder<bool>(
      future: _post != null
          ? travelPostService.hasUserLikedPost(_post!.id)
          : Future.value(false),
      builder: (context, snapshot) {
        final bool hasLiked = snapshot.data ?? false;

        return GestureDetector(
          onTap: () async {
            if (_post != null) {
              // Toggle like status based on current status
              try {
                if (hasLiked) {
                  // If user already liked the post, unlike it
                  await travelPostService.unlikePost(_post!.id);

                  // Update local state immediately for responsive UI
                  setState(() {
                    // Create a temporary likedBy list by removing current user
                    final List<String> updatedLikedBy =
                        List.from(_post!.likedBy);
                    final currentUserId = authService.currentUser?.uid;
                    if (currentUserId != null &&
                        updatedLikedBy.contains(currentUserId)) {
                      updatedLikedBy.remove(currentUserId);
                    }

                    // Update post with new like count
                    _post = _post!.copyWith(
                        likeCount: updatedLikedBy.length,
                        likedBy: updatedLikedBy,
                        isFavorite: false);
                  });
                } else {
                  // If user hasn't liked the post, like it
                  await travelPostService.likePost(_post!.id);

                  // Update local state immediately for responsive UI
                  setState(() {
                    // Create a temporary likedBy list by adding current user
                    final List<String> updatedLikedBy =
                        List.from(_post!.likedBy);
                    final currentUserId = authService.currentUser?.uid;
                    if (currentUserId != null &&
                        !updatedLikedBy.contains(currentUserId)) {
                      updatedLikedBy.add(currentUserId);
                    }

                    // Update post with new like count
                    _post = _post!.copyWith(
                        likeCount: updatedLikedBy.length,
                        likedBy: updatedLikedBy,
                        isFavorite: true);
                  });
                }
              } catch (e) {
                print("Error toggling like: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Couldn't update like status: $e")),
                  );
                }
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasLiked ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  _post != null
                      ? (_post!.likeCount > 99 ? '99+' : '${_post!.likeCount}')
                      : '0',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Simple navigation without animations
  void _navigateForward(Widget destination) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  // Simple back navigation
  void _navigateBack({bool refresh = false}) {
    Navigator.pop(context, refresh);
  }

  Widget _buildProfileImage() {
    if (_userData == null) {
      return CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        radius: 20,
        child: Icon(
          Icons.person,
          color: Colors.grey.shade600,
          size: 24,
        ),
      );
    }

    final photoURL = _userData!['photoURL'];

    if (photoURL != null && photoURL.toString().isNotEmpty) {
      try {
        // Handle data URL format base64
        if (photoURL.toString().startsWith('data:image/')) {
          final base64String = photoURL.toString().split(',').last;
          return CircleAvatar(
            backgroundImage: MemoryImage(base64Decode(base64String)),
            radius: 20,
            onBackgroundImageError: (error, stackTrace) {
              print('Error loading avatar image: $error');
            },
          );
        }
        // Handle network URLs
        else if (photoURL.toString().startsWith('http://') ||
            photoURL.toString().startsWith('https://')) {
          return CircleAvatar(
            backgroundImage: NetworkImage(photoURL.toString()),
            radius: 20,
            onBackgroundImageError: (error, stackTrace) {
              print('Error loading network avatar: $error');
            },
          );
        }
        // Handle pure base64
        else if (_isBase64(photoURL.toString())) {
          return CircleAvatar(
            backgroundImage: MemoryImage(base64Decode(photoURL.toString())),
            radius: 20,
            onBackgroundImageError: (error, stackTrace) {
              print('Error loading base64 avatar: $error');
            },
          );
        }
      } catch (e) {
        print('Error creating avatar: $e');
      }
    }

    return CircleAvatar(
      backgroundColor: Colors.blue,
      radius: 20,
      child: Text(
        _userInitials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
