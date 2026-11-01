/// Les documents existants utilisent des blocs fixes : 18–20 h, 20–22 h…
/// Cette consultation conserve ce fonctionnement, sans durée glissante.
bool isInTableReservationSlot(DateTime booked, DateTime selected) {
  final a = booked.toLocal();
  final b = selected.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day &&
      a.hour ~/ 2 == b.hour ~/ 2;
}

String tableReservationStatusLabel(String status) => const {
  'pending': 'En attente',
  'accepted': 'Acceptée',
  'rejected': 'Refusée',
  'cancelled': 'Annulée',
}[status] ?? status;

bool blocksTableReservationSlot(String status) =>
    status == 'pending' || status == 'accepted';
