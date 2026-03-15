import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String kAdminEmail = 'dioneayou@gmail.com';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (email.toLowerCase() == kAdminEmail.toLowerCase()) {
        await _ensureAdminDocument(email);
      }
      return {'success': true, 'message': 'Connexion réussie'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _authErrorMessage(e.code)};
    } catch (_) {
      return {'success': false, 'message': 'Erreur de connexion inattendue'};
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String nomComplet,
    String telephone,
  ) async {
    try {
      final bool isAdmin = email.toLowerCase() == kAdminEmail.toLowerCase();
      final UserCredential cred =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'nomComplet': nomComplet,
        'email': email,
        'telephone': telephone,
        'isAdmin': isAdmin,
        'dateCreation': FieldValue.serverTimestamp(),
      });
      await _firebaseAuth.signOut();
      return {'success': true, 'message': 'Compte créé avec succès'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _authErrorMessage(e.code)};
    } catch (_) {
      return {'success': false, 'message': "Erreur inattendue lors de l'inscription"};
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
  }

  Future<void> _ensureAdminDocument(String email) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(uid).set({
        'nomComplet': 'Administrateur',
        'email': email,
        'telephone': '',
        'isAdmin': true,
        'dateCreation': FieldValue.serverTimestamp(),
      });
    } else if (doc.data()?['isAdmin'] != true) {
      await _firestore.collection('users').doc(uid).update({'isAdmin': true});
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte associé à cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect';
      case 'email-already-in-use':
        return 'Ce compte est déjà inscrit';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      default:
        return 'Une erreur est survenue. Veuillez réessayer';
    }
  }
}
