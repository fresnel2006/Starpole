# StarPole - contexte du projet pour Claude Code

Lis ce fichier en entier avant chaque tâche. Il décrit le projet, ses règles et la façon de travailler. Les instructions que je te donnerai ensuite s'appuient dessus.

## 1. Qui je suis

- Je m'appelle Fresnel (Ange Fresnel Traoré), étudiant en Licence 3 TWIN à l'ESATIC, à Abidjan (Côte d'Ivoire).
- Je travaille sous Windows, avec Android Studio et Flutter.
- Dans l'équipe, je m'occupe du web design, des interfaces (UI) et de la charte graphique. C'est moi qui développe l'appli.
- Je préfère des échanges simples et directs, en français.

## 2. Le projet

StarPole est une application mobile d'entraide de quartier, géolocalisée, pour Abidjan. Elle réunit dans une seule appli :

- **Alerter** : lancer une alerte d'urgence (malaise, accident, incendie, vol) en un appui, avec sa position, à tous les voisins proches.
- **Demander** : publier une demande d'aide (coup de main, objet, service) visible par les voisins.
- **Donner** : proposer ce qui ne sert plus (vêtements, nourriture, fournitures, meubles) à quelqu'un du quartier.

Positionnement : StarPole **complète** les groupes WhatsApp de quartier, il ne les remplace pas. Par exemple, une alerte doit pouvoir être partagée vers WhatsApp.

Signature : « Une étoile pour ne jamais rester seul. »
Autres messages : « L'aide de votre quartier, à portée de main. », « Chaque alerte compte, chaque geste compte. »

Cadre : projet de groupe (Groupe 7) du TP1 UX Design, encadré par M. Cédric Cissé. Équipe :
- Coulibaly Fatima Halima Hébara : recherche utilisateurs, personas, wireframes ;
- Kouadio Koffi Emmanuel Eliezer : SEO et Analytics ;
- moi : UI, charte graphique, développement.

Calendrier : du 8 septembre au **27 octobre 2026 (soutenance finale)**. L'objectif est un **prototype fonctionnel et démontrable**, testé par un panel d'au moins 15 personnes, avec au moins 80 % de satisfaction.

L'appli **n'est pas encore sortie**. Tout texte ou écran promo doit dire « Bientôt disponible », jamais « Disponible sur le Play Store ».

## 3. Les utilisateurs (personas)

1. **Mariam**, 38 ans, mère de 4 enfants, Adjamé : petit budget, cherche des dons, utilise son téléphone vite, langage simple (parfois nouchi). Besoins : recherche de dons par catégorie, demande simple avec photo, messagerie, avis sur les personnes, alertes quand une offre correspond.
2. **Oncle Kouassi**, 54 ans, commerçant, Yopougon : pas à l'aise avec la technologie. Besoins : bouton d'alerte en un clic, appel direct du voisin qui répond, gros boutons et peu de texte (mode « facile »), voisins dans un rayon très proche.
3. **Aya**, 27 ans, jeune active, Cocody : peu de temps, se méfie des arnaques. Besoins : filtrer par proximité, trajet solidaire, voir le profil et les avis, notifications seulement pour les urgences proches, réponses pré-remplies.
4. **Ibrahim**, 19 ans, étudiant bénévole, Abobo : beaucoup de temps libre. Besoins : missions de bénévolat par quartier, historique des aides, badges et niveaux de confiance, partage sur les réseaux, groupes de quartier.
5. **Yves**, 42 ans, veilleur de nuit : témoin d'incidents. Besoins : signalement géolocalisé, alerte groupée au secteur, carte précise, accusé « vu », mode nuit discret.

## 4. Fonctionnalités, par priorité

**MVP (indispensable pour la soutenance)**
1. Inscription et connexion (téléphone ou e-mail), profil avec quartier.
2. Accueil avec un grand bouton **ALERTE** : il faut le maintenir 2 secondes pour éviter les fausses alertes, puis on choisit le type (malaise, accident, incendie, sécurité, autre).
3. Envoi de l'alerte avec position GPS aux utilisateurs dans un rayon réglable (500 m par défaut), compteur « X voisins prévenus ».
4. Carte du quartier : position de l'alerte, voisins qui répondent, temps d'arrivée estimé (« Awa arrive, 2 min »).
5. Réponse à une alerte (« J'arrive »), appel direct et accusé « vu ».
6. Demandes d'aide : publier (texte et photo), lister par proximité, répondre.
7. Dons : publier, lister par catégorie et proximité, réserver.
8. Notifications push pour les alertes proches.
9. Partage d'une alerte vers WhatsApp.

**Ensuite, si le temps le permet** : messagerie intégrée, avis et notes, badges et niveaux de confiance, mode facile, mode nuit, trajets solidaires, missions de bénévolat, groupes de quartier.

## 5. Stack technique

- **Flutter** (Dart, SDK ^3.13), cible principale Android. Le projet est à `C:\Users\fresnel\StudioProjects\projet_starpole`. Au départ, c'est le projet Flutter par défaut : `lib/main.dart` contient encore le compteur de démo.
- **Firebase** : Authentication, Cloud Firestore, Cloud Messaging (notifications), Storage (photos).
- **Carte** : `flutter_map` avec les tuiles Mapbox (style `mapbox/streets-v12`, palier gratuit de Mapbox ; le jeton public est dans `lib/noyau/cle_mapbox.dart`, privé et dans le `.gitignore`, modèle `cle_mapbox.exemple.dart`), et `geolocator` pour la position.
- **Back-end** : FastAPI seulement si une logique ne peut pas tenir dans Firebase (par exemple un calcul de proximité côté serveur). Sinon, Firestore suffit.
- Contrainte du cahier des charges : **outils gratuits ou open-source uniquement**, rien de payant.
- Données de démo : des quartiers réels d'Abidjan (Treichville, Marcory, Koumassi, Cocody, Yopougon, Adjamé, Abobo, Plateau) et des noms ivoiriens.

Organisation du code (noms en français, pour que Fresnel puisse reprendre la main) :

```
lib/
  main.dart
  application/        thème, couleurs, racine de l'appli
  noyau/              services (auth, localisation, notifications), utilitaires
  fonctionnalites/
    info_departs/     écran des 3 pages de bienvenue
    accueil/
    alerte/           bouton ALERTE, choix du type, envoi, suivi
    carte/
    demandes/
    dons/
    profil/
  partage/composants/ composants réutilisables
```

Pour la gestion d'état, utilise une seule solution simple et cohérente (Provider ou Riverpod). Demande-moi avant d'en changer.

## 6. Charte graphique (à respecter dans toute l'UI)

- **Couleur principale : rouge StarPole `#E3060B`**. Variantes : `#FF2A30` (clair, textes et icônes), `#8A0003` (foncé).
- **Thème sombre** par défaut : fond `#0D0D11`, cartes `#17171D`, bordures `#26262E`, texte `#FFFFFF`, texte secondaire `#9A9AA6`. Accent de succès : vert `#22C55E`, par exemple pour « Awa arrive ».
- **Police : Poppins** (500 à 900). Titres en gras, avec un espacement des lettres légèrement serré.
- Coins arrondis (16 à 30 px), lueur rouge discrète autour du bouton ALERTE, icônes à trait fin.
- Le nom s'écrit « Star » en blanc et « Pole » en rouge. Le logo contient des silhouettes et une étoile : je fournirai le fichier.
- Accueil type : en-tête « StarPole » avec le quartier (« Treichville, Abidjan ») et l'avatar ; au centre, le grand bouton rond ALERTE avec un anneau de progression pendant l'appui ; en bas, trois tuiles Signaler, Demander, Donner.
- Accessibilité : gros boutons, peu de texte, bon contraste (pensé pour Oncle Kouassi).

Règles de style à ne jamais enfreindre :
- **pas d'emojis** dans l'interface ni dans les textes (utilise de vraies icônes) ;
- **pas de tiret long « — »** dans les textes : utilise « - » ou reformule ;
- pas d'orange façon Claude ;
- pas de bordure colorée à gauche des cartes ;
- l'appli ne doit pas avoir l'air générée par une IA : sobre, cohérente, professionnelle.

## 7. Comment travailler avec moi

- **Fais le travail toi-même** : crée les fichiers, lance les commandes (`flutter pub get`, `flutter analyze`, `flutter run`...). Ne me demande pas de taper des commandes à ta place.
- Avant une grosse tâche, donne-moi un **plan court** (3 à 6 étapes), puis avance.
- Pose-moi des questions **seulement si c'est bloquant**, et regroupe-les en un seul message.
- **Vérifie avant de dire que c'est fini** : `flutter analyze` sans erreur, et l'appli qui se lance. Si quelque chose ne marche pas, dis-le clairement au lieu d'annoncer un succès.
- **Fais uniquement ce que je demande, rien de plus.** Pas d'écran, de fonctionnalité ou de dépendance en plus, même si ça semble utile : propose-le d'abord. Quand une maquette ou une liste de widgets imposés est donnée, respecte-la.
- Écris le code comme tu veux (nommage libre). Les textes visibles dans l'appli sont en français.
- Garde le code propre et commenté brièvement, avec des widgets réutilisables plutôt que du copier-coller.
- N'invente pas de fonctionnalité hors de ce fichier sans me demander. Si une idée te semble utile, propose-la.
- Ne mets jamais de clés, mots de passe ou identifiants Firebase en dur dans le code ni dans Git (utilise `firebase_options.dart` généré par FlutterFire et `.gitignore`).
- À la fin de chaque tâche, résume en 2 ou 3 lignes ce qui a changé et ce qui reste à faire.

## 8. État actuel

Écrans faits d'après les maquettes de Fresnel (textes en français, Poppins, widgets `Stack`, `Column`, `Container` et `color`) : infos de départ, inscription, connexion (logo `assets/images/Starpole logo.png`), accueil, carte, poster une alerte, messagerie, profil, détails de l'alerte, suivi (timeline), conversation, mes alertes, noter l'aidant.

**Données réelles (Firebase, projet `starpole-3d84d`, zone Paris)**
- Comptes : un seul champ « Email » (pas de numéro de téléphone : un SMS est payant) et Google (`google_sign_in`). Service : `lib/noyau/service_auth.dart`. Par e-mail, l'inscription et la connexion passent par un code de confirmation à 4 chiffres : le serveur FastAPI (`https://starpole-backend.vercel.app`, dépôt `Starpole_fastapi` sur le bureau, routes `/auth/demander-code` et `/auth/verifier-code`) envoie le code par e-mail, puis renvoie un jeton qui ouvre la session Firebase (`signInWithCustomToken`). L'écran du code est `lib/fonctionnalites/otp/ecran_code_otp.dart` (cases, vérification automatique au 4e chiffre, mauvais code qui fait vibrer, renvoi après 1 minute). Le numéro de téléphone ne sert pas à se connecter : on l'ajoute ensuite (bannière de l'onglet Message, ou page Modification) pour être retrouvé par ses contacts. La connexion avec Google n'a JAMAIS de code (Google a déjà vérifié l'e-mail). L'ancien mode démonstration sans code a été supprimé. La page `/sante` du serveur dit si ses 7 variables d'environnement sont bien configurées.
- Animation d ouverture : `lib/fonctionnalites/ouverture/ecran_ouverture.dart` (3,4 s, fond blanc) : l etoile dessinee en code pousse branche par branche en tournant, s illumine avec deux ondes, monte, puis StarPole apparait lettre par lettre (Star noir, Pole rouge), un trait rouge et la signature ; fondu vers la bienvenue ou l accueil, un appui passe l animation. L ecran de lancement Android a le meme fond (launch_background.xml). Desactivee dans les tests (`animationOuverture: false`).
- Profil : collection `utilisateurs` (nom, téléphone, e-mail, photo en base64). Photo de profil modifiable (caméra ou galerie). Dans l'onglet Profil, toucher la photo permet de la changer (sélecteur de photos), et le crayon de la photo ouvre la page « Modification » (`lib/fonctionnalites/profil/ecran_modification.dart`) : photo, nouveau nom et nouveau numéro enregistrés par `modifierProfil` ; le bouton « Changer d'Email » explique seulement que l'e-mail est lié au compte.
- Carte des alertes en 3D : l'onglet Carte (`lib/fonctionnalites/carte/ecran_carte.dart`) affiche Mapbox GL JS dans une page web intégrée (`assets/carte/carte_3d.html`, widget `lib/partage/composants/carte_3d.dart`, paquet `webview_flutter`) : style Mapbox « Standard » incliné, bâtiments en 3D, ma position en point bleu, et les alertes en repères colorés (les urgences pulsent) qu'on touche pour choisir l'alerte. Il n'utilise que le jeton public. Le logo Mapbox est masqué à la demande de Fresnel (règle `.mapboxgl-ctrl-logo` dans le HTML, contraire aux conditions de Mapbox : à retirer si le jeton est suspendu) ; le « i » des crédits reste. Elle a besoin d'Internet (message et bouton « Réessayer » sinon). Dans les tests, une fausse carte remplace la vraie (`ConstructeurCarte`).
- Cartes miniatures (position dans « Poster une alerte », position envoyée dans un message) : `flutter_map` avec la même couche `tuilesCarte` de `lib/partage/composants/couche_tuiles.dart`, avec la mention « © Mapbox © OpenStreetMap ». Pour changer le style de carte, modifier `styleCarte` dans ce fichier.
- Position : `lib/noyau/service_localisation.dart` (geolocator et geocoding), quartier d'Abidjan le plus proche avec `lib/noyau/quartiers.dart`, mémorisée dans `PositionUtilisateur`.
- Choix d'une photo : un seul appui ouvre le sélecteur de photos du téléphone (`image_picker`, Android Photo Picker), sans demande d'autorisation et sans feuille « caméra ou galerie ».
- Photos : `lib/noyau/traitement_photo.dart` redresse la photo (orientation du téléphone), la coupe autour de son centre (carré 400 px pour le profil, rectangle 2 pour 1 de 640 px pour une alerte) et l'enregistre en JPEG léger (paquet `image`). Ce qui est enregistré est exactement ce qui est affiché.
- Le rouage de l'onglet Profil ouvre « Paramètres » (`lib/fonctionnalites/parametres/ecran_parametres.dart`) : autorisations de l'appli (réglages du téléphone), conditions d'utilisation et politique de confidentialité (`lib/fonctionnalites/legal/`, texte dans `textes_legaux.dart`, aussi ouverts par les liens de la case de l'inscription), à propos et déconnexion. Les conditions et la confidentialité doivent être acceptées (case de l'inscription) pour s'inscrire par e-mail ET pour « Continuer avec Google » sur la page d'inscription. Les textes légaux sont un brouillon à relire par l'équipe : il manque une adresse de contact.
- Photo d une alerte : enregistree ENTIERE (`FormePhoto.entiere`, plus grand cote 900 px, JPEG sous 200 Ko), jamais coupee. Les cartes de la liste la coupent en 2 pour 1 a l affichage ; les details de l alerte la montrent en entier. Les alertes publiees avant ce changement ont encore leur photo coupee.
- Poster une alerte (`lib/fonctionnalites/poster_alerte/`) : d'après la maquette, tuiles Urgence, Dons, Services, un titre (enregistré dans le champ `categorie`, qui sert de titre partout), une description, la position sur une mini carte et une photo en 2 pour 1, OBLIGATOIRE (sans photo, la zone vibre et l'alerte n'est pas publiée). L'image `assets/images/carte_cote_d_ivoire.png` illustre l'en-tête.
- Accueil, tri par categorie : le bouton Categories affiche trois tuiles (urgences, aides, dons) qui filtrent la liste des alertes a proximite ; toucher la tuile choisie ou refermer les tuiles enleve le tri.
- Alertes : collection `alertes` (urgence, don, service). Service : `lib/noyau/service_alertes.dart`. Poster une alerte enregistre vraiment ; l'accueil, la carte, « Mes alertes » et le suivi lisent la base en direct ; « Je peux aider », « Terminé » et « Stopper » mettent l'alerte à jour ; le bandeau « Alerte en cours » vient de la base.
- Seul l auteur d une alerte peut la terminer (bouton Terminé du suivi et règle Firestore). La personne qui aide garde Stopper : une confirmation precise que seule son aide s arrete, un message "J arrete d aider" est ajoute au suivi, et l alerte redevient libre pour les autres. Le Stopper de l auteur ferme l alerte pour tout le monde (confirmation aussi).
- Progression : sous-collection `alertes/{id}/progression` (messages d'avancement, « Je suis en route »). L'auteur et la personne qui aide les écrivent depuis le suivi, et ils s'affichent dans la timeline en direct.
- Numéro de téléphone : sans numéro dans son profil, on ne peut pas être retrouvé par ses contacts (la recherche se fait par numéro). L'onglet Message affiche donc une bannière « Entrez votre numéro de téléphone pour être visible par vos contacts » avec un bouton « Ajouter mon numéro » (feuille du bas, enregistre par `modifierProfil`), tant que le profil n'a pas de numéro. Le numéro n'est pas vérifié par SMS (payant).
- Contacts et messagerie : service `lib/noyau/service_messagerie.dart`. On ajoute un contact en tapant son numéro de téléphone ou son e-mail (champs `telephoneNormalise` et `emailNormalise` du profil, voir `lib/noyau/normalisation.dart`) ; ses contacts sont dans `utilisateurs/{uid}/contacts`. Les conversations sont dans `conversations/{uidA_uidB}` (identifiants triés) avec une sous-collection `messages`. Un repère « non lu » se base sur le champ `lu` de la conversation. La page « Nouvelle conversation » (`lib/fonctionnalites/messagerie/ecran_contacts.dart`) demande l'accès aux contacts du téléphone dès l'ouverture et montre ceux qui ont StarPole, sans les enregistrer : `lib/noyau/service_carnet.dart` (paquet `flutter_contacts`, permission `READ_CONTACTS`) lit le carnet, puis `trouverParTelephones` compare les numéros avec ceux des inscrits, par paquets de 30. Les contacts ajoutés à la main (icône en haut à droite : formulaire prénom, nom et numéro, `ecran_ajouter_contact.dart`) sont ajoutés à la liste si le numéro a un compte StarPole, et peuvent aussi être enregistrés dans le carnet du téléphone (interrupteur « Synchroniser », permission `WRITE_CONTACTS`, `ServiceCarnet.enregistrer`). Si la personne n'est pas inscrite, un bouton « Inviter sur StarPole » ouvre le partage du téléphone (`lib/noyau/invitation.dart`, paquet `share_plus`). La recherche d'un profil est limitée à 30 résultats par les règles (on ne peut pas télécharger tous les profils).
- Notifications de messages : `lib/noyau/service_notifications.dart` (paquet `firebase_messaging`). À l'ouverture de l'accueil, l'appli demande l'autorisation et enregistre le jeton du téléphone dans `utilisateurs/{uid}/appareils/{jeton}` (retiré à la déconnexion). Après chaque message envoyé, `service_messagerie.dart` prévient le serveur (`/notifications/message`, jeton Firebase en `Authorization: Bearer`, via `lib/noyau/serveur_starpole.dart`). Appli ouverte, la notification du telephone est affichee par `flutter_local_notifications` (canal `messages`, importance haute, sauf pour la conversation deja affichee) ; appli fermee, Android l affiche seul (canal par defaut declare dans le manifeste). Toucher la notification ouvre la conversation. Appels en notification (comme WhatsApp) : en lancant un appel, `service_appel.dart` previent le serveur (`/notifications/appel`, message de donnees en priorite haute). Appli fermee ou en arriere-plan, `gestionnaireMessageArrierePlan` (`lib/noyau/notification_appel.dart`, enregistre dans `main.dart`) affiche une notification d appel : canal `appels`, sonnerie du telephone repetee, plein ecran si permis, boutons Refuser (refuse dans Firestore sans ouvrir l appli) et Repondre (ouvre l appli et decroche tout seul via `appelARepondre`), disparition apres 45 s. Appli ouverte, l ecran d appel entrant sonne lui-meme et retire la notification. Pas encore de notification pour les alertes.
- Messagerie, réponse et modification : glisser un message vers la droite (ou appui long, puis Répondre) cite ce message dans la réponse (champs `reponseTexte` et `reponseAuteurId`). Appui long sur un de ses propres messages texte, puis Modifier : seul le texte change, avec `modifie: true` (mention « Modifié »). Règles dans `firestore.rules`, service `modifierMessage`.
- Coches des messages envoyes : 1 coche envoye, 2 coches recu (l autre personne est connectee : champ `vuLe` de son profil, mis a jour toutes les 45 s par l accueil tant que l appli est ouverte), 3 coches vu (champ `lu` de la conversation). Service : `signalerPresence`, `luParAutre`, `presenceDe`.
- Emojis dans les conversations : le smiley de la zone de saisie ouvre un panneau d emojis (paquet `emoji_picker_flutter`, les emojis choisis s ajoutent au texte) ; le clavier du telephone en propose aussi. La regle "pas d emojis" concerne les textes de l interface, pas les messages ecrits par les utilisateurs.
- Menus des trois points : composant `lib/partage/composants/menu_trois_points.dart` (menu deroulant blanc, icones fines, trait de separation). Liste des conversations : Nouvelle conversation, Tout marquer comme lu, Parametres, Deconnexion (`seDeconnecter` dans `ecran_parametres.dart`).
- Menu des trois points de la conversation : Rechercher un message (filtre les messages du fil, cote appli) et Photos et positions (page `ecran_medias.dart`, grille des photos a agrandir et liste des positions partagees).
- Notes : collection `avis` (étoiles, commentaire, étiquettes) ; le profil affiche les vrais chiffres et la note moyenne.
- Règles de sécurité : `firestore.rules` ; index : `firestore.indexes.json`. Déploiement : `firebase deploy --only firestore:rules,firestore:indexes --project starpole-3d84d`.
- Les clés (`firebase_options.dart`, `google-services.json`) sont dans le `.gitignore` : `flutterfire configure --project=starpole-3d84d` les recrée.
- La Realtime Database créée au départ n'est pas utilisée. Firebase Storage n'est pas utilisé (forfait payant) : les photos sont réduites et enregistrées dans Firestore.
- Icône de l'application : l'étoile rouge StarPole (images dans `assets/icone/`, générée avec `flutter_launcher_icons` : `dart run flutter_launcher_icons`), fond blanc, icône adaptative Android ; le nom sous l'icône est « StarPole ».
- Adaptation aux écrans (`lib/partage/adaptatif.dart`, branché dans le `builder` du `MaterialApp`) : largeur du contenu limitée à 520 px et centrée sur tablette ou en paysage, texte plafonné à 130 %, et `hauteurConception` pour les écrans placés en pourcentage de la hauteur (infos de départ, connexion, inscription) qui défilent sur un petit écran au lieu de se chevaucher.
- État : Provider. Les écrans utilisent des services (`ServiceAuth`, `ServiceAlertes`, `ServiceMessagerie`, `ServiceCarnet`, `ServicePhoto`, `ServiceLocalisation`) remplacés par de faux services dans `test/widget_test.dart`.

**Pas encore fait**
- Messagerie : pas encore de groupes, d'envoi de photo ou de position, de présence « en ligne », ni de notifications quand un message arrive.
- Tonalité d'appel : pendant que ça sonne chez l'autre, l'appelant entend le « tuuut... tuuut... » du téléphone (`lib/noyau/sonnerie.dart` et `MainActivity.kt`, `ToneGenerator`, sans fichier son ni paquet) ; elle s'arrête quand l'autre décroche, refuse, ou qu'on raccroche.
- Appels voix et vidéo par Internet : `lib/noyau/service_appel.dart` (paquet `flutter_webrtc`, serveurs STUN gratuits de Google). Les deux téléphones s'échangent offre, réponse et candidats dans la collection `appels` (sous-collection `candidats`, règles dans `firestore.rules`). Les icônes téléphone et caméra de la conversation lancent l'appel ; l'appel entrant s'ouvre en plein écran (`lib/fonctionnalites/appel/`) avec vibration et signal sonore, tant que l'appli est ouverte. Dans les détails d'une alerte, toucher « Signalé par » ouvre la messagerie avec l'auteur.
- Appels : un appel sans réponse (45 s) ou annulé laisse un message « Appel vocal manqué » ou « Appel vidéo manqué » dans la conversation, visible à la connexion de la personne appelée (écrit par l'appelant, donc seulement si son appli est restée ouverte). Pas de serveur TURN (quelques réseaux mobiles stricts peuvent bloquer), et pas de sonnerie quand l'appli est fermée (étape 2 : notifications push avec FastAPI).
- Conversation : les raccourcis « Localisation » (envoie ma position, affichée sur une petite carte dans la bulle) et « Photo » (envoie une photo en 2 pour 1) fonctionnent ; les messages peuvent porter `photo`, `latitude` et `longitude` (règles dans `firestore.rules`). Pas encore de « En ligne ».
- Bouton « Itineraire » des details d une alerte (si elle a une position) : ouvre Google Maps ou le navigateur avec le trajet vers l alerte depuis la position actuelle (`ouvrirItineraire` dans `lib/noyau/invitation.dart`, paquet `url_launcher`).
- Bouton « Partager » d'une alerte : ouvre le partage du téléphone (WhatsApp) avec le titre, la description, le lieu et un lien vers la carte (`partagerAlerte`, `lib/noyau/invitation.dart`). L'icône filtre de la carte choisit le type d'alertes montré (toutes, urgences, dons, services).
- Photos des avatars des autres personnes, notifications push (FastAPI), connexion par numéro de téléphone, « Mot de passe oublié ? ».
