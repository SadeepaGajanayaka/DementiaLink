import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Initialize GoogleSignIn with scopes
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print("Attempting to create user with email: $email");
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("User created successfully with UID: ${userCredential.user?.uid}");
      
      // Update display name
      await userCredential.user!.updateDisplayName(name);
      
      // Add user details to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'photoUrl': userCredential.user!.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'authProvider': 'email',
      });
      
      print("User profile created in Firestore");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    }
  }

  // Login with email and password
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print("Attempting to sign in user with email: $email");
      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("User signed in successfully with UID: ${userCredential.user?.uid}");
      
      // Update last login timestamp
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    }
  }
  
  // Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      print("Attempting anonymous sign-in");
      UserCredential userCredential = await _auth.signInAnonymously();
      print("Anonymous sign-in successful: ${userCredential.user?.uid}");
      
      // Create a document for the anonymous user
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': 'Anonymous User',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'authProvider': 'anonymous',
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      print("Sending password reset email to: $email");
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent successfully");
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    }
  }
  
  // Confirm password reset with code and new password
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      print("Confirming password reset");
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      print("Password reset confirmed successfully");
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print("Signing out user: ${currentUser?.uid}");
      // Sign out from social providers
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _auth.signOut();
      print("User signed out successfully");
    } catch (e) {
      print("Error during sign out: $e");
      rethrow;
    }
  }

  // Google Sign In - This shows the account picker dialog
  Future<UserCredential> signInWithGoogle() async {
    try {
      print("Starting Google sign-in flow");
      // Trigger the authentication flow - This shows the account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // Check if sign in was canceled
      if (googleUser == null) {
        print("Google sign-in was cancelled by user");
        throw 'Google sign in was cancelled';
      }
      
      print("Google account selected: ${googleUser.email}");
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the credential
      print("Signing in to Firebase with Google credential");
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      print("Google sign-in successful: ${userCredential.user?.uid}");
      
      // Add or update user in Firestore
      await _handleSocialSignInFirestore(userCredential, 'google');
      
      return userCredential;
    } catch (e) {
      print('Error during Google sign in: $e');
      throw 'Google sign in failed: $e';
    }
  }

  // Handle storing user data after social sign in
  Future<void> _handleSocialSignInFirestore(UserCredential userCredential, String provider) async {
    try {
      // Check if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        print("Creating new user document for: ${userCredential.user?.uid}");
        // Create new user document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName ?? 'User',
          'email': userCredential.user!.email ?? '',
          'photoUrl': userCredential.user!.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'authProvider': provider,
        });
      } else {
        print("Updating existing user document for: ${userCredential.user?.uid}");
        // Update existing user's last login
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          // Update profile photo if available and changed
          if (userCredential.user!.photoURL != null) 'photoUrl': userCredential.user!.photoURL,
        });
      }
    } catch (e) {
      print("Error handling social sign-in Firestore update: $e");
      // Don't throw, just log the error
    }
  }
  
  // Get user data from Firestore
  Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      print("Fetching user data for UID: $uid");
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        print("User data found");
        return doc.data() as Map<String, dynamic>;
      } else {
        print("No user data found for UID: $uid");
        return {};
      }
    } catch (e) {
      print('Error getting user data: $e');
      return {};
    }
  }

  // Check if user exists and is authenticated
  Future<bool> ensureUserAuthenticated() async {
    User? user = _auth.currentUser;
    
    if (user != null) {
      print("User is already authenticated: ${user.uid}");
      return true;
    }
    
    try {
      print("No authenticated user found, attempting anonymous sign-in");
      UserCredential result = await signInAnonymously();
      return result.user != null;
    } catch (e) {
      print("Failed to authenticate user: $e");
      return false;
    }
  }

  // Handle Firebase Auth exceptions with user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'email-already-in-use':
        message = 'This email is already registered. Please login instead.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'user-disabled':
        message = 'This user account has been disabled.';
        break;
      case 'user-not-found':
        message = 'No user found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'weak-password':
        message = 'The password is too weak. Please use a stronger password.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed. Please make sure Email/Password sign-in is enabled in Firebase Console.';
        break;
      case 'account-exists-with-different-credential':
        message = 'An account already exists with the same email address but different sign-in credentials.';
        break;
      case 'invalid-credential':
        message = 'The authentication credential is invalid.';
        break;
      case 'requires-recent-login':
        message = 'This operation requires recent authentication. Please log in again.';
        break;
      default:
        message = e.message ?? 'An unknown error occurred.';
    }
    
    return message;
  }
}
