import 'package:flutter/material.dart';
import 'post_screen.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_screen.dart';
import '../models/travel_post.dart';
import '../services/travel_post_service.dart';
import 'dart:convert';
import '../widgets/custom_bottom_navbar.dart';
import 'detail_screen.dart';
import 'map_view_screen.dart';
import 'best_destinations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String userName = '';
  String userInitials = '';
  String? userPhotoURL;

  List<TravelPost> _recentPosts = [];
  List<TravelPost> _bestDestinations = [];
  List<TravelPost> _userPosts = []; // Current user's posts
  bool _isLoading = true;

  Map<String, Map<String, dynamic>?> _userDataCache = {};

  @override
  void initState() {
    super.initState();
    // Get current user data
    _loadUserData();
    // Load recent posts and popular destinations
    _loadPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data when the screen becomes visible
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = authService.currentUser;
      if (user != null) {
        try {
          // Clear the user data cache to ensure we get fresh data
          _userDataCache.clear();

          final userData = await authService.getUserData();
          if (userData != null && mounted) {
            setState(() {
              userName = userData['fullName'] ?? user.displayName ?? 'User';
              userInitials = _getInitials(userName);
              userPhotoURL = userData['photoURL'];
            });
          } else {
            // If no Firestore data found, fallback to Auth user data
            setState(() {
              userName =
                  user.displayName ?? user.email?.split('@')[0] ?? 'User';
              userInitials = _getInitials(userName);
              userPhotoURL = user.photoURL;
            });
          }
        } catch (e) {
          // If we can't get Firestore data, still show the user's display name from Auth
          print("Home Screen: Error getting Firestore data: $e");
          setState(() {
            userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
            userInitials = _getInitials(userName);
          });
        }
      }
    } catch (e) {
      print("Home Screen: Error loading user data: $e");
    }
  }

  Future<void> _loadPosts() async {
    try {
      setState(() => _isLoading = true);

      // Get all posts from Firestore
      final posts = await travelPostService.getRecentPosts();

      // Get current user's posts
      final userPosts = await travelPostService.getUserPosts();

      // Get current user ID
      final userId = authService.currentUser?.uid;

      // Filter posts not created by the current user
      final otherUsersPosts = userId != null
          ? posts.where((post) => post.userId != userId).toList()
          : posts;

      // For best destinations, use all posts including user's own
      final bestDestinations = List<TravelPost>.from(posts);
      bestDestinations.sort((a, b) => (b.likeCount).compareTo(a.likeCount));

      if (mounted) {
        setState(() {
          _recentPosts = otherUsersPosts;
          _userPosts = userPosts;
          _bestDestinations = bestDestinations.take(5).toList(); // Get top 5
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading posts: $e");

      if (mounted) {
        setState(() {
          _recentPosts = [];
          _userPosts = [];
          _bestDestinations = [];
          _isLoading = false;
        });

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't load posts: $e")),
        );
      }
    }
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return 'U';

    final nameParts =
        fullName.split(' ').where((part) => part.isNotEmpty).toList();
    if (nameParts.isEmpty) return 'U';

    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }

    return (nameParts[0].substring(0, 1) + nameParts[1].substring(0, 1))
        .toUpperCase();
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

  String _getInitialsFromUserData(Map<String, dynamic>? userData) {
    if (userData == null ||
        userData['fullName'] == null ||
        userData['fullName'].toString().isEmpty) {
      return 'U';
    }
    return _getInitials(userData['fullName'].toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final containerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
                future: authService.getUserData(),
                builder: (context, snapshot) {
                  // Always use the latest data
                  final userData = snapshot.data;
                  final photoURL = userData?['photoURL'] ?? userPhotoURL;

                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue,
                    backgroundImage: _buildUserProfileImage(photoURL),
                    child: (photoURL == null || photoURL.isEmpty)
                        ? Text(
                            userInitials.isEmpty ? 'U' : userInitials,
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  );
                }),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                userName.isEmpty ? 'Loading...' : userName.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: textColor),
            onPressed: () {
              // Navigate to favorites screen
              Navigator.pushNamed(context, '/favorites');
            },
          ),
        ],
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome text
              Text(
                'Jelajahi Keindahan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Dunia',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    ' !',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Best Destination section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Best Destinations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all best destinations
                      _navigateForward(const BestDestinationsScreen(),
                          onReturn: () => _loadPosts());
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Best Destinations list
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (_bestDestinations.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        Icons.location_city_outlined,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No destinations yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _bestDestinations.length,
                    itemBuilder: (context, index) {
                      final post = _bestDestinations[index];
                      return _buildDestinationCard(post);
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // My Travel Notes
              if (_userPosts.isNotEmpty) ...[
                const Text(
                  'My Travel Notes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // User's posts list
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _userPosts.length > 3
                      ? 3
                      : _userPosts.length, // Show only first 3
                  itemBuilder: (context, index) {
                    final post = _userPosts[index];
                    return _buildPostCard(post);
                  },
                ),

                // View all button if there are more than 3 posts
                if (_userPosts.length > 3)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to detail screen without specific postId to show all posts
                        _navigateForward(const DetailScreen(),
                            onReturn: () => _loadPosts(), allowBack: true);
                      },
                      child: const Text(
                        'View all my notes',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],

              // Recent posts from other users section
              const Text(
                'Discover Travel Notes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // Recent posts list
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (_recentPosts.isEmpty && _userPosts.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Icon(
                        Icons.photo_album_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first travel memory',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _navigateForward(const PostScreen(),
                              onReturn: () => _loadPosts());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Create Post'),
                      ),
                    ],
                  ),
                )
              else if (_recentPosts.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Icon(
                        Icons.search_off_outlined,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No other travel notes found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _recentPosts.length,
                  itemBuilder: (context, index) {
                    final post = _recentPosts[index];
                    return _buildPostCard(post);
                  },
                ),
            ],
          ),
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

  Widget _buildDestinationCard(TravelPost post) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final containerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;

    // Check if this is the current user's post
    final isUserPost = post.userId == authService.currentUser?.uid;

    return GestureDetector(
      onTap: () {
        _navigateForward(DetailScreen(postId: post.id),
            onReturn: () => _loadPosts(), allowBack: true);
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Post image
              if (post.imageUrl != null)
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _buildImage(post.imageUrl!),
                )
              else
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: containerColor,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.photo,
                      size: 50,
                      color: isDarkMode
                          ? Colors.grey.shade600
                          : Colors.grey.shade500,
                    ),
                  ),
                ),

              // Category tag overlay
              if (post.category.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      post.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Your post indicator for user's own posts
              if (isUserPost)
                Positioned(
                  top: 40,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

              // Like count display
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title and details overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author row
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _getUserDataForPost(post.userId),
                        builder: (context, snapshot) {
                          final userData = snapshot.data;
                          if (userData != null) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  _buildUserAvatar(userData),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      userData['fullName'] ?? 'User',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),

                      Text(
                        post.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(TravelPost post) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final containerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return GestureDetector(
      onTap: () {
        _navigateForward(DetailScreen(postId: post.id),
            onReturn: () => _loadPosts());
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.cardColor,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with user info
            FutureBuilder<Map<String, dynamic>?>(
                future: _getUserDataForPost(post.userId),
                builder: (context, snapshot) {
                  final userData = snapshot.data;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        userData != null
                            ? _buildUserAvatar(userData)
                            : CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue,
                                child: Icon(Icons.person,
                                    color: Colors.white, size: 16),
                              ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData != null
                                  ? userData['fullName'] ?? 'User'
                                  : 'User',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            Text(
                              _formatDate(post.date),
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Is user's post indicator
                        if (post.userId == authService.currentUser?.uid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Your Post',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

            // Post image
            Stack(
              children: [
                // Post image
                if (post.imageUrl != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildImage(post.imageUrl!),
                  )
                else
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.photo,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                // Category overlay
                if (post.category.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        post.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            // Navigate to map view if coordinates are available
                            if (post.latitude != null &&
                                post.longitude != null) {
                              _navigateForward(MapViewScreen(post: post),
                                  onReturn: () => {}, allowBack: true);
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
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Text(
                  //   post.description,
                  //   style: TextStyle(
                  //     fontSize: 16,
                  //     color: textColor?.withOpacity(0.8),
                  //   ),
                  //   maxLines: 3,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build image from base64 or URL
  Widget _buildImage(String imageSource) {
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
      // Assume it's a network URL
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
    return Container(
      height: 180,
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

  // Format date for display
  String _formatDate(DateTime date) {
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

  // Simple navigation
  void _navigateForward(Widget destination,
      {VoidCallback? onReturn, bool allowBack = false}) {
    if (allowBack) {
      // Use regular push for screens that should have back button (like DetailScreen)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      ).then((_) {
        _loadUserData();
        if (onReturn != null) {
          onReturn();
        }
      });
    } else {
      // Use pushReplacement for screens that shouldn't have back button
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      ).then((_) {
        _loadUserData();
        if (onReturn != null) {
          onReturn();
        }
      });
    }
  }

  // Add this helper method for building user profile images
  ImageProvider? _buildUserProfileImage(String? photoURL) {
    if (photoURL == null || photoURL.isEmpty) {
      return null;
    }

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
      print('Error building user profile image: $e');
    }

    return null;
  }

  // Helper method to build user avatar with proper support for base64 images
  Widget _buildUserAvatar(Map<String, dynamic>? userData) {
    if (userData == null) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person, color: Colors.white, size: 16),
      );
    }

    final photoURL = userData['photoURL'];
    final userInitials = _getInitialsFromUserData(userData);

    if (photoURL != null && photoURL.toString().isNotEmpty) {
      try {
        // Handle data URL format base64
        if (photoURL.toString().startsWith('data:image/')) {
          final base64String = photoURL.toString().split(',').last;
          return CircleAvatar(
            radius: 16,
            backgroundImage: MemoryImage(base64Decode(base64String)),
            backgroundColor: Colors.blue,
            onBackgroundImageError: (error, stackTrace) {
              print('Error loading avatar image: $error');
            },
          );
        }
        // Handle network URLs
        else if (photoURL.toString().startsWith('http://') ||
            photoURL.toString().startsWith('https://')) {
          return CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(photoURL.toString()),
            backgroundColor: Colors.blue,
            onBackgroundImageError: (error, stackTrace) {
              print('Error loading network avatar: $error');
            },
          );
        }
        // Handle pure base64
        else if (_isBase64(photoURL.toString())) {
          return CircleAvatar(
            radius: 16,
            backgroundImage: MemoryImage(base64Decode(photoURL.toString())),
            backgroundColor: Colors.blue,
            onBackgroundImageError: (error, stackTrace) {
              print('Error loading base64 avatar: $error');
            },
          );
        }
      } catch (e) {
        print('Error creating avatar: $e');
      }
    }

    // Fallback to initials
    return CircleAvatar(
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
  }
}
