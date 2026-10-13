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
