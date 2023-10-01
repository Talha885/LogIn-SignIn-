import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_page.dart';

class AuthService {
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn(scopes: ['email']).signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Navigate to the AuthPage after successful sign-in
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );

      return userCredential;
    } catch (e) {
      // Handle any errors that occur during the authentication process
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(
      User? user, String username, String bio) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(user.email)
          .update({
        'username': username,
        'bio': bio,
      });
    } catch (e) {
      print("Error updating user profile: $e");
    }
  }
}
