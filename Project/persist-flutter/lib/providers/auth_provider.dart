import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  UserProfile? _profile;
  bool _loading = true;

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _fetchProfile(user.uid);
    } else {
      _profile = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _fetchProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _profile = UserProfile.fromFirestore(doc);
      }
    } catch (_) {}
  }

  Future<void> signUp(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final profile = UserProfile(
      id: uid,
      name: name,
      email: email,
      displayName: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.collection('users').doc(uid).set(profile.toFirestore());
    _profile = profile;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> refreshProfile() async {
    if (_user != null) await _fetchProfile(_user!.uid);
    notifyListeners();
  }
}
