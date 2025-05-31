import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/travel_post.dart';
import 'storage_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

class TravelPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _postsCollection => _firestore.collection('posts');

  // Get all posts for current user
  Stream<List<TravelPost>> getAllPosts() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ensure data has a likeCount field
        if (!data.containsKey('likeCount')) {
          data['likeCount'] = 0;
        }
        return TravelPost.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Add a new post
  Future<void> addPost(TravelPost post) async {
    try {
      // Get current user's ID and add it to the post
      final userId = authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Create a map with the current user's ID
      final postWithUserId = {...post.toMap(), 'userId': userId};
      
      // Add post to Firestore
      await _firestore.collection('posts').doc(post.id).set(postWithUserId);
    } catch (e) {
      print('Error adding post: $e');
      rethrow;
    }
  }

  // Get posts by category
  Stream<List<TravelPost>> getPostsByCategory(String category) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ensure data has a likeCount field
        if (!data.containsKey('likeCount')) {
          data['likeCount'] = 0;
        }
        return TravelPost.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Get posts for a specific date
  Stream<List<TravelPost>> getPostsByDate(DateTime date) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    
    // Convert date to timestamp range for the entire day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: endOfDay.millisecondsSinceEpoch)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ensure data has a likeCount field
        if (!data.containsKey('likeCount')) {
          data['likeCount'] = 0;
        }
        return TravelPost.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    // Get current favorite status
    final docSnapshot = await _postsCollection.doc(postId).get();
    if (!docSnapshot.exists) {
      throw Exception('Post not found');
    }
    
    final postData = docSnapshot.data() as Map<String, dynamic>;
    final currentFavorite = postData['isFavorite'] ?? false;
    
    // Update favorite status
    await _postsCollection.doc(postId).update({
      'isFavorite': !currentFavorite,
    });
  }

  // Get favorite posts
  Stream<List<TravelPost>> getFavoritePosts() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    
    // Return a stream that combines posts from two queries
    return _firestore.collection('posts').snapshots().map((snapshot) {
      final posts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        if (!data.containsKey('likeCount')) {
          data['likeCount'] = 0;
        }
        return TravelPost.fromMap(data, doc.id);
      }).toList();
      
      // Filter to keep only posts that:
      // 1. Are marked as favorite AND belong to the current user, OR
      // 2. Have the current user in their likedBy array
      return posts.where((post) {
        // Check if post is liked by current user
        final likedByCurrentUser = post.likedBy.contains(userId);
        
        // Check if post is owned by current user and marked as favorite
        final isOwnedAndFavorite = post.userId == userId && post.isFavorite;
        
        // Include post if either condition is true
        return likedByCurrentUser || isOwnedAndFavorite;
      }).toList();
    });
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      // Delete the post document from Firestore
      await _firestore.collection('posts').doc(postId).delete();
      
      // Optionally delete the post image from Storage
      try {
        final userId = authService.currentUser?.uid;
        if (userId != null) {
          await _storage.ref().child('post_images/$userId/$postId.jpg').delete();
        }
      } catch (e) {
        // Ignore errors when deleting image - it might not exist
        print('Note: Failed to delete image: $e');
      }
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  // Update a post
  Future<void> updatePost(TravelPost updatedPost) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    // Ensure the post belongs to the current user
    final docSnapshot = await _postsCollection.doc(updatedPost.id).get();
    if (!docSnapshot.exists) {
      throw Exception('Post not found');
    }
    
    final postData = docSnapshot.data() as Map<String, dynamic>;
    if (postData['userId'] != userId) {
      throw Exception('You do not have permission to update this post');
    }
    
    // Update post in Firestore
    await _postsCollection.doc(updatedPost.id).update(updatedPost.toMap());
  }

  // Upload image, compress it, and convert to base64 string
  Future<String?> uploadImage(File imageFile, String postId) async {
    try {
      final userId = authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Compress image first
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath = p.join(dir.path, "${DateTime.now().millisecondsSinceEpoch}.jpg");
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: 70, // Adjust quality as needed (lower = smaller file)
        minWidth: 1024, // Adjust dimensions as needed
        minHeight: 1024,
      );
      
      if (compressedFile == null) {
        throw Exception('Failed to compress image');
      }
      
      // Read compressed file as bytes
      final bytes = await compressedFile.readAsBytes();
      
      // Convert to base64
      final base64Image = base64Encode(bytes);
      
      // Cleanup - XFile doesn't have delete method, so we delete the File
      final tempFile = File(compressedFile.path);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return base64Image;
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }

  // Get all unique categories from all posts
  Future<List<String>> getAllCategories() async {
    try {
      final snapshot = await _postsCollection.get();
      
      final posts = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ensure data has a likeCount field
        if (!data.containsKey('likeCount')) {
          data['likeCount'] = 0;
        }
        return TravelPost.fromMap(data, doc.id);
      }).toList();
      
      // Extract unique categories and sort them alphabetically
      final categories = posts.map((post) => post.category).where((category) => category.isNotEmpty).toSet().toList();
      categories.sort(); // Sort alphabetically
      return categories;
    } catch (e) {
      print('Error getting all categories: $e');
      return [];
    }
  }

  // Get recent posts
  Future<List<TravelPost>> getRecentPosts() async {
    try {
      // Get current user's ID for reference, but don't filter by it
      final userId = authService.currentUser?.uid;
      
      // Query posts from Firestore, ordered by date (most recent first)
      final snapshot = await _firestore
          .collection('posts')
          // Removed the filter for current user to show all posts
          .orderBy('date', descending: true)
          .limit(20) // Increased limit to show more posts
          .get();
      
      // Convert Firestore documents to TravelPost objects
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        // Ensure data has a likeCount field
        if (!data.containsKey('likeCount')) {
          data['likeCount'] = 0;
        }
        return TravelPost.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting recent posts: $e');
      rethrow;
    }
  }

  // Get user's posts
  Future<List<TravelPost>> getUserPosts() async {
    try {
      // Get current user's ID
      final userId = authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Query posts from Firestore, ordered by date (most recent first)
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId) // Only get the current user's posts
          .orderBy('date', descending: true)
          .get();
      
      // Convert Firestore documents to TravelPost objects
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        // Ensure data has a likeCount field
        if (!data.containsKey('likeCount')) {
          data['likeCount'] = 0;
        }
        return TravelPost.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting user posts: $e');
      rethrow;
    }
  }

  // Get a post by ID
  Future<TravelPost?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data()!;
        // Ensure data has a likeCount field
        if (!data.containsKey('likeCount')) {
          data['likeCount'] = 0;
        }
        return TravelPost.fromMap(data, doc.id);
      }
      
      return null; // Post not found
    } catch (e) {
      print('Error getting post: $e');
      rethrow;
    }
  }

  // Like a post - add user to likedBy array and update like count
  Future<void> likePost(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      // Get the document reference
      final docRef = _postsCollection.doc(postId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Post not found');
      }
      
      final postData = doc.data() as Map<String, dynamic>;
      
      List<String> likedBy = [];
      if (postData.containsKey('likedBy')) {
        likedBy = List<String>.from(postData['likedBy']);
      }
      
      
      if (!likedBy.contains(userId)) {
        // Add current user to likedBy array
        likedBy.add(userId);
        
        // Update the post with new likedBy array and updated like count
        await docRef.update({
          'likedBy': likedBy,
          'likeCount': likedBy.length,
          'isFavorite': true 
        });
      }
    } catch (e) {
      print('Error liking post: $e');
      rethrow;
    }
  }
  
  // remove user from likedBy array and update like count
  Future<void> unlikePost(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    try {
      // Get the document reference
      final docRef = _postsCollection.doc(postId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Post not found');
      }
      
      final postData = doc.data() as Map<String, dynamic>;
      
      // Check if likedBy array exists
      if (postData.containsKey('likedBy')) {
        List<String> likedBy = List<String>.from(postData['likedBy']);
        
        // Remove current user from likedBy array if present
        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          
          // Update the post with new likedBy array and updated like count
          await docRef.update({
            'likedBy': likedBy,
            'likeCount': likedBy.length,
            'isFavorite': false 
          });
        }
      }
    } catch (e) {
      print('Error unliking post: $e');
      rethrow;
    }
  }
  
  // Check if current user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;
    
    try {
      // Get the post document
      final doc = await _postsCollection.doc(postId).get();
      
      if (!doc.exists) {
        return false;
      }
      
      final postData = doc.data() as Map<String, dynamic>;
      
      // Check if likedBy array exists and contains current user
      if (postData.containsKey('likedBy')) {
        List<String> likedBy = List<String>.from(postData['likedBy']);
        return likedBy.contains(userId);
      }
      
      return false;
    } catch (e) {
      print('Error checking if user liked post: $e');
      return false;
    }
  }
}

// Singleton instance for easy access throughout the app
final travelPostService = TravelPostService(); 