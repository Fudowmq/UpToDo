import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // Добавлено для debugPrint

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('GoogleSignIn: start');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('GoogleSignIn: googleUser = \\${googleUser?.email}');
      if (googleUser == null) {
        debugPrint('GoogleSignIn: user cancelled');
        throw Exception('Google sign-in cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('GoogleSignIn: accessToken = \\${googleAuth.accessToken}');
      debugPrint('GoogleSignIn: idToken = \\${googleAuth.idToken}');
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google auth tokens are null');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('GoogleSignIn: credential created');

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('GoogleSignIn: userCredential = \\${userCredential.user?.uid}');
      return userCredential;
    } catch (e, stack) {
      debugPrint('GoogleSignIn ERROR: \\${e.toString()}');
      debugPrint('Stack: \\${stack.toString()}');
      rethrow;
    }
  }

  // Выход
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
