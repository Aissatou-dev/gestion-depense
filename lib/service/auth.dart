import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {'success': true, 'message': 'Connexion réussie'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return {'success': false, 'message': 'Cet email n\'existe pas'};
      } else if (e.code == 'wrong-password') {
        return {'success': false, 'message': 'Mot de passe incorrect'};
      }
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String nomComplet,
    String telephone,
  ) async {
    try {
      // Créer le compte directement - Firebase va lever une exception si l'email existe déjà
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Stocker les infos supplémentaires dans Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'nomComplet': nomComplet,
        'email': email,
        'telephone': telephone,
        'dateCreation': DateTime.now(),
      });

      // sign out user so they must login manually (Firebase auto-signs in on create)
      await _firebaseAuth.signOut();

      return {'success': true, 'message': 'Compte créé avec succès'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return {'success': false, 'message': 'Ce compte est déjà inscrit'};
      } else if (e.code == 'weak-password') {
        return {'success': false, 'message': 'Mot de passe trop faible'};
      } else if (e.code == 'invalid-email') {
        return {'success': false, 'message': 'Email invalide'};
      }
      return {'success': false, 'message': 'Erreur lors de l\'inscription: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur inattendue lors de l\'inscription'};
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      // Erreur de déconnexion
    }
  }
}
