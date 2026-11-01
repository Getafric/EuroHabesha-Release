import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

/// Booking UI. Server-side authorization and atomic slot locking are required
/// before public production use.
class AppointmentBookingScreen extends StatefulWidget {
  final String businessId;
  final String sourceCollection;
  final String businessName;

  const AppointmentBookingScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
    required this.businessName,
  });

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  static const dark = Color(0xFF061E12);
  static const gold = Color(0xFFFFD700);
  static const green = Color(0xFF123629);
  static const beige = Color(0xFFE8D8B5);
  static const reservedRed = Color(0xFF702C2C);

  String? serviceId;
  DateTime day = DateTime.now().add(const Duration(days: 1));
  DateTime? selectedStart;
  bool busy = false;
  int availabilityRefresh = 0;
  Future<List<Map<String, dynamic>>>? _availabilityFuture;
  String _availabilityKey = "";

  DocumentReference<Map<String, dynamic>> get business => FirebaseFirestore
      .instance.collection(widget.sourceCollection).doc(widget.businessId);
  CollectionReference<Map<String, dynamic>> get services =>
      business.collection('appointmentServices');
  CollectionReference<Map<String, dynamic>> get appointments =>
      business.collection('appointments');

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  int? minutes(dynamic value) {
    final parts = value?.toString().split(':');
    if (parts == null || parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  DateTime atMinute(int value) =>
      DateTime(day.year, day.month, day.day, value ~/ 60, value % 60);

  String timeLabel(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  bool overlaps(DateTime aStart, DateTime aEnd, DateTime bStart,
          DateTime bEnd) =>
      aStart.isBefore(bEnd) && aEnd.isAfter(bStart);

  Future<List<Map<String, dynamic>>> cachedAvailability() {
    final key = '${widget.sourceCollection}/${widget.businessId}/${day.year}-${day.month}-${day.day}/$availabilityRefresh';
    if (_availabilityFuture == null || _availabilityKey != key) {
      _availabilityKey = key;
      _availabilityFuture = availability();
    }
    return _availabilityFuture!;
  }

  Future<List<Map<String, dynamic>>> availability() async {
    final begin = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('getAppointmentAvailability').call({
      'sourceCollection': widget.sourceCollection,
      'businessId': widget.businessId,
      'dayStartMs': begin.millisecondsSinceEpoch,
      'dayEndMs': end.millisecondsSinceEpoch,
    });
    return (result.data['occupied'] as List).map((v) =>
        Map<String, dynamic>.from(v as Map)).toList();
  }

  bool occupied(DateTime start, DateTime end, List<Map<String, dynamic>> docs) {
    final a = start.millisecondsSinceEpoch;
    final b = end.millisecondsSinceEpoch;
    return docs.any((d) => (d['startMs'] as num).toInt() < b &&
        (d['endMs'] as num).toInt() > a);
  }

  Future<void> book(
    QueryDocumentSnapshot<Map<String, dynamic>> serviceDoc,
    int duration,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      message('Connectez-vous avec votre compte pour réserver.');
      return;
    }
    final start = selectedStart;
    if (start == null) {
      message('Choisissez un créneau disponible.');
      return;
    }
    if (!start.isAfter(DateTime.now())) {
      message('Choisissez un créneau futur.');
      return;
    }
    setState(() => busy = true);
    try {
      final settings = await business.get(const GetOptions(source: Source.server));
      if (!settings.exists || settings.data()?['appointmentsEnabled'] == false) {
        message('Cet établissement ne propose pas de rendez-vous actuellement.');
        return;
      }
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('createProfessionalAppointment').call({
        'sourceCollection': widget.sourceCollection,
        'businessId': widget.businessId,
        'serviceId': serviceDoc.id,
        'startMs': start.millisecondsSinceEpoch,
        'localDate': '${start.year.toString().padLeft(4, '0')}-'
            '${start.month.toString().padLeft(2, '0')}-'
            '${start.day.toString().padLeft(2, '0')}',
        'localMinute': start.hour * 60 + start.minute,
      });
      final isAutomatic = result.data['status'] == 'confirmed';
      if (mounted) setState(() { selectedStart = null; availabilityRefresh++; });
      message(isAutomatic
          ? 'Rendez-vous enregistré. Confirmation automatique.'
          : 'Demande envoyée. En attente de confirmation.');
    } catch (e) {
      message('Réservation impossible : $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: dark,
        appBar: AppBar(
          title: Text('Réserver · ${widget.businessName}'),
          backgroundColor: dark,
          foregroundColor: gold,
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: business.snapshots(),
          builder: (context, businessSnap) {
            if (businessSnap.hasError) {
              return error('Lecture des horaires impossible : ${businessSnap.error}');
            }
            if (!businessSnap.hasData) return loading();
            final data = businessSnap.data!.data();
            if (data == null || data['appointmentsEnabled'] == false) {
              return error('Cet établissement ne propose pas de rendez-vous actuellement.');
            }
            final workingHours = data['appointmentWorkingHours'];
            final automatic = data['bookingConfirmationMode'] == 'automatic';
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: services.where('enabled', isEqualTo: true).snapshots(),
              builder: (context, servicesSnap) {
                if (servicesSnap.hasError) {
                  return error('Lecture des prestations impossible : ${servicesSnap.error}');
                }
                if (!servicesSnap.hasData) return loading();
                final options = servicesSnap.data!.docs;
                if (options.isEmpty) {
                  return error('Aucune prestation disponible pour le moment. '
                      'Vous pouvez contacter le professionnel depuis sa fiche.');
                }
                final matches = options.where((doc) => doc.id == serviceId);
                final chosen = matches.isEmpty ? null : matches.first;
                final durationRaw = chosen?.data()['durationMinutes'];
                final duration = durationRaw is int && durationRaw > 0
                    ? durationRaw
                    : 30;


                                 return FutureBuilder<List<Map<String, dynamic>>>(
                   key: ValueKey('${widget.businessId}_${day.toIso8601String()}_$availabilityRefresh'),
                   future: cachedAvailability(),
builder: (context, appointmentsSnap) {
                    final reservationsError = appointmentsSnap.error;
                    final reservationsLoaded = appointmentsSnap.hasData;
                    final reservations = appointmentsSnap.data ?? <Map<String, dynamic>>[];
                    final row = workingHours is Map
                        ? workingHours['${day.weekday}']
                        : null;
                    final open = row is Map ? minutes(row['open']) : null;
                    final close = row is Map ? minutes(row['close']) : null;
                    final pauseStart = row is Map && row['pauseEnabled'] == true
                        ? minutes(row['pauseStart'])
                        : null;
                    final pauseEnd = row is Map && row['pauseEnabled'] == true
                        ? minutes(row['pauseEnd'])
                        : null;
                    final openToday = row is Map && row['enabled'] == true &&
                        open != null && close != null && open < close;
                    final slots = <DateTime>[];
                    if (openToday && chosen != null) {
                      final first = ((open + 14) ~/ 15) * 15;
                      for (var minute = first;
                          minute + duration <= close;
                          minute += 15) {
                        slots.add(atMinute(minute));
                      }
                    }
                    return ListView(
                      padding: EdgeInsets.fromLTRB(16, 16, 16,
                          32 + MediaQuery.of(context).viewPadding.bottom),
                      children: [
                        const Text('Choisissez une prestation',
                            style: TextStyle(color: gold, fontSize: 18)),
                        const SizedBox(height: 12),
                        ...options.map((doc) => _serviceCard(
                              doc.id,
                              doc.data(),
                              selected: serviceId == doc.id,
                              onTap: () => setState(() {
                                serviceId = doc.id;
                                selectedStart = null;
                              }),
                            )),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, color: gold),
                          label: Text('Sélectionner une date : ${day.day}/${day.month}/${day.year}',
                              style: const TextStyle(color: gold)),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: day,
                              firstDate: DateTime(now.year, now.month, now.day),
                              lastDate: now.add(const Duration(days: 365)),
                              builder: (dialogContext, child) => Theme(
                                data: Theme.of(dialogContext).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: gold, onPrimary: dark,
                                    surface: green, onSurface: Colors.white,
                                  ),
                                  datePickerTheme: DatePickerThemeData(
                                    backgroundColor: green,
                                    headerBackgroundColor: dark,
                                    headerForegroundColor: gold,
                                    weekdayStyle: const TextStyle(color: gold),
                                    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.disabled)) return Colors.white38;
                                      return states.contains(WidgetState.selected) ? dark : Colors.white;
                                    }),
                                    dayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
                                      states.contains(WidgetState.selected) ? gold : null),
                                    todayForegroundColor: WidgetStateProperty.resolveWith((states) =>
                                      states.contains(WidgetState.selected) ? dark : gold),
                                    todayBorder: const BorderSide(color: gold),
                                    cancelButtonStyle: TextButton.styleFrom(foregroundColor: gold),
                                    confirmButtonStyle: TextButton.styleFrom(
                                      foregroundColor: dark, backgroundColor: gold),
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null && mounted) {
                              setState(() {
                                day = picked;
                                selectedStart = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(automatic
                            ? 'Confirmation automatique par cet établissement'
                            : 'Confirmation manuelle par cet établissement',
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        const Text('Choisissez un créneau horaire',
                            style: TextStyle(color: gold, fontSize: 18)),
                        if (chosen == null)
                          note('Sélectionnez d’abord une prestation.'),
                        if (chosen != null && workingHours is! Map)
                          note('Horaires non configurés par cet établissement.'),
                        if (chosen != null && workingHours is Map && !openToday)
                          note('Établissement fermé ou indisponible ce jour.'),
                        if (chosen != null && openToday && reservationsError != null)
                          error(
                            reservationsError is FirebaseFunctionsException &&
                                    reservationsError.code == 'not-found'
                                ? 'Disponibilités : ${reservationsError.code}\n'
                                    '${reservationsError.message ?? "Aucun détail"}'
                                : 'Impossible de vérifier les disponibilités. Réessayez plus tard.'
                          ),
                        if (chosen != null && openToday && !reservationsLoaded &&
                            reservationsError == null)
                          loading(),
                        if (chosen != null && openToday && reservationsLoaded &&
                            slots.isEmpty)
                          note('Aucun créneau compatible avec la durée de cette prestation.'),
                        if (chosen != null && openToday && reservationsLoaded)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: slots.map((start) {
                                                        final m = start.hour * 60 + start.minute;
                              final inPause = pauseStart != null &&
                                  pauseEnd != null &&
                                  m < pauseEnd && m + duration > pauseStart;
                             final taken = occupied(
  start,
  start.add(Duration(minutes: duration)),
  reservations,
);
                              final past = !start.isAfter(DateTime.now());
                              final available = !inPause && !taken && !past;
                              final selected = selectedStart == start;
                              final unavailable = inPause || past;
                              final background = taken
                                  ? reservedRed
                                  : unavailable
                                      ? beige
                                      : selected
                                          ? gold
                                          : green;
                              final labelColor = unavailable || (selected && available)
                                  ? dark
                                  : Colors.white;
                              final status = taken
                                  ? 'Réservé'
                                  : unavailable
                                      ? (inPause ? 'Pause' : 'Indisponible')
                                      : selected
                                          ? 'Sélectionné'
                                          : 'Disponible';
                              return ChoiceChip(
                                label: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(timeLabel(start),
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 3),
                                    Text(status, style: const TextStyle(fontSize: 11)),
                                  ],
                                ),
                                selected: selected && available,
                                onSelected: available
                                    ? (_) => setState(() => selectedStart = start)
                                    : null,
                                selectedColor: gold,
                                backgroundColor: background,
                                disabledColor: background,
                                showCheckmark: false,
                                labelStyle: WidgetStateTextStyle.resolveWith(
                                  (_) => TextStyle(color: labelColor)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 12),
                        const Text(
                          'Vert : disponible · Rouge : réservé · Or : sélectionné · Beige : pause ou indisponible',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: dark,
                          ),
                          onPressed: busy || chosen == null ||
                                  selectedStart == null || !reservationsLoaded ||
                                  reservationsError != null
                              ? null
                              : () => book(chosen, duration),
                          child: Text(busy
                              ? 'Enregistrement...'
                              : automatic
                                  ? 'Confirmer le rendez-vous'
                                  : 'Demander ce rendez-vous'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      );

  String _durationLabel(dynamic raw) {
    final minutes = raw is num ? raw.toInt() : 30;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h ${rest.toString().padLeft(2, '0')}';
  }

  List<String> _photos(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<String>()
        .where((url) => Uri.tryParse(url)?.hasScheme == true &&
            (url.startsWith('https://') || url.startsWith('http://')))
        .toList();
  }

  Widget _serviceCard(
    String id,
    Map<String, dynamic> data, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final photos = _photos(data['photoUrls']);
    final description = (data['description'] ?? '').toString().trim();
    final info = (data['additionalInfo'] ?? '').toString().trim();
    final name = (data['name'] ?? 'Prestation').toString();
    final price = data['price'];
    final priceText = price is num
        ? (price == price.roundToDouble() ? price.toInt().toString() : price.toStringAsFixed(2))
        : (price ?? '0').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: green,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? gold : const Color(0xFF355443),
                  width: selected ? 2 : 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photos.isNotEmpty)
                  SizedBox(
                    height: 190,
                    child: PageView.builder(
                      itemCount: photos.length,
                      itemBuilder: (context, index) => Image.network(
                        photos[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image_outlined,
                                color: gold, size: 42)),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(name,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 18, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 8),
                          Text('$priceText €',
                              style: const TextStyle(color: gold, fontSize: 19,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.schedule, color: gold, size: 18),
                        const SizedBox(width: 6),
                        Text(_durationLabel(data['durationMinutes']),
                            style: const TextStyle(color: Colors.white)),
                        const Spacer(),
                        Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                            color: gold),
                      ]),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(description,
                            style: const TextStyle(color: Colors.white, height: 1.4)),
                      ],
                      if (info.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: dark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Informations complémentaires',
                                  style: TextStyle(color: gold,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text(info,
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                      if (photos.length > 1) ...[
                        const SizedBox(height: 10),
                        Text('${photos.length} photos · Faites glisser pour les voir',
                            style: const TextStyle(color: Colors.white70,
                                fontSize: 12)),
                      ],
                      if (selected) ...[
                        const SizedBox(height: 10),
                        const Text('Prestation sélectionnée · Choisissez une date ci-dessous',
                            style: TextStyle(color: gold, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget loading() => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: gold),
        ),
      );

  Widget note(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text, style: const TextStyle(color: Colors.white70)),
      );

  Widget error(String text) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: const TextStyle(color: Colors.orangeAccent)),
      );
}
