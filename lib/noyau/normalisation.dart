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

/// Vrai si [email] (déjà normalisé) a la forme d'une adresse e-mail.
bool emailValide(String email) =>
    email.length <= 254 &&
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
