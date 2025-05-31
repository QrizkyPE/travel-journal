import 'package:flutter/foundation.dart';

/// Utility class for handling errors in the app
class ErrorHandler {
  
  /// Logs errors with more readable format for debugging
  static void logError(String source, dynamic error, [StackTrace? stackTrace]) {
    String errorMessage = 'ERROR in $source: ${error.toString()}';
    
    if (kDebugMode) {
      print('==========================================');
      print(errorMessage);
      if (stackTrace != null) {
        print('STACK TRACE:');
        print(stackTrace.toString());
      }
      print('==========================================');
    }
  }
  
  /// Formats Firebase error messages to be more user-friendly
  static String getReadableFirebaseError(dynamic error) {
    String errorMessage = error.toString();
    
    // Extract the error message from the Firebase error string
    if (errorMessage.contains(']')) {
      errorMessage = errorMessage.split(']').last.trim();
    }
    
    // Handle common Firebase error messages
    if (errorMessage.contains('network-request-failed')) {
      return 'No internet connection. Please check your connection and try again.';
    } else if (errorMessage.contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    } else if (errorMessage.contains('user-not-found')) {
      return 'No user found with this email.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    
    // Fallback to a generic message for debugging
    return 'Error: $errorMessage';
  }
} 