import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:projet_starpole/application/application.dart';
import 'package:projet_starpole/application/couleurs.dart';
import 'package:projet_starpole/noyau/alerte.dart';
import 'package:projet_starpole/partage/composants/carte_3d.dart';
import 'package:projet_starpole/noyau/appel.dart';
import 'package:projet_starpole/noyau/messagerie.dart';
import 'package:projet_starpole/noyau/normalisation.dart';
import 'package:projet_starpole/noyau/service_alertes.dart';
import 'package:projet_starpole/noyau/service_appel.dart';
import 'package:projet_starpole/noyau/service_auth.dart';
import 'package:projet_starpole/noyau/service_carnet.dart';
import 'package:projet_starpole/noyau/service_localisation.dart';
import 'package:projet_starpole/noyau/service_messagerie.dart';
import 'package:projet_starpole/noyau/service_photo.dart';
import 'package:projet_starpole/partage/composants/case_a_cocher.dart';
import 'package:projet_starpole/partage/composants/champ_texte.dart';
import 'package:projet_starpole/partage/composants/vibrant.dart';

// ---------------------------------------------------------------------------
// Faux services : ils évitent d'appeler le vrai Firebase et le vrai GPS.
// ---------------------------------------------------------------------------

/// Faux service de compte.
class FausseAuth implements ServiceAuth {
  FausseAuth({this.erreur, this.codeValide = '1234'});

  /// Si renseigné, la demande de code échoue avec ce message.
  String? erreur;

  /// Le seul code accepté par la vérification.
  final String codeValide;

  /// Le numéro du profil (vide : la messagerie propose d'en ajouter un).
  String telephone = '0700000000';

  final List<String> appels = [];

  /// Ce que renvoie la connexion Google (false = fenêtre fermée).
  bool googleReussi = true;

  /// Combien de fois le compte a été rendu recherchable.
  int rendusRecherchables = 0;

  @override
  Future<void> assurerRecherchable() async {
    rendusRecherchables++;
  }

  /// Les photos envoyées par changerPhoto.
  final List<Uint8List> photosEnvoyees = [];

  @override
  bool get estConnecte => false;

  @override
  Future<void> demanderCode({required String email}) async {
    appels.add('demander:$email');
    if (erreur != null) throw ErreurAuth(erreur!);
  }

  @override
  Future<void> verifierCode({
    required String email,
    required String code,
    String? nom,
  }) async {
    appels.add('verifier:$email:$code:${nom ?? ''}');
    if (code != codeValide) throw const ErreurAuth('Code incorrect.');
  }

  @override
  Future<void> deconnecter() async {
    appels.add('deconnecter');
  }

  @override
  Future<bool> connecterAvecGoogle() async {
    appels.add('google');
    if (erreur != null) throw ErreurAuth(erreur!);
    return googleReussi;
  }

  @override
  Future<void> changerPhoto(Uint8List octets) async {
    photosEnvoyees.add(octets);
  }

  @override
  Future<void> modifierProfil({String? nom, String? telephone}) async {
    appels.add('modifier:$nom:$telephone');
    if (erreur != null) throw ErreurAuth(erreur!);
    if (telephone != null) this.telephone = telephone;
  }

  @override
  Future<ProfilUtilisateur?> chargerProfil() async =>
      ProfilUtilisateur(nom: 'Ange Fresnel', telephone: telephone);
}

/// Fausses alertes en mémoire : elles se comportent comme Firestore (les
/// écrans se mettent à jour en direct), sans internet.
class FausseAlertes implements ServiceAlertes {
  FausseAlertes({List<Alerte>? initiales, this.statistiquesFausses})
    : _liste = [...?initiales];

  final List<Alerte> _liste;
  final StreamController<void> _changement = StreamController.broadcast();

  /// Les chiffres que renvoie le profil.
  final StatistiquesProfil? statistiquesFausses;

  /// Ce qui s'est passé, dans l'ordre (« accepter:a1 », « terminer:a1 »...).
  final List<String> actions = [];

  /// Les alertes publiées par l'utilisateur de test.
  final List<Alerte> publiees = [];

  @override
  String? get utilisateurId => 'moi';

  Stream<T> _flux<T>(T Function() lire) async* {
    yield lire();
    await for (final _ in _changement.stream) {
      yield lire();
    }
  }

  /// Remplace une alerte par une copie modifiée.
  void _modifier(
    String id, {
    StatutAlerte? statut,
    Object? aidantId = _inchange,
    Object? aidantNom = _inchange,
  }) {
    final i = _liste.indexWhere((a) => a.id == id);
    final a = _liste[i];
    _liste[i] = Alerte(
      id: a.id,
      type: a.type,
      categorie: a.categorie,
      description: a.description,
      ville: a.ville,
      quartier: a.quartier,
      latitude: a.latitude,
      longitude: a.longitude,
      auteurId: a.auteurId,
      auteurNom: a.auteurNom,
      statut: statut ?? a.statut,
      creeLe: a.creeLe,
      aidantId: aidantId == _inchange ? a.aidantId : aidantId as String?,
      aidantNom: aidantNom == _inchange ? a.aidantNom : aidantNom as String?,
      accepteLe: DateTime.now(),
      termineLe: statut == StatutAlerte.resolue ? DateTime.now() : null,
      photo: a.photo,
    );
    _changement.add(null);
  }

  static const Object _inchange = Object();

  @override
  Stream<List<Alerte>> alertes() => _flux(
    () => List.of(_liste)..sort((x, y) => y.creeLe.compareTo(x.creeLe)),
  );

  @override
  Stream<List<Alerte>> mesAlertes() => _flux(
    () => _liste
        .where((a) => a.auteurId == 'moi' || a.aidantId == 'moi')
        .toList(),
  );

  @override
  Stream<Alerte?> alerteEnCours() => _flux(() {
    for (final a in _liste) {
      if (a.aidantId == 'moi' && a.statut == StatutAlerte.enCours) return a;
    }
    return null;
  });

  @override
  Stream<Alerte?> alerte(String id) => _flux(() {
    for (final a in _liste) {
      if (a.id == id) return a;
    }
    return null;
  });

  @override
  Future<void> publier({
    required TypeAlerte type,
    required String categorie,
    required String description,
    required String ville,
    String? quartier,
    double? latitude,
    double? longitude,
    Uint8List? photo,
  }) async {
    actions.add('publier:$categorie:${type.code}:$ville:$quartier');
    final alerte = Alerte(
      id: 'n${_liste.length}',
      type: type,
      categorie: categorie,
      description: description,
      ville: ville,
      quartier: quartier,
      latitude: latitude,
      longitude: longitude,
      auteurId: 'moi',
      auteurNom: 'Ange Fresnel',
      creeLe: DateTime.now(),
      photo: photo,
    );
    publiees.add(alerte);
    _liste.add(alerte);
    _changement.add(null);
  }

  @override
  Future<void> accepter(String id) async {
    actions.add('accepter:$id');
    _modifier(id, aidantId: 'moi', aidantNom: 'Ange Fresnel');
  }

  @override
  Future<void> terminer(String id) async {
    actions.add('terminer:$id');
    _modifier(id, statut: StatutAlerte.resolue);
  }

  @override
  Future<void> arreter(String id) async {
    actions.add('arreter:$id');
    _modifier(id, aidantId: null, aidantNom: null);
  }

  final Map<String, List<MiseAJour>> _messages = {};

  @override
  Stream<List<MiseAJour>> progression(String alerteId) =>
      _flux(() => List.of(_messages[alerteId] ?? const []));

  @override
  Future<void> envoyerProgression(String alerteId, String texte) async {
    actions.add('progression:$alerteId:$texte');
    (_messages[alerteId] ??= []).add(
      MiseAJour(
        id: 'm${_messages.length}',
        texte: texte,
        auteurId: 'moi',
        auteurNom: 'Ange Fresnel',
        creeLe: DateTime.now(),
      ),
    );
    _changement.add(null);
  }

  @override
  Future<StatistiquesProfil> statistiques() async =>
      statistiquesFausses ?? const StatistiquesProfil();

  @override
  Future<void> noter({
    required String alerteId,
    required String pourId,
    required int etoiles,
    String commentaire = '',
    List<String> etiquettes = const [],
  }) async {
    actions.add('noter:$alerteId:$pourId:$etoiles');
  }
}

/// Fausse messagerie en mémoire : contacts, conversations et messages se
/// comportent comme avec Firestore (en direct), sans internet.
class FausseMessagerie implements ServiceMessagerie {
  FausseMessagerie({
    Map<String, Contact> comptes = const {},
    List<Contact> contacts = const [],
  }) : _contacts = [...contacts] {
    // On range les comptes par numéro ou e-mail « normalisé », comme la base.
    for (final entree in comptes.entries) {
      final cle = ressembleAUnEmail(entree.key)
          ? normaliserEmail(entree.key)
          : normaliserTelephone(entree.key);
      _comptes[cle] = entree.value;
    }
  }

  final Map<String, Contact> _comptes = {};
  final List<Contact> _contacts;
  final Map<String, Contact> _autres = {};
  final Map<String, List<Message>> _messages = {};
  final Set<String> _nonLus = {};
  final StreamController<void> _changement = StreamController.broadcast();

  /// Ce qui s'est passé, dans l'ordre (« ouvrir:k1 », « message:c_k1:Salut »...).
  final List<String> actions = [];

  @override
  String? get utilisateurId => 'moi';

  Stream<T> _flux<T>(T Function() lire) async* {
    yield lire();
    await for (final _ in _changement.stream) {
      yield lire();
    }
  }

  @override
  Future<Contact?> chercherUtilisateur(String saisie) async {
    final texte = saisie.trim();
    final parEmail = ressembleAUnEmail(texte);
    final valeur = parEmail
        ? normaliserEmail(texte)
        : normaliserTelephone(texte);
    if (valeur.length < 8) {
      throw ErreurMessagerie(
        parEmail
            ? 'Adresse e-mail trop courte.'
            : 'Numéro de téléphone trop court.',
      );
    }
    final trouve = _comptes[valeur];
    if (trouve != null && trouve.id == 'moi') {
      throw const ErreurMessagerie("C'est votre propre compte.");
    }
    return trouve;
  }

  @override
  Future<Map<String, Contact>> trouverParTelephones(
    Iterable<String> numeros,
  ) async {
    actions.add('carnet:${numeros.length}');
    final trouves = <String, Contact>{};
    for (final numero in numeros) {
      final contact = _comptes[numero];
      if (contact != null && contact.id != 'moi') trouves[numero] = contact;
    }
    return trouves;
  }

  @override
  Future<void> ajouterContact(Contact contact) async {
    actions.add('ajouter:${contact.id}');
    if (!_contacts.any((c) => c.id == contact.id)) _contacts.add(contact);
    _changement.add(null);
  }

  @override
  Stream<List<Contact>> contacts() =>
      _flux(() => List.of(_contacts)..sort((a, b) => a.nom.compareTo(b.nom)));

  @override
  Stream<List<Conversation>> conversations() => _flux(() {
    final liste = <Conversation>[];
    _messages.forEach((id, messages) {
      if (messages.isEmpty) return;
      final autre = _autres[id]!;
      final dernier = messages.last;
      liste.add(
        Conversation(
          id: id,
          autreId: autre.id,
          autreNom: autre.nom,
          dernierMessage: dernier.texte,
          dernierTemps: dernier.creeLe,
          dernierParMoi: dernier.auteurId == 'moi',
          nonLu: _nonLus.contains(id),
        ),
      );
    });
    liste.sort((a, b) => b.dernierTemps.compareTo(a.dernierTemps));
    return liste;
  });

  @override
  Future<String> ouvrirConversation(Contact contact) async {
    actions.add('ouvrir:${contact.id}');
    final id = 'c_${contact.id}';
    _autres[id] = contact;
    _messages.putIfAbsent(id, () => []);
    return id;
  }

  @override
  Stream<List<Message>> messages(String conversationId) =>
      _flux(() => List.of(_messages[conversationId] ?? const []));

  @override
  Future<void> envoyerMessage(
    String conversationId,
    String texte, {
    Uint8List? photo,
    double? latitude,
    double? longitude,
  }) async {
    actions.add('message:$conversationId:$texte');
    if (photo != null) actions.add('photo:$conversationId');
    if (latitude != null) actions.add('position:$conversationId:$latitude');
    (_messages[conversationId] ??= []).add(
      Message(
        id: 'm${_messages[conversationId]!.length}',
        texte: texte,
        auteurId: 'moi',
        creeLe: DateTime.now(),
        photo: photo,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    _changement.add(null);
  }

  @override
  Future<void> marquerLu(String conversationId) async {
    actions.add('lu:$conversationId');
    if (_nonLus.remove(conversationId)) _changement.add(null);
  }

  @override
  Future<Contact?> profilDe(String id) async {
    for (final c in [..._contacts, ..._comptes.values]) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Simule un message reçu de [autre] (la conversation est créée au besoin).
  void recevoir(Contact autre, String texte) {
    final id = 'c_${autre.id}';
    _autres[id] = autre;
    (_messages[id] ??= []).add(
      Message(
        id: 'r${_messages[id]!.length}',
        texte: texte,
        auteurId: autre.id,
        creeLe: DateTime.now(),
      ),
    );
    _nonLus.add(id);
    _changement.add(null);
  }
}

/// Faux carnet de contacts du téléphone.
class FausseCarnet implements ServiceCarnet {
  FausseCarnet([this.resultat = const ResultatCarnet(EtatCarnet.ok)]);

  ResultatCarnet resultat;
  int lectures = 0;
  int reglagesOuverts = 0;

  @override
  Future<ResultatCarnet> lire() async {
    lectures++;
    return resultat;
  }

  @override
  Future<void> ouvrirReglages() async {
    reglagesOuverts++;
  }

  /// Les personnes « enregistrées dans le téléphone », par le formulaire.
  final List<String> enregistres = [];

  /// Ce que répond l'enregistrement (ok, refusé ou bloqué).
  EtatCarnet etatEnregistrement = EtatCarnet.ok;

  @override
  Future<EtatCarnet> enregistrer({
    required String prenom,
    String nom = '',
    required String numero,
  }) async {
    if (etatEnregistrement == EtatCarnet.ok) {
      enregistres.add('$prenom|$nom|$numero');
    }
    return etatEnregistrement;
  }
}

/// Fausse position : renvoie le résultat voulu, sans toucher au GPS.
class FausseLocalisation implements ServiceLocalisation {
  FausseLocalisation({
    this.resultat = const ResultatLocalisation(
      EtatLocalisation.ok,
      LieuActuel(
        ville: 'Abidjan',
        quartier: 'Plateau',
        latitude: 5.3197,
        longitude: -4.0167,
      ),
    ),
  });

  ResultatLocalisation resultat;
  int recherches = 0;
  final List<EtatLocalisation> reglagesOuverts = [];

  @override
  Future<ResultatLocalisation> localiser() async {
    recherches++;
    return resultat;
  }

  @override
  Future<void> ouvrirReglages(EtatLocalisation etat) async {
    reglagesOuverts.add(etat);
  }
}

/// Faux choix de photo : renvoie tout de suite une minuscule image PNG.
class FausseSelectionPhoto implements ServicePhoto {
  final List<FormePhoto> formes = [];

  @override
  Future<Uint8List?> choisir({FormePhoto forme = FormePhoto.carre}) async {
    formes.add(forme);
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    );
  }
}

// ---------------------------------------------------------------------------
// Aides pour les tests
// ---------------------------------------------------------------------------

/// Les alertes de départ : deux à Abidjan, une dans une autre ville.
List<Alerte> alertesDeDepart() => [
  Alerte(
    id: 'a1',
    type: TypeAlerte.urgence,
    categorie: 'Personne en detresse',
    description: 'Une personne agee est perdue pres du marche.',
    ville: 'Abidjan',
    quartier: 'Treichville',
    auteurId: 'kouadio',
    auteurNom: 'Kouadio Eliezer',
    creeLe: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  Alerte(
    id: 'a2',
    type: TypeAlerte.service,
    categorie: 'Objet perdu',
    description: 'Un sac noir a ete perdu.',
    ville: 'Abidjan',
    quartier: 'Plateau',
    auteurId: 'mariam',
    auteurNom: 'Mariam',
    creeLe: DateTime.now().subtract(const Duration(minutes: 32)),
  ),
  Alerte(
    id: 'a3',
    type: TypeAlerte.urgence,
    categorie: 'Accident',
    description: 'Accident a Bouake.',
    ville: 'Bouaké',
    auteurId: 'yves',
    auteurNom: 'Yves',
    creeLe: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
];

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

/// Ouvre l'appli et passe les 3 pages d'infos jusqu'à l'inscription.
Future<void> allerALInscription(
  WidgetTester tester,
  ServiceAuth auth, {
  ServicePhoto? photos,
  ServiceLocalisation? localisation,
  ServiceAlertes? alertes,
  ServiceMessagerie? messagerie,
  ServiceCarnet? carnet,
  ServiceAppel? appels,
  Size taille = const Size(390, 844),
  double echelleTexte = 1,
}) async {
  await chargerPoppins();
  tester.view.physicalSize = taille * 2;
  tester.platformDispatcher.textScaleFactorTestValue = echelleTexte;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ApplicationStarPole(
      auth: auth,
      alertes: alertes ?? FausseAlertes(initiales: alertesDeDepart()),
      messagerie: messagerie ?? FausseMessagerie(),
      carnet: carnet ?? FausseCarnet(),
      appels: appels ?? FausseAppel(),
      constructeurCarte: carteDeTest,
      photos: photos,
      localisation: localisation ?? FausseLocalisation(),
    ),
  );
  // Sur un petit écran, la page défile : on amène chaque bouton à l'écran.
  await tester.ensureVisible(find.text('Suivant'));
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Suivant'));
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text("C'est parti !"));
  await tester.tap(find.text("C'est parti !"));
  await tester.pumpAndSettle();
  expect(find.text('Créer un compte'), findsOneWidget);
}

/// Remplit les 2 champs de l'inscription (nom, e-mail ou numéro).
Future<void> remplirInscription(WidgetTester tester) async {
  final champs = find.byType(TextField);
  await tester.enterText(champs.at(0), 'Ange Fresnel');
  await tester.enterText(champs.at(1), 'fresnel@exemple.ci');
}

/// Inscription complète : on arrive sur l'accueil.
Future<void> sInscrire(WidgetTester tester) async {
  await remplirInscription(tester);
  await tester.ensureVisible(find.byType(CaseACocher));
  await tester.tap(find.byType(CaseACocher));
  await tester.ensureVisible(find.text("S'inscrire").last);
  await tester.tap(find.text("S'inscrire").last);
  await tester.pumpAndSettle();
  // Le code reçu par e-mail est saisi sur l'écran suivant.
  await tester.enterText(find.byType(TextField), '1234');
  await tester.pumpAndSettle();
  // On est arrivé sur l'accueil.
  expect(find.text("Types d'alerte"), findsOneWidget);
}

void main() {
  testWidgets("Inscription : vérifications, code par e-mail puis accueil", (
    tester,
  ) async {
    final auth = FausseAuth();
    await allerALInscription(tester, auth);

    // Champs vides : ils vibrent et clignotent, sans message, et aucun code
    // n'est demandé.
    await tester.tap(find.text("S'inscrire").last);
    await tester.pump();
    for (var i = 0; i < 2; i++) {
      final champ = tester.state<ChampTexteState>(
        find.byType(ChampTexte).at(i),
      );
      expect(champ.enErreur, isTrue, reason: 'le champ $i doit vibrer');
    }
    expect(find.byType(SnackBar), findsNothing);
    expect(auth.appels, isEmpty);
    await tester.pumpAndSettle();

    // Une adresse invalide fait vibrer le champ.
    await tester.enterText(find.byType(TextField).at(0), 'Ange Fresnel');
    await tester.enterText(find.byType(TextField).at(1), 'abc');
    await tester.tap(find.byType(CaseACocher));
    await tester.tap(find.text("S'inscrire").last);
    await tester.pump();
    expect(
      tester.state<ChampTexteState>(find.byType(ChampTexte).at(1)).enErreur,
      isTrue,
    );
    expect(auth.appels, isEmpty);
    await tester.pumpAndSettle();

    // Un numéro de téléphone n'est pas une adresse : le champ vibre.
    await tester.enterText(find.byType(TextField).at(1), '07 07 07 07 07');
    await tester.tap(find.text("S'inscrire").last);
    await tester.pump();
    expect(
      tester.state<ChampTexteState>(find.byType(ChampTexte).at(1)).enErreur,
      isTrue,
    );
    expect(auth.appels, isEmpty);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CaseACocher)); // on décoche

    // Champs remplis mais conditions non cochées : la case vibre.
    await remplirInscription(tester);
    await tester.tap(find.text("S'inscrire").last);
    await tester.pump();
    expect(
      tester.state<CaseACocherState>(find.byType(CaseACocher)).enErreur,
      isTrue,
    );
    expect(auth.appels, isEmpty);
    await tester.pumpAndSettle();

    // Tout est bon : un code est demandé et l'écran du code s'ouvre.
    await tester.tap(find.byType(CaseACocher));
    await tester.tap(find.text("S'inscrire").last);
    await tester.pumpAndSettle();
    expect(auth.appels, ['demander:fresnel@exemple.ci']);
    expect(find.text('Création du compte'), findsOneWidget);
    expect(find.text('Saisie du code OTP envoyé'), findsOneWidget);

    // Un mauvais code est refusé, puis le bon code ouvre l'accueil.
    await tester.enterText(find.byType(TextField), '9999');
    await tester.pumpAndSettle();
    expect(find.text('Code incorrect.'), findsOneWidget);
    expect(find.text("Types d'alerte"), findsNothing);
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pumpAndSettle();
    expect(auth.appels, [
      'demander:fresnel@exemple.ci',
      'verifier:fresnel@exemple.ci:9999:Ange Fresnel',
      'verifier:fresnel@exemple.ci:1234:Ange Fresnel',
    ]);
    expect(find.text('Abidjan, Plateau'), findsOneWidget);
  });

  testWidgets("Connexion : erreur du serveur, puis code reçu par e-mail", (
    tester,
  ) async {
    final auth = FausseAuth(erreur: 'Le serveur ne répond pas. Réessayez.');
    await allerALInscription(tester, auth);

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);

    // Champ vide : il vibre, sans message.
    await tester.tap(find.text('Se connecter').last);
    await tester.pump();
    expect(
      tester.state<ChampTexteState>(find.byType(ChampTexte).at(0)).enErreur,
      isTrue,
    );
    expect(find.byType(SnackBar), findsNothing);
    await tester.pumpAndSettle();
    // Le champ reste rouge après l'animation (fond blanc de la connexion).
    expect(
      tester.state<ChampTexteState>(find.byType(ChampTexte).at(0)).rougeFixe,
      isTrue,
    );

    // Dès qu'on écrit dans le champ, il n'est plus rouge.
    await tester.enterText(find.byType(TextField).at(0), 'a');
    await tester.pump();
    expect(
      tester.state<ChampTexteState>(find.byType(ChampTexte).at(0)).rougeFixe,
      isFalse,
    );

    // Pas une adresse : le champ vibre, aucun code n'est demandé.
    await tester.tap(find.text('Se connecter').last);
    await tester.pump();
    expect(
      tester.state<ChampTexteState>(find.byType(ChampTexte).at(0)).enErreur,
      isTrue,
    );
    expect(auth.appels, isEmpty);
    await tester.pumpAndSettle();

    // Un numéro de téléphone n'est pas une adresse : le champ vibre.
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(0), '07 07 07 07 07');
    await tester.tap(find.text('Se connecter').last);
    await tester.pump();
    expect(
      tester.state<ChampTexteState>(find.byType(ChampTexte).at(0)).enErreur,
      isTrue,
    );
    expect(auth.appels, isEmpty);
    await tester.pumpAndSettle();

    // Une erreur du serveur s'affiche et on reste sur la connexion.
    await tester.enterText(champs.at(0), 'fresnel@exemple.ci');
    await tester.tap(find.text('Se connecter').last);
    await tester.pumpAndSettle();
    expect(find.text('Le serveur ne répond pas. Réessayez.'), findsOneWidget);
    expect(auth.appels, ['demander:fresnel@exemple.ci']);

    // Le serveur répond : l'écran du code s'ouvre, et le bon code connecte.
    auth.erreur = null;
    await tester.tap(find.text('Se connecter').last);
    await tester.pumpAndSettle();
    expect(find.text('Saisie du code OTP envoyé'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pumpAndSettle();
    expect(auth.appels.last, 'verifier:fresnel@exemple.ci:1234:');
    expect(find.text("Types d'alerte"), findsOneWidget);
  });

  testWidgets('Google : fenêtre fermée, erreur, puis connexion réussie', (
    tester,
  ) async {
    final auth = FausseAuth()..googleReussi = false;
    await allerALInscription(tester, auth);

    // L'utilisateur ferme la fenêtre Google : rien ne se passe.
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();
    expect(auth.appels, ['google']);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    // Il choisit un compte : on arrive sur l'accueil.
    auth.googleReussi = true;
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();
    expect(auth.appels, ['google', 'google']);
    expect(find.text('Abidjan, Plateau'), findsOneWidget);
  });

  testWidgets('Google : une erreur affiche un message', (tester) async {
    final auth = FausseAuth(erreur: "Google n'est pas encore configuré.");
    await allerALInscription(tester, auth);

    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();
    expect(find.text("Google n'est pas encore configuré."), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });

  testWidgets('Accueil : seules les alertes de ma ville apparaissent', (
    tester,
  ) async {
    await allerALInscription(tester, FausseAuth());
    await sInscrire(tester);

    // Deux alertes à Abidjan ; celle de Bouaké est cachée.
    expect(find.text('2 Alertes'), findsOneWidget);
    expect(find.text('Personne en detresse'), findsOneWidget);
    expect(find.text('Objet perdu'), findsOneWidget);
    expect(find.text('Accident'), findsNothing);
    expect(find.text('Treichville'), findsOneWidget);
  });

  testWidgets("Accueil : message quand il n'y a aucune alerte", (tester) async {
    await allerALInscription(tester, FausseAuth(), alertes: FausseAlertes());
    await sInscrire(tester);

    expect(find.text('0 Alerte'), findsOneWidget);
    expect(
      find.text('Aucune alerte près de chez vous pour le moment.'),
      findsOneWidget,
    );
  });

  testWidgets("Un appui sur « Signalé par » ouvre la messagerie de l'auteur", (
    tester,
  ) async {
    final messagerie = FausseMessagerie();
    await allerALInscription(
      tester,
      FausseAuth(),
      alertes: FausseAlertes(initiales: alertesDeDepart()),
      messagerie: messagerie,
    );
    await sInscrire(tester);

    await tester.tap(find.text('Personne en detresse'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Signalé par'));
    await tester.tap(find.text('Signalé par'));
    await tester.pumpAndSettle();

    expect(messagerie.actions, contains('ouvrir:kouadio'));
    expect(find.text('Dites bonjour à Kouadio Eliezer.'), findsOneWidget);
    expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
  });

  testWidgets("Aider une alerte : bandeau, suivi, arrêt et note de l'auteur", (
    tester,
  ) async {
    final alertes = FausseAlertes(initiales: alertesDeDepart());
    await allerALInscription(tester, FausseAuth(), alertes: alertes);
    await sInscrire(tester);

    // Je ne vois pas encore de bandeau.
    expect(find.text('Alerte en cours'), findsNothing);

    // J'ouvre l'alerte et j'accepte d'aider : le suivi s'ouvre.
    await tester.tap(find.text('Personne en detresse'));
    await tester.pumpAndSettle();
    expect(
      find.text('Une personne agee est perdue pres du marche.'),
      findsOneWidget,
    );
    expect(find.text('Signalé par'), findsOneWidget);
    await tester.tap(find.text('Je peux aider'));
    await avancer(tester);
    expect(alertes.actions, ['accepter:a1']);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Ange Fresnel repond'), findsOneWidget);

    // Retour : le bandeau « Alerte en cours » est visible sur l'accueil.
    await tester.tap(find.byIcon(Icons.chevron_left)); // retour aux détails
    await avancer(tester);
    expect(find.text('Voir le suivi'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left)); // retour à l'accueil
    await avancer(tester);
    expect(find.text('Alerte en cours'), findsOneWidget);

    // Le bandeau rouvre le suivi ; « Stopper » libère l'alerte et ouvre la
    // note de l'auteur.
    await tester.tap(find.text('Alerte en cours'));
    await avancer(tester);
    expect(find.text('Timeline'), findsOneWidget);
    await tester.tap(find.text('Stopper'));
    await tester.pumpAndSettle();
    expect(alertes.actions, ['accepter:a1', 'arreter:a1']);
    expect(find.text("Noter l'auteur"), findsOneWidget);
    expect(find.text('Kouadio Eliezer'), findsOneWidget);
    expect(find.text('Alerte en cours'), findsNothing);

    // J'envoie la note : elle est enregistrée, et je reviens à l'accueil.
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(alertes.actions.last, 'noter:a1:kouadio:5');
    expect(find.text('Abidjan, Plateau'), findsOneWidget);
    // L'alerte est de nouveau libre : elle est toujours dans la liste.
    expect(find.text('2 Alertes'), findsOneWidget);
  });

  testWidgets("Terminer : l'alerte est résolue et la note s'ouvre", (
    tester,
  ) async {
    final alertes = FausseAlertes(initiales: alertesDeDepart());
    await allerALInscription(tester, FausseAuth(), alertes: alertes);
    await sInscrire(tester);

    await tester.tap(find.text('Personne en detresse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je peux aider'));
    await avancer(tester);
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();

    expect(alertes.actions, ['accepter:a1', 'terminer:a1']);
    expect(find.text("Noter l'auteur"), findsOneWidget);
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    // L'alerte résolue n'est plus proposée à l'accueil.
    expect(find.text('1 Alerte'), findsOneWidget);
    expect(find.text('Personne en detresse'), findsNothing);
  });

  testWidgets('Poster une alerte : elle est publiée avec ma position', (
    tester,
  ) async {
    final alertes = FausseAlertes(initiales: alertesDeDepart());
    await allerALInscription(tester, FausseAuth(), alertes: alertes);
    await sInscrire(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Poster une alerte'), findsOneWidget);
    expect(find.text('Localisation'), findsOneWidget);
    expect(find.text('Abidjan, Plateau'), findsOneWidget);

    // Je choisis « Dons », je donne un titre et je décris.
    await tester.tap(find.text('Dons'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Don de vetements');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Des vetements pour enfants',
    );
    await tester.ensureVisible(find.text("Publier l'alerte"));
    await tester.tap(find.text("Publier l'alerte"));
    await tester.pumpAndSettle();

    // L'alerte est enregistrée avec le titre, le type, la ville et le quartier.
    expect(alertes.actions, ['publier:Don de vetements:don:Abidjan:Plateau']);
    expect(alertes.publiees.single.description, 'Des vetements pour enfants');
    expect(alertes.publiees.single.latitude, 5.3197);

    // On revient à l'accueil, où la nouvelle alerte apparaît.
    expect(find.text('Alerte publiée.'), findsOneWidget);
    expect(find.text('3 Alertes'), findsOneWidget);
    expect(find.text('Don de vetements'), findsOneWidget);
  });

  testWidgets('Poster une alerte : titre ou description vide, ça vibre', (
    tester,
  ) async {
    final alertes = FausseAlertes(initiales: alertesDeDepart());
    await allerALInscription(tester, FausseAuth(), alertes: alertes);
    await sInscrire(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Tout est vide : le titre et la description vibrent, sans message.
    await tester.ensureVisible(find.text("Publier l'alerte"));
    await tester.tap(find.text("Publier l'alerte"));
    await tester.pump();
    expect(
      tester.state<VibrantState>(find.byType(Vibrant).at(0)).enErreur,
      isTrue,
    );
    expect(
      tester.state<VibrantState>(find.byType(Vibrant).at(1)).enErreur,
      isTrue,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(alertes.actions, isEmpty);
    await tester.pumpAndSettle();

    // Titre rempli, description vide : seule la description vibre.
    await tester.enterText(find.byType(TextField).at(0), 'Un titre');
    await tester.tap(find.text("Publier l'alerte"));
    await tester.pump();
    expect(
      tester.state<VibrantState>(find.byType(Vibrant).at(0)).enErreur,
      isFalse,
    );
    expect(
      tester.state<VibrantState>(find.byType(Vibrant).at(1)).enErreur,
      isTrue,
    );
    expect(alertes.actions, isEmpty);
    await tester.pumpAndSettle();
  });

  testWidgets('Poster une alerte : sans position, on explique pourquoi', (
    tester,
  ) async {
    final alertes = FausseAlertes(initiales: alertesDeDepart());
    final position = FausseLocalisation(
      resultat: const ResultatLocalisation(EtatLocalisation.serviceDesactive),
    );
    await allerALInscription(
      tester,
      FausseAuth(),
      alertes: alertes,
      localisation: position,
    );
    await sInscrire(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Au secours');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Une personne a besoin',
    );
    await tester.ensureVisible(find.text("Publier l'alerte"));
    await tester.tap(find.text("Publier l'alerte"));
    await tester.pumpAndSettle();

    expect(alertes.actions, isEmpty);
    expect(
      find.text(
        'Activez la localisation pour publier une alerte près de chez vous.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Mes alertes : mes alertes et celles que j\'aide', (
    tester,
  ) async {
    final mienne = Alerte(
      id: 'm1',
      type: TypeAlerte.don,
      categorie: 'Don de nourriture',
      description: 'Du riz',
      ville: 'Abidjan',
      quartier: 'Cocody',
      auteurId: 'moi',
      auteurNom: 'Ange Fresnel',
      statut: StatutAlerte.resolue,
      creeLe: DateTime.now().subtract(const Duration(hours: 2)),
    );
    final alertes = FausseAlertes(
      initiales: [mienne, ...alertesDeDepart()],
      statistiquesFausses: const StatistiquesProfil(
        alertesPubliees: 3,
        aidesApportees: 1,
        donsEffectues: 2,
        noteMoyenne: 4.5,
        nombreAvis: 2,
      ),
    );
    await allerALInscription(tester, FausseAuth(), alertes: alertes);
    await sInscrire(tester);

    // Le profil montre les vrais chiffres et la vraie note.
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('Ange Fresnel'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('4.5 • 2 avis'), findsOneWidget);

    // « Mes alertes » : seulement les miennes (celles des autres n'y sont pas).
    await tester.tap(find.text('Mes alertes, aides & dons'));
    await tester.pumpAndSettle();
    expect(find.text('Don de nourriture'), findsOneWidget);
    expect(find.text('Résolue'), findsOneWidget);
    expect(find.text('Personne en detresse'), findsNothing);

    // La recherche filtre la liste.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Aucun résultat pour cette recherche.'), findsOneWidget);
  });

  testWidgets('Profil : changer la photo avec la galerie', (tester) async {
    final auth = FausseAuth();
    final photos = FausseSelectionPhoto();
    await allerALInscription(tester, auth, photos: photos);
    await sInscrire(tester);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // Le crayon du profil ouvre la page « Modification », où le crayon de la
    // photo ouvre directement le sélecteur de photos, sans autre choix.
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(find.text('Modification'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(find.text('Prendre une photo'), findsNothing);
    expect(find.text('Choisir dans la galerie'), findsNothing);
    expect(photos.formes, [FormePhoto.carre]);
    expect(auth.photosEnvoyees, hasLength(1));
    expect(find.text('Modification'), findsOneWidget);
  });

  testWidgets("Accueil : la position s'affiche, ou dit quoi faire", (
    tester,
  ) async {
    final position = FausseLocalisation(
      resultat: const ResultatLocalisation(EtatLocalisation.permissionBloquee),
    );
    await allerALInscription(tester, FausseAuth(), localisation: position);
    await remplirInscription(tester);
    await tester.tap(find.byType(CaseACocher));
    await tester.tap(find.text("S'inscrire").last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pumpAndSettle();

    // L'autorisation est bloquée : l'en-tête le dit.
    expect(find.text('Autorisez la localisation'), findsOneWidget);
    expect(find.text('Appuyez ici pour réessayer'), findsOneWidget);

    // L'utilisateur autorise, puis appuie : les réglages s'ouvrent et la
    // position est recherchée de nouveau.
    position.resultat = const ResultatLocalisation(
      EtatLocalisation.ok,
      LieuActuel(ville: 'Abidjan', quartier: 'Cocody'),
    );
    await tester.tap(find.text('Autorisez la localisation'));
    await tester.pumpAndSettle();
    expect(position.reglagesOuverts, [EtatLocalisation.permissionBloquee]);
    expect(position.recherches, 2);
    expect(find.text('Abidjan, Cocody'), findsOneWidget);
    expect(find.text('Restez informé, restez en securité'), findsOneWidget);
  });

  testWidgets('Onglets : Message, Profil et bouton +', (tester) async {
    await allerALInscription(tester, FausseAuth());
    await sInscrire(tester);

    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(find.text('Messagerie'), findsOneWidget);
    expect(
      find.textContaining("Aucune conversation pour l'instant."),
      findsOneWidget,
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Mon profil'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Poster une alerte'), findsOneWidget);
  });

  testWidgets("Suivi : écrire l'avancement et l'envoyer", (tester) async {
    final alertes = FausseAlertes(initiales: alertesDeDepart());
    await allerALInscription(tester, FausseAuth(), alertes: alertes);
    await sInscrire(tester);

    // J'accepte d'aider : le suivi s'ouvre avec son champ d'avancement.
    await tester.tap(find.text('Personne en detresse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je peux aider'));
    await avancer(tester);
    expect(find.text('Timeline'), findsOneWidget);

    // Champ vide : il vibre et clignote, rien n'est envoyé.
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(tester.state<VibrantState>(find.byType(Vibrant)).enErreur, isTrue);
    expect(alertes.actions, ['accepter:a1']);
    await avancer(tester);

    // J'écris l'avancement et j'envoie : il est enregistré, apparaît dans
    // la timeline avec mon nom, et le champ se vide.
    await tester.enterText(find.byType(TextField), 'Je suis en route');
    await tester.tap(find.byIcon(Icons.send));
    await avancer(tester);
    expect(alertes.actions, ['accepter:a1', 'progression:a1:Je suis en route']);
    expect(find.text('Vous : Je suis en route'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );

    // Un deuxième message s'ajoute à la suite.
    await tester.enterText(find.byType(TextField), 'Je suis arrive');
    await tester.tap(find.byIcon(Icons.send));
    await avancer(tester);
    expect(find.text('Vous : Je suis arrive'), findsOneWidget);
    expect(find.text('Vous : Je suis en route'), findsOneWidget);
  });

  testWidgets('Poster une alerte : la photo est coupée en paysage et publiée', (
    tester,
  ) async {
    final alertes = FausseAlertes(initiales: alertesDeDepart());
    final photos = FausseSelectionPhoto();
    await allerALInscription(
      tester,
      FausseAuth(),
      alertes: alertes,
      photos: photos,
    );
    await sInscrire(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Pas de photo : la zone en pointillés propose d'en prendre une.
    await tester.ensureVisible(find.text('Appuyer pour prendre une photo'));
    expect(find.text('Appuyer pour prendre une photo'), findsOneWidget);
    await tester.tap(find.text('Appuyer pour prendre une photo'));
    await tester.pumpAndSettle();

    // La photo est demandée en paysage (2 pour 1), et un aperçu apparaît.
    expect(photos.formes, [FormePhoto.paysage]);
    expect(find.text('Appuyer pour prendre une photo'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // On peut la retirer, puis en remettre une.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Appuyer pour prendre une photo'), findsOneWidget);
    await tester.tap(find.text('Appuyer pour prendre une photo'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);

    // La photo part avec l'alerte.
    await tester.enterText(find.byType(TextField).at(0), 'Une photo');
    await tester.enterText(find.byType(TextField).at(1), 'Regardez la photo');
    await tester.ensureVisible(find.text("Publier l'alerte"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Publier l'alerte"));
    await tester.pumpAndSettle();
    expect(alertes.publiees.single.photo, isNotNull);
  });

  final kouassi = const Contact(
    id: 'kouassi',
    nom: 'Oncle Kouassi',
    telephone: '0707070707',
  );

  testWidgets('Contacts : ajouter quelqu\'un par son numéro', (tester) async {
    final messagerie = FausseMessagerie(
      comptes: {
        '0707070707': kouassi,
        'kouassi@exemple.ci': kouassi,
        '0102030405': const Contact(id: 'moi', nom: 'Ange Fresnel'),
      },
    );
    final carnet = FausseCarnet();
    await allerALInscription(
      tester,
      FausseAuth(),
      messagerie: messagerie,
      carnet: carnet,
    );
    await sInscrire(tester);

    // La messagerie est vide, avec un message qui dit quoi faire.
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining("Aucune conversation pour l'instant."),
      findsOneWidget,
    );

    // Le bouton en bas ouvre « Nouvelle conversation », sans contact.
    await tester.tap(find.byIcon(Icons.forum));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle conversation'), findsOneWidget);
    expect(
      find.textContaining("Aucun de vos contacts n'est encore sur StarPole."),
      findsOneWidget,
    );

    // Ajouter un contact : prénom et numéro vides, ils vibrent sans message.
    await tester.tap(find.byIcon(Icons.person_add_alt_1));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter un contact'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    ChampTexteState champ(int i) =>
        tester.state<ChampTexteState>(find.byType(ChampTexte).at(i));
    expect(champ(0).enErreur, isTrue); // prénom
    expect(champ(1).enErreur, isFalse); // nom : facultatif
    expect(champ(2).enErreur, isTrue); // numéro
    expect(find.byType(SnackBar), findsNothing);
    await tester.pumpAndSettle();

    // Un numéro trop court.
    final saisies = find.byType(TextField);
    await tester.enterText(saisies.at(0), 'Inconnu');
    await tester.enterText(saisies.at(2), '0707');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(champ(2).enErreur, isTrue);
    expect(champ(0).enErreur, isFalse);
    await tester.pumpAndSettle();

    // Un numéro que personne n'a : on propose d'inviter.
    await tester.enterText(saisies.at(2), '0100000000');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.textContaining("pas encore sur StarPole"), findsOneWidget);
    expect(find.text('Inviter sur StarPole'), findsOneWidget);
    expect(carnet.enregistres, isEmpty); // le bouton était éteint

    // Mon propre numéro.
    await tester.enterText(saisies.at(2), '01 02 03 04 05');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text("C'est votre propre compte."), findsOneWidget);

    // Le numéro de quelqu'un, avec l'indicatif, et « synchroniser » allumé :
    // le contact va dans le téléphone et dans mes contacts StarPole.
    await tester.enterText(saisies.at(0), 'Papa');
    await tester.enterText(saisies.at(1), 'Kouassi');
    await tester.enterText(saisies.at(2), '+225 07 07 07 07 07');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(carnet.enregistres, ['Papa|Kouassi|+225 07 07 07 07 07']);
    expect(messagerie.actions.where((a) => a.startsWith('ajouter:')), [
      'ajouter:kouassi',
    ]);
    expect(
      find.text('Papa Kouassi a été ajouté à vos contacts.'),
      findsOneWidget,
    );
    // Retour à la liste, où il apparaît sous le nom tapé.
    expect(find.text('Nouvelle conversation'), findsOneWidget);
    expect(find.text('Papa Kouassi'), findsOneWidget);
  });

  testWidgets('Contacts : enregistrement dans le téléphone refusé', (
    tester,
  ) async {
    final messagerie = FausseMessagerie(comptes: {'0707070707': kouassi});
    final carnet = FausseCarnet()..etatEnregistrement = EtatCarnet.refuse;
    await allerALInscription(
      tester,
      FausseAuth(),
      messagerie: messagerie,
      carnet: carnet,
    );
    await sInscrire(tester);
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.forum));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_add_alt_1));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Papa');
    await tester.enterText(find.byType(TextField).at(2), '0707070707');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    // Le contact StarPole est ajouté, mais le téléphone n'a rien reçu.
    expect(carnet.enregistres, isEmpty);
    expect(messagerie.actions, contains('ajouter:kouassi'));
    expect(find.textContaining("n'a pas été enregistré"), findsOneWidget);
  });

  testWidgets('Conversation : envoyer ma localisation et une photo', (
    tester,
  ) async {
    final messagerie = FausseMessagerie(contacts: [kouassi]);
    final photos = FausseSelectionPhoto();
    await allerALInscription(
      tester,
      FausseAuth(),
      messagerie: messagerie,
      photos: photos,
    );
    await sInscrire(tester);
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.forum));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oncle Kouassi'));
    await tester.pumpAndSettle();

    // « Localisation » envoie ma vraie position, avec le nom du lieu.
    await tester.tap(find.text('Localisation'));
    await tester.pumpAndSettle();
    expect(
      messagerie.actions,
      contains('message:c_kouassi:Ma localisation : Abidjan, Plateau'),
    );
    expect(messagerie.actions, contains('position:c_kouassi:5.3197'));
    expect(find.text('Ma localisation : Abidjan, Plateau'), findsOneWidget);

    // « Photo » propose la caméra ou la galerie, puis envoie la photo.
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    expect(photos.formes, [FormePhoto.paysage]);
    expect(messagerie.actions, contains('photo:c_kouassi'));
  });

  testWidgets('Détails : « Partager » ouvre le partage avec le texte', (
    tester,
  ) async {
    final partages = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (appel) async {
        partages.add(appel.arguments.toString());
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        null,
      ),
    );
    await allerALInscription(tester, FausseAuth());
    await sInscrire(tester);

    await tester.tap(find.text('Personne en detresse'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Partager'));
    await tester.tap(find.text('Partager'));
    await tester.pumpAndSettle();

    expect(partages, hasLength(1));
    expect(partages.single, contains('Alerte StarPole : Personne en detresse'));
    expect(partages.single, contains('Une personne agee est perdue'));
    expect(partages.single, contains('Treichville'));
  });

  testWidgets('Carte : toucher un repère choisit l\'alerte', (tester) async {
    final alertes = [
      Alerte(
        id: 'u1',
        type: TypeAlerte.urgence,
        categorie: 'Accident grave',
        description: 'Une voiture a percute un mur.',
        ville: 'Abidjan',
        latitude: 5.32,
        longitude: -4.01,
        auteurId: 'kouadio',
        auteurNom: 'Kouadio Eliezer',
        creeLe: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Alerte(
        id: 's1',
        type: TypeAlerte.service,
        categorie: 'Objet perdu',
        description: 'Un sac noir.',
        ville: 'Abidjan',
        latitude: 5.33,
        longitude: -4.02,
        auteurId: 'mariam',
        auteurNom: 'Mariam',
        creeLe: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
      // Sans position : elle n'a pas de repère sur la carte.
      Alerte(
        id: 'x1',
        type: TypeAlerte.don,
        categorie: 'Don sans lieu',
        description: 'Pas de position.',
        ville: 'Abidjan',
        auteurId: 'yves',
        auteurNom: 'Yves',
        creeLe: DateTime.now(),
      ),
    ];
    await allerALInscription(
      tester,
      FausseAuth(),
      alertes: FausseAlertes(initiales: alertes),
    );
    await sInscrire(tester);
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    // Un repère par alerte qui a une position, et la fiche de la première.
    expect(find.byKey(const ValueKey('repere_u1')), findsOneWidget);
    expect(find.byKey(const ValueKey('repere_s1')), findsOneWidget);
    expect(find.byKey(const ValueKey('repere_x1')), findsNothing);
    expect(find.text('Accident grave'), findsOneWidget);

    // Toucher l'autre repère change la fiche.
    await tester.tap(find.byKey(const ValueKey('repere_s1')));
    await tester.pumpAndSettle();
    expect(find.text('Objet perdu'), findsOneWidget);
    expect(find.text('Accident grave'), findsNothing);
  });

  test('Carte : ce qui est envoyé à la page 3D', () {
    final donnees = DonneesCarte(
      alertes: [
        Alerte(
          id: 'u1',
          type: TypeAlerte.urgence,
          categorie: 'Accident',
          description: 'x',
          ville: 'Abidjan',
          latitude: 5.32,
          longitude: -4.01,
          auteurId: 'a',
          auteurNom: 'A',
          creeLe: DateTime(2026),
        ),
        Alerte(
          id: 'd1',
          type: TypeAlerte.don,
          categorie: 'Riz',
          description: 'x',
          ville: 'Abidjan',
          latitude: 5.33,
          longitude: -4.02,
          auteurId: 'b',
          auteurNom: 'B',
          creeLe: DateTime(2026),
        ),
        // Sans position : n'est pas envoyée.
        Alerte(
          id: 'z',
          type: TypeAlerte.service,
          categorie: 'Sans lieu',
          description: 'x',
          ville: 'Abidjan',
          auteurId: 'c',
          auteurNom: 'C',
          creeLe: DateTime(2026),
        ),
      ],
      choisieId: 'd1',
      auChoix: (_) {},
      hautEntete: 100,
      basFiche: 235,
      latitude: 5.3197,
      longitude: -4.0167,
    );

    final json = donnees.versJson();
    expect(json['haut'], 100);
    expect(json['bas'], 235);
    expect(json['moi'], {'lat': 5.3197, 'lng': -4.0167});
    final liste = json['alertes'] as List;
    expect(liste, hasLength(2));
    expect(liste[0]['id'], 'u1');
    expect(liste[0]['urgence'], isTrue);
    expect(liste[0]['choisie'], isFalse);
    expect(liste[1]['id'], 'd1');
    expect(liste[1]['choisie'], isTrue);
    expect(liste[1]['urgence'], isFalse);
    // Les couleurs sont au format « #RRGGBB ».
    expect(liste[0]['couleur'], matches(RegExp(r'^#[0-9a-f]{6}$')));
    expect(liste[0]['couleur'], isNot(liste[1]['couleur']));
    // Sans position, « moi » est vide.
    final sans = DonneesCarte(
      alertes: const [],
      choisieId: null,
      auChoix: (_) {},
      hautEntete: 0,
      basFiche: 0,
    );
    expect(sans.versJson()['moi'], isNull);
  });

  testWidgets('Carte : le filtre ne garde que le type choisi', (tester) async {
    final avecPosition = [
      Alerte(
        id: 'u1',
        type: TypeAlerte.urgence,
        categorie: 'Accident grave',
        description: 'Une voiture a percute un mur.',
        ville: 'Abidjan',
        latitude: 5.32,
        longitude: -4.01,
        auteurId: 'kouadio',
        auteurNom: 'Kouadio Eliezer',
        creeLe: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Alerte(
        id: 'd1',
        type: TypeAlerte.don,
        categorie: 'Don de riz',
        description: 'Un sac de riz a donner.',
        ville: 'Abidjan',
        latitude: 5.33,
        longitude: -4.02,
        auteurId: 'mariam',
        auteurNom: 'Mariam',
        creeLe: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
    ];
    await allerALInscription(
      tester,
      FausseAuth(),
      alertes: FausseAlertes(initiales: avecPosition),
    );
    await sInscrire(tester);
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    // Sans filtre, la fiche montre l'alerte la plus récente.
    expect(find.text('Accident grave'), findsOneWidget);

    // Je ne garde que les dons.
    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Filtrer les alertes'), findsOneWidget);
    await tester.tap(find.text('Dons'));
    await tester.pumpAndSettle();
    expect(find.text('Don de riz'), findsOneWidget);
    expect(find.text('Accident grave'), findsNothing);

    // Un type sans alerte : la fiche le dit. Puis je reprends tout.
    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();
    // Le filtre actif se voit : l'icône devient bleue pour les services.
    expect(
      tester.widget<Icon>(find.byIcon(Icons.filter_alt_outlined)).color,
      Couleurs.tuileService,
    );
    expect(find.text('Don de riz'), findsNothing);
    expect(
      find.text("Aucune alerte avec une position pour l'instant."),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toutes les alertes'));
    await tester.pumpAndSettle();
    expect(find.text('Accident grave'), findsOneWidget);
  });

  testWidgets('Profil : le rouage ouvre les Paramètres, pas la modification', (
    tester,
  ) async {
    final auth = FausseAuth();
    await allerALInscription(tester, auth);
    await sInscrire(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Modification'), findsNothing);

    // Les textes légaux s'ouvrent.
    await tester.tap(find.text('Politique de confidentialité'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1. Qui est responsable'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Conditions d'utilisation"));
    await tester.pumpAndSettle();
    expect(find.textContaining('1. À quoi sert StarPole'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    // Se déconnecter : confirmation, puis retour à la connexion.
    await tester.ensureVisible(find.text('Se déconnecter'));
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(auth.appels, isNot(contains('deconnecter')));
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se déconnecter').last);
    await tester.pumpAndSettle();
    expect(auth.appels, contains('deconnecter'));
    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets("Inscription : les conditions et la confidentialité s'ouvrent", (
    tester,
  ) async {
    await allerALInscription(tester, FausseAuth());

    Future<void> toucherLien(String texte) async {
      final finder = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains("J'accepte les"),
      );
      final riche = tester.widget<RichText>(finder);
      TapGestureRecognizer? lien;
      riche.text.visitChildren((span) {
        if (span is TextSpan && span.text == texte) {
          lien = span.recognizer as TapGestureRecognizer?;
        }
        return true;
      });
      expect(lien, isNotNull, reason: 'le lien « $texte » doit être cliquable');
      lien!.onTap!();
      await tester.pumpAndSettle();
    }

    await toucherLien("conditions d'utilisation");
    expect(find.textContaining('1. À quoi sert StarPole'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    await toucherLien('politique de confidentialité');
    expect(find.textContaining('1. Qui est responsable'), findsOneWidget);
  });

  testWidgets(
    'Profil : la photo change la photo, le crayon ouvre Modification',
    (tester) async {
      final auth = FausseAuth();
      final photos = FausseSelectionPhoto();
      await allerALInscription(tester, auth, photos: photos);
      await sInscrire(tester);
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      // Un appui sur la photo ouvre le sélecteur de photos et l'enregistre,
      // sans ouvrir la page de modification.
      await tester.tap(find.byType(ClipOval).first);
      await tester.pumpAndSettle();
      expect(photos.formes, [FormePhoto.carre]);
      expect(auth.photosEnvoyees, hasLength(1));
      expect(find.text('Modification'), findsNothing);
      expect(find.text('Mon profil'), findsOneWidget);

      // Le crayon ouvre la page de modification, sans changer la photo.
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      expect(find.text('Modification'), findsOneWidget);
      expect(auth.photosEnvoyees, hasLength(1));
    },
  );

  testWidgets('Modification : une seule opération suffit pour valider', (
    tester,
  ) async {
    final auth = FausseAuth();
    final photos = FausseSelectionPhoto();
    await allerALInscription(tester, auth, photos: photos);
    await sInscrire(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // Seul le nom est rempli : le numéro peut rester vide.
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Autre Nom');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(auth.appels, contains('modifier:Autre Nom:null'));
    expect(find.text('Modification'), findsNothing);
    expect(find.text('Profil mis à jour.'), findsOneWidget);

    // La photo est changée : « Valider » sans rien écrire ferme la page, sans
    // faire vibrer les champs.
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(auth.photosEnvoyees, hasLength(1));
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Modification'), findsNothing);
    expect(find.text('Mon profil'), findsOneWidget);
  });

  testWidgets('Messagerie : la bannière demande le numéro tant qu\'il manque', (
    tester,
  ) async {
    final auth = FausseAuth()..telephone = '';
    await allerALInscription(tester, auth);
    await sInscrire(tester);

    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Entrez votre numéro de téléphone pour être visible par vos contacts.',
      ),
      findsOneWidget,
    );

    // Un numéro vide ou trop court fait vibrer le champ, rien n'est enregistré.
    await tester.tap(find.text('Ajouter mon numéro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(
      tester.state<ChampTexteState>(find.byType(ChampTexte).last).enErreur,
      isTrue,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '0707');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(
      tester.state<ChampTexteState>(find.byType(ChampTexte).last).enErreur,
      isTrue,
    );
    expect(auth.appels.where((a) => a.startsWith('modifier')), isEmpty);
    await tester.pumpAndSettle();

    // Un vrai numéro : enregistré, la bannière disparaît.
    await tester.enterText(find.byType(TextField).last, '07 07 07 07 07');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(auth.appels, contains('modifier:null:07 07 07 07 07'));
    expect(find.text('Ajouter mon numéro'), findsNothing);
    expect(find.textContaining('Numéro enregistré'), findsOneWidget);
  });

  testWidgets('Messagerie : pas de bannière quand le numéro est connu', (
    tester,
  ) async {
    await allerALInscription(tester, FausseAuth());
    await sInscrire(tester);
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter mon numéro'), findsNothing);
  });

  testWidgets('Profil : page Modification (nom et numéro)', (tester) async {
    final auth = FausseAuth();
    await allerALInscription(tester, auth);
    await sInscrire(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // Le crayon ouvre la page ; les champs blancs montrent les valeurs actuelles.
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(find.text('Modification'), findsOneWidget);
    expect(find.text('Ange Fresnel'), findsOneWidget);
    expect(find.text('0700000000'), findsOneWidget);

    // Rien de saisi : les deux champs gris vibrent, rien n'est enregistré.
    await tester.tap(find.text('Valider'));
    await tester.pump();
    for (final i in [1, 3]) {
      final champ = tester.state<ChampTexteState>(
        find.byType(ChampTexte).at(i),
      );
      expect(champ.enErreur, isTrue);
    }
    expect(find.byType(SnackBar), findsNothing);
    await tester.pumpAndSettle();

    // Un numéro trop court vibre.
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(3), '123');
    await tester.tap(find.text('Valider'));
    await tester.pump();
    expect(
      tester.state<ChampTexteState>(find.byType(ChampTexte).at(3)).enErreur,
      isTrue,
    );
    expect(auth.appels.where((a) => a.startsWith('modifier')), isEmpty);
    await tester.pumpAndSettle();

    // Nom et numéro valides : enregistrés, retour au profil.
    await tester.enterText(champs.at(1), 'Nouveau Nom');
    await tester.enterText(champs.at(3), '05 05 05 05 05');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(auth.appels, contains('modifier:Nouveau Nom:05 05 05 05 05'));
    expect(find.text('Modification'), findsNothing);
    expect(find.text('Profil mis à jour.'), findsOneWidget);
  });

  testWidgets('Appel : lancer un appel vidéo puis raccrocher', (tester) async {
    final messagerie = FausseMessagerie(contacts: [kouassi]);
    final appels = FausseAppel();
    await allerALInscription(
      tester,
      FausseAuth(),
      messagerie: messagerie,
      appels: appels,
    );
    await sInscrire(tester);
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.forum));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oncle Kouassi'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.videocam_outlined));
    await tester.pumpAndSettle();
    expect(appels.actions, ['appeler:kouassi:video']);
    expect(find.text('Appel en cours...'), findsOneWidget);

    // L'autre décroche : la durée s'affiche.
    appels.derniere.etatInterne.value = EtatAppel.enCours;
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:02'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pumpAndSettle();
    expect(appels.derniere.raccroche, isTrue);
    expect(find.text('Dites bonjour à Oncle Kouassi.'), findsOneWidget);
  });

  testWidgets('Appel : un appel entrant, répondre puis refuser un autre', (
    tester,
  ) async {
    final appels = FausseAppel();
    await allerALInscription(tester, FausseAuth(), appels: appels);
    await sInscrire(tester);

    appels.entrants.add(
      const AppelEntrant(
        id: 'a1',
        appelantId: 'kouassi',
        appelantNom: 'Oncle Kouassi',
        video: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Oncle Kouassi'), findsOneWidget);
    expect(find.text('Appel vocal StarPole'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Répondre'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(appels.actions, ['repondre:a1']);
    expect(find.text('Raccrocher'), findsNothing);
    expect(find.byIcon(Icons.call_end), findsOneWidget);
    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.call_end), findsNothing);

    // Un second appel est refusé.
    appels.entrants.add(
      const AppelEntrant(
        id: 'a2',
        appelantId: 'kouassi',
        appelantNom: 'Oncle Kouassi',
        video: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Appel vidéo StarPole'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pumpAndSettle();
    expect(appels.actions, ['repondre:a1', 'refuser:a2']);
    expect(find.text('Appel vidéo StarPole'), findsNothing);
  });

  testWidgets('Messagerie : écrire à un contact et le voir dans la liste', (
    tester,
  ) async {
    final messagerie = FausseMessagerie(contacts: [kouassi]);
    await allerALInscription(tester, FausseAuth(), messagerie: messagerie);
    await sInscrire(tester);

    // Message, bouton en bas, puis le contact : la conversation s'ouvre.
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.forum));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oncle Kouassi'));
    await tester.pumpAndSettle();
    expect(messagerie.actions, contains('ouvrir:kouassi'));
    expect(find.text('Dites bonjour à Oncle Kouassi.'), findsOneWidget);

    // Un message vide fait vibrer la zone, sans rien envoyer.
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(tester.state<VibrantState>(find.byType(Vibrant)).enErreur, isTrue);
    expect(messagerie.actions.where((a) => a.startsWith('message:')), isEmpty);
    await tester.pumpAndSettle();

    // J'écris : le message apparaît et le champ se vide.
    await tester.enterText(find.byType(TextField), 'Bonjour Kouassi');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(messagerie.actions, contains('message:c_kouassi:Bonjour Kouassi'));
    expect(find.text('Bonjour Kouassi'), findsOneWidget);
    expect(find.text('Dites bonjour à Oncle Kouassi.'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );

    // Retour : la liste des conversations montre ce que j'ai écrit.
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('Messagerie'), findsOneWidget);
    expect(find.text('Oncle Kouassi'), findsOneWidget);
    expect(find.text('Vous : Bonjour Kouassi'), findsOneWidget);
  });

  testWidgets('Messagerie : un message reçu est signalé, puis lu', (
    tester,
  ) async {
    final messagerie = FausseMessagerie(contacts: [kouassi]);
    await allerALInscription(tester, FausseAuth(), messagerie: messagerie);
    await sInscrire(tester);
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('non-lu')), findsNothing);

    // Kouassi m'écrit : la conversation apparaît avec un repère « non lu ».
    messagerie.recevoir(kouassi, 'Tu es là ?');
    await tester.pumpAndSettle();
    expect(find.text('Tu es là ?'), findsOneWidget);
    expect(find.byKey(const ValueKey('non-lu')), findsOneWidget);

    // J'ouvre la conversation : elle est marquée comme lue.
    await tester.tap(find.text('Oncle Kouassi'));
    await tester.pumpAndSettle();
    expect(messagerie.actions, contains('lu:c_kouassi'));
    expect(find.text('Tu es là ?'), findsOneWidget);

    // Il m'écrit encore pendant que la conversation est ouverte.
    messagerie.recevoir(kouassi, 'Réponds-moi');
    await tester.pumpAndSettle();
    expect(find.text('Réponds-moi'), findsOneWidget);

    // Retour à la liste : plus de repère.
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('non-lu')), findsNothing);
  });

  testWidgets('Messagerie : le compte est rendu recherchable au démarrage', (
    tester,
  ) async {
    final auth = FausseAuth();
    await allerALInscription(tester, auth);
    await sInscrire(tester);
    expect(auth.rendusRecherchables, 1);
  });

  /// Un carnet avec trois personnes, dont deux ont StarPole.
  ResultatCarnet carnetDeTest() => const ResultatCarnet(EtatCarnet.ok, [
    EntreeCarnet(nom: 'Papa Kouassi', numeros: ['0707070707']),
    EntreeCarnet(
      nom: 'Mariam Coulibaly',
      numeros: ['0505050505', '0101010101'],
    ),
    EntreeCarnet(nom: 'Le plombier', numeros: ['0808080808']),
  ]);

  Future<void> ouvrirNouvelleConversation(WidgetTester tester) async {
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.forum));
    await tester.pumpAndSettle();
  }

  testWidgets('Contacts : synchronisation automatique avec le téléphone', (
    tester,
  ) async {
    const mariam = Contact(id: 'mariam', nom: 'Mariam Coulibaly');
    const ancien = Contact(id: 'ancien', nom: 'Ancien Contact');
    final messagerie = FausseMessagerie(
      comptes: {
        '0707070707': kouassi,
        '0101010101': mariam, // son 2e numéro dans le carnet
        '0505050505': mariam, // son 1er numéro : même personne
      },
      contacts: [ancien], // ajouté à la main avant
    );
    final carnet = FausseCarnet(carnetDeTest());
    await allerALInscription(
      tester,
      FausseAuth(),
      messagerie: messagerie,
      carnet: carnet,
    );
    await sInscrire(tester);
    await ouvrirNouvelleConversation(tester);

    // Le carnet est lu dès l'ouverture, sans bouton à toucher.
    expect(carnet.lectures, 1);
    expect(find.text('Mes contacts'), findsOneWidget);
    // Seuls les inscrits apparaissent, une seule fois chacun.
    expect(find.text('Oncle Kouassi'), findsOneWidget);
    expect(find.text('Dans votre carnet : Papa Kouassi'), findsOneWidget);
    expect(find.text('Mariam Coulibaly'), findsOneWidget);
    expect(find.text('Ancien Contact'), findsOneWidget);
    expect(find.text('Le plombier'), findsNothing);
    expect(find.textContaining('ne les enregistre pas'), findsOneWidget);
    // Rien n'est enregistré dans la base : pas de « ajouter: ».
    expect(messagerie.actions.where((a) => a.startsWith('ajouter:')), isEmpty);
    // Les numéros du carnet (sans doublon) ont été comparés.
    expect(messagerie.actions.first, 'carnet:4');

    // Un appui sur une personne ouvre la conversation.
    await tester.tap(find.text('Mariam Coulibaly'));
    await tester.pumpAndSettle();
    expect(messagerie.actions, contains('ouvrir:mariam'));
    expect(find.text('Dites bonjour à Mariam Coulibaly.'), findsOneWidget);
  });

  testWidgets('Contacts : accès refusé puis accordé', (tester) async {
    final messagerie = FausseMessagerie(comptes: {'0707070707': kouassi});
    final carnet = FausseCarnet(const ResultatCarnet(EtatCarnet.refuse));
    await allerALInscription(
      tester,
      FausseAuth(),
      messagerie: messagerie,
      carnet: carnet,
    );
    await sInscrire(tester);
    await ouvrirNouvelleConversation(tester);

    expect(carnet.lectures, 1);
    expect(find.textContaining("Sans l'accès à vos contacts"), findsOneWidget);
    expect(messagerie.actions, isEmpty); // rien n'a été envoyé

    // L'utilisateur change d'avis et autorise.
    carnet.resultat = carnetDeTest();
    await tester.tap(find.text('Autoriser'));
    await tester.pumpAndSettle();
    expect(carnet.lectures, 2);
    expect(find.text('Oncle Kouassi'), findsOneWidget);
    expect(find.textContaining("Sans l'accès"), findsNothing);
  });

  testWidgets('Contacts : accès bloqué, ouverture des réglages', (
    tester,
  ) async {
    final carnet = FausseCarnet(const ResultatCarnet(EtatCarnet.bloque));
    await allerALInscription(tester, FausseAuth(), carnet: carnet);
    await sInscrire(tester);
    await ouvrirNouvelleConversation(tester);

    expect(find.textContaining('bloqué'), findsOneWidget);
    await tester.tap(find.text('Ouvrir les réglages'));
    await tester.pumpAndSettle();
    expect(carnet.reglagesOuverts, 1);
  });

  testWidgets("Contacts : personne n'est encore sur StarPole", (tester) async {
    await allerALInscription(
      tester,
      FausseAuth(),
      carnet: FausseCarnet(carnetDeTest()),
    );
    await sInscrire(tester);
    await ouvrirNouvelleConversation(tester);

    expect(
      find.textContaining("Aucun de vos contacts n'est encore sur StarPole."),
      findsOneWidget,
    );
  });
}

/// Fausse carte : un bouton par alerte qui a une position, pour pouvoir
/// « toucher un repère » sans afficher la vraie carte 3D.
Widget carteDeTest(BuildContext context, DonneesCarte donnees) {
  return Column(
    children: [
      for (final a in donnees.alertes)
        TextButton(
          key: ValueKey('repere_${a.id}'),
          onPressed: () => donnees.auChoix(a.id),
          child: Text('repere ${a.categorie}'),
        ),
    ],
  );
}

/// Faux service d'appel : il note ce qui est demandé et laisse le test
/// faire sonner un appel entrant.
class FausseAppel implements ServiceAppel {
  final StreamController<AppelEntrant?> entrants =
      StreamController<AppelEntrant?>.broadcast();
  final List<String> actions = [];
  late FausseSession derniere;

  @override
  Stream<AppelEntrant?> appelsEntrants() => entrants.stream;

  @override
  Future<SessionAppel> appeler(Contact contact, {required bool video}) async {
    actions.add('appeler:${contact.id}:${video ? 'video' : 'voix'}');
    return derniere = FausseSession(video: video);
  }

  @override
  Future<SessionAppel> repondre(AppelEntrant appel) async {
    actions.add('repondre:${appel.id}');
    return derniere = FausseSession(
      video: appel.video,
      etat: EtatAppel.enCours,
    );
  }

  @override
  Future<void> refuser(AppelEntrant appel) async {
    actions.add('refuser:${appel.id}');
  }
}

/// Fausse session d'appel : l'état se change à la main dans les tests.
class FausseSession implements SessionAppel {
  FausseSession({required this.video, EtatAppel etat = EtatAppel.sonne})
    : etatInterne = ValueNotifier(etat);

  @override
  final bool video;
  final ValueNotifier<EtatAppel> etatInterne;
  bool raccroche = false;

  @override
  ValueListenable<EtatAppel> get etat => etatInterne;
  @override
  final ValueNotifier<bool> microCoupe = ValueNotifier(false);
  @override
  final ValueNotifier<bool> cameraCoupee = ValueNotifier(false);
  @override
  final ValueNotifier<bool> hautParleur = ValueNotifier(false);

  @override
  void basculerMicro() => microCoupe.value = !microCoupe.value;
  @override
  void basculerCamera() => cameraCoupee.value = !cameraCoupee.value;
  @override
  void basculerHautParleur() => hautParleur.value = !hautParleur.value;

  @override
  Widget vueDistante() => const SizedBox();
  @override
  Widget vueLocale() => const SizedBox();

  @override
  Future<void> raccrocher() async {
    if (raccroche) return;
    raccroche = true;
    etatInterne.value = EtatAppel.termine;
  }

  @override
  void dispose() {}
}
