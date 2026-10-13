/// « Il y'a 15 min », « Il y'a 2h »... pour dire depuis quand une alerte existe.
String tempsEcoule(DateTime date, {DateTime? maintenant}) {
  final ecart = (maintenant ?? DateTime.now()).difference(date);
  if (ecart.inMinutes < 1) return "À l'instant";
  if (ecart.inMinutes < 60) return "Il y'a ${ecart.inMinutes} min";
  if (ecart.inHours < 24) return "Il y'a ${ecart.inHours}h";
  return "Il y'a ${ecart.inDays} j";
}

/// L'heure sous la forme « 09:15 ».
String heureCourte(DateTime date) {
  final heures = date.hour.toString().padLeft(2, '0');
  final minutes = date.minute.toString().padLeft(2, '0');
  return '$heures:$minutes';
}

/// « 850 m » sous 1 km, sinon « 1.2 km ».
String libelleDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}
