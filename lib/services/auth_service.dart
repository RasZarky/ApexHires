import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:apex_hires/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user model from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;
    final doc =
        await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // Email & Password Sign Up
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) return null;

      await user.updateDisplayName(fullName);

      final userModel = UserModel(
        uid: user.uid,
        email: email,
        role: role,
        fullName: fullName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());

      // Set custom claims via admin SDK (handled by cloud function in production)
      // For now we store role in Firestore
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Email & Password Sign In
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) return null;

      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      rethrow;
    }
  }

  // Google Sign In
  Future<UserModel?> signInWithGoogle({required String role}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return null;

      // Check if user already exists
      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }

      // New user — only create if a role was provided (signup flow)
      if (role.isEmpty) {
        // No role = login flow, but user doesn't exist yet
        await _googleSignIn.signOut();
        await _auth.signOut();
        throw Exception('No account found. Please sign up first.');
      }

      // Create new user with the selected role
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        role: role,
        fullName: user.displayName ?? '',
        avatarUrl: user.photoURL ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel userModel) async {
    await _firestore
        .collection('users')
        .doc(userModel.uid)
        .update(userModel.toMap());
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
