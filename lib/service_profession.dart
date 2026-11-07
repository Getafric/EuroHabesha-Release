// Public presentation only; never an identity, payment or booking authority.
class ServiceField {
  final String key, label, hint;
  const ServiceField(this.key, this.label, this.hint);
}

class ServiceDefinition {
  final String id, category, label;
  final List<String> offers, modes, units;
  final List<ServiceField> fields;
  const ServiceDefinition(
    this.id,
    this.category,
    this.label,
    this.offers,
    this.modes,
    this.units,
    this.fields,
  );
}

const serviceDefinitions = <ServiceDefinition>[
  ServiceDefinition(
    "photo",
    "Photographer/Videographer",
    "Photographie et vidéo",
    ["Mariage", "Portrait", "Événement", "Entreprise", "Vidéo"],
    ["Chez le client", "En studio", "Sur le lieu de l’événement"],
    ["Forfait", "Par heure", "Sur devis"],
    [
      ServiceField(
        "delivery",
        "Livrables et délais",
        "Photos, vidéo, album, délai de livraison…",
      ),
    ],
  ),
  ServiceDefinition(
    "translator",
    "Translator",
    "Traduction et interprétation",
    ["Traduction écrite", "Interprétation orale"],
    [
      "Documents numériques",
      "Documents papier",
      "Téléphone",
      "Visio",
      "Sur place",
    ],
    ["Par mot", "Par page", "Par document", "Par heure", "Sur devis"],
    [
      ServiceField(
        "languages",
        "Langues proposées *",
        "Amharique, français, tigrinya…",
      ),
      ServiceField(
        "specialties",
        "Domaines et délais",
        "Type de documents, rendez-vous, événement…",
      ),
    ],
  ),
  ServiceDefinition(
    "plumber",
    "Plumber",
    "Plomberie",
    ["Fuite", "Débouchage", "Sanitaires", "Installation"],
    ["Chez le client", "Dans un local professionnel"],
    ["Par heure", "Forfait", "Sur devis"],
    [
      ServiceField(
        "specialties",
        "Interventions et conditions",
        "Travaux, fournitures, déplacement…",
      ),
    ],
  ),
  ServiceDefinition(
    "mechanic",
    "Mechanic",
    "Mécanique automobile",
    ["Diagnostic", "Entretien", "Réparation", "Pneumatiques"],
    ["En atelier", "Service mobile"],
    ["Par heure", "Forfait", "Sur devis"],
    [
      ServiceField(
        "vehicles",
        "Véhicules pris en charge",
        "Marques, modèles et types de véhicules…",
      ),
      ServiceField(
        "conditions",
        "Conditions de prestation",
        "Pièces, diagnostic, déplacement…",
      ),
    ],
  ),
  ServiceDefinition(
    "catering",
    "Catering / Food Seller (Injera & Wot)",
    "Traiteur et pâtisserie",
    ["Buffet", "Plats", "Gâteaux", "Desserts", "Événement"],
    ["Retrait", "Livraison", "Sur le lieu de l’événement"],
    ["Par personne", "Par plat", "Par gâteau", "Forfait", "Sur devis"],
    [
      ServiceField(
        "specialties",
        "Cuisine et créations",
        "Cuisine Habesha, buffet, gâteau personnalisé…",
      ),
      ServiceField(
        "capacity",
        "Capacité et délai de commande",
        "Personnes ou parts, délai nécessaire…",
      ),
      ServiceField(
        "conditions",
        "Préférences et conditions",
        "Discuter des allergies et besoins avant accord.",
      ),
    ],
  ),
  ServiceDefinition(
    "dj",
    "DJ / Music Services",
    "DJ et animation musicale",
    ["Mariage", "Anniversaire", "Soirée", "Son et lumière"],
    ["Sur le lieu de l’événement"],
    ["Par heure", "Forfait", "Sur devis"],
    [
      ServiceField("music", "Styles musicaux", "Styles et langues de musique…"),
      ServiceField(
        "equipment",
        "Matériel fourni",
        "Sonorisation, micros, éclairage…",
      ),
      ServiceField(
        "conditions",
        "Installation et conditions",
        "Durée, montage, démontage, déplacement…",
      ),
    ],
  ),
  ServiceDefinition(
    "painter",
    "Painter",
    "Peinture",
    ["Intérieur", "Extérieur", "Murs et plafonds", "Finitions"],
    ["Chez le client", "Dans un local professionnel"],
    ["Au m²", "Forfait", "Sur devis"],
    [
      ServiceField(
        "specialties",
        "Travaux et finitions",
        "Surfaces, préparation et finitions…",
      ),
    ],
  ),
  ServiceDefinition(
    "electrician",
    "Electrician",
    "Électricité",
    ["Installation", "Dépannage", "Éclairage", "Rénovation"],
    ["Chez le client", "Dans un local professionnel"],
    ["Par heure", "Forfait", "Sur devis"],
    [
      ServiceField(
        "specialties",
        "Interventions proposées",
        "Types de travaux et locaux pris en charge…",
      ),
    ],
  ),
  ServiceDefinition(
    "decorator",
    "Event Decoration",
    "Décoration d’événements",
    ["Mariage", "Anniversaire", "Salle", "Tables et fleurs"],
    ["Sur le lieu de l’événement"],
    ["Formule", "Forfait", "Sur devis"],
    [
      ServiceField(
        "styles",
        "Styles et thèmes",
        "Couleurs, thèmes et ambiances…",
      ),
      ServiceField(
        "equipment",
        "Location de matériel",
        "Arches, tables, fleurs, éléments décoratifs…",
      ),
      ServiceField(
        "conditions",
        "Installation et démontage",
        "Ce qui est inclus, horaires et déplacement…",
      ),
    ],
  ),
  ServiceDefinition(
    "makeup",
    "Makeup Artist",
    "Maquillage à domicile",
    ["Mariage", "Invitée", "Événement", "Autre prestation"],
    ["Chez le client", "Chez le professionnel", "Sur le lieu de l’événement"],
    ["Par prestation", "Forfait", "Sur devis"],
    [
      ServiceField(
        "specialties",
        "Prestations et préparation",
        "Styles, essai, durée, préparation…",
      ),
    ],
  ),
  ServiceDefinition(
    "hair",
    "Hairdresser/Barber",
    "Coiffure et tresses",
    [
      "Tresses / shuruba",
      "Coiffure mariage",
      "Extensions",
      "Coupe",
      "Autre coiffure",
    ],
    ["Chez le client", "Chez le professionnel"],
    ["Par coiffure", "Forfait", "Sur devis"],
    [
      ServiceField(
        "specialties",
        "Coiffures proposées",
        "Tresses, shuruba et techniques…",
      ),
      ServiceField(
        "conditions",
        "Extensions et préparation",
        "Fournies ou à apporter, durée, préparation…",
      ),
    ],
  ),
  ServiceDefinition(
    "vtc",
    "Taxi Driver",
    "Chauffeur VTC / Taxi",
    ["Aéroport", "Gare", "Trajet privé", "Mariage", "Mise à disposition"],
    ["Sur réservation à convenir"],
    ["Par heure", "Forfait", "Sur devis"],
    [
      ServiceField(
        "vehicle",
        "Présentation du véhicule",
        "Places, bagages, équipements…",
      ),
      ServiceField(
        "conditions",
        "Conditions de prestation",
        "Zone, horaires et besoins à confirmer directement.",
      ),
    ],
  ),
];
const otherServiceLabels = <String, String>{
  'Cleaning': 'Nettoyage',
  'Fashion/Clothes Designer': 'Mode et couture',
  'Furniture Assembly': 'Montage de meubles',
  'Babysitting/Nanny': 'Garde d’enfants',
  'Moving/Transport (Truck)': 'Déménagement et transport',
  'Airport Luggage Delivery': 'Transport de bagages',
  'Eyebrow/Beauty Services': 'Soins et beauté',
  'Nail Technician': 'Onglerie',
  'Gardener': 'Jardinage',
  'Car Wash': 'Lavage automobile',
  'Tutoring/Language Teacher (e.g., Amharic, Tigrinya)': 'Cours et langues',
  'IT / Computer Support': 'Assistance informatique',
  'Home Cooking': 'Cuisine à domicile',
  'Other Service': 'Autre service',
};
ServiceDefinition serviceDefinition(String category) {
  final text = category.trim().toLowerCase();
  for (final p in serviceDefinitions) {
    if ([
      p.id,
      p.category.toLowerCase(),
      p.label.toLowerCase(),
    ].contains(text)) {
      return p;
    }
  }
  return ServiceDefinition(
    'general',
    category,
    otherServiceLabels[category] ?? category,
    const [],
    const [
      'À distance',
      'Chez le client',
      'Chez le professionnel',
      'Sur place',
    ],
    const ['Par prestation', 'Par heure', 'Forfait', 'Sur devis'],
    const [
      ServiceField(
        'specialties',
        'Prestations proposées',
        'Présentez vos services et conditions…',
      ),
    ],
  );
}

Map<String, dynamic> serviceMap(dynamic v) => v is Map
    ? {
        for (final e in v.entries)
          if (e.key is String) e.key as String: e.value,
      }
    : {};
String serviceText(dynamic v, [int limit = 1200]) {
  if (v is! String) return '';
  final s = v.trim();
  return s.length > limit ? s.substring(0, limit) : s;
}

const serviceCurrencies = ['EUR', 'CHF', 'USD', 'GBP', 'CAD', 'AUD', 'ETB'];
List<String> serviceChoices(dynamic v, List<String> allowed) =>
    v is List ? allowed.where(v.contains).toList() : [];
double? serviceRate(dynamic v) {
  final s = serviceText(v, 30);
  if (!RegExp(r'^\d{1,7}([.,]\d{1,4})?$').hasMatch(s)) return null;
  final n = double.tryParse(s.replaceAll(',', '.'));
  return n != null && n.isFinite && n > 0 && n <= 1000000 ? n : null;
}

Map<String, dynamic> serviceDefaults(ServiceDefinition p) => {
  'version': 1,
  'category': p.category,
  'offers': <String>[],
  'modes': <String>[],
  'unit': 'Sur devis',
  'rate': '',
  'currency': 'EUR',
  'extras': <String, dynamic>{},
};
Map<String, dynamic> cleanServiceDetails(
  ServiceDefinition p,
  Map<String, dynamic> v,
) {
  final unit = p.units.contains(v['unit']) ? v['unit'] : 'Sur devis';
  final extras = serviceMap(v['extras']);
  return {
    'version': 1,
    'category': p.category,
    'offers': serviceChoices(v['offers'], p.offers),
    'modes': serviceChoices(v['modes'], p.modes),
    'unit': unit,
    'rate': unit == 'Sur devis' || serviceRate(v['rate']) == null
        ? ''
        : serviceText(v['rate'], 30),
    'currency': serviceCurrencies.contains(v['currency'])
        ? v['currency']
        : 'EUR',
    'extras': {for (final f in p.fields) f.key: serviceText(extras[f.key])},
  };
}

String? validateServiceDetails(ServiceDefinition p, Map<String, dynamic> v) {
  if (p.offers.isNotEmpty && serviceChoices(v['offers'], p.offers).isEmpty) {
    return 'Choisissez au moins une prestation.';
  }
  if (serviceChoices(v['modes'], p.modes).isEmpty) {
    return 'Choisissez un lieu ou mode de prestation.';
  }
  if (p.id == 'translator' &&
      serviceText(serviceMap(v['extras'])['languages']).isEmpty) {
    return 'Indiquez les langues proposées.';
  }
  if (!p.units.contains(v['unit'])) return 'Choisissez une base de tarif.';
  if (v['unit'] != 'Sur devis' && serviceRate(v['rate']) == null) {
    return 'Indiquez un tarif positif valide ou choisissez « Sur devis ».';
  }
  if (!serviceCurrencies.contains(v['currency'])) {
    return 'Choisissez une devise.';
  }
  return null;
}

Map<String, dynamic> publicServiceDetails(Map<String, dynamic> data) {
  final f = serviceMap(data['fields']);
  final v = serviceMap(data['serviceDetails'] ?? f['serviceDetails']);
  if (v['version'] != 1) return {};
  final category = serviceText(f['jobCategory']).isNotEmpty
      ? serviceText(f['jobCategory'])
      : serviceText(data['jobCategory']).isNotEmpty
      ? serviceText(data['jobCategory'])
      : serviceText(v['category']);
  if (v['category'] != category || category.isEmpty) return {};
  return cleanServiceDetails(serviceDefinition(category), v);
}

String servicePrice(Map<String, dynamic> v) {
  final n = serviceRate(v['rate']);
  if (n == null || v['unit'] == 'Sur devis') return 'Sur devis';
  var s = n.toStringAsFixed(4);
  while (s.endsWith('0') && s.split('.').last.length > 2) {
    s = s.substring(0, s.length - 1);
  }
  return "${s.replaceAll('.', ',')} ${serviceText(v['currency'])} · ${serviceText(v['unit']).toLowerCase()}";
}

List<String> serviceGallery(Map<String, dynamic> data) {
  final f = serviceMap(data['fields']), m = serviceMap(data['media']);
  final result = <String>[];
  for (final group in [data['gallery'], f['gallery'], m['photoUrls']]) {
    if (group is! List) continue;
    for (final raw in group) {
      final url = serviceText(raw, 4096),
          uri = Uri.tryParse(serviceText(raw, 4096));
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.path.toLowerCase().contains('verification')) {
        continue;
      }
      if (!result.contains(url)) result.add(url);
      if (result.length == 10) return result;
    }
  }
  return result;
}

String? serviceImageExtension(List<int> b) {
  if (b.length >= 3 && b[0] == 255 && b[1] == 216 && b[2] == 255) return 'jpg';
  if (b.length >= 8 &&
      [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ].asMap().entries.every((e) => b[e.key] == e.value)) {
    return 'png';
  }
  if (b.length >= 12 &&
      String.fromCharCodes(b.take(4)) == 'RIFF' &&
      String.fromCharCodes(b.skip(8).take(4)) == 'WEBP') {
    return 'webp';
  }
  return null;
}
