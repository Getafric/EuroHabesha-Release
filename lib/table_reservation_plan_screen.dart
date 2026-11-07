import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'table_reservation_slot.dart';
export 'table_reservation_slot.dart' show tableReservationStatusLabel;

/// Consultation du plan enregistré. Aucun déplacement ni changement de QR.
/// Le mode client ne lit QUE le document de sa propre réservation.
/// Le mode professionnel reste protégé par les règles Firestore existantes.
class TableReservationPlanScreen extends StatefulWidget {
  const TableReservationPlanScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
    this.professionalView = false,
    this.reservationId,
    this.initialRoomId,
    this.initialTableId,
    this.initialDate,
  });

  final String businessId;
  final String sourceCollection;
  final bool professionalView;
  final String? reservationId;
  final String? initialRoomId;
  final String? initialTableId;
  final DateTime? initialDate;

  @override
  State<TableReservationPlanScreen> createState() =>
      _TableReservationPlanScreenState();
}

class _TableReservationPlanScreenState
    extends State<TableReservationPlanScreen> {
  static const _dark = Color(0xFF061E12);
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF137B59);
  static const _red = Color(0xFFB7353A);
  static const _amber = Color(0xFFAD6900);
  late DateTime _date;
  String? _roomId;
  String? _tableId;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _layout;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _bookings;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _ownBooking;

  DocumentReference<Map<String, dynamic>> get _business => FirebaseFirestore
      .instance
      .collection(widget.sourceCollection)
      .doc(widget.businessId);

  @override
  void initState() {
    super.initState();
    _date = (widget.initialDate ?? DateTime.now()).toLocal();
    _roomId = widget.initialRoomId;
    _tableId = widget.initialTableId;
    _layout = _business.collection('roomLayouts').doc('main').snapshots();
    if (widget.professionalView) {
      _setBookingsStream();
    } else if (widget.reservationId?.isNotEmpty == true) {
      _ownBooking = _business
          .collection('tableReservations')
          .doc(widget.reservationId!)
          .snapshots();
    }
  }

  void _setBookingsStream() {
    final start = DateTime(_date.year, _date.month, _date.day);
    final end = DateTime(_date.year, _date.month, _date.day + 1);
    _bookings = _business
        .collection('tableReservations')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateTime', isLessThan: Timestamp.fromDate(end))
        .snapshots();
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map(_map).toList()
      : <Map<String, dynamic>>[];
  String _key(Map<String, dynamic> table) =>
      (table['qrId'] ?? table['id'] ?? '').toString();
  bool _matches(Map<String, dynamic> table, String? id) =>
      id != null &&
      id.isNotEmpty &&
      (_key(table) == id || '${table['id']}' == id);
  DateTime? _when(Map<String, dynamic> data) => data['dateTime'] is Timestamp
      ? (data['dateTime'] as Timestamp).toDate().toLocal()
      : null;
  String _dateText(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _timeText(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
  double _fraction(dynamic value) =>
      value is num ? value.toDouble().clamp(0.0, 1.0) : 0;

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );

  ThemeData _pickerTheme(BuildContext context) => Theme.of(context).copyWith(
    colorScheme: const ColorScheme.dark(
      primary: _gold,
      onPrimary: _dark,
      surface: _dark,
      onSurface: Colors.white,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _gold),
    ),
  );

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 5),
      lastDate: DateTime(_date.year + 5, 12, 31),
      builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _date = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _date.hour,
        _date.minute,
      );
      _tableId = null;
      _setBookingsStream();
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        selected.hour,
        selected.minute,
      );
      _tableId = null;
    });
  }

  Widget _reservationDetails(Map<String, dynamic> data) {
    final when = _when(data);
    final status = tableReservationStatusLabel(
      (data['status'] ?? 'pending').toString(),
    );
    String text(dynamic value) => value?.toString().trim() ?? '';
    final name = text(
      data['clientName'] ?? data['customerName'] ?? data['userName'],
    );
    final phone = text(data['clientPhone'] ?? data['customerPhone']);
    final email = text(data['clientEmail'] ?? data['customerEmail']);
    return Card(
      color: const Color(0xFF004D40),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Table ${data['tableLabel'] ?? data['tableId'] ?? 'non précisée'} · $status',
              style: const TextStyle(
                color: _gold,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in [
              if (when != null) '${_dateText(when)} à ${_timeText(when)}',
              '${data['guests'] ?? '-'} personne(s)',
              if (text(data['roomName']).isNotEmpty)
                'Salle : ${data['roomName']}',
              'Client : ${name.isEmpty ? 'Nom non renseigné' : name}',
              if (phone.isNotEmpty) 'Téléphone : $phone',
              if (email.isNotEmpty) 'E-mail : $email',
              if (phone.isEmpty && email.isEmpty)
                'Coordonnées non enregistrées pour cette réservation.',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: SelectableText(
                  line,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTable(
    Map<String, dynamic> table,
    List<Map<String, dynamic>> records,
  ) {
    setState(() => _tableId = _key(table));
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _dark,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .65,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppText(
                'Table ${table['id'] ?? ''}',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppText(
                '${table['capacity'] ?? '-'} places',
                style: const TextStyle(color: Colors.white70),
              ),
              if (records.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    widget.professionalView
                        ? 'Aucune demande pour cette table sur le créneau choisi. '
                              'Les éventuels blocages manuels restent appliqués.'
                        : 'Seule votre réservation est affichée ici.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              for (final data in records) _reservationDetails(data),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const AppText('Fermer', style: TextStyle(color: _gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plan(
    Map<String, dynamic> layout,
    List<Map<String, dynamic>> all, {
    required bool fromCache,
  }) {
    final rooms = _maps(layout['rooms']);
    if (rooms.isEmpty) return _message('Aucun plan de salle enregistré.');
    final matches = rooms
        .where((r) => r['roomId']?.toString() == _roomId)
        .toList();
    if (_roomId != null && matches.isEmpty) {
      return _message(
        'La salle de cette réservation ne figure plus dans le plan actuel. '
        'Les informations de la réservation restent conservées.',
      );
    }
    final room = matches.isEmpty ? rooms.first : matches.first;
    final tables = _maps(room['tables']);
    final roomId = room['roomId']?.toString() ?? '';
    final slot = all.where((r) {
      final date = _when(r);
      return date != null && isInTableReservationSlot(date, _date);
    }).toList();
    final records = (widget.professionalView ? slot : all)
        .where((r) => r['roomId']?.toString() == roomId)
        .toList();
    List<Map<String, dynamic>> forTable(Map<String, dynamic> t) =>
        records.where((r) => _matches(t, r['tableId']?.toString())).toList();
    final selectedMissing =
        _tableId != null && !tables.any((t) => _matches(t, _tableId));
    final blockStart = (_date.hour ~/ 2) * 2;
    final accepted = tables
        .where((t) => forTable(t).any((r) => r['status'] == 'accepted'))
        .length;
    final pending = tables
        .where((t) => forTable(t).any((r) => r['status'] == 'pending'))
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (fromCache)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: AppText(
              'Données en cache : reconnectez-vous pour vérifier les dernières réservations.',
              style: TextStyle(color: _gold),
            ),
          ),
        if (widget.professionalView) ...[
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(_dateText(_date)),
                style: OutlinedButton.styleFrom(foregroundColor: _gold),
              ),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule),
                label: Text(_timeText(_date)),
                style: OutlinedButton.styleFrom(foregroundColor: _gold),
              ),
            ],
          ),
          AppText(
            'Créneau : ${blockStart.toString().padLeft(2, '0')} h–'
            '${(blockStart + 2).toString().padLeft(2, '0')} h',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          AppText(
            '$accepted table(s) acceptée(s) · $pending en attente',
            style: const TextStyle(color: _gold, fontWeight: FontWeight.bold),
          ),
        ] else ...[
          for (final data in all) _reservationDetails(data),
          const AppText(
            'Votre table est entourée en or. Les réservations des autres clients '
            'ne sont pas affichées.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in rooms)
              ChoiceChip(
                label: Text((r['name'] ?? 'Salle').toString()),
                selected: identical(r, room),
                selectedColor: _gold,
                backgroundColor: const Color(0xFF004D40),
                labelStyle: TextStyle(
                  color: identical(r, room) ? _dark : Colors.white,
                ),
                onSelected: widget.professionalView
                    ? (_) => setState(() {
                        _roomId = r['roomId']?.toString();
                        _tableId = null;
                      })
                    : null,
              ),
          ],
        ),
        if (selectedMissing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: AppText(
              'Cette table a été retirée ou son identifiant a changé dans le plan actuel.',
              style: TextStyle(color: _gold),
            ),
          ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final width = constraints.maxWidth;
            final height = width * 1.45;
            return Container(
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF304536),
                border: Border.all(color: _gold),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    left: 12,
                    bottom: 10,
                    child: AppText(
                      '↑ ENTRÉE',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  for (final table in tables)
                    Builder(
                      builder: (context) {
                        final capacity = table['capacity'] is num
                            ? (table['capacity'] as num).toInt()
                            : 4;
                        final size = (58.0 + capacity.clamp(1, 20) * 4.6).clamp(
                          62.0,
                          (width - 28).clamp(62.0, 160.0),
                        );
                        final tableRecords = forTable(table);
                        final active = tableRecords
                            .where(
                              (r) => blocksTableReservationSlot(
                                (r['status'] ?? 'pending').toString(),
                              ),
                            )
                            .toList();
                        final confirmed = active.any(
                          (r) => r['status'] == 'accepted',
                        );
                        final selected = _matches(table, _tableId);
                        final manual =
                            (table['status'] ?? 'available') != 'available';
                        final color = confirmed
                            ? _red
                            : active.isNotEmpty
                            ? _amber
                            : !widget.professionalView || manual
                            ? Colors.blueGrey
                            : _green;
                        final label = confirmed
                            ? 'Acceptée'
                            : active.isNotEmpty
                            ? 'En attente'
                            : !widget.professionalView
                            ? 'Table'
                            : manual
                            ? 'Blocage manuel'
                            : 'Libre';
                        return Positioned(
                          left:
                              12 +
                              _fraction(table['x']) *
                                  (width - size - 24).clamp(
                                    1.0,
                                    double.infinity,
                                  ),
                          top:
                              12 +
                              _fraction(table['y']) *
                                  (height - size - 24).clamp(
                                    1.0,
                                    double.infinity,
                                  ),
                          child: Semantics(
                            label:
                                'Table ${table['id']}, $label, $capacity places',
                            button: true,
                            selected: selected,
                            child: GestureDetector(
                              onTap: () => _showTable(table, tableRecords),
                              child: SizedBox(
                                width: size,
                                height: size,
                                child: Center(
                                  child: Container(
                                    width: size * .78,
                                    height: table['shape'] == 'rectangle'
                                        ? size * .57
                                        : size * .78,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: table['shape'] == 'round'
                                          ? BoxShape.circle
                                          : BoxShape.rectangle,
                                      borderRadius: table['shape'] == 'round'
                                          ? null
                                          : BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? _gold
                                            : Colors.white54,
                                        width: selected ? 4 : 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        table['shape'] == 'round' ? 12 : 6,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AppText(
                                              'T${table['id'] ?? ''}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            AppText(
                                              '$capacity places',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                              ),
                                            ),
                                            Text(
                                              label,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (widget.professionalView)
          const AppText(
            'Rouge : acceptée · Orange : en attente · Vert : libre sur ce créneau · '
            'Gris : blocage manuel · Bordure or : table sélectionnée.\n'
            'Touchez une table pour consulter ses réservations.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        if (widget.professionalView) ...[
          const SizedBox(height: 12),
          for (final data in records.where(
            (r) =>
                _tableId == null ||
                tables.any(
                  (t) =>
                      _matches(t, _tableId) &&
                      _matches(t, r['tableId']?.toString()),
                ),
          ))
            _reservationDetails(data),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _dark,
    appBar: AppBar(
      backgroundColor: _dark,
      foregroundColor: _gold,
      title: Text(
        widget.professionalView ? 'Plan des réservations' : 'Ma table',
      ),
    ),
    body: SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _layout,
        builder: (context, layoutSnapshot) {
          if (layoutSnapshot.hasError)
            return _message('Impossible de charger le plan de salle.');
          if (!layoutSnapshot.hasData)
            return const Center(child: CircularProgressIndicator(color: _gold));
          final layout = layoutSnapshot.data!.data();
          if (layout == null)
            return _message('Aucun plan de salle enregistré.');
          if (widget.professionalView) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _bookings,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return _message(
                    'Impossible de consulter les réservations. '
                    'Vérifiez que vous êtes connecté au compte propriétaire de cet établissement.',
                  );
                if (!snapshot.hasData ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _gold),
                  );
                }
                return _plan(
                  layout,
                  snapshot.data!.docs.map((d) => d.data()).toList(),
                  fromCache:
                      snapshot.data!.metadata.isFromCache ||
                      layoutSnapshot.data!.metadata.isFromCache,
                );
              },
            );
          }
          if (_ownBooking == null) return _message('Réservation non précisée.');
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _ownBooking,
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return _message('Impossible de consulter votre réservation.');
              if (!snapshot.hasData)
                return const Center(
                  child: CircularProgressIndicator(color: _gold),
                );
              final data = snapshot.data!.data();
              if (data == null) return _message('Réservation introuvable.');
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null ||
                  (data['clientId'] != uid && data['userId'] != uid)) {
                return _message('Accès réservé au client concerné.');
              }
              return _plan(
                layout,
                [data],
                fromCache:
                    snapshot.data!.metadata.isFromCache ||
                    layoutSnapshot.data!.metadata.isFromCache,
              );
            },
          );
        },
      ),
    ),
  );
}
