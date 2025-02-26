import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// For social logins - uncomment when needed
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'dart:convert';
// import 'dart:math';
// import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For social login - uncomment when needed
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
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
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
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
    // Sign out from social providers if needed
    // await _googleSignIn.signOut();

    // Sign out from Firebase
    await _auth.signOut();
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    if (currentUser == null) throw 'No user logged in';

    try {
      Map<String, dynamic> dataToUpdate = {};

      if (name != null && name.isNotEmpty) {
        // Update display name in Firebase Auth
        await currentUser!.updateDisplayName(name);
        dataToUpdate['name'] = name;
      }

      if (photoUrl != null && photoUrl.isNotEmpty) {
        // Update photo URL in Firebase Auth
        await currentUser!.updatePhotoURL(photoUrl);
        dataToUpdate['photoUrl'] = photoUrl;
      }

      // Add any additional data
      if (additionalData != null) {
        dataToUpdate.addAll(additionalData);
      }

      // Update data in Firestore if we have something to update
      if (dataToUpdate.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(dataToUpdate);
      }
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  // Change password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    if (currentUser == null || currentUser!.email == null) {
      throw 'No user logged in or email is missing';
    }

    try {
      // Re-authenticate the user to confirm current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );

      await currentUser!.reauthenticateWithCredential(credential);

      // Change the password
      await currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete account
  Future<void> deleteAccount(String password) async {
    if (currentUser == null || currentUser!.email == null) {
      throw 'No user logged in or email is missing';
    }

    try {
      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );

      await currentUser!.reauthenticateWithCredential(credential);

      // Delete Firestore user data
      await _firestore.collection('users').doc(currentUser!.uid).delete();

      // Delete the user account
      await currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google Sign In - Uncomment when needed
  /*
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
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
      throw 'Google sign in failed: $e';
    }
  }
  */

  // Facebook Sign In - Uncomment when needed
  /*
  Future<UserCredential> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login();
      
      if (result.status != LoginStatus.success) {
        throw 'Facebook login failed or was cancelled';
      }
      
      // Create a credential from the access token
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );
      
      // Sign in to Firebase with the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Add or update user in Firestore
      await _handleSocialSignInFirestore(userCredential, 'facebook');
      
      return userCredential;
    } catch (e) {
      throw 'Facebook sign in failed: $e';
    }
  }
  */

  // Apple Sign In - Uncomment when needed
  /*
  Future<UserCredential> signInWithApple() async {
    try {
      // Generate a random nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      
      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      
      // Create an OAuthCredential from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      
      // Sign in to Firebase with the Apple credential
      UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      
      // If this is the first sign in and we have full name information
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        String? displayName;
        if (appleCredential.givenName != null && appleCredential.familyName != null) {
          displayName = "${appleCredential.givenName} ${appleCredential.familyName}";
          
          // Update display name in Firebase Auth
          await userCredential.user?.updateDisplayName(displayName);
        }
      }
      
      // Add or update user in Firestore
      await _handleSocialSignInFirestore(userCredential, 'apple');
      
      return userCredential;
    } catch (e) {
      throw 'Apple sign in failed: $e';
    }
  }
  
  // Generate a random nonce for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }
  
  // Return the SHA-256 hash of the input string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  */

  // Handle storing user data after social sign in
  Future<void> _handleSocialSignInFirestore(
      UserCredential userCredential, String provider) async {
    // Check if it's a new user
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      // Create new user document
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': userCredential.user!.displayName,
        'email': userCredential.user!.email,
        'photoUrl': userCredential.user!.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'authProvider': provider,
      });
    } else {
      // Update existing user's last login
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

