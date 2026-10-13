import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'normalisation.dart';

/// Erreur d'inscription ou de connexion, avec un message déjà en français
/// que l'on peut afficher tel quel à l'utilisateur.
class ErreurAuth implements Exception {
  const ErreurAuth(this.message, {this.champs = const {}});

  final String message;

  /// Les champs à faire vibrer : 'email' et/ou 'motDePasse'.
  final Set<String> champs;

  @override
  String toString() => message;
}

/// Les informations d'un utilisateur, telles qu'enregistrées dans Firestore.
class ProfilUtilisateur {
  const ProfilUtilisateur({
    required this.nom,
    this.telephone = '',
    this.email = '',
    this.photo,
    this.photoUrl,
  });

  final String nom;
  final String telephone;
  final String email;

  /// Photo choisie par l'utilisateur dans l'appli (prioritaire).
  final Uint8List? photo;

  /// Photo du compte Google, utilisée tant qu'il n'a pas choisi la sienne.
  final String? photoUrl;
}

/// Ce que l'appli sait faire côté compte utilisateur. Les écrans utilisent
/// cette classe, jamais Firebase directement (ce qui permet de la remplacer
/// dans les tests).
abstract class ServiceAuth {
  /// Vrai si quelqu'un est déjà connecté (la session est gardée par Firebase).
  bool get estConnecte;

  /// Crée un compte avec un e-mail et un mot de passe, puis enregistre le
  /// profil (nom, téléphone, e-mail) dans Firestore.
  Future<void> inscrire({
    required String nom,
    required String telephone,
    required String email,
    required String motDePasse,
  });

  Future<void> connecter({required String email, required String motDePasse});

  Future<void> deconnecter();

  /// Connexion (ou inscription au premier passage) avec un compte Google.
  /// Renvoie false si l'utilisateur a fermé la fenêtre Google sans choisir.
  Future<bool> connecterAvecGoogle();

  /// Le profil de la personne connectée, ou null s'il n'y en a pas.
  Future<ProfilUtilisateur?> chargerProfil();

  /// Fait en sorte que la personne connectée puisse être retrouvée par son
  /// numéro de téléphone ou son e-mail (pour les comptes créés avant que la
  /// recherche de contacts existe). Ne fait rien si c'est déjà le cas.
  Future<void> assurerRecherchable();

  /// Enregistre la nouvelle photo de profil de la personne connectée.
  Future<void> changerPhoto(Uint8List octets);
}

/// Version réelle, basée sur Firebase Authentication et Firestore.
class ServiceAuthFirebase implements ServiceAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _base = FirebaseFirestore.instance;

  @override
  bool get estConnecte => _auth.currentUser != null;

  @override
  Future<void> inscrire({
    required String nom,
    required String telephone,
    required String email,
    required String motDePasse,
  }) async {
    final UserCredential compte;
    try {
      compte = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: motDePasse,
      );
    } on FirebaseAuthException catch (e) {
      throw _erreur(e.code);
    }

    final utilisateur = compte.user;
    if (utilisateur == null) return;
    await utilisateur.updateDisplayName(nom.trim());

    // Le compte existe déjà à ce stade. Si l'écriture du profil échoue (réseau
    // coupé par exemple), on laisse l'utilisateur entrer : chargerProfil()
    // retombe alors sur le nom et l'e-mail du compte.
    try {
      await _base.collection('utilisateurs').doc(utilisateur.uid).set({
        'nom': nom.trim(),
        'telephone': telephone.trim(),
        'email': email.trim(),
        // Formes comparables, utilisées par la recherche de contacts.
        'telephoneNormalise': normaliserTelephone(telephone),
        'emailNormalise': normaliserEmail(email),
        'creeLe': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      // Volontairement ignoré, voir le commentaire ci-dessus.
    }
  }

  @override
  Future<void> connecter({
    required String email,
    required String motDePasse,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: motDePasse,
      );
    } on FirebaseAuthException catch (e) {
      throw _erreur(e.code);
    }
  }

  @override
  Future<void> deconnecter() => _auth.signOut();

  bool _googleInitialise = false;

  @override
  Future<bool> connecterAvecGoogle() async {
    try {
      // Le paquet Google demande d'être initialisé une seule fois. Sur Android,
      // il trouve tout seul son identifiant dans google-services.json.
      if (!_googleInitialise) {
        await GoogleSignIn.instance.initialize();
        _googleInitialise = true;
      }
      final compteGoogle = await GoogleSignIn.instance.authenticate();
      final jeton = compteGoogle.authentication.idToken;
      if (jeton == null) {
        throw const ErreurAuth('Connexion Google impossible. Réessayez.');
      }

      final resultat = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: jeton),
      );

      // Premier passage : on crée le profil avec les infos du compte Google.
      final utilisateur = resultat.user;
      if (utilisateur != null &&
          (resultat.additionalUserInfo?.isNewUser ?? false)) {
        try {
          await _base.collection('utilisateurs').doc(utilisateur.uid).set({
            'nom': utilisateur.displayName ?? '',
            'telephone': '',
            'email': utilisateur.email ?? '',
            'telephoneNormalise': '',
            'emailNormalise': normaliserEmail(utilisateur.email ?? ''),
            'creeLe': FieldValue.serverTimestamp(),
          });
        } on FirebaseException {
          // Même principe que pour l'inscription : on laisse entrer.
        }
      }
      return true;
    } on GoogleSignInException catch (e) {
      debugPrint('Google : ${e.code} ${e.description}');
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          return false;
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw const ErreurAuth(
            "Google n'est pas encore configuré pour cette appli.",
          );
        default:
          throw const ErreurAuth('Connexion Google impossible. Réessayez.');
      }
    } on FirebaseAuthException catch (e) {
      throw _erreur(e.code);
    }
  }

  @override
  Future<ProfilUtilisateur?> chargerProfil() async {
    final utilisateur = _auth.currentUser;
    if (utilisateur == null) return null;

    try {
      final doc = await _base
          .collection('utilisateurs')
          .doc(utilisateur.uid)
          .get();
      final donnees = doc.data();
      if (donnees != null) {
        final photo = donnees['photo'] as String?;
        return ProfilUtilisateur(
          nom: (donnees['nom'] as String?) ?? utilisateur.displayName ?? '',
          telephone: (donnees['telephone'] as String?) ?? '',
          email: (donnees['email'] as String?) ?? utilisateur.email ?? '',
          photo: (photo == null || photo.isEmpty) ? null : base64Decode(photo),
          photoUrl: utilisateur.photoURL,
        );
      }
    } on FirebaseException {
      // Pas de réseau ou pas d'accès : on utilise les infos du compte.
    }
    return ProfilUtilisateur(
      nom: utilisateur.displayName ?? '',
      email: utilisateur.email ?? '',
      photoUrl: utilisateur.photoURL,
    );
  }

  @override
  Future<void> assurerRecherchable() async {
    final utilisateur = _auth.currentUser;
    if (utilisateur == null) return;
    try {
      final ref = _base.collection('utilisateurs').doc(utilisateur.uid);
      final donnees = (await ref.get()).data() ?? <String, dynamic>{};

      final email = (donnees['email'] as String?) ?? utilisateur.email ?? '';
      final telephone = (donnees['telephone'] as String?) ?? '';
      final aJour =
          donnees['emailNormalise'] == normaliserEmail(email) &&
          donnees['telephoneNormalise'] == normaliserTelephone(telephone);
      if (aJour) return;

      // Profil incomplet ou ancien : on complète sans toucher au reste.
      await ref.set({
        'nom': (donnees['nom'] as String?) ?? utilisateur.displayName ?? '',
        'email': email,
        'telephone': telephone,
        'emailNormalise': normaliserEmail(email),
        'telephoneNormalise': normaliserTelephone(telephone),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Pas de réseau : ce sera refait au prochain démarrage.
    }
  }

  @override
  Future<void> changerPhoto(Uint8List octets) async {
    final utilisateur = _auth.currentUser;
    if (utilisateur == null) {
      throw const ErreurAuth('Connectez-vous pour changer votre photo.');
    }
    try {
      // `merge` garde le reste du profil (nom, téléphone...) intact.
      await _base.collection('utilisateurs').doc(utilisateur.uid).set({
        'photo': base64Encode(octets),
      }, SetOptions(merge: true));
    } on FirebaseException {
      throw const ErreurAuth(
        "Impossible d'enregistrer la photo. Vérifiez votre connexion.",
      );
    }
  }

  /// Traduit le code d'erreur de Firebase en erreur claire, avec les champs
  /// à faire vibrer.
  ErreurAuth _erreur(String code) {
    switch (code) {
      case 'email-already-in-use':
      case 'invalid-email':
        return ErreurAuth(_message(code), champs: {'email'});
      case 'weak-password':
        return ErreurAuth(_message(code), champs: {'motDePasse'});
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return ErreurAuth(_message(code), champs: {'email', 'motDePasse'});
      default:
        return ErreurAuth(_message(code));
    }
  }

  /// Le message en français pour un code d'erreur de Firebase.
  String _message(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cette adresse e-mail est déjà utilisée.';
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'weak-password':
        return 'Mot de passe trop court (6 caractères minimum).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou mot de passe incorrect.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop d\'essais. Réessayez dans quelques minutes.';
      case 'network-request-failed':
        return 'Pas de connexion internet.';
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return 'La connexion par e-mail n\'est pas encore activée '
            'dans la console Firebase.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}
