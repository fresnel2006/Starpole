import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// Ouvre une adresse web dans une autre appli (remplaçable dans les tests).
Future<bool> Function(Uri adresse) lanceurExterne = (adresse) =>
    launchUrl(adresse, mode: LaunchMode.externalApplication);

/// Ouvre l'application de cartes du téléphone (Google Maps en général) avec
/// l'itinéraire jusqu'à l'alerte, depuis la position actuelle. Renvoie faux si
/// l'alerte n'a pas de position ou si rien ne peut s'ouvrir.
Future<bool> ouvrirItineraire(Alerte alerte) async {
  if (!alerte.aUnePosition) return false;
  final adresse = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${alerte.latitude},${alerte.longitude}',
    'travelmode': 'driving',
  });
  try {
    return await lanceurExterne(adresse);
  } catch (_) {
    return false;
  }
}
