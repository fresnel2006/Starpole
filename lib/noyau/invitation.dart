import 'package:share_plus/share_plus.dart';

import 'alerte.dart';

/// Ouvre le partage du téléphone (WhatsApp, SMS...) avec un message
/// d'invitation à rejoindre StarPole.
Future<void> inviterSurStarPole() {
  return SharePlus.instance.share(
    ShareParams(
      text:
          'Rejoins-moi sur StarPole, l\'appli d\'entraide de quartier à '
          'Abidjan. Une étoile pour ne jamais rester seul. '
          'Bientôt disponible.',
    ),
  );
}

/// Ouvre le partage du téléphone (WhatsApp en tête) avec le texte d'une
/// alerte : son titre, sa description, le lieu et un lien vers la carte.
Future<void> partagerAlerte(Alerte alerte) {
  final lignes = <String>[
    'Alerte StarPole : ${alerte.categorie}',
    alerte.description,
    if (alerte.lieu.isNotEmpty) 'Lieu : ${alerte.lieu}',
    if (alerte.aUnePosition)
      'https://www.openstreetmap.org/?mlat=${alerte.latitude}'
          '&mlon=${alerte.longitude}#map=17/${alerte.latitude}/${alerte.longitude}',
    "StarPole, l'appli d'entraide de quartier. Bientôt disponible.",
  ];
  return SharePlus.instance.share(ShareParams(text: lignes.join('\n')));
}
