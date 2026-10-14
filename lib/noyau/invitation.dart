import 'package:share_plus/share_plus.dart';

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
