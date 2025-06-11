import 'package:flutter/material.dart';
import '../models/travel_post.dart';
import '../services/travel_post_service.dart';
import '../widgets/custom_bottom_navbar.dart';
import 'detail_screen.dart';
import 'map_view_screen.dart';
import 'dart:async';
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TravelPost> _allPosts = [];
  List<TravelPost> _filteredPosts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isFiltering = false;
  Timer? _debounce;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      final posts = await travelPostService.getRecentPosts();
      if (mounted) {
        setState(() {
          _allPosts = posts;
          _filteredPosts = List.from(posts);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading posts: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't load posts: $e")),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await travelPostService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  void _filterPosts() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _isFiltering = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.toLowerCase();

      if (mounted) {
        setState(() {
          _filteredPosts = _allPosts.where((post) {
            // Filter by search query
            final matchesQuery = query.isEmpty ||
                post.title.toLowerCase().contains(query) ||
                post.description.toLowerCase().contains(query) ||
                post.location.toLowerCase().contains(query);

            // Filter by category if selected
            final matchesCategory =
                _selectedCategory == null || post.category == _selectedCategory;

            return matchesQuery && matchesCategory;
          }).toList();
          _isFiltering = false;
        });
      }
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category == _selectedCategory ? null : category;
    });
    _filterPosts();
  }

  void _navigateForward(Widget destination) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    ).then((_) => _loadPosts()); // Refresh data when returning
  }

  // Simple back navigation
  void _navigateBack() {
    Navigator.pop(context);
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
        title: Text(
          'Search Posts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: iconColor),
                  hintText: 'Search by title, description or location...',
                  hintStyle: TextStyle(color: textColor?.withOpacity(0.6)),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: iconColor),
                          onPressed: () {
                            _searchController.clear();
                            _filterPosts();
                          },
                        )
                      : null,
                ),
                style: TextStyle(color: textColor),
                onChanged: (_) => _filterPosts(),
              ),
            ),
          ),

          // Category filters
          if (_categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Category:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // All Categories chip
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All Categories'),
                            selected: _selectedCategory == null,
                            onSelected: (_) => _selectCategory(null),
                            backgroundColor: containerColor,
                            selectedColor: Colors.green.withOpacity(0.2),
                            checkmarkColor: Colors.green,
                            labelStyle: TextStyle(
                              color: _selectedCategory == null
                                  ? Colors.green
                                  : textColor,
                              fontWeight: _selectedCategory == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        // Individual category chips
                        ..._categories.map((category) {
                          final isSelected = category == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) => _selectCategory(category),
                              backgroundColor: containerColor,
                              selectedColor: Colors.blue.withOpacity(0.2),
                              checkmarkColor: Colors.blue,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.blue : textColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Results header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Results (${_filteredPosts.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_filteredPosts.isNotEmpty)
                  Text(
                    _selectedCategory != null
                        ? 'Category: $_selectedCategory'
                        : 'All Categories',
                    style: TextStyle(
                      color:
                          _selectedCategory != null ? Colors.blue : Colors.grey,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isFiltering
                    ? const Center(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Filtering posts...'),
                        ],
                      ))
                    : _filteredPosts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: iconColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No posts found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try different search terms or filters',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: iconColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post = _filteredPosts[index];
                              return _buildPostCard(post);
                            },
                          ),
          ),
        ],
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

  Widget _buildPostCard(TravelPost post) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final containerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return GestureDetector(
      onTap: () {
        _navigateForward(DetailScreen(postId: post.id));
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
            // Post image
            Stack(
              children: [
                if (post.imageUrl != null)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: _buildImage(post.imageUrl!),
                  )
                else
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.photo,
                        size: 50,
                        color: iconColor,
                      ),
                    ),
                  ),

                // Category badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.blue.shade900.withOpacity(0.7)
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      post.category,
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.blue.shade100
                            : Colors.blue.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Like indicator
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
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
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                    style: TextStyle(
                      color: textColor?.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Location and date
                  Row(
                    children: [
                      // Location
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (post.latitude != null &&
                                post.longitude != null) {
                              _navigateForward(MapViewScreen(post: post));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('No location coordinates available'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
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
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: iconColor,
                          ),
                          const SizedBox(width: 4),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper to build image from base64 or URL
  Widget _buildImage(String imageSource) {
    try {
      // Check if it's a base64 image (data URL format)
      if (imageSource.startsWith('data:image/')) {
        final base64String = imageSource.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          height: 160,
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
          height: 160,
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
          height: 160,
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
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image: $error');
            return _buildErrorImage();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 160,
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

// Add these helper methods after the _buildImage method:

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
      height: 160,
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
}
