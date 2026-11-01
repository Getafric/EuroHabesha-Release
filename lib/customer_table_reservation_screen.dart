import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Réservation de tables : demandes enregistrées dans Firestore.
class ClientTableReservationScreen extends StatefulWidget {
  final String businessId;
  final String sourceCollection;
  final String businessName;
  const ClientTableReservationScreen({super.key, required this.businessId,
    required this.sourceCollection, required this.businessName});

  @override
  State<ClientTableReservationScreen> createState() => _ClientTableReservationScreenState();
}

class _ClientTableReservationScreenState extends State<ClientTableReservationScreen> with WidgetsBindingObserver {
  static const bg = Color(0xFF061E12);
  static const gold = Color(0xFFFFD700);
  static const emerald = Color(0xFF137B59);
  String? selectedRoomId;
  String? selectedTableId;
  DateTime day = DateTime.now();
  TimeOfDay hour = const TimeOfDay(hour: 19, minute: 0);
  int guests = 2;
  bool _saving = false;
  bool _durationMode = false;
  int? _durationMinutes;
  DateTime? _reservationEnd;
  Map<String, dynamic>? _pendingRequest;
  String? _pendingUid;

  DateTime get _arrival =>
      DateTime(day.year, day.month, day.day, hour.hour, hour.minute);

  String _dateText(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} à '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  String _durationText(int minutes) => minutes == 90 ? '1 h 30' : '${minutes ~/ 60} h';

  String _errorText(Object error) {
    if (error is FirebaseFunctionsException) {
      if (error.code == 'failed-precondition') {
        return error.message ?? 'Les réglages ont changé. Actualisez les disponibilités.';
      }
      if (error.code == 'already-exists') {
        return 'Cette table est déjà demandée pendant cette période.';
      }
      if (error.code == 'unauthenticated') {
        return 'Reconnectez-vous pour réserver.';
      }
    }
    return 'Vérification impossible. Vérifiez la connexion puis réessayez.';
  }

  Future<bool> _readDurationMode() async {
    final profile = await FirebaseFirestore.instance
        .collection(widget.sourceCollection).doc(widget.businessId)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));
    if (!profile.exists) throw StateError('Établissement introuvable.');
    return profile.data()?['tableReservationMode'] == 'duration_v2';
  }

  // An uncertain network response must replay the exact same request, never
  // create a new request ID. Retained until success or a definite rejection.
  Future<void> _sendPendingRequest() async {
    final payload = _pendingRequest;
    if (payload == null) return;
    if (FirebaseAuth.instance.currentUser?.uid != _pendingUid) {
      throw StateError('Reconnectez-vous avec le compte utilisé pour cette demande.');
    }
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('createTableReservationV2')
          .call(payload).timeout(const Duration(seconds: 35));
      final raw = result.data;
      if (raw is! Map || raw['reservationId'] is! String ||
          raw['startMs'] is! num || raw['endMs'] is! num) {
        throw const FormatException('Réponse de réservation invalide.');
      }
      _pendingRequest = null;
      _pendingUid = null;
      if (!mounted) return;
      final status = <String, String>{'pending': 'En attente de confirmation',
        'accepted': 'Acceptée', 'rejected': 'Refusée', 'cancelled': 'Annulée'};
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        backgroundColor: bg,
        title: const Text('Demande enregistrée', style: TextStyle(color: gold)),
        content: Text('${_dateText(DateTime.fromMillisecondsSinceEpoch((raw['startMs'] as num).toInt()))}'
          '\nFin : ${_dateText(DateTime.fromMillisecondsSinceEpoch((raw['endMs'] as num).toInt()))}'
          '\n\n${status[raw['status']] ?? 'Consultez le suivi de votre réservation.'}'
          '\nUne demande en attente ne confirme pas encore votre table.',
          style: const TextStyle(color: Colors.white)),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Compris', style: TextStyle(color: gold)))],
      ));
    } on FirebaseFunctionsException catch (error) {
      if (['invalid-argument', 'failed-precondition', 'already-exists',
          'permission-denied', 'not-found', 'resource-exhausted',
          'unauthenticated'].contains(error.code)) {
        _pendingRequest = null;
        _pendingUid = null;
      }
      rethrow;
    }
  }

  Future<void> _retryPendingRequest() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _sendPendingRequest();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(error))));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        unawaited(_refreshAvailability());
      }
    }
  }


  Map<String, Map<String, String>> _availability = {};
  bool _availabilityLoading = true;
  bool _bookingEnabled = true;
  String? _availabilityError;
  int _availabilityRequest = 0;
  bool _foreground = true;
  bool _availabilityInFlight = false;
  Timer? _availabilityTimer;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) unawaited(_refreshAvailability());
    });
    _availabilityTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_foreground && !_saving && !_availabilityInFlight) {
        unawaited(_refreshAvailability(silent: true));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && !_saving) unawaited(_refreshAvailability());
  }

  @override
  void dispose() {
    _availabilityRequest++;
    _availabilityTimer?.cancel();
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshAvailability({bool silent = false}) async {
    if (!mounted) return;
    final requestId = ++_availabilityRequest;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _availabilityInFlight = false;
      setState(() {
        _availabilityLoading = false;
        _availabilityError = 'Connectez-vous pour voir les disponibilités et réserver.';
        _availability = {};
      });
      return;
    }
    _availabilityInFlight = true;
    // Construct both local boundaries independently to handle daylight saving.
    final block = (hour.hour ~/ 2) * 2;
    final start = DateTime(day.year, day.month, day.day, block);
    final end = DateTime(day.year, day.month, day.day, block + 2);
    if (!silent) setState(() {
      _availabilityLoading = true;
      _availabilityError = null;
    });
    try {
      final durationMode = await _readDurationMode();
      if (!mounted || requestId != _availabilityRequest) return;
      final arrival = _arrival;
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable(durationMode
              ? 'getTableReservationAvailabilityV2' : 'getTableReservationAvailability')
          .call(<String, dynamic>{
            'sourceCollection': widget.sourceCollection,
            'businessId': widget.businessId,
            'startMs': (durationMode ? arrival : start).millisecondsSinceEpoch,
            if (!durationMode) 'endMs': end.millisecondsSinceEpoch,
          }).timeout(const Duration(seconds: 35));
      if (!mounted || requestId != _availabilityRequest) return;
      final layout = await FirebaseFirestore.instance.collection(widget.sourceCollection)
          .doc(widget.businessId).collection('roomLayouts').doc('main')
          .get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 15));
      if (!mounted || requestId != _availabilityRequest) return;
      final layoutEnabled = layout.exists && layout.data()?['reservationsEnabled'] != false;
      final raw = result.data;
      if (raw is! Map || raw['enabled'] is! bool || raw['slots'] is! List) {
        throw const FormatException('Disponibilités invalides.');
      }
      int? duration;
      DateTime? reservationEnd;
      if (durationMode) {
        final value = raw['durationMinutes'];
        final endValue = raw['endMs'];
        if (value is! num || ![60, 90, 120, 180].contains(value) ||
            endValue is! num ||
            endValue != arrival.millisecondsSinceEpoch + value * 60000) {
          throw const FormatException('Durée de réservation invalide.');
        }
        duration = value.toInt();
        reservationEnd = DateTime.fromMillisecondsSinceEpoch(endValue.toInt());
      }
      final next = <String, Map<String, String>>{};
      for (final entry in raw['slots'] as List) {
        if (entry is! Map || entry['roomId'] is! String ||
            entry['tableId'] is! String ||
            !['pending', 'accepted'].contains(entry['status'])) {
          throw const FormatException('Disponibilités invalides.');
        }
        final roomId = entry['roomId'] as String;
        final tableId = entry['tableId'] as String;
        next.putIfAbsent(roomId, () => <String, String>{})[tableId] = entry['status'] as String;
      }
      setState(() {
        _durationMode = durationMode;
        _durationMinutes = duration;
        _reservationEnd = reservationEnd;
        _availability = next;
        _bookingEnabled = raw['enabled'] == true && layoutEnabled;
        _availabilityLoading = false;
        _availabilityError = null;
      });
    } catch (error) {
      if (!mounted || requestId != _availabilityRequest) return;
      setState(() {
        _availabilityLoading = false;
        _availabilityError = 'Disponibilités indisponibles. ${_errorText(error)}';
      });
    } finally {
      if (requestId == _availabilityRequest) _availabilityInFlight = false;
    }
  }

  String _tableStatus(Map<String, dynamic> room, Map<String, dynamic> table) {
    if (_availabilityLoading || _availabilityError != null) return 'unknown';
    if (!_bookingEnabled) return 'disabled';
    final slots = _availability[(room['roomId'] ?? '').toString()];
    final booked = slots?[_tableKey(table)] ?? slots?[(table['id'] ?? '').toString()];
    if (booked != null) return booked;
    return (table['status'] ?? 'available').toString();
  }

  bool _canReserve(Map<String, dynamic> room, Map<String, dynamic> table) =>
      _tableStatus(room, table) == 'available' &&
      _number(table['capacity'], 4) >= guests;

  String _slotId(String roomId, String tableId) {
    final date = "${day.year.toString().padLeft(4, '0')}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}";
    final block = (hour.hour ~/ 2) * 2;
    String safe(String value) => Uri.encodeComponent(value).replaceAll("%", "_");
    return "${date}_${block.toString().padLeft(2, '0')}_${safe(roomId)}_${safe(tableId)}";
  }

  Future<void> _reserve(Map<String, dynamic> room, Map<String, dynamic> table) async {
    if (_saving || _pendingRequest != null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connectez-vous pour réserver.")));
      return;
    }
    final when = DateTime(day.year, day.month, day.day, hour.hour, hour.minute);
    if (!when.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Choisissez une date et une heure futures.")));
      return;
    }
    final roomId = (room["roomId"] ?? "").toString();
    final tableId = _tableKey(table);
    if (roomId.isEmpty || tableId.isEmpty) return;
    final ref = FirebaseFirestore.instance.collection(widget.sourceCollection)
      .doc(widget.businessId).collection("tableReservations")
      .doc(_slotId(roomId, tableId));
    final requestedDurationMode = _durationMode;
    final requestedDuration = _durationMinutes;
    final requestedGuests = guests;
    final requestedSlotHour = (hour.hour ~/ 2) * 2;
    setState(() => _saving = true);
    try {
      final contact = await _contactForReservation(user);
      if (!mounted || contact == null) return;
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
        throw StateError('Votre session a changé. Reconnectez-vous.');
      }
      if (!when.isAfter(DateTime.now())) {
        throw StateError('Choisissez une date et une heure futures.');
      }
      // Recheck after the contact form: another client may have booked meanwhile.
      await _refreshAvailability();
      if (!mounted) return;
      if (_durationMode != requestedDurationMode ||
          (requestedDurationMode && _durationMinutes != requestedDuration)) {
        throw StateError('La durée a changé. Vérifiez le nouvel horaire puis envoyez à nouveau votre demande.');
      }
      if (!_canReserve(room, table)) {
        throw StateError(_availabilityError ??
            'Cette table n’est plus disponible pour ce créneau. Choisissez une autre table.');
      }
      if (requestedDurationMode) {
        final duration = requestedDuration;
        if (duration == null) throw StateError('Actualisez les disponibilités.');
        final end = when.add(Duration(minutes: duration));
        final confirmed = await showDialog<bool>(context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: bg,
            title: const Text('Vérifier votre demande', style: TextStyle(color: gold)),
            content: Text('Table ${table["id"] ?? tableId} · $requestedGuests personne(s)'
              '\nArrivée : ${_dateText(when)}\nFin : ${_dateText(end)}'
              '\nDurée : ${_durationText(duration)}'
              '\n\nLe restaurant doit encore accepter votre demande.',
              style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler', style: TextStyle(color: Colors.white70))),
              FilledButton(style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: bg),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Envoyer la demande')),
            ],
          ));
        if (!mounted || confirmed != true) return;
        _pendingUid = user.uid;
        _pendingRequest = <String, dynamic>{
          'requestId': FirebaseFirestore.instance.collection('tableReservations').doc().id,
          'sourceCollection': widget.sourceCollection, 'businessId': widget.businessId,
          'roomId': roomId, 'tableId': tableId, 'guests': requestedGuests,
          'startMs': when.millisecondsSinceEpoch,
          'expectedDurationMinutes': duration, ...contact,
        };
        await _sendPendingRequest();
        return;
      }
      // A mode change during the form must never fall back to a legacy write.
      if (await _readDurationMode()) {
        throw StateError('Les réservations ont changé. Actualisez puis confirmez à nouveau.');
      }
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final parentRef = FirebaseFirestore.instance.collection(widget.sourceCollection)
            .doc(widget.businessId);
        final profile = await tx.get(parentRef);
        final layout = await tx.get(parentRef.collection('roomLayouts').doc('main'));
        if (!profile.exists || profile.data()?['tableReservationsEnabled'] == false ||
            profile.data()?['tableReservationMode'] == 'duration_v2' ||
            !layout.exists || layout.data()?['reservationsEnabled'] == false) {
          throw StateError('Les réservations ont changé ou sont désactivées. Actualisez la page.');
        }
        final existing = await tx.get(ref);
        if (existing.exists && existing.data()?["status"] != "rejected" && existing.data()?["status"] != "cancelled") {
          throw StateError("Cette table est déjà demandée pour ce créneau de 2 heures.");
        }
        final payload = <String, dynamic>{
          "clientId": user.uid, "businessId": widget.businessId,
          "sourceCollection": widget.sourceCollection, "roomId": roomId,
          "tableId": tableId, "tableLabel": (table["id"] ?? tableId).toString(),
          "guests": requestedGuests, "dateTime": Timestamp.fromDate(when),
          ...contact,
          "roomName": (room["name"] ?? "Salle").toString(),
          "slotStartHour": requestedSlotHour, "status": "pending",
          "createdAt": FieldValue.serverTimestamp(),
        };
        if (existing.exists) {
          tx.update(ref, payload);
        } else {
          tx.set(ref, payload);
        }
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: 380,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: gold.withValues(alpha: .8), width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 22, offset: Offset(0, 12))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withValues(alpha: .12),
                    border: Border.all(color: gold, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Text('EH', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                const SizedBox(height: 14),
                const Icon(Icons.mark_email_read_outlined, color: gold, size: 38),
                const SizedBox(height: 12),
                const Text('Demande envoyée !', textAlign: TextAlign.center,
                  style: TextStyle(color: gold, fontSize: 23, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Text('Votre demande de réservation a bien été enregistrée.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15, height: 1.45)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF164536), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_outlined, color: gold, size: 19),
                      SizedBox(width: 8),
                      Flexible(child: Text('En attente de confirmation du restaurant',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Ce message ne confirme pas encore votre table.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: gold, foregroundColor: bg,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is StateError ? error.message.toString() : _errorText(error))));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        unawaited(_refreshAvailability());
      }
    }
  }

  String _contactText(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  Future<Map<String, String>?> _contactForReservation(User user) async {
    Map<String, dynamic> profile = {};
    try {
      final doc = await FirebaseFirestore.instance.collection('users')
          .doc(user.uid).get().timeout(const Duration(seconds: 5));
      profile = doc.data() ?? {};
    } catch (_) {
      // Le client peut saisir ses coordonnées si son profil est indisponible.
    }
    if (!mounted) return null;
    var name = _contactText([profile['displayName'], profile['fullName'],
      profile['name'], '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}',
      user.displayName]);
    var phone = _contactText([profile['phoneNumber'], profile['phone'], user.phoneNumber]);
    var email = _contactText([profile['email'], user.email]);
    final formKey = GlobalKey<FormState>();
    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: bg,
        title: const Text('Vos coordonnées', style: TextStyle(color: gold)),
        content: SingleChildScrollView(child: Form(key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Indiquez le nom de la réservation et au moins un moyen de contact. '
              'Ces coordonnées seront transmises au restaurant.',
              style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextFormField(initialValue: name, maxLength: 100,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Nom de la réservation',
                labelStyle: TextStyle(color: gold)),
              onChanged: (v) => name = v.trim(),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Indiquez votre nom.' : null),
            TextFormField(initialValue: phone, maxLength: 40,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Téléphone (facultatif)',
                labelStyle: TextStyle(color: gold)),
              onChanged: (v) => phone = v.trim()),
            TextFormField(initialValue: email, maxLength: 254,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'E-mail',
                labelStyle: TextStyle(color: gold)),
              onChanged: (v) => email = v.trim(),
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.isEmpty && phone.isEmpty) return 'Ajoutez un e-mail ou un téléphone.';
                if (text.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
                  return 'Vérifiez votre adresse e-mail.';
                }
                return null;
              }),
          ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: bg),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, <String, String>{
                'clientName': name, 'clientPhone': phone, 'clientEmail': email,
              });
            }, child: Text(_durationMode ? 'Continuer' : 'Envoyer la demande')),
        ],
      ),
    );
  }

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  int _number(dynamic value, int fallback) => value is num ? value.toInt() : fallback;
  double _fraction(dynamic value) => value is num ? value.toDouble().clamp(0.0, 1.0) : 0.0;
  String _tableKey(Map<String, dynamic> table) =>
      (table['qrId'] ?? table['id'] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance.collection(widget.sourceCollection)
        .doc(widget.businessId).collection('roomLayouts').doc('main');
    return PopScope(
      canPop: !_saving && _pendingRequest == null,
      child: Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, foregroundColor: gold,
        title: const Text('Réserver une table')),
      body: Column(children: [
        if (_pendingRequest != null) Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text('La réponse reste à vérifier. Réessayez la même demande pour éviter un doublon. Ne fermez pas cet écran.',
              style: TextStyle(color: gold)),
            TextButton(onPressed: _saving ? null : _retryPendingRequest,
              child: const Text('Vérifier ma demande', style: TextStyle(color: gold))),
          ]),
        ),
        Expanded(child: AbsorbPointer(absorbing: _saving || _pendingRequest != null, child: SafeArea(bottom: true, child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: doc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Plan indisponible. Vérifiez les autorisations Firebase.',
                style: TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: gold));
          }
          final rawRooms = snapshot.data!.data()?['rooms'];
          final rooms = rawRooms is List ? rawRooms.map(_map).toList() : <Map<String, dynamic>>[];
          if (rooms.isEmpty) {
            return const Center(child: Text('Aucun plan de salle publié par cet établissement.',
                style: TextStyle(color: Colors.white)));
          }
          final room = rooms.firstWhere(
            (r) => r['roomId'] == selectedRoomId,
            orElse: () => rooms.first,
          );
          final tables = (room['tables'] is List ? room['tables'] as List : <dynamic>[])
              .map(_map).toList();
          final selected = tables.where((t) => _tableKey(t) == selectedTableId).toList();
          final chosen = selected.isEmpty ? null : selected.first;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
            Text(widget.businessName, style: const TextStyle(color: gold,
                fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Choisissez une salle', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in rooms)
                ChoiceChip(label: Text((r['name'] ?? 'Salle').toString()),
                  selected: identical(r, room),
                  selectedColor: gold, backgroundColor: const Color(0xFF164536),
                  labelStyle: TextStyle(color: identical(r, room) ? bg : Colors.white),
                  onSelected: (_) => setState(() {
                    selectedRoomId = (r['roomId'] ?? '').toString();
                    selectedTableId = null;
                  })),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: gold),
                onPressed: () async {
                  final value = await showDatePicker(context: context,
                    initialDate: day.isBefore(DateUtils.dateOnly(DateTime.now())) ? DateTime.now() : day, firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (dialogContext, child) => Theme(
                      data: Theme.of(dialogContext).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: bg, onPrimary: gold, surface: Color(0xFFFFFCF0),
                          onSurface: bg, secondary: emerald, onSecondary: Colors.white),
                        datePickerTheme: DatePickerThemeData(
                          backgroundColor: const Color(0xFFFFFCF0),
                          headerBackgroundColor: bg, headerForegroundColor: gold,
                          dayForegroundColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected) ? gold : bg),
                          dayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected) ? bg : null),
                          todayForegroundColor: const WidgetStatePropertyAll(bg),
                          todayBorder: const BorderSide(color: emerald, width: 2),
                          cancelButtonStyle: TextButton.styleFrom(foregroundColor: bg),
                          confirmButtonStyle: TextButton.styleFrom(foregroundColor: bg),
                        ),
                      ),
                      child: child!,
                    ));
                  if (value != null && mounted) {
                    setState(() { day = value; selectedTableId = null; });
                    unawaited(_refreshAvailability());
                  }
                },
                icon: const Icon(Icons.calendar_month),
                label: Text('${day.day}/${day.month}/${day.year}'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: gold),
                onPressed: () async {
                  final value = await showTimePicker(context: context, initialTime: hour,
                     builder: (dialogContext, child) => Theme(
                       data: Theme.of(dialogContext).copyWith(
                         colorScheme: const ColorScheme.light(
                           primary: bg, onPrimary: gold, surface: Color(0xFFFFFCF0),
                           onSurface: bg, secondary: emerald, onSecondary: Colors.white),
                         timePickerTheme: const TimePickerThemeData(
                           backgroundColor: Color(0xFFFFFCF0),
                           dialBackgroundColor: Color(0xFFE4EEE7),
                           dialHandColor: bg, dialTextColor: bg,
                         ),
                       ), child: child!,
                     ));
                  if (value != null && mounted) {
                    setState(() { hour = value; selectedTableId = null; });
                    unawaited(_refreshAvailability());
                  }
                },
                icon: const Icon(Icons.schedule), label: Text(hour.format(context)))),
            ]),
            Row(children: [
              const Text('Personnes', style: TextStyle(color: Colors.white)),
              IconButton(onPressed: guests > 1 ? () => setState(() { guests--; selectedTableId = null; }) : null,
                icon: const Icon(Icons.remove_circle_outline, color: gold)),
              Text('$guests', style: const TextStyle(color: gold, fontSize: 18)),
              IconButton(onPressed: guests < 20 ? () => setState(() { guests++; selectedTableId = null; }) : null,
                icon: const Icon(Icons.add_circle_outline, color: gold)),
            ]),
            if (_durationMode && _durationMinutes != null && _reservationEnd != null &&
                !_availabilityLoading && _availabilityError == null)
              Padding(padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('Durée : ${_durationText(_durationMinutes!)}'
                  '\nArrivée : ${_dateText(_arrival)}\nFin : ${_dateText(_reservationEnd!)}',
                  style: const TextStyle(color: gold, fontWeight: FontWeight.bold))),
            if (_availabilityLoading) const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(color: gold)),
            if (_availabilityError != null) Text(_availabilityError!,
              style: const TextStyle(color: gold)),
            if (!_bookingEnabled && _availabilityError == null && !_availabilityLoading)
              const Text('Les réservations sont désactivées pour cet établissement.',
                style: TextStyle(color: gold)),
            Align(alignment: Alignment.centerRight, child: TextButton.icon(
              onPressed: _availabilityLoading || _saving ? null : () => _refreshAvailability(),
              icon: const Icon(Icons.refresh), label: const Text('Actualiser les disponibilités'),
              style: TextButton.styleFrom(foregroundColor: gold))),
            const Text('Plan de salle — choisissez votre table',
              style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, limits) {
              final width = limits.maxWidth;
              final height = width * 1.45;
              const margin = 12.0;
              return Container(height: height, clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: const Color(0xFF35463C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: gold)),
                child: Stack(children: [
                  const Positioned(left: 12, bottom: 10,
                    child: Text('⬆ ENTRÉE', style: TextStyle(color: Colors.white))),
                  for (final t in tables)
                    Builder(builder: (context) {
                      final capacity = _number(t['capacity'], 4);
                      final size = (58.0 + capacity.clamp(1, 20) * 4.6)
                          .clamp(62.0, (width - 28).clamp(62.0, 160.0));
                      final travelX = (width - size - 2 * margin).clamp(1.0, double.infinity);
                      final travelY = (height - size - 2 * margin).clamp(1.0, double.infinity);
                      final status = _tableStatus(room, t);
                      final enabled = _canReserve(room, t);
                      final picked = enabled && _tableKey(t) == selectedTableId;
                      final color = picked ? gold
                          : status == 'pending' ? const Color(0xFFA76500)
                          : status == 'accepted' || status == 'reserved' || status == 'occupied'
                              ? const Color(0xFFCC4849)
                          : status == 'available' && capacity >= guests ? emerald : Colors.blueGrey;
                      final statusLabel = status == 'pending' ? 'En attente'
                          : status == 'accepted' || status == 'reserved' ? 'Réservée'
                          : status == 'occupied' ? 'Occupée'
                          : status == 'unknown' ? 'À vérifier'
                          : status == 'disabled' ? 'Fermée'
                          : capacity < guests ? 'Trop petite' : 'Libre';
                      return Positioned(
                        left: margin + _fraction(t['x']) * travelX,
                        top: margin + _fraction(t['y']) * travelY,
                        child: GestureDetector(
                          onTap: enabled ? () => setState(() => selectedTableId = _tableKey(t)) : null,
                          child: Opacity(opacity: status == 'unknown' ? .6 : 1,
                            child: SizedBox(width: size, height: size,
                              child: Stack(alignment: Alignment.center, children: [
                                const Positioned(top: 2, child: Icon(Icons.chair, size: 18, color: Color(0xFFC7AD83))),
                                const Positioned(bottom: 2, child: Icon(Icons.chair, size: 18, color: Color(0xFFC7AD83))),
                                Container(width: size * .78,
                                  height: t['shape'] == 'rectangle' ? size * .57 : size * .78,
                                  decoration: BoxDecoration(color: color,
                                    shape: t['shape'] == 'round' ? BoxShape.circle : BoxShape.rectangle,
                                    borderRadius: t['shape'] == 'round' ? null : BorderRadius.circular(12),
                                    border: Border.all(color: picked ? Colors.white : gold, width: 2)),
                                  child: FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text('T${t['id']}', style: TextStyle(
                                      color: picked ? bg : Colors.white, fontWeight: FontWeight.bold)),
                                    Text('$capacity pers.', style: TextStyle(
                                      color: picked ? bg : Colors.white, fontSize: 10)),
                                    Text(statusLabel, style: TextStyle(
                                      color: picked ? bg : Colors.white, fontSize: 9)),
                                  ]))),
                              ]))),
                        ),
                      );
                    }),
                ]),
              );
            }),
            const SizedBox(height: 12),
            const Text('Vert : libre · Rouge : réservée ou occupée · Orange : en attente · Gris : indisponible ou à vérifier · Or : votre sélection',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 14),
            if (chosen != null) Text('Table T${chosen['id']} · ${chosen['capacity']} places',
              style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_durationMode
              ? 'La disponibilité est vérifiée pour toute la durée affichée. Le restaurant doit accepter votre demande.'
              : 'Les demandes sont regroupées par créneaux fixes de 2 heures (18 h–20 h, 20 h–22 h…). Le restaurant doit accepter votre demande.',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: bg,
                padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: chosen == null || _saving || !_canReserve(room, chosen)
                  ? null : () => _reserve(room, chosen),
              icon: Icon(_saving ? Icons.hourglass_top : Icons.event_available),
              label: Text(_saving ? 'Enregistrement…' : 'Envoyer ma demande de réservation'),
            ),
            const SizedBox(height: 80),
          ]);
        },
      )))),
      ]),
    ));
  }
}

/// Décor illustratif non interactif. Le plan des tables reste inchangé.
class _RestaurantDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()..color = const Color(0xFF9DAD96)..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    final light = Paint()..color = const Color(0xFFB9E8DF);
    final frame = Paint()..color = const Color(0xFFFFD700)..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final leaf = Paint()..color = const Color(0xFF66A96A);
    final leaf2 = Paint()..color = const Color(0xFF92C77A);
    final pot = Paint()..color = const Color(0xFFBB8661);
    final floor = Paint()..color = const Color(0x11FFFFFF)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), floor);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), floor);
    }
    canvas.drawLine(const Offset(0, 3), Offset(size.width, 3), wall);
    canvas.drawLine(const Offset(3, 0), Offset(3, size.height), wall);
    canvas.drawLine(Offset(size.width - 3, 0),
      Offset(size.width - 3, size.height), wall);
    for (final f in <double>[0.22, 0.72]) {
      final x = size.width * f;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 26, 1, 52, 12), const Radius.circular(3));
      canvas.drawRRect(r, light);
      canvas.drawRRect(r, frame);
      canvas.drawLine(Offset(x, 2), Offset(x, 12), frame);
    }
    for (final y in <double>[0.20, 0.76]) {
      final cy = size.height * y;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 13, cy - 27, 12, 54),
        const Radius.circular(3));
      canvas.drawRRect(r, light);
      canvas.drawRRect(r, frame);
    }
    for (final p in <Offset>[
      Offset(25, size.height * .42),
      Offset(size.width - 24, size.height * .92),
      Offset(25, size.height * .91),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: p + const Offset(0, 9), width: 17, height: 14),
        const Radius.circular(3)), pot);
      canvas.drawCircle(p + const Offset(-7, -2), 9, leaf);
      canvas.drawCircle(p + const Offset(6, -7), 10, leaf2);
      canvas.drawCircle(p + const Offset(0, -13), 8, leaf);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
