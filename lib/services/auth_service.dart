import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class AuthService {
  // Use the global firebaseAuth instance from main.dart
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // If user creation successful, store additional user info in Firestore
      if (userCredential.user != null) {
        try {
          // Update display name in Firebase Auth
          try {
            await userCredential.user!.updateDisplayName(fullName);
          } catch (e) {
            // Catch the PigeonUserInfo/PigeonUserDetails error
            if (e.toString().contains('PigeonUserInfo') || 
                e.toString().contains('PigeonUserDetails')) {
              print('Firebase Auth display name update failed with type cast error: $e');
              // Continue with Firestore update even if Auth update fails
            } else {
              print('Error updating user display name: $e');
            }
          }
          
          // Store user data in Firestore
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'fullName': fullName,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'photoURL': null,
          });
        } catch (e) {
          print('Error updating user profile: $e');
          // Continue even if there's an error with profile update
          // The account is still created successfully
        }
        
        // Return the user object
        return userCredential.user;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Check if it's the PigeonUserDetails error
      if (e.toString().contains('PigeonUserInfo') || 
          e.toString().contains('PigeonUserDetails')) {
        print('Firebase Auth sign-up succeeded but encountered type cast error: $e');
        
        // Wait a moment and check if the user was created
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check for current user - if we have one, the registration was successful
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          // Manually create Firestore record if needed
          try {
            final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
            if (!userDoc.exists) {
              await _firestore.collection('users').doc(currentUser.uid).set({
                'fullName': fullName,
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
                'photoURL': null,
              });
            }
            
            // Return the current user
            return currentUser;
          } catch (firestoreError) {
            print('Error creating Firestore record: $firestoreError');
          }
        }
        // Return an error-specific message
        throw 'Account was created but profile setup failed. You can still sign in with your credentials.';
      }
      
      print('Unexpected error during sign up: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with email and password - updated with workaround for PigeonUserDetails error
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Use the try-catch approach to handle the PigeonUserDetails error
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        return userCredential.user;
      } catch (e) {
        if (e.toString().contains('PigeonUserDetails')) {
          // If we get the specific type cast error, try to retrieve the current user directly
          // This is a workaround for the Firebase Auth bug
          
          // Wait a moment for Firebase Auth to complete the sign-in
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if we have a signed-in user
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            print('Successfully signed in using workaround: ${currentUser.uid}');
            return currentUser;
          } else {
            print('Workaround failed - no current user after sign-in attempt');
            throw 'Could not complete sign in. Please try again.';
          }
        } else {
          // Rethrow if it's not the specific error we're handling
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during sign in: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? location,
    String? phoneNumber,
  }) async {
    try {
      if (_auth.currentUser != null) {
        // Try to update the Firebase Auth user profile with error handling
        try {
          if (displayName != null) {
            await _auth.currentUser!.updateDisplayName(displayName);
          }
          
          if (photoURL != null) {
            await _auth.currentUser!.updatePhotoURL(photoURL);
          }
        } catch (e) {
          // Check if it's the PigeonUserInfo error
          if (e.toString().contains('PigeonUserInfo') || 
              e.toString().contains('PigeonUserDetails')) {
            print('Firebase Auth profile update failed with type cast error: $e');
            // Continue with Firestore update even if Auth update fails
          } else {
            rethrow;
          }
        }
        
        // Check if user document exists in Firestore
        final userDocRef = _firestore.collection('users').doc(_auth.currentUser!.uid);
        final userDoc = await userDocRef.get();
        
        if (userDoc.exists) {
          // Update existing document
          await userDocRef.update({
            if (displayName != null) 'fullName': displayName,
            if (photoURL != null) 'photoURL': photoURL,
            if (location != null) 'location': location,
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
          });
        } else {
          // Create new document if it doesn't exist
          await userDocRef.set({
            'fullName': displayName ?? _auth.currentUser!.displayName ?? 'User',
            'email': _auth.currentUser!.email ?? '',
            'photoURL': photoURL ?? _auth.currentUser!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            if (location != null) 'location': location,
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_auth.currentUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Get user data for a specific userId from Firestore
  Future<Map<String, dynamic>?> getUserDataById(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Handle Firebase Auth exceptions with user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'user-disabled':
        return 'This user has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

// Create a singleton instance for easy access
final authService = AuthService(); 