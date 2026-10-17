/// Une partie d'un texte légal : un titre et ses paragraphes.
class SectionLegale {
  const SectionLegale(this.titre, this.paragraphes);

  final String titre;
  final List<String> paragraphes;
}

/// Un texte légal complet.
class TexteLegal {
  const TexteLegal({
    required this.titre,
    required this.introduction,
    required this.sections,
  });

  final String titre;
  final String introduction;
  final List<SectionLegale> sections;
}

/// Les conditions d'utilisation de StarPole.
const TexteLegal conditionsUtilisation = TexteLegal(
  titre: "Conditions d'utilisation",
  introduction:
      "Dernière mise à jour : octobre 2026. En créant un compte, vous "
      "acceptez ces conditions. Elles sont écrites simplement, pour que "
      "chacun les comprenne.",
  sections: [
    SectionLegale("1. À quoi sert StarPole", [
      "StarPole est une application d'entraide de quartier pour Abidjan. Elle "
          "permet d'alerter ses voisins en cas d'urgence, de demander de "
          "l'aide et de donner ce qui ne sert plus.",
      "StarPole complète les groupes de quartier, comme ceux de WhatsApp : "
          "elle ne les remplace pas. L'application est un prototype réalisé "
          "dans le cadre d'un projet de l'ESATIC et n'est pas encore "
          "disponible au public.",
    ]),
    SectionLegale("2. Votre compte", [
      "Donnez des informations exactes (nom, e-mail ou numéro de téléphone). "
          "Un compte correspond à une seule personne.",
      "Vous êtes responsable de l'usage de votre compte. Si vous pensez que "
          "quelqu'un d'autre y accède, prévenez l'équipe StarPole.",
    ]),
    SectionLegale("3. Une aide qui compte", [
      "Ne lancez une alerte d'urgence que pour une situation réelle. Les "
          "fausses alertes, les blagues et les alertes répétées sans raison "
          "sont interdites : elles font perdre du temps à ceux qui ont "
          "vraiment besoin d'aide.",
      "Soyez respectueux avec vos voisins. Les insultes, les propos haineux, "
          "le harcèlement, les contenus illégaux ou choquants et l'usurpation "
          "d'identité sont interdits.",
    ]),
    SectionLegale("4. StarPole ne remplace pas les secours", [
      "En cas de danger grave (incendie, accident, blessure, agression), "
          "appelez d'abord les services d'urgence officiels : pompiers, SAMU "
          "et police. Utilisez ensuite StarPole pour prévenir vos voisins.",
    ]),
    SectionLegale("5. Vos contenus", [
      "Les textes, photos et messages que vous publiez restent les vôtres. "
          "En les publiant, vous autorisez StarPole à les afficher aux "
          "personnes concernées (par exemple vos voisins pour une alerte).",
      "Ne publiez que ce que vous avez le droit de partager. StarPole peut "
          "retirer un contenu qui ne respecte pas ces règles.",
    ]),
    SectionLegale("6. Rencontrer ses voisins en sécurité", [
      "StarPole met des personnes en relation mais ne peut pas vérifier "
          "chacune d'elles ni garantir qu'une aide sera donnée. Soyez prudent "
          ": privilégiez les lieux publics, prévenez un proche et regardez le "
          "profil et les avis de la personne.",
    ]),
    SectionLegale("7. Limites du service", [
      "L'application est fournie telle quelle, sans garantie qu'elle "
          "fonctionne sans interruption. L'équipe StarPole ne peut pas être "
          "tenue responsable des échanges entre utilisateurs ni des dommages "
          "qui en résulteraient, dans la limite de ce que la loi permet.",
    ]),
    SectionLegale("8. Changements", [
      "Ces conditions peuvent évoluer avec l'application. En cas de "
          "changement important, vous en serez informé dans l'application.",
    ]),
  ],
);

/// La politique de confidentialité de StarPole.
const TexteLegal politiqueConfidentialite = TexteLegal(
  titre: 'Politique de confidentialité',
  introduction:
      "Dernière mise à jour : octobre 2026. Voici, simplement, quelles "
      "informations StarPole utilise, pourquoi, et comment vous gardez la "
      "main dessus.",
  sections: [
    SectionLegale("1. Qui est responsable", [
      "StarPole est un projet du Groupe 7 de l'ESATIC, encadré par "
          "M. Cédric Cissé. L'application est un prototype : elle n'est pas "
          "encore publiée.",
    ]),
    SectionLegale("2. Les informations que nous utilisons", [
      "Votre compte : votre nom, votre e-mail ou votre numéro de téléphone, "
          "et votre photo de profil si vous en ajoutez une.",
      "Votre position : elle sert à trouver votre quartier, à placer vos "
          "alertes sur la carte et à vous montrer les alertes proches. Elle "
          "n'est lue que lorsque vous l'autorisez.",
      "Vos contenus : les alertes, descriptions, photos, messages et avis "
          "que vous écrivez.",
      "Vos appels : les informations techniques nécessaires pour relier deux "
          "téléphones. Le son et la vidéo ne sont jamais enregistrés par "
          "StarPole.",
    ]),
    SectionLegale("3. Vos contacts téléphoniques", [
      "Si vous l'acceptez, StarPole lit le carnet de contacts de votre "
          "téléphone pour vous montrer lesquels de vos proches ont déjà "
          "StarPole. Les numéros sont seulement comparés avec ceux des "
          "inscrits : ils ne sont pas enregistrés dans la base de StarPole.",
      "Si vous activez « Synchroniser le contact sur le téléphone » en "
          "ajoutant un contact, cette personne est ajoutée à votre carnet.",
    ]),
    SectionLegale("4. Qui voit quoi", [
      "Vos voisins voient votre nom, votre photo et le lieu de vos alertes. "
          "Vos messages ne sont lisibles que par vous et la personne qui "
          "écrit avec vous. Vos contacts sont privés.",
      "StarPole ne vend pas vos informations et ne les utilise pas pour de "
          "la publicité.",
    ]),
    SectionLegale("5. Où elles sont gardées", [
      "Les informations sont hébergées chez Google (Firebase), sur des "
          "serveurs en Europe. Les codes de connexion sont envoyés par "
          "e-mail. L'accès aux données est limité par des règles de "
          "sécurité, et les échanges sont chiffrés.",
      "Aucun système n'est parfait : gardez votre téléphone verrouillé et ne "
          "partagez pas vos codes.",
    ]),
    SectionLegale("6. Combien de temps", [
      "Vos informations sont gardées tant que votre compte existe. Si vous "
          "demandez la suppression de votre compte, elles sont effacées.",
    ]),
    SectionLegale("7. Vos droits", [
      "Vous pouvez à tout moment : modifier votre nom, votre numéro et votre "
          "photo depuis la page de modification du profil ; retirer les "
          "autorisations (position, contacts, micro, caméra) dans les "
          "réglages du téléphone, accessibles depuis Paramètres ; demander à "
          "l'équipe StarPole de voir, corriger ou supprimer vos informations.",
    ]),
    SectionLegale("8. Changements", [
      "Cette politique peut évoluer avec l'application. En cas de changement "
          "important, vous en serez informé dans l'application.",
    ]),
  ],
);
