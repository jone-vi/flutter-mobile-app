import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() async {
    return await _auth.signOut();
  }

  Future<void> forgotPassword(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  Future<void> sendVerifyEmail() async {
    User? user = _auth.currentUser;

    if (user == null || user.emailVerified) {
      return;
    }
    DocumentSnapshot doc = await _firestore.getData('users', user.uid);

    Timestamp? lastEmailSent = doc.get('lastEmailSent');
    Timestamp now = Timestamp.now();

    if (lastEmailSent != null && now.seconds - lastEmailSent.seconds < 60) {
      return;
    }

    await _firestore.updateLastEmailSent();

    return await user.sendEmailVerification();
  }
}
