import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class FirebaseAuthService extends ChangeNotifier {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  /// Current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign up with email and password
  Future<String> signUpWithEmail(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return 'Email and password are required';
      }

      if (!_isValidEmail(email)) {
        return 'Please enter a valid email address';
      }

      if (password.length < 6) {
        return 'Password must be at least 6 characters long';
      }

      // Create user with Firebase Auth
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return 'Failed to create user account';
      }

      // Create UserModel
      final UserModel userModel = UserModel.fromFirebaseUser(
        firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );

      // Save user data to Firestore
      await _firestoreService.createUserInFirestore(userModel);

      // Send email verification
      if (!firebaseUser.emailVerified) {
        await firebaseUser.sendEmailVerification();
      }

      debugPrint('User signed up successfully: ${firebaseUser.uid}');
      notifyListeners();
      return 'Success';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception during sign up: ${e.code}');
      return _handleFirebaseAuthError(e);
    } catch (e) {
      debugPrint('General error during sign up: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign in with email and password
  Future<String> signInWithEmail(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return 'Email and password are required';
      }

      if (!_isValidEmail(email)) {
        return 'Please enter a valid email address';
      }

      // Sign in with Firebase Auth
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return 'Failed to sign in';
      }

      // Update last login timestamp in Firestore
      await _firestoreService.updateLastLoginAt(firebaseUser.uid);

      debugPrint('User signed in successfully: ${firebaseUser.uid}');
      notifyListeners();
      return 'Success';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception during sign in: ${e.code}');
      return _handleFirebaseAuthError(e);
    } catch (e) {
      debugPrint('General error during sign in: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign in with Google
  Future<String> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return 'Google sign-in was cancelled';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return 'Failed to obtain Google authentication tokens';
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return 'Failed to sign in with Google';
      }

      // Check if this is a new user
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      if (isNewUser) {
        // Create UserModel for new user
        final UserModel userModel = UserModel.fromFirebaseUser(
          firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
        );

        // Save user data to Firestore
        await _firestoreService.createUserInFirestore(userModel);
      } else {
        // Update last login timestamp for existing user
        await _firestoreService.updateLastLoginAt(firebaseUser.uid);
      }

      debugPrint('User signed in with Google successfully: ${firebaseUser.uid}');
      notifyListeners();
      return 'Success';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception during Google sign in: ${e.code}');
      return _handleFirebaseAuthError(e);
    } catch (e) {
      debugPrint('General error during Google sign in: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      debugPrint('User signed out successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Don't throw error for sign out - always allow it to proceed
    }
  }

  /// Send password reset email
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      if (email.isEmpty) {
        return 'Email is required';
      }

      if (!_isValidEmail(email)) {
        return 'Please enter a valid email address';
      }

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      
      debugPrint('Password reset email sent to: $email');
      return 'Success';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception during password reset: ${e.code}');
      return _handleFirebaseAuthError(e);
    } catch (e) {
      debugPrint('General error during password reset: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Delete user account
  Future<String> deleteUserAccount() async {
    try {
      final User? user = currentUser;
      if (user == null) {
        return 'No user is currently signed in';
      }

      final String uid = user.uid;

      // Delete user data from Firestore
      await _firestoreService.deleteUser(uid);

      // Delete user from Firebase Auth
      await user.delete();

      debugPrint('User account deleted successfully: $uid');
      notifyListeners();
      return 'Success';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception during account deletion: ${e.code}');
      return _handleFirebaseAuthError(e);
    } catch (e) {
      debugPrint('General error during account deletion: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Update user profile
  Future<String> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final User? user = currentUser;
      if (user == null) {
        return 'No user is currently signed in';
      }

      // Update Firebase Auth profile
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);

      // Update Firestore document
      if (displayName != null) {
        await _firestoreService.updateDisplayName(user.uid, displayName);
      }
      if (photoURL != null) {
        await _firestoreService.updatePhotoUrl(user.uid, photoURL);
      }

      debugPrint('User profile updated successfully');
      notifyListeners();
      return 'Success';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception during profile update: ${e.code}');
      return _handleFirebaseAuthError(e);
    } catch (e) {
      debugPrint('General error during profile update: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Update Firebase Auth profile (simpler method for profile screen)
  Future<void> updateAuthProfile(String displayName, String? photoUrl) async {
    try {
      final User? user = currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Update Firebase Auth profile
      await user.updateDisplayName(displayName);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update auth profile: $e');
    }
  }

  /// Reload current user
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
      notifyListeners();
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }
  }

  /// Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Send email verification
  Future<String> sendEmailVerification() async {
    try {
      final User? user = currentUser;
      if (user == null) {
        return 'No user is currently signed in';
      }

      if (user.emailVerified) {
        return 'Email is already verified';
      }

      await user.sendEmailVerification();
      debugPrint('Email verification sent');
      return 'Success';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception during email verification: ${e.code}');
      return _handleFirebaseAuthError(e);
    } catch (e) {
      debugPrint('General error during email verification: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Handle Firebase Auth errors and return user-friendly messages
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      default:
        return 'An error occurred: ${e.message ?? 'Please try again.'}';
    }
  }
}