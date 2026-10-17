import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:projet_starpole/fonctionnalites/otp/ecran_code_otp.dart';
import 'package:projet_starpole/partage/composants/vibrant.dart';

void main() {
  testWidgets('OTP : mauvais code puis renvoi après le compte à rebours', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final codes = <String>[];
    var renvois = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: EcranCodeOtp(
          titre: 'Création du compte',
          verifier: (code) async {
            codes.add(code);
            return 'Code incorrect.';
          },
          renvoyer: () async {
            renvois++;
            return renvois == 2 ? 'Trop de codes demandés.' : null;
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Création du compte'), findsOneWidget);
    expect(find.text('Saisie du code OTP envoyé'), findsOneWidget);
    expect(find.text('1:00'), findsOneWidget);
    // Quatre cases vides montrent un « 0 » pâle.
    expect(find.text('0'), findsNWidgets(4));

    // Trois chiffres : rien n'est vérifié. Les lettres sont ignorées.
    await tester.enterText(find.byType(TextField), '12a3');
    await tester.pump();
    expect(codes, isEmpty);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(1));

    // Le quatrième chiffre lance la vérification : mauvais code, les cases
    // vibrent, le message s'affiche et le champ est vidé.
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    await tester.pump();
    expect(codes, ['1234']);
    expect(find.text('Code incorrect.'), findsOneWidget);
    expect(tester.state<VibrantState>(find.byType(Vibrant)).enErreur, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    await tester.pump(const Duration(seconds: 1));

    // « Renvoyer » ne fait rien avant la fin du compte à rebours.
    await tester.tap(find.text('Renvoyer'));
    await tester.pump();
    expect(renvois, 0);

    await tester.pump(const Duration(seconds: 60));
    expect(find.text('0:00'), findsOneWidget);
    await tester.tap(find.text('Renvoyer'));
    await tester.pump();
    expect(renvois, 1);
    // Le compte à rebours repart.
    expect(find.text('1:00'), findsOneWidget);

    // Si le serveur refuse un nouveau code, son message s'affiche.
    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.text('Renvoyer'));
    await tester.pump();
    await tester.pump();
    expect(renvois, 2);
    expect(find.text('Trop de codes demandés.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
