import 'package:flutter/material.dart';
import '../models/travel_post.dart';
import '../services/travel_post_service.dart';
import 'dart:convert';
import '../widgets/custom_bottom_navbar.dart';
import 'detail_screen.dart';
import '../services/auth_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<TravelPost> _favoritePosts = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the stream and take the first value
      final favorites = await travelPostService.getFavoritePosts().first;

      if (mounted) {
        setState(() {
          _favoritePosts = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorites: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: textColor,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: null,
          ),
        ],
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favoritePosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: iconColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No favorites yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add some posts to your favorites',
                          style: TextStyle(
                            fontSize: 14,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favoritePosts.length,
                    itemBuilder: (context, index) {
                      final post = _favoritePosts[index];
                      return _buildFavoriteCard(post);
                    },
                  ),
      ),
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

  Widget _buildFavoriteCard(TravelPost post) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final containerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    // Current user ID
    final currentUserId = authService.currentUser?.uid;
    final isCurrentUserPost = post.userId == currentUserId;

    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService().getUserDataById(post.userId),
      builder: (context, snapshot) {
        // Default author info
        String authorName = isCurrentUserPost ? "You" : "User";
        String authorInitials = "U";
        String? photoURL;

        // Update with actual data if available
        if (snapshot.hasData && snapshot.data != null) {
          final userData = snapshot.data!;
          if (!isCurrentUserPost) {
            authorName = userData['fullName'] ?? "User";
          }
          authorInitials = _getInitials(userData['fullName'] ?? "User");
          photoURL = userData['photoURL'];
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(postId: post.id),
              ),
            ).then((_) => _loadFavorites()); // Refresh favorites on return
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post author
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      // Author photo
                      _buildAuthorAvatar(photoURL, authorInitials),
                      const SizedBox(width: 12),

                      // Author name
                      Expanded(
                        child: Text(
                          authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Unlike/Remove from favorites button
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () async {
                          if (isCurrentUserPost) {
                            // If this is the user's own post, toggle the favorite status
                            await travelPostService.toggleFavorite(post.id);
                          } else {
                            // If this is another user's post, unlike it
                            await travelPostService.unlikePost(post.id);
                          }
                          _loadFavorites(); // Refresh the list
                        },
                        constraints: const BoxConstraints(minWidth: 40),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                // Post image
                if (post.imageUrl != null)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                    child: _buildImage(post.imageUrl!),
                  )
                else
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.photo,
                        size: 50,
                        color: iconColor,
                      ),
                    ),
                  ),

                // Post details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      // Description
                      Text(
                        post.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor?.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Location and date in a row that won't overflow
                      Row(
                        children: [
                          // Location with Expanded to prevent overflow
                          Expanded(
                            child: Row(
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: iconColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Date
                          Text(
                            _formatDate(post.date),
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to get initials from name
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

  // Helper to build image from base64 or URL
  Widget _buildImage(String imageSource) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final containerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    try {
      // Check if it's a base64 image (data URL format)
      if (imageSource.startsWith('data:image/')) {
        final base64String = imageSource.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          height: 180,
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
          height: 180,
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
          height: 180,
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
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image: $error');
            return _buildErrorImage();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 180,
              color: containerColor,
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

// Helper method to check if string is valid base64
  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

// Helper method for error image
  Widget _buildErrorImage() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final containerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      height: 180,
      color: containerColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: iconColor,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                fontSize: 12,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorAvatar(String? photoURL, String initials) {
    if (photoURL == null || photoURL.isEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.blue,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    try {
      // Handle data URL format base64
      if (photoURL.startsWith('data:image/')) {
        final base64String = photoURL.split(',').last;
        return CircleAvatar(
          radius: 18,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          backgroundColor: Colors.blue,
          onBackgroundImageError: (error, stackTrace) {
            print('Error loading avatar image: $error');
          },
        );
      }
      // Handle network URLs
      else if (photoURL.startsWith('http://') ||
          photoURL.startsWith('https://')) {
        return CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(photoURL),
          backgroundColor: Colors.blue,
          onBackgroundImageError: (error, stackTrace) {
            print('Error loading network avatar: $error');
          },
        );
      }
      // Handle pure base64
      else if (_isBase64(photoURL)) {
        return CircleAvatar(
          radius: 18,
          backgroundImage: MemoryImage(base64Decode(photoURL)),
          backgroundColor: Colors.blue,
          onBackgroundImageError: (error, stackTrace) {
            print('Error loading base64 avatar: $error');
          },
        );
      }
    } catch (e) {
      print('Error creating avatar: $e');
    }

    // Fallback to initials
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.blue,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
