import 'package:cloud_firestore/cloud_firestore.dart';

class TravelPost {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String? imageUrl;
  final DateTime date;
  final bool isFavorite;
  final String userId;
  final double? latitude;
  final double? longitude;
  final int likeCount;
  final List<String> likedBy;

  TravelPost({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.imageUrl,
    required this.date,
    this.isFavorite = false,
    required this.userId,
    this.latitude,
    this.longitude,
    this.likeCount = 0,
    this.likedBy = const [],
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'imageUrl': imageUrl,
      'date': date.millisecondsSinceEpoch,
      'isFavorite': isFavorite,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'likeCount': likeCount,
      'likedBy': likedBy,
    };
  }

  // Create from Map (Firestore document)
  factory TravelPost.fromMap(Map<String, dynamic> map, String id) {
    // Handle null likeCount more safely
    int getLikeCount() {
      final likes = map['likeCount'];
      if (likes == null) return 0;
      if (likes is int) return likes;
      if (likes is num) return likes.toInt();
      return 0; // Default fallback
    }
    
    // Parse likedBy array safely
    List<String> getLikedBy() {
      if (map['likedBy'] == null) return [];
      if (map['likedBy'] is List) {
        return List<String>.from(map['likedBy']);
      }
      return [];
    }
    
    return TravelPost(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'],
      date: map['date'] is Timestamp 
          ? (map['date'] as Timestamp).toDate()
          : map['date'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(map['date'])
              : (map['date'] as DateTime),
      isFavorite: map['isFavorite'] ?? false,
      userId: map['userId'] ?? '',
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      likeCount: getLikeCount(),
      likedBy: getLikedBy(),
    );
  }

  // Create a copy of the post with updated fields
  TravelPost copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? imageUrl,
    DateTime? date,
    bool? isFavorite,
    String? userId,
    double? latitude,
    double? longitude,
    int? likeCount,
    List<String>? likedBy,
  }) {
    return TravelPost(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }
} 