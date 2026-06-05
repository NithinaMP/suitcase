import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — Auth Provider
//  Handles both Mobile (Android/iOS) and Web (Chrome/Firebase)
//  Google Sign-In uses different flow per platform:
//    Mobile → google_sign_in package (.signIn())
//    Web    → Firebase signInWithPopup (browser popup)
// ══════════════════════════════════════════════════════════════

enum AuthState { unknown, authenticated, unauthenticated }

class SuitcaseAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Only instantiate GoogleSignIn on non-web platforms
  // On web, Firebase handles Google auth directly via popup
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  AuthState _state = AuthState.unknown;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  String? _userStyleVibe;

  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String? get userStyleVibe => _userStyleVibe;
  bool get isLoggedIn => _state == AuthState.authenticated;

  SuitcaseAuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      _state = AuthState.authenticated;
      await _loadUserProfile();
    } else {
      _state = AuthState.unauthenticated;
      _userStyleVibe = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;
    try {
      final doc = await _db
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (doc.exists) {
        _userStyleVibe = doc.data()?['style_vibe'] as String?;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Email Sign Up ─────────────────────────────────────────
  Future<bool> signUpWithEmail(
      String email, String password, String styleVibe) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email.trim(),
        'style_vibe': styleVibe,
        'created_at': FieldValue.serverTimestamp(),
      });
      _userStyleVibe = styleVibe;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Email Sign In ─────────────────────────────────────────
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Google Sign In ─────────────────────────────────────────
  // Automatically uses the correct flow per platform:
  //   Web    → signInWithPopup (Firebase handles everything)
  //   Mobile → google_sign_in package then Firebase credential
  Future<bool> signInWithGoogle(String styleVibe) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      UserCredential cred;

      if (kIsWeb) {
        // ── Web flow ──────────────────────────────────────
        // Firebase opens a Google popup in the browser directly
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        cred = await _auth.signInWithPopup(provider);
      } else {
        // ── Mobile flow ───────────────────────────────────
        final googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          // User cancelled the sign-in
          _setLoading(false);
          return false;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }

      // ── Save profile if new user ──────────────────────
      final docRef = _db.collection('users').doc(cred.user!.uid);
      final existing = await docRef.get();
      if (!existing.exists) {
        await docRef.set({
          'email': cred.user!.email,
          'display_name': cred.user!.displayName,
          'style_vibe': styleVibe,
          'created_at': FieldValue.serverTimestamp(),
        });
        _userStyleVibe = styleVibe;
      } else {
        _userStyleVibe = existing.data()?['style_vibe'] as String?;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      return false;
    } catch (_) {
      _errorMessage = 'Google sign-in failed. Try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update Style Vibe ─────────────────────────────────────
  Future<void> updateStyleVibe(String vibe) async {
    if (_user == null) return;
    await _db
        .collection('users')
        .doc(_user!.uid)
        .update({'style_vibe': vibe});
    _userStyleVibe = vibe;
    notifyListeners();
  }

  // ── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    // Only call googleSignIn.signOut() on mobile
    if (!kIsWeb) await _googleSignIn?.signOut();
  }

  // ── Helpers ───────────────────────────────────────────────
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'popup-closed-by-user':
        return 'Sign-in cancelled.';
      case 'popup-blocked':
        return 'Popup was blocked. Allow popups for this site.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}