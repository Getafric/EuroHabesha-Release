/// Schema for the public activity form. Private verification documents are not
/// collected here and these values never grant verification or payment rights.
class ActivityFieldSpec {
  const ActivityFieldSpec(
    this.key,
    this.fr,
    this.en, {
    this.requiredField = false,
    this.lines = 1,
    this.numeric = false,
  });
  final String key, fr, en;
  final bool requiredField, numeric;
  final int lines;
}

const activityBusinessCategories = <String, List<String>>{
  'Restaurant / Café': ['Restaurant / Café', 'Restaurant / Café'],
  'Grocery / Food Shop': ['Épicerie / Supermarché', 'Grocery / Supermarket'],
  'Retail / Clothing Shop': ['Boutique / Vêtements', 'Retail / Clothing shop'],
  'Hair Salon / Barber': ['Coiffure / Barbier', 'Hair salon / Barber'],
  'Beauty / Nails': ['Beauté / Ongles', 'Beauty / Nails'],
  'Catering / Bakery': ['Traiteur / Boulangerie', 'Catering / Bakery'],
  'Hotel / Guesthouse': ['Hôtel / Hébergement', 'Hotel / Guesthouse'],
  'Event Venue': ['Salle / Événementiel', 'Event venue'],
  'Travel / Transport': ['Voyage / Transport', 'Travel / Transport'],
  'Photography / Media Studio': [
    'Photographie / Studio',
    'Photography / Studio',
  ],
  'Professional Office / Agency': [
    'Cabinet / Agence',
    'Professional office / Agency',
  ],
  'Other Establishment': ['Autre activité', 'Other business'],
};

const _businessFields = <String, List<ActivityFieldSpec>>{
  'Restaurant / Café': [
    ActivityFieldSpec(
      'cuisineType',
      'Cuisine et spécialités',
      'Cuisine and specialties',
      requiredField: true,
    ),
    ActivityFieldSpec(
      'serviceModes',
      'Sur place, à emporter, livraison',
      'Dine-in, takeaway, delivery',
    ),
    ActivityFieldSpec(
      'dietaryOptions',
      'Options alimentaires',
      'Dietary options',
    ),
  ],
  'Grocery / Food Shop': [
    ActivityFieldSpec(
      'productTypes',
      'Produits proposés',
      'Products offered',
      requiredField: true,
      lines: 3,
    ),
    ActivityFieldSpec(
      'fulfilmentOptions',
      'Retrait et livraison',
      'Pickup and delivery',
    ),
  ],
  'Retail / Clothing Shop': [
    ActivityFieldSpec(
      'productTypes',
      'Articles et gammes',
      'Items and ranges',
      requiredField: true,
      lines: 3,
    ),
    ActivityFieldSpec(
      'fulfilmentOptions',
      'Retrait et livraison',
      'Pickup and delivery',
    ),
  ],
  'Hair Salon / Barber': [
    ActivityFieldSpec(
      'appointmentServices',
      'Prestations de coiffure',
      'Hair services',
      requiredField: true,
      lines: 3,
    ),
    ActivityFieldSpec(
      'pricingDetails',
      'Tarifs indicatifs',
      'Indicative prices',
      lines: 2,
    ),
    ActivityFieldSpec(
      'appointmentConditions',
      'Avec ou sans rendez-vous',
      'Appointment or walk-in',
    ),
  ],
  'Beauty / Nails': [
    ActivityFieldSpec(
      'appointmentServices',
      'Soins et prestations',
      'Treatments and services',
      requiredField: true,
      lines: 3,
    ),
    ActivityFieldSpec(
      'pricingDetails',
      'Tarifs indicatifs',
      'Indicative prices',
      lines: 2,
    ),
    ActivityFieldSpec(
      'appointmentConditions',
      'Conditions de rendez-vous',
      'Appointment conditions',
    ),
  ],
  'Catering / Bakery': [
    ActivityFieldSpec(
      'specialties',
      'Produits et spécialités',
      'Products and specialties',
      requiredField: true,
      lines: 3,
    ),
    ActivityFieldSpec('orderLeadTime', 'Délai de commande', 'Order lead time'),
    ActivityFieldSpec(
      'dietaryOptions',
      'Options alimentaires',
      'Dietary options',
    ),
  ],
  'Hotel / Guesthouse': [
    ActivityFieldSpec(
      'roomTypes',
      'Types de chambres',
      'Room types',
      requiredField: true,
      lines: 2,
    ),
    ActivityFieldSpec(
      'guestCapacity',
      'Capacité d’accueil',
      'Guest capacity',
      numeric: true,
    ),
    ActivityFieldSpec(
      'checkInOut',
      'Arrivée et départ',
      'Check-in and check-out',
    ),
  ],
  'Event Venue': [
    ActivityFieldSpec(
      'venueEvents',
      'Événements accueillis',
      'Types of events hosted',
      requiredField: true,
      lines: 2,
    ),
    ActivityFieldSpec(
      'guestCapacity',
      'Capacité d’accueil',
      'Guest capacity',
      numeric: true,
    ),
    ActivityFieldSpec(
      'venueEquipment',
      'Équipements disponibles',
      'Available equipment',
      lines: 2,
    ),
  ],
  'Travel / Transport': [
    ActivityFieldSpec(
      'vehicleTypes',
      'Véhicules et prestations',
      'Vehicles and services',
      requiredField: true,
      lines: 2,
    ),
    ActivityFieldSpec('serviceArea', 'Zones desservies', 'Service areas'),
    ActivityFieldSpec(
      'transportConditions',
      'Conditions et réservation',
      'Conditions and booking',
      lines: 2,
    ),
  ],
  'Photography / Media Studio': [
    ActivityFieldSpec(
      'photoServices',
      'Prestations photo et vidéo',
      'Photo and video services',
      requiredField: true,
      lines: 3,
    ),
    ActivityFieldSpec(
      'pricingDetails',
      'Tarifs indicatifs',
      'Indicative prices',
      lines: 2,
    ),
    ActivityFieldSpec(
      'deliveryDetails',
      'Livrables et délais',
      'Deliverables and turnaround',
      lines: 2,
    ),
  ],
  'Professional Office / Agency': [
    ActivityFieldSpec(
      'officeServices',
      'Services proposés',
      'Services offered',
      requiredField: true,
      lines: 3,
    ),
    ActivityFieldSpec(
      'pricingDetails',
      'Tarifs indicatifs',
      'Indicative prices',
      lines: 2,
    ),
  ],
  'Other Establishment': [
    ActivityFieldSpec(
      'activityDetails',
      'Détail de votre activité',
      'Activity details',
      requiredField: true,
      lines: 3,
    ),
  ],
};

List<ActivityFieldSpec> activityFieldsForBusiness(String category) =>
    _businessFields[category] ?? const <ActivityFieldSpec>[];

Set<String> get activityBusinessSpecificKeys => _businessFields.values
    .expand((fields) => fields)
    .map((field) => field.key)
    .toSet();

/// Null means the common wizard requirements are present. This is a client
/// usability check; server moderation and verification remain authoritative.
int? activityMissingStep({
  required String type,
  required bool categoryChosen,
  required bool hasPhoto,
  required Map<String, String> fields,
}) {
  if (!categoryChosen) {
    return 0;
  }
  final presentation = ['title', 'phoneNumber', 'cityAddress', 'description'];
  if (presentation.any((key) => (fields[key] ?? '').trim().isEmpty) ||
      (const ['job', 'professional', 'business'].contains(type) && !hasPhoto)) {
    return 1;
  }
  if (type == 'business') {
    if ((fields['address'] ?? '').trim().isEmpty) {
      return 2;
    }
    if (activityFieldsForBusiness(fields['businessCategory'] ?? '')
        .where((field) => field.requiredField)
        .any((field) => (fields[field.key] ?? '').trim().isEmpty)) {
      return 2;
    }
  }
  if (type == 'employer' &&
      const [
        'companyName',
        'businessSector',
        'contactPerson',
      ].any((key) => (fields[key] ?? '').trim().isEmpty)) {
    return 2;
  }
  return null;
}

/// Publication approval is separate from identity verification.
bool activityPublicationApproved(Object? status) =>
    const ['approved', 'published'].contains(status?.toString());

/// Registration is deliberately absent: it never determines the work route.
String activityRoute(String originalType, bool? welcomesClients) {
  if (welcomesClients == null ||
      !const ['business', 'professional', 'job'].contains(originalType)) {
    return originalType;
  }
  return welcomesClients
      ? 'business'
      : originalType == 'professional'
      ? 'professional'
      : 'job';
}
