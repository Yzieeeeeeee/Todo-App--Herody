import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Stream → listens to login/logout changes automatically ──
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Get current logged in user ───────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── Get current user's UID ───────────────────────────────────
  String? get currentUserId => _auth.currentUser?.uid;

  // ── Get current user's email ─────────────────────────────────
  String? get currentUserEmail => _auth.currentUser?.email;

  // ── Get current user's display name ──────────────────────────
  String? get currentUserName => _auth.currentUser?.displayName;

  // ─────────────────────────────────────────────────────────────
  // 1. SIGN UP with Email & Password
  // ─────────────────────────────────────────────────────────────
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create the account
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Set the display name on the Firebase user profile
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. LOGIN with Email & Password
  // ─────────────────────────────────────────────────────────────
  Future<UserCredential?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. GOOGLE SIGN IN
  // ─────────────────────────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Opens the Google account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the picker
      if (googleUser == null) return null;

      // Get auth tokens from Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential from Google tokens
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('DEBUG: Google Sign-In Error: $e');
      if (e.toString().contains('sign_in_failed')) {
        throw 'Google Sign-In failed (code 10). Please ensure SHA-1 is added to Firebase Console.';
      }
      throw 'Google Sign-In failed. Error: $e';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4. FORGOT PASSWORD
  // ─────────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 5. LOGOUT
  // ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      // Sign out from Google too if they used Google Sign-In
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw 'Sign out failed. Please try again.';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 6. ERROR HANDLER → converts Firebase codes to readable messages
  // ─────────────────────────────────────────────────────────────
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
