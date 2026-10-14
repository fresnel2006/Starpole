import 'dart:convert';

/// Met un numéro de téléphone sous une forme unique pour pouvoir le comparer :
/// seuls les chiffres comptent, et on garde les 10 derniers. Ainsi
/// « 07 07 07 07 07 », « 0707070707 » et « +225 07 07 07 07 07 » donnent le
/// même résultat.
String normaliserTelephone(String saisie) {
  final chiffres = saisie.replaceAll(RegExp(r'\D'), '');
  if (chiffres.length >= 10) return chiffres.substring(chiffres.length - 10);
  return chiffres;
}

/// Met une adresse e-mail en minuscules, sans espaces autour.
String normaliserEmail(String saisie) => saisie.trim().toLowerCase();

/// Vrai si ce que la personne a tapé ressemble à une adresse e-mail.
bool ressembleAUnEmail(String saisie) => saisie.contains('@');

/// Ce que la personne a tapé pour se connecter : une adresse e-mail ou un
/// numéro de téléphone.
///
/// MODE DEMONSTRATION : il n'y a pas de mot de passe ni de code de
/// confirmation. Le compte Firebase est créé avec une adresse interne et un mot
/// de passe calculé à partir de l'identifiant, donc n'importe qui connaissant
/// l'identifiant peut entrer dans le compte. À remplacer par un code envoyé par
/// e-mail (serveur FastAPI) avant tout usage réel.
class IdentifiantCompte {
  const IdentifiantCompte._({
    required this.email,
    required this.telephone,
    required this.emailInterne,
  });

  /// L'e-mail saisi (vide si la personne a tapé un numéro).
  final String email;

  /// Le numéro saisi (vide si la personne a tapé un e-mail).
  final String telephone;

  /// L'adresse utilisée pour le compte Firebase. Pour un numéro, c'est une
  /// adresse interne qui n'existe pas vraiment.
  final String emailInterne;

  /// Le mot de passe calculé (voir le commentaire de la classe).
  String get motDePasse =>
      base64Url.encode(utf8.encode('starpole:$emailInterne'));

  /// Lit ce que la personne a tapé. Renvoie null si ce n'est ni un e-mail ni
  /// un numéro plausible.
  static IdentifiantCompte? depuis(String saisie) {
    final texte = saisie.trim();
    if (ressembleAUnEmail(texte)) {
      final email = normaliserEmail(texte);
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return null;
      return IdentifiantCompte._(
        email: email,
        telephone: '',
        emailInterne: email,
      );
    }
    final numero = normaliserTelephone(texte);
    if (numero.length < 8) return null;
    return IdentifiantCompte._(
      email: '',
      telephone: texte,
      emailInterne: '$numero@telephone.starpole.app',
    );
  }
}
