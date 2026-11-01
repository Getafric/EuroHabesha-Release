import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'professional_hours_screen.dart';

/// Gestion des rendez-vous et prestations d'un établissement.
class ProfessionalAppointmentsScreen extends StatefulWidget {
  final String businessId;
  final String sourceCollection;
  final String businessName;
  const ProfessionalAppointmentsScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
    required this.businessName,
  });

  @override
  State<ProfessionalAppointmentsScreen> createState() =>
      _ProfessionalAppointmentsScreenState();
}

class _ProfessionalAppointmentsScreenState
    extends State<ProfessionalAppointmentsScreen> {
  static const dark = Color(0xFF061E12);
  static const gold = Color(0xFFFFD700);
  static const green = Color(0xFF0C3022);
  ThemeData themed(BuildContext context) => Theme.of(context).copyWith(
    colorScheme: const ColorScheme.dark(primary: gold, onPrimary: dark, surface: green, onSurface: Colors.white),
    dialogTheme: const DialogThemeData(backgroundColor: green),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: gold)),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold)),
    ),
  );
  int tab = 0;
  DateTime selectedDay = DateTime.now();
  int agendaView = 1; // 0 jour, 1 semaine, 2 mois

  DocumentReference<Map<String, dynamic>> get parent =>
      FirebaseFirestore.instance.collection(widget.sourceCollection).doc(widget.businessId);
  CollectionReference<Map<String, dynamic>> get appointments =>
      parent.collection('appointments');
  CollectionReference<Map<String, dynamic>> get services =>
      parent.collection('appointmentServices');

  void showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')} min';
  }

  Future<bool> verifyBusinessOwner() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snapshot = await parent.get();
    final data = snapshot.data();
    return data != null && (data['ownerId'] == uid || data['submittedBy'] == uid);
  }

  Future<void> addService() async {
    String name = '';
    String description = '';
    String notes = '';
    String priceText = '';
    String minutesText = '30';
    int hours = 0;
    int remainingMinutes = 30;
    bool useHours = false;
    bool enabled = true;
    bool saving = false;
    final photos = <XFile>[];
    final picker = ImagePicker();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Theme(
        data: themed(dialogContext).copyWith(
          textTheme: Theme.of(dialogContext).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
          inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(color: gold),
            hintStyle: TextStyle(color: Colors.white60),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: gold)),
          ),
        ),
        child: StatefulBuilder(builder: (dialogContext, refresh) {
          final totalMinutes = useHours ? hours * 60 + remainingMinutes : int.tryParse(minutesText) ?? 0;
          Widget field(String label, ValueChanged<String> onChanged, {String? initial, int lines = 1, TextInputType? keyboard}) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  initialValue: initial,
                  onChanged: onChanged,
                  maxLines: lines,
                  keyboardType: keyboard,
                  cursorColor: gold,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(labelText: label),
                ),
              );
          return AlertDialog(
            backgroundColor: green,
            title: const Text('Ajouter une prestation', style: TextStyle(color: gold)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field('Nom de la prestation', (v) => name = v),
                  field('Description', (v) => description = v, lines: 3),
                  const Text('Photos de vos réalisations', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (photos.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: [
                    for (int i = 0; i < photos.length; i++)
                      Chip(
                        label: Text(photos[i].name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                        backgroundColor: dark,
                        deleteIconColor: gold,
                        onDeleted: saving ? null : () => refresh(() => photos.removeAt(i)),
                      ),
                  ]),
                  OutlinedButton.icon(
                    onPressed: saving ? null : () async {
                      try {
                        final selected = await picker.pickMultiImage(imageQuality: 85, maxWidth: 1600);
                        refresh(() {
                          for (final file in selected) {
                            if (photos.length >= 6) break;
                            if (!photos.any((p) => p.path == file.path)) photos.add(file);
                          }
                        });
                      } catch (e) { showMessage('Sélection impossible : $e'); }
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text('Ajouter des photos (${photos.length}/6)'),
                    style: OutlinedButton.styleFrom(foregroundColor: gold, side: const BorderSide(color: gold)),
                  ),
                  const SizedBox(height: 12),
                  field('Prix en euros', (v) => priceText = v, keyboard: const TextInputType.numberWithOptions(decimal: true)),
                  const Text('Durée de la prestation', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Choisir heures / minutes', style: TextStyle(color: Colors.white)),
                    value: useHours,
                    activeThumbColor: gold,
                    onChanged: saving ? null : (v) => refresh(() => useHours = v),
                  ),
                  if (!useHours)
                    field('Durée en minutes', (v) => refresh(() => minutesText = v),
                        initial: '30', keyboard: TextInputType.number)
                  else Row(children: [
                    Expanded(child: DropdownButtonFormField<int>(
                      initialValue: hours,
                      dropdownColor: green,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Heures'),
                      items: [for (int i = 0; i <= 8; i++) DropdownMenuItem(value: i, child: Text('$i h'))],
                      onChanged: saving ? null : (v) => refresh(() => hours = v ?? 0),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<int>(
                      initialValue: remainingMinutes,
                      dropdownColor: green,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Minutes'),
                      items: [for (int i = 0; i < 60; i += 5) DropdownMenuItem(value: i, child: Text('$i min'))],
                      onChanged: saving ? null : (v) => refresh(() => remainingMinutes = v ?? 0),
                    )),
                  ]),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Durée : ${formatDuration(totalMinutes)}',
                      style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                  field('Informations complémentaires (facultatif)', (v) => notes = v, lines: 3),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Réservable', style: TextStyle(color: Colors.white)),
                    value: enabled,
                    activeThumbColor: gold,
                    onChanged: saving ? null : (v) => refresh(() => enabled = v),
                  ),
                  if (saving) const LinearProgressIndicator(color: gold),
                ],
              )),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: dark),
                onPressed: saving ? null : () async {
                  final p = double.tryParse(priceText.trim().replaceAll(',', '.'));
                  if (name.trim().isEmpty || p == null || !p.isFinite || p < 0 || totalMinutes < 5 || totalMinutes > 480) {
                    showMessage('Nom, prix et durée valides requis (5 à 480 minutes).');
                    return;
                  }
                  refresh(() => saving = true);
                  try {
                    if (!await verifyBusinessOwner()) throw Exception('Compte non autorisé pour cet établissement.');
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    final serviceRef = services.doc();
                    final urls = <String>[];
                    for (int i = 0; i < photos.length; i++) {
                      final bytes = await photos[i].readAsBytes();
                      if (bytes.length >= 15 * 1024 * 1024) throw Exception('Une photo dépasse 15 Mo.');
                      final file = photos[i];
                      final lower = file.name.toLowerCase();
                      final type = lower.endsWith('.png') ? 'image/png' : lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
                      final extension = type == 'image/png' ? 'png' : type == 'image/webp' ? 'webp' : 'jpg';
                      final ref = FirebaseStorage.instance.ref('businesses/$uid/${serviceRef.id}_${i}_${DateTime.now().microsecondsSinceEpoch}.$extension');
                      await ref.putData(bytes, SettableMetadata(contentType: type));
                      urls.add(await ref.getDownloadURL());
                    }
                    await serviceRef.set({
                      'name': name.trim(),
                      'description': description.trim(),
                      'additionalInfo': notes.trim(),
                      'price': p,
                      'durationMinutes': totalMinutes,
                      'photoUrls': urls,
                      'enabled': enabled,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                  } catch (e) {
                    showMessage('Enregistrement impossible : $e');
                    refresh(() => saving = false);
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        }),
      ),
    );
    if (saved == true) showMessage('Prestation enregistrée.');
  }

  Future<void> changeStatus(DocumentReference<Map<String, dynamic>> ref, String status) async {
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw StateError('Rendez-vous introuvable.');
        final current = snap.data()?['status'];
        if (!((current == 'pending' && ['confirmed', 'rejected'].contains(status)) ||
            (current == 'confirmed' && status == 'completed'))) {
          throw StateError('Ce rendez-vous a déjà été traité.');
        }
        tx.update(ref, {'status': status, 'updatedAt': FieldValue.serverTimestamp()});
      });
      showMessage('Statut du rendez-vous mis à jour.');
    } catch (e) {
      showMessage('Modification refusée : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(body: Center(child: Text('Connexion requise')));
    }
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        foregroundColor: gold,
        title: Text(widget.businessName),
      ),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: _tabButton(0, Icons.calendar_month, 'Rendez-vous')),
              const SizedBox(width: 10),
              Expanded(child: _tabButton(1, Icons.design_services, 'Prestations')),
            ]),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfessionalHoursScreen(
                  businessId: widget.businessId, sourceCollection: widget.sourceCollection))),
              icon: const Icon(Icons.schedule),
              label: const Text('Horaires et disponibilités'),
              style: OutlinedButton.styleFrom(foregroundColor: gold,
                side: const BorderSide(color: gold)),
            ),
            if (tab == 1) FilledButton.icon(
              onPressed: addService,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une prestation'),
              style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: dark),
            ),
          ])),
        Expanded(child: tab == 0 ? buildAppointments() : buildServices()),
      ])),
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final active = tab == index;
    return Material(color: active ? gold : green,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(onTap: () => setState(() => tab = index),
        borderRadius: BorderRadius.circular(14),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            Icon(icon, color: active ? dark : gold),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: active ? dark : Colors.white,
              fontWeight: FontWeight.bold)),
          ])),
      ));
  }

  Widget buildServices() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: services.snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return error(snapshot.error);
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) return empty('Ajoutez votre première prestation avec le bouton +.');
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: docs.length,
        itemBuilder: (context, i) {
          final doc = docs[i];
          final data = doc.data();
          return Card(
            color: green,
            child: ListTile(
              leading: (data['photoUrls'] is List && (data['photoUrls'] as List).isNotEmpty)
                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(
                      (data['photoUrls'] as List).first.toString(), width: 54, height: 54,
                      fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: gold)))
                  : const Icon(Icons.design_services, color: gold),
              title: Text('${data['name'] ?? 'Prestation'}', style: const TextStyle(color: Colors.white)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${formatDuration((data['durationMinutes'] as num?)?.toInt() ?? 30)} · ${data['price'] ?? 0} €',
                    style: const TextStyle(color: gold)),
                if ((data['description'] ?? '').toString().isNotEmpty)
                  Text('${data['description']}', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white)),
                if ((data['additionalInfo'] ?? '').toString().isNotEmpty)
                  Text('${data['additionalInfo']}', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
              ]),
              trailing: Switch(
                value: data['enabled'] == true,
                activeThumbColor: gold,
                onChanged: (v) async {
                  try {
                    await doc.reference.update({'enabled': v});
                  } catch (e) {
                    showMessage('$e');
                  }
                },
              ),
            ),
          );
        },
      );
    },
  );

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);
  DateTime _weekStart(DateTime date) => _dayOnly(date).subtract(Duration(days: date.weekday - 1));
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _two(int n) => n.toString().padLeft(2, '0');
  String _dateLabel(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
  String _timeLabel(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  DateTime get _rangeStart {
    if (agendaView == 2) return DateTime(selectedDay.year, selectedDay.month, 1);
    if (agendaView == 1) return _weekStart(selectedDay);
    return _dayOnly(selectedDay);
  }

  DateTime get _rangeEnd {
    if (agendaView == 2) return DateTime(selectedDay.year, selectedDay.month + 1, 1);
    if (agendaView == 1) return _weekStart(selectedDay).add(const Duration(days: 7));
    return DateTime(selectedDay.year, selectedDay.month, selectedDay.day + 1);
  }

  void _navigate(int direction) {
    setState(() {
      if (agendaView == 2) {
        selectedDay = DateTime(selectedDay.year, selectedDay.month + direction, 1);
      } else {
        selectedDay = selectedDay.add(Duration(days: direction * (agendaView == 1 ? 7 : 1)));
      }
    });
  }

  Widget _agendaCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final ts = d['startAt'];
    if (ts is! Timestamp) return const SizedBox.shrink();
    final dt = ts.toDate().toLocal();
    final end = d['endAt'] is Timestamp ? (d['endAt'] as Timestamp).toDate().toLocal() : null;
    final status = (d['status'] ?? 'pending').toString();
    final isRejected = status == 'rejected' || status == 'cancelled';
    final color = isRejected ? Colors.white54 : status == 'confirmed' ? const Color(0xFFEF9A9A) : gold;
    return Card(
      color: green,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.event, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('${_timeLabel(dt)}${end == null ? '' : ' – ${_timeLabel(end)}'}  ·  ${d['serviceName'] ?? 'Prestation'}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 7),
          Text('Client : ${d['clientName'] ?? 'Client'}', style: const TextStyle(color: Colors.white)),
          Text('Date : ${_dateLabel(dt)}', style: const TextStyle(color: gold)),
          if ((d['clientEmail'] ?? '').toString().isNotEmpty)
            SelectableText('E-mail : ${d['clientEmail']}', style: const TextStyle(color: Colors.white)),
          if ((d['clientPhone'] ?? '').toString().isNotEmpty)
            SelectableText('Téléphone : ${d['clientPhone']}', style: const TextStyle(color: Colors.white)),
          Text('Statut : ${const {
            'pending': 'En attente', 'confirmed': 'Confirmé',
            'rejected': 'Refusé', 'cancelled': 'Annulé',
            'completed': 'Terminé',
          }[status] ?? status}', style: TextStyle(color: color)),
          if (status == 'pending') Wrap(spacing: 10, children: [
            TextButton(onPressed: () => changeStatus(doc.reference, 'confirmed'), child: const Text('Accepter', style: TextStyle(color: gold))),
            TextButton(onPressed: () => changeStatus(doc.reference, 'rejected'), child: const Text('Refuser', style: TextStyle(color: Colors.white))),
          ]),
          if (status == 'confirmed')
            TextButton(onPressed: () => changeStatus(doc.reference, 'completed'), child: const Text('Terminé', style: TextStyle(color: gold))),
        ]),
      ),
    );
  }

  Widget _dayAgenda(List<QueryDocumentSnapshot<Map<String, dynamic>>> all) {
    final docs = all.where((doc) {
      final ts = doc.data()['startAt'];
      return ts is Timestamp && _sameDay(ts.toDate().toLocal(), selectedDay);
    }).toList();
    final byHour = <int, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final doc in docs) {
      final hour = (doc.data()['startAt'] as Timestamp).toDate().toLocal().hour;
      byHour.putIfAbsent(hour, () => []).add(doc);
    }
    final hours = <int>{for (int h = 8; h <= 20; h++) h, ...byHour.keys}.toList()..sort();
    return ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 24), children: [
      Text('Journée du ${_dateLabel(selectedDay)}', style: const TextStyle(color: gold, fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      if (docs.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Aucun rendez-vous enregistré pour cette date. Les heures ci-dessous sont un repère visuel.', style: TextStyle(color: Colors.white70))),
      for (final hour in hours) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 58, child: Padding(padding: const EdgeInsets.only(top: 12), child: Text('${_two(hour)}:00', style: const TextStyle(color: gold)))),
        Expanded(child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF315343)))),
          child: byHour[hour] == null
              ? const Padding(padding: EdgeInsets.all(12), child: Text('—', style: TextStyle(color: Colors.white38)))
              : Column(children: byHour[hour]!.map(_agendaCard).toList()),
        )),
      ]),
    ]);
  }

  Widget _weekAgenda(List<QueryDocumentSnapshot<Map<String, dynamic>>> all) {
    final first = _weekStart(selectedDay);
    const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Row(children: [
        for (int i = 0; i < 7; i++) Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: () => setState(() { selectedDay = DateTime(first.year, first.month, first.day + i); agendaView = 0; }),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: _sameDay(DateTime(first.year, first.month, first.day + i), selectedDay) ? gold : green, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text(names[i], style: TextStyle(fontSize: 11, color: _sameDay(DateTime(first.year, first.month, first.day + i), selectedDay) ? dark : Colors.white70)),
                Text('${DateTime(first.year, first.month, first.day + i).day}', style: TextStyle(fontWeight: FontWeight.bold, color: _sameDay(DateTime(first.year, first.month, first.day + i), selectedDay) ? dark : Colors.white)),
              ]),
            ),
          ),
        )),
      ])),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime(first.year, first.month, first.day + index);
          final docs = all.where((doc) { final ts = doc.data()['startAt']; return ts is Timestamp && _sameDay(ts.toDate().toLocal(), date); }).toList();
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${names[index]} ${_dateLabel(date)} · ${docs.length} rendez-vous', style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
            if (docs.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Text('Aucun rendez-vous', style: TextStyle(color: Colors.white54))),
            ...docs.map(_agendaCard),
          ]));
        },
      )),
    ]);
  }

  Widget _monthAgenda(List<QueryDocumentSnapshot<Map<String, dynamic>>> all) {
    final first = DateTime(selectedDay.year, selectedDay.month, 1);
    final offset = first.weekday - 1;
    final daysInMonth = DateTime(selectedDay.year, selectedDay.month + 1, 0).day;
    final cells = ((offset + daysInMonth + 6) ~/ 7) * 7;
    final counts = <int, int>{};
    for (final doc in all) {
      final ts = doc.data()['startAt'];
      if (ts is! Timestamp) continue;
      final date = ts.toDate().toLocal();
      if (date.year == first.year && date.month == first.month) counts.update(date.day, (v) => v + 1, ifAbsent: () => 1);
    }
    const names = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [for (final n in names) Expanded(child: Center(child: Text(n, style: const TextStyle(color: gold, fontWeight: FontWeight.bold))))]),
      const SizedBox(height: 8),
      for (int row = 0; row < cells ~/ 7; row++)
        Row(children: [
          for (int col = 0; col < 7; col++) Expanded(child: Padding(
            padding: const EdgeInsets.all(2),
            child: Builder(builder: (context) {
              final n = row * 7 + col - offset + 1;
              if (n < 1 || n > daysInMonth) return const SizedBox(height: 62);
              final count = counts[n] ?? 0;
              final date = DateTime(first.year, first.month, n);
              final active = _sameDay(date, selectedDay);
              return InkWell(
                onTap: () => setState(() { selectedDay = date; agendaView = 0; }),
                borderRadius: BorderRadius.circular(9),
                child: Container(height: 62, decoration: BoxDecoration(color: active ? gold : green, borderRadius: BorderRadius.circular(9)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$n', style: TextStyle(color: active ? dark : Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (count > 0) Text('$count RDV', style: TextStyle(fontSize: 10, color: active ? dark : gold)),
                  ])),
              );
            }),
          )),
        ]),
      const SizedBox(height: 12),
      const Text('Touchez une date pour voir les heures et les détails des rendez-vous.', style: TextStyle(color: Colors.white70)),
    ]);
  }

  Widget buildAppointments() => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4), child: Column(children: [
      Row(children: [
        for (int i = 0; i < 3; i++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: agendaView == i ? gold : green, foregroundColor: agendaView == i ? dark : Colors.white, padding: const EdgeInsets.symmetric(horizontal: 3)),
          onPressed: () => setState(() => agendaView = i),
          child: Text(['Jour', 'Semaine', 'Mois'][i]),
        ))),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        IconButton(onPressed: () => _navigate(-1), icon: const Icon(Icons.chevron_left, color: gold)),
        Expanded(child: Text(agendaView == 2 ? '${_two(selectedDay.month)}/${selectedDay.year}' : agendaView == 1 ? '${_dateLabel(_weekStart(selectedDay))} – ${_dateLabel(_weekStart(selectedDay).add(const Duration(days: 6)))}' : _dateLabel(selectedDay), textAlign: TextAlign.center, style: const TextStyle(color: gold, fontWeight: FontWeight.bold))),
        IconButton(onPressed: () => _navigate(1), icon: const Icon(Icons.chevron_right, color: gold)),
        IconButton(onPressed: () async {
          final d = await showDatePicker(context: context, initialDate: selectedDay, firstDate: DateTime(2024), lastDate: DateTime(2100), builder: (context, child) => Theme(data: themed(context), child: child!));
          if (d != null && mounted) setState(() => selectedDay = d);
        }, icon: const Icon(Icons.calendar_month, color: gold)),
      ]),
    ])),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // DateTime local -> Timestamp conserve l'instant exact, y compris les changements d'heure.
      stream: appointments.where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_rangeStart))
          .where('startAt', isLessThan: Timestamp.fromDate(_rangeEnd)).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return error(snapshot.error);
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: gold));
        final docs = snapshot.data!.docs.where((doc) => doc.data()['startAt'] is Timestamp).toList()
          ..sort((a, b) => (a.data()['startAt'] as Timestamp).compareTo(b.data()['startAt'] as Timestamp));
        if (agendaView == 2) return _monthAgenda(docs);
        if (agendaView == 1) return _weekAgenda(docs);
        return _dayAgenda(docs);
      },
    )),
  ]);

  Widget empty(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70)),
    ),
  );

  Widget error(Object? e) => empty('Erreur Firestore : $e');
}
