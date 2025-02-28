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
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
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
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Login with email and password
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login timestamp
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Confirm password reset with code and new password
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Sign out from social providers
    await _googleSignIn.signOut();
    
    // Sign out from Firebase
    await _auth.signOut();
  }

  // Google Sign In - This shows the account picker dialog
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow - This shows the account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // Check if sign in was canceled
      if (googleUser == null) {
        throw 'Google sign in was cancelled';
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
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
    // Check if it's a new user
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
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
      // Update existing user's last login
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
        // Update profile photo if available and changed
        if (userCredential.user!.photoURL != null) 'photoUrl': userCredential.user!.photoURL,
      });
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
    
    return message;
  }
}