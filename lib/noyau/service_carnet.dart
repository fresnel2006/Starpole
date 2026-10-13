import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as carnet;

import 'normalisation.dart';

/// Une personne du carnet de contacts du téléphone.
class EntreeCarnet {
  const EntreeCarnet({required this.nom, required this.numeros});

  /// Le nom, tel que la personne l'a enregistré dans son téléphone.
  final String nom;

  /// Les numéros de cette personne, déjà mis sous forme comparable.
  final List<String> numeros;
}

/// Comment s'est passée la lecture du carnet.
enum EtatCarnet {
  ok,

  /// L'utilisateur a refusé : on peut le lui redemander.
  refuse,

  /// Il a refusé pour de bon : il faut passer par les réglages du téléphone.
  bloque,
}

class ResultatCarnet {
  const ResultatCarnet(this.etat, [this.entrees = const []]);

  final EtatCarnet etat;
  final List<EntreeCarnet> entrees;
}

/// Lit le carnet de contacts du téléphone. Les écrans utilisent cette classe,
/// jamais le paquet de contacts directement (pour pouvoir la remplacer dans
/// les tests).
abstract class ServiceCarnet {
  /// Demande l'autorisation si besoin, puis lit le carnet.
  Future<ResultatCarnet> lire();

  /// Ouvre les réglages de l'appli (pour autoriser l'accès aux contacts).
  Future<void> ouvrirReglages();
}

/// Version réelle, basée sur le paquet `flutter_contacts`.
class ServiceCarnetReel implements ServiceCarnet {
  @override
  Future<ResultatCarnet> lire() async {
    try {
      final statut = await carnet.FlutterContacts.permissions.request(
        carnet.PermissionType.read,
      );
      switch (statut) {
        case carnet.PermissionStatus.granted:
        case carnet.PermissionStatus.limited:
          break;
        case carnet.PermissionStatus.permanentlyDenied:
        case carnet.PermissionStatus.restricted:
          return const ResultatCarnet(EtatCarnet.bloque);
        case carnet.PermissionStatus.denied:
        case carnet.PermissionStatus.notDetermined:
          return const ResultatCarnet(EtatCarnet.refuse);
      }

      final contacts = await carnet.FlutterContacts.getAll(
        properties: {carnet.ContactProperty.phone},
      );
      final entrees = <EntreeCarnet>[];
      for (final contact in contacts) {
        // Seuls les numéros assez longs comptent (on ignore les codes courts).
        final numeros = contact.phones
            .map((p) => normaliserTelephone(p.number))
            .where((n) => n.length >= 8)
            .toSet()
            .toList();
        if (numeros.isEmpty) continue;
        entrees.add(
          EntreeCarnet(nom: contact.displayName ?? '', numeros: numeros),
        );
      }
      return ResultatCarnet(EtatCarnet.ok, entrees);
    } on PlatformException {
      return const ResultatCarnet(EtatCarnet.refuse);
    }
  }

  @override
  Future<void> ouvrirReglages() =>
      carnet.FlutterContacts.permissions.openSettings();
}
