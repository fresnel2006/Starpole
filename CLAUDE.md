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
- **Carte** : OpenStreetMap avec `flutter_map` (gratuit), et `geolocator` pour la position.
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
- Comptes : e-mail et mot de passe, et Google (`google_sign_in`). Service : `lib/noyau/service_auth.dart`.
- Profil : collection `utilisateurs` (nom, téléphone, e-mail, photo en base64). Photo de profil modifiable (caméra ou galerie).
- Position : `lib/noyau/service_localisation.dart` (geolocator et geocoding), quartier d'Abidjan le plus proche avec `lib/noyau/quartiers.dart`, mémorisée dans `PositionUtilisateur`.
- Photos : `lib/noyau/traitement_photo.dart` redresse la photo (orientation du téléphone), la coupe autour de son centre (carré 400 px pour le profil, rectangle 2 pour 1 de 640 px pour une alerte) et l'enregistre en JPEG léger (paquet `image`). Ce qui est enregistré est exactement ce qui est affiché.
- Alertes : collection `alertes` (urgence, don, service). Service : `lib/noyau/service_alertes.dart`. Poster une alerte enregistre vraiment ; l'accueil, la carte, « Mes alertes » et le suivi lisent la base en direct ; « Je peux aider », « Terminé » et « Stopper » mettent l'alerte à jour ; le bandeau « Alerte en cours » vient de la base.
- Progression : sous-collection `alertes/{id}/progression` (messages d'avancement, « Je suis en route »). L'auteur et la personne qui aide les écrivent depuis le suivi, et ils s'affichent dans la timeline en direct.
- Contacts et messagerie : service `lib/noyau/service_messagerie.dart`. On ajoute un contact en tapant son numéro de téléphone ou son e-mail (champs `telephoneNormalise` et `emailNormalise` du profil, voir `lib/noyau/normalisation.dart`) ; ses contacts sont dans `utilisateurs/{uid}/contacts`. Les conversations sont dans `conversations/{uidA_uidB}` (identifiants triés) avec une sous-collection `messages`. Un repère « non lu » se base sur le champ `lu` de la conversation. La recherche d'un profil est limitée à 5 résultats par les règles (on ne peut pas télécharger tous les profils).
- Notes : collection `avis` (étoiles, commentaire, étiquettes) ; le profil affiche les vrais chiffres et la note moyenne.
- Règles de sécurité : `firestore.rules` ; index : `firestore.indexes.json`. Déploiement : `firebase deploy --only firestore:rules,firestore:indexes --project starpole-3d84d`.
- Les clés (`firebase_options.dart`, `google-services.json`) sont dans le `.gitignore` : `flutterfire configure --project=starpole-3d84d` les recrée.
- La Realtime Database créée au départ n'est pas utilisée. Firebase Storage n'est pas utilisé (forfait payant) : les photos sont réduites et enregistrées dans Firestore.
- État : Provider. Les écrans utilisent des services (`ServiceAuth`, `ServiceAlertes`, `ServicePhoto`, `ServiceLocalisation`) remplacés par de faux services dans `test/widget_test.dart`.

**Pas encore fait**
- Messagerie : pas encore de groupes, d'envoi de photo ou de position, de présence « en ligne », ni de notifications quand un message arrive.
- Les boutons d'appel et de vidéo de la conversation, et les raccourcis « Localisation » et « Photo », ne font rien.
- Photos des avatars des autres personnes, bouton Partager, notifications push (FastAPI), connexion par numéro de téléphone, « Mot de passe oublié ? », filtre de la carte.
