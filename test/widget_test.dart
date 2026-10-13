import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:projet_starpole/application/application.dart';

/// Charge Poppins pour que les textes aient la bonne taille dans le test.
Future<void> chargerPoppins() async {
  final chargeur = FontLoader('Poppins');
  for (final style in ['Regular', 'Medium', 'Bold']) {
    chargeur.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/Poppins/Poppins-$style.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  await chargeur.load();
}

/// Avance le temps de l'animation d'un changement d'écran. On n'utilise pas
/// pumpAndSettle tant que le bandeau est visible : son point clignote sans fin.
Future<void> avancer(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets("Du début de l'appli jusqu'à l'accueil et ses onglets", (
    tester,
  ) async {
    await chargerPoppins();
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ApplicationStarPole());

    // Infos de départ : 3 pages.
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text("C'est parti !"), findsOneWidget);

    // C'est parti mène à l'inscription, puis à la connexion et retour.
    await tester.tap(find.text("C'est parti !"));
    await tester.pumpAndSettle();
    expect(find.text('Créer un compte'), findsOneWidget);
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
    await tester.tap(find.text("S'inscrire"));
    await tester.pumpAndSettle();
    expect(find.text('Créer un compte'), findsOneWidget);

    // S'inscrire ouvre l'accueil.
    await tester.tap(find.text("S'inscrire").last);
    await tester.pumpAndSettle();
    expect(find.text('Abidjan, Plateau'), findsOneWidget);

    // Accepter une alerte : le bandeau « Alerte en cours » apparaît partout.
    expect(find.text('Alerte en cours'), findsNothing);
    await tester.tap(find.text('Personne en detresse').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je peux aider'));
    await avancer(tester);
    // « Je peux aider » ouvre directement le détail de l'alerte acceptée.
    expect(find.text('Timeline'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left)); // retour aux détails
    await avancer(tester);
    await tester.tap(find.byIcon(Icons.chevron_left)); // retour à l'accueil
    await avancer(tester);
    expect(find.text('Alerte en cours'), findsOneWidget);

    // Le bandeau ouvre le suivi, et « Stopper » le fait disparaître.
    await tester.tap(find.text('Alerte en cours'));
    await avancer(tester);
    expect(find.text('Timeline'), findsOneWidget);
    await tester.tap(find.text('Stopper'));
    await tester.pumpAndSettle();
    // « Stopper » (comme « Terminé ») ouvre la note de l'aidant.
    expect(find.text("Noter l'aidant"), findsOneWidget);
    expect(find.text('Alerte en cours'), findsNothing);
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(find.text('Abidjan, Plateau'), findsOneWidget);

    // Onglets : Message, conversation, puis Profil.
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(find.text('Messagerie'), findsOneWidget);
    await tester.tap(find.text('Mariam'));
    await tester.pumpAndSettle();
    expect(find.text('En ligne'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Mon profil'), findsOneWidget);

    // Le bouton + ouvre « Poster une alerte ».
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Poster une alerte'), findsOneWidget);
  });
}
