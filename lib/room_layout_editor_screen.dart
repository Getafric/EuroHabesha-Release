import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'table_reservation_plan_screen.dart';

/// Euro Habesha — plans de salles avec sauvegarde Firebase et copie locale.
/// Remplacer uniquement le fichier qui contient RoomLayoutEditorScreen.
class RoomLayoutEditorScreen extends StatefulWidget {
  final String businessName;
  final String businessId;
  final String sourceCollection;
  const RoomLayoutEditorScreen({
    super.key,
    required this.businessName,
    required this.businessId,
    required this.sourceCollection,
  });

  @override
  State<RoomLayoutEditorScreen> createState() => _RoomLayoutEditorScreenState();
}

String _newStableId() {
  final random = Random.secure();
  return base64UrlEncode(List<int>.generate(18, (_) => random.nextInt(256))).replaceAll('=', '');
}

class _EhTable {
  _EhTable({required this.id, required this.x, required this.y, String? qrId,
    this.capacity = 4, this.status = 'available', this.shape = 'square'}) : qrId = qrId ?? _newStableId();
  int id;
  late String qrId;
  double x, y;
  int capacity;
  String status, shape;
  Map<String, dynamic> toJson() => {
    'qrId': qrId, 'id': id, 'x': x, 'y': y, 'capacity': capacity,
    'status': status, 'shape': shape,
  };
  factory _EhTable.fromJson(Map<String, dynamic> m) => _EhTable(
    qrId: m['qrId'] as String?,
    id: (m['id'] as num?)?.toInt() ?? 1,
    x: ((m['x'] as num?)?.toDouble() ?? .1).clamp(0.0, 1.0),
    y: ((m['y'] as num?)?.toDouble() ?? .1).clamp(0.0, 1.0),
    capacity: (m['capacity'] as num?)?.toInt() ?? 4,
    status: (m['status'] ?? (m['reserved'] == true ? 'reserved' : 'available')).toString(),
    shape: (m['shape'] ?? 'square').toString(),
  );
}

class _EhRoom {
  _EhRoom({required this.name, required this.kind, required this.tables, this.photoUrl = '', String? roomId}) : roomId = roomId ?? _newStableId();
  final String roomId;
  String name, kind, photoUrl;
  List<_EhTable> tables;
  Map<String, dynamic> toJson() => {
    'roomId': roomId, 'name': name, 'kind': kind, 'photoUrl': photoUrl,
    'tables': tables.map((e) => e.toJson()).toList(),
  };
  factory _EhRoom.fromJson(Map<String, dynamic> m) => _EhRoom(
    roomId: m['roomId'] as String?,
    name: (m['name'] ?? 'Salle').toString(),
    kind: (m['kind'] ?? 'Restaurant').toString(),
    photoUrl: (m['photoUrl'] ?? '').toString(),
    tables: ((m['tables'] as List?) ?? [])
        .map((e) => _EhTable.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class _RoomLayoutEditorScreenState extends State<RoomLayoutEditorScreen> {
  static const _bg = Color(0xFF061E12);
  static const _panel = Color(0xFF0A382C);
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF137B59);
  static const _red = Color(0xFFCC4849);
  static const _amber = Color(0xFFF0AA32);
  final List<_EhRoom> _rooms = [];
  int _selected = -1;
  bool _loading = true, _dirty = false, _saving = false, _list = false;
  bool _needsQrMigration = false;
  bool _reservationsEnabled = false;
  int? _reservationDurationMinutes;
  bool _durationEdited = false;
  static const _durationOptions = <int, String>{
    60: '1 h', 90: '1 h 30', 120: '2 h', 180: '3 h',
  };

  String get _key => 'euro_habesha_room_layout_v4_${widget.sourceCollection}_${widget.businessId}';
  String get _legacyKey => 'euro_habesha_room_layout_v3_${widget.businessName.trim().toLowerCase()}';
  DocumentReference<Map<String, dynamic>> get _remoteDoc => FirebaseFirestore.instance
      .collection(widget.sourceCollection).doc(widget.businessId)
      .collection('roomLayouts').doc('main');
  _EhRoom get _room => _rooms[_selected];

  @override
  void initState() { super.initState(); _load(); }

  List<_EhTable> _exampleTables(int count) => List.generate(count, (i) => _EhTable(
    id: i + 1,
    x: .08 + (i % 3) * .38,
    y: .07 + (i ~/ 3) * .28,
  ));

  Future<void> _load() async {
    try {
      // La version distante prime sur la copie locale lorsqu'elle existe.
      final remote = await _remoteDoc.get();
      final data = remote.data();
      if (data != null && data['rooms'] is List) {
        _reservationsEnabled = data['reservationsEnabled'] == true;
        final savedDuration = data['reservationDurationMinutes'];
        if (savedDuration is int && _durationOptions.containsKey(savedDuration)) {
          _reservationDurationMinutes = savedDuration;
        }
        _needsQrMigration = _hasLegacyIds(data['rooms'] as List);
        _rooms.addAll((data['rooms'] as List)
            .map((e) => _EhRoom.fromJson(Map<String, dynamic>.from(e as Map))));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_key, jsonEncode(_rooms.map((e) => e.toJson()).toList()));
      } else {
        await _loadLocal();
      }
    } catch (e) {
      debugPrint('Lecture Firebase impossible : $e');
      await _loadLocal();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Firebase inaccessible : affichage du plan local. Vérifiez la connexion et les autorisations.')));
    }
    if (_rooms.isEmpty) {
      _rooms.add(_EhRoom(name: 'Salle principale', kind: 'Restaurant', tables: _exampleTables(9)));
      _needsQrMigration = true;
    }
    if (mounted) setState(() { _loading = false; _dirty = _needsQrMigration; });
  }

  bool _hasLegacyIds(List<dynamic> rooms) {
    for (final item in rooms) {
      if (item is! Map || item['roomId'] is! String || (item['roomId'] as String).isEmpty) return true;
      for (final table in (item['tables'] as List? ?? [])) {
        if (table is! Map || table['qrId'] is! String || (table['qrId'] as String).isEmpty) return true;
      }
    }
    return false;
  }

  Future<void> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key) ?? prefs.getString(_legacyKey) ??
          prefs.getString('eurohabesha_room_layout_v2_${widget.businessName.trim().toLowerCase()}');
      if (raw != null) {
        final data = jsonDecode(raw) as List;
        _needsQrMigration = _hasLegacyIds(data);
        _rooms.addAll(data.map((e) => _EhRoom.fromJson(Map<String, dynamic>.from(e as Map))));
      }
    } catch (e) {
      debugPrint('Lecture locale impossible : $e');
    }
  }

  void _change(VoidCallback action) {
    setState(() { action(); _dirty = true; });
  }

  Future<bool> _save() async {
    if (_saving) return false;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour enregistrer sur Firebase.')));
      return false;
    }
    setState(() => _saving = true);
    try {
      // Vérification du propriétaire avant l'écriture. Les règles Firestore
      // doivent également imposer cette vérification côté serveur.
      final parent = await FirebaseFirestore.instance
          .collection(widget.sourceCollection).doc(widget.businessId).get();
      if (!parent.exists || parent.data()?['ownerId'] != uid) {
        throw StateError('Cet établissement ne vous appartient pas ou est inaccessible.');
      }
      final rooms = _rooms.map((e) => e.toJson()).toList();
      await _remoteDoc.set({
        'ownerId': uid,
        'businessId': widget.businessId,
        'sourceCollection': widget.sourceCollection,
        'rooms': rooms,
        'reservationsEnabled': _reservationsEnabled,
        // Only an explicit choice changes the saved duration. A local fallback
        // must not replace a remote setting with an assumed default.
        if (_durationEdited && _reservationDurationMinutes != null)
          'reservationDurationMinutes': _reservationDurationMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _durationEdited = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(rooms));
      if (mounted) {
        setState(() => _dirty = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Salles et tables enregistrées dans Firebase.')));
      }
      return true;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sauvegarde Firebase impossible : $e')));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _durationSettings() {
    final minutes = _reservationDurationMinutes;
    final endMinutes = 19 * 60 + (minutes ?? 120);
    final endHour = (endMinutes ~/ 60).toString().padLeft(2, '0');
    final endMinute = (endMinutes % 60).toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: .5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Durée d’une réservation', style: TextStyle(
          color: _gold, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Choisissez le temps prévu à table pour votre établissement.',
          style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final option in _durationOptions.entries)
            ChoiceChip(
              label: Text(option.value),
              selected: minutes == option.key,
              selectedColor: _gold,
              backgroundColor: _bg,
              checkmarkColor: _bg,
              labelStyle: TextStyle(
                color: minutes == option.key ? _bg : Colors.white),
              onSelected: _saving ? null : (_) => _change(() {
                _reservationDurationMinutes = option.key;
                _durationEdited = true;
              }),
            ),
        ]),
        const SizedBox(height: 12),
        Text(minutes == null
            ? 'Choisissez une durée, puis enregistrez les modifications.'
            : 'Exemple après activation : arrivée à 19 h 00, '
              'table réservée jusqu’à $endHour h $endMinute.',
          style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Text(_durationEdited ? 'Durée sélectionnée — non enregistrée.'
            : minutes == null ? 'Aucune durée configurée.' : 'Durée enregistrée.',
          style: const TextStyle(color: _gold, fontSize: 12)),
        const SizedBox(height: 8),
        const Text('En préparation : ce réglage sera appliqué aux nouvelles '
          'réservations après activation du système de durées. Pour le moment, '
          'les créneaux fixes de 2 heures restent utilisés.',
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
      ]),
    );
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final action = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: _panel,
      title: const Text('Modifications non enregistrées', style: TextStyle(color: _gold)),
      content: const Text('Enregistrer vos salles et vos tables avant de quitter ?', style: TextStyle(color: Colors.white)),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
          onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Rester')),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF8585)),
          onPressed: () => Navigator.pop(ctx, 'discard'), child: const Text('Quitter sans enregistrer')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
          onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Enregistrer')),
      ],
    ));
    if (action == 'save') return _save();
    return action == 'discard';
  }

  Future<void> _editRoom({_EhRoom? existing}) async {
    var name = existing?.name ?? '';
    var kind = existing?.kind ?? 'Restaurant';
    var photoUrl = existing?.photoUrl ?? '';
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
        backgroundColor: _panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: _gold)),
        title: Text(existing == null ? 'Ajouter une salle' : 'Modifier la salle',
          style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Nom de la salle', style: TextStyle(color: _gold)),
          TextFormField(initialValue: name, maxLength: 60,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Ex. Étage 1, Terrasse, Balcon', hintStyle: TextStyle(color: Colors.white54)),
            onChanged: (v) => name = v),
          const SizedBox(height: 12),
          const Text('Photo de la salle (facultatif)', style: TextStyle(color: _gold)),
          const SizedBox(height: 6),
          const Text('Colle un lien HTTPS vers une photo de ton établissement.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          TextFormField(initialValue: photoUrl,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'https://exemple.com/salle.jpg', hintStyle: TextStyle(color: Colors.white54)),
            onChanged: (v) => photoUrl = v.trim()),
          const SizedBox(height: 12),
          const Text('Type / emplacement', style: TextStyle(color: _gold)),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (final value in ['Restaurant', 'Étage 1', 'Étage 2', 'Terrasse', 'Balcon', 'Salon privé', 'Autre'])
              ChoiceChip(label: Text(value), selected: kind == value,
                onSelected: (_) => refresh(() => kind = value),
                selectedColor: _gold, backgroundColor: _bg,
                labelStyle: TextStyle(color: kind == value ? _bg : Colors.white)),
          ]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
            onPressed: () { if (name.trim().isNotEmpty) Navigator.pop(ctx, {'name': name.trim(), 'kind': kind, 'photoUrl': photoUrl}); },
            child: const Text('Enregistrer')),
        ],
      )),
    );
    if (!mounted || result == null) return;
    _change(() {
      if (existing != null) {
        existing.name = result['name']!;
        existing.kind = result['kind']!;
        existing.photoUrl = result['photoUrl'] ?? '';
      } else {
        _rooms.add(_EhRoom(name: result['name']!, kind: result['kind']!, photoUrl: result['photoUrl'] ?? '', tables: []));
        _selected = _rooms.length - 1;
      }
    });
  }

  Uri _tableUri(_EhRoom room, _EhTable table) => Uri.https(
    'eurohabesha.eu', '/table', {
      'source': widget.sourceCollection,
      'businessId': widget.businessId,
      'roomId': room.roomId,
      'tableId': table.qrId,
    });

  Future<void> _showQr(_EhTable table) async {
    if (_dirty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enregistre d’abord le plan pour activer le QR code permanent.')));
      return;
    }
    final room = _room;
    final url = _tableUri(room, table).toString();
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => _EhQrPage(
        businessName: widget.businessName,
        roomName: room.name,
        tableNumber: table.id,
        url: url,
      ),
    ));
  }

  Future<void> _editTable(_EhTable table) async {
    var capacity = table.capacity;
    var status = table.status;
    var shape = table.shape;
    final action = await showDialog<String>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
        backgroundColor: _panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: _gold)),
        title: Text('Table T${table.id}', style: const TextStyle(color: _gold)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Capacité : $capacity personnes', style: const TextStyle(color: Colors.white)),
          const Text('La table grandit automatiquement sur le plan.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Row(children: [
            IconButton(onPressed: capacity > 1 ? () => refresh(() => capacity--) : null,
              icon: const Icon(Icons.remove_circle_outline, color: _gold)),
            Expanded(child: Slider(value: capacity.toDouble(), min: 1, max: 20, divisions: 19,
              activeColor: _gold, onChanged: (v) => refresh(() => capacity = v.round()))),
            IconButton(onPressed: capacity < 20 ? () => refresh(() => capacity++) : null,
              icon: const Icon(Icons.add_circle_outline, color: _gold)),
          ]),
          const Text('Forme', style: TextStyle(color: _gold)),
          Wrap(spacing: 7, children: [
            for (final value in ['square', 'round', 'rectangle'])
              ChoiceChip(label: Text(value == 'square' ? 'Carrée' : value == 'round' ? 'Ronde' : 'Rectangle'),
                selected: shape == value, selectedColor: _gold, backgroundColor: _bg,
                labelStyle: TextStyle(color: shape == value ? _bg : Colors.white),
                onSelected: (_) => refresh(() => shape = value)),
          ]),
          const SizedBox(height: 12),
          const Text('Disponibilité', style: TextStyle(color: _gold)),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (final value in ['available', 'reserved', 'occupied'])
              ChoiceChip(label: Text(value == 'available' ? 'Disponible' : value == 'reserved' ? 'Réservée' : 'En cours'),
                selected: status == value, selectedColor: _gold, backgroundColor: _bg,
                labelStyle: TextStyle(color: status == value ? _bg : Colors.white),
                onSelected: (_) => refresh(() => status = value)),
          ]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'qr'),
            child: const Text('QR code', style: TextStyle(color: _gold))),
          TextButton(onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Supprimer', style: TextStyle(color: _red))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
            onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Enregistrer')),
        ],
      )),
    );
    if (!mounted) return;
    if (action == 'qr') {
      // La page QR s’ouvre après la fermeture du dialogue de modification.
      await _showQr(table);
      return;
    }
    if (action == 'delete') _change(() => _room.tables.remove(table));
    if (action == 'save') _change(() { table.capacity = capacity; table.status = status; table.shape = shape; });
  }

  void _addTable() {
    _change(() {
      final tables = _room.tables;
      final next = tables.fold<int>(0, (max, t) => t.id > max ? t.id : max) + 1;
      final n = tables.length;
      tables.add(_EhTable(id: next, x: (.08 + (n % 3) * .38).clamp(0.0, 1.0),
        y: (.07 + ((n ~/ 3) % 4) * .25).clamp(0.0, 1.0)));
    });
  }

  Color _statusColor(String status) => status == 'reserved' ? _red : status == 'occupied' ? _amber : _green;
  int _reserved(_EhRoom room) => room.tables.where((e) => e.status == 'reserved').length;
  int _available(_EhRoom room) => room.tables.where((e) => e.status == 'available').length;
  int _capacity(_EhRoom room) => room.tables.fold(0, (sum, t) => sum + t.capacity);

  Widget _goldButton(String text, IconData icon, VoidCallback onTap) => SizedBox(
    width: double.infinity, height: 54,
    child: FilledButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))));

  Widget _summary(_EhRoom room) => Container(
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white12)),
    child: Row(children: [
      _stat(Icons.table_restaurant, '${room.tables.length}', 'Tables', _gold),
      _stat(Icons.event_busy, '${_reserved(room)}', 'Blocages manuels', _red),
      _stat(Icons.check_circle, '${_available(room)}', 'Sans blocage', const Color(0xFF4BE38D)),
    ]));

  Widget _stat(IconData icon, String number, String label, Color color) => Expanded(
    child: Column(children: [Icon(icon, color: color, size: 23),
      Text(number, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]));

  Widget _roomPicker() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(widget.businessName, style: const TextStyle(color: _gold, fontSize: 19, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    const Text('Mes salles', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    for (var i = 0; i < _rooms.length; i++) ...[
      Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold.withValues(alpha: .45))),
        child: Row(children: [
          Container(width: 57, height: 70, alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFF125540), borderRadius: BorderRadius.circular(12)),
            child: _rooms[i].photoUrl.startsWith('https://')
              ? ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: Image.network(_rooms[i].photoUrl, width: 57, height: 70, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: _gold)))
              : Icon(_rooms[i].kind == 'Terrasse' ? Icons.deck :
                  _rooms[i].kind == 'Balcon' ? Icons.balcony : Icons.meeting_room, color: _gold, size: 31)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_rooms[i].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${_rooms[i].kind} · ${_rooms[i].tables.length} tables · ${_capacity(_rooms[i])} places',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: FilledButton(onPressed: () => setState(() { _selected = i; _list = false; }),
                style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
                child: const Text('Ouvrir'))),
              const SizedBox(width: 8),
              IconButton(onPressed: () => _editRoom(existing: _rooms[i]),
                icon: const Icon(Icons.edit_outlined, color: _gold), tooltip: 'Modifier la salle'),
            ]),
          ])),
        ]),
      ),
    ],
    const SizedBox(height: 12),
    _goldButton('Ajouter une salle / un étage', Icons.add, () => _editRoom()),
  ]);

  Widget _tableTile(_EhTable table) => Card(color: _panel, margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(onTap: () => _editTable(table),
      leading: Icon(Icons.table_restaurant, color: _statusColor(table.status)),
      title: Text('Table T${table.id}', style: const TextStyle(color: Colors.white)),
      subtitle: Text('${table.capacity} personnes · ${table.status == 'available' ? 'Disponible' : table.status == 'reserved' ? 'Réservée' : 'En cours'}',
        style: const TextStyle(color: Colors.white70)),
      trailing: IconButton(tooltip: 'QR code de la table',
        onPressed: () => _showQr(table),
        icon: const Icon(Icons.qr_code, color: _gold))));

  // La taille augmente automatiquement selon le nombre de places.
  // Les coordonnées restent relatives, même après un changement de capacité.
  double _tableSize(int capacity, double floorWidth) {
    final desired = 58.0 + capacity.clamp(1, 20) * 4.6;
    return desired.clamp(62.0, (floorWidth - 28).clamp(62.0, 160.0));
  }

  Widget _tableGraphic(_EhTable table, double size) {
    final color = _statusColor(table.status);
    final fontSize = size < 85 ? 12.0 : 15.0;
    final isRectangle = table.shape == 'rectangle';
    final innerWidth = size * .78;
    final innerHeight = isRectangle ? size * .57 : size * .78;
    return SizedBox(width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        Positioned(top: 2, child: _chair()),
        Positioned(bottom: 2, child: _chair()),
        Positioned(left: 2, child: _chair(side: true)),
        Positioned(right: 2, child: _chair(side: true)),
        if (table.capacity >= 6) ...[
          Positioned(top: 2, left: size * .20, child: _chair()),
          Positioned(bottom: 2, right: size * .20, child: _chair()),
        ],
        if (table.capacity >= 10) ...[
          Positioned(top: 2, right: size * .20, child: _chair()),
          Positioned(bottom: 2, left: size * .20, child: _chair()),
        ],
        Container(width: innerWidth, height: innerHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color,
            shape: table.shape == 'round' ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: table.shape == 'round' ? null : BorderRadius.circular(12),
            border: Border.all(color: _gold, width: 1.6),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5)]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('T${table.id}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: fontSize)),
            Text('${table.capacity} pers.', style: TextStyle(color: Colors.white, fontSize: size < 85 ? 9 : 11)),
          ])),
      ]));
  }

  Widget _chair({bool side = false}) => Container(
    width: side ? 7 : 18, height: side ? 18 : 7,
    decoration: BoxDecoration(color: const Color(0xFFC7AD83), borderRadius: BorderRadius.circular(3)));

  Widget _floor() => LayoutBuilder(builder: (ctx, constraints) {
    final width = constraints.maxWidth;
    final height = width * 1.45;
    const margin = 12.0;
    return Container(height: height, clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: const Color(0xFF304536),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: _gold, width: 1.5)),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _WoodFloorPainter())),
        const Positioned(left: 12, bottom: 10, child: Text('⬆ ENTRÉE',
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        for (final table in _room.tables)
          Builder(builder: (context) {
            final size = _tableSize(table.capacity, width);
            final travelX = (width - size - 2 * margin).clamp(1.0, double.infinity);
            final travelY = (height - size - 2 * margin).clamp(1.0, double.infinity);
            return Positioned(key: ValueKey('${_selected}_${table.id}'),
              left: margin + table.x * travelX,
              top: margin + table.y * travelY,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _editTable(table),
                onPanUpdate: (details) {
                  _change(() {
                    table.x = (table.x + details.delta.dx / travelX).clamp(0.0, 1.0);
                    table.y = (table.y + details.delta.dy / travelY).clamp(0.0, 1.0);
                  });
                },
                child: _tableGraphic(table, size),
              ));
          }),
      ]));
  });

  Widget _editor() {
    final room = _room;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(onPressed: () => setState(() => _selected = -1),
          icon: const Icon(Icons.arrow_back, color: _gold)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(room.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(room.kind, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        IconButton(onPressed: () => _editRoom(existing: room),
          icon: const Icon(Icons.edit, color: _gold), tooltip: 'Modifier la salle'),
      ]),
      const SizedBox(height: 12),
      if (room.photoUrl.startsWith('https://')) ...[
        ClipRRect(borderRadius: BorderRadius.circular(16),
          child: Image.network(room.photoUrl, height: 145, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        const SizedBox(height: 12),
      ],
      _summary(room),
      const SizedBox(height: 8),
      const Text('Pour voir un QR code, ouvre une table puis touche « QR code ». Enregistre d’abord les changements.',
        style: TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _tab('Plan de salle', !_list, () => setState(() => _list = false))),
        const SizedBox(width: 7),
        Expanded(child: _tab('Liste des tables', _list, () => setState(() => _list = true))),
      ]),
      const SizedBox(height: 12),
      if (_list) ...[
        for (final table in room.tables) _tableTile(table),
        if (room.tables.isEmpty) const Padding(padding: EdgeInsets.all(30),
          child: Text('Aucune table dans cette salle.', style: TextStyle(color: Colors.white70))),
      ] else ...[
        _floor(),
        const SizedBox(height: 10),
        const Text('Glisse une table avec le doigt pour la déplacer. Appuie dessus pour modifier la capacité, la forme ou le statut.',
          style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
      const SizedBox(height: 14),
      _goldButton('Ajouter une table', Icons.add, _addTable),
    ]);
  }

  Widget _tab(String text, bool selected, VoidCallback onTap) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(backgroundColor: selected ? _gold : _panel,
      foregroundColor: selected ? _bg : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5)),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      final leave = await _confirmLeave();
      if (leave && context.mounted) Navigator.of(context).pop();
    },
    child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('Gestion des salles'),
        backgroundColor: _bg, foregroundColor: _gold),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: _gold))
        : SafeArea(child: Column(children: [
            Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                SwitchListTile(
                  title: const Text('Autoriser la sélection des tables', style: TextStyle(color: _gold)),
                  subtitle: const Text('Affiche Réserver une table sur la fiche publique. Les demandes sont à traiter dans Réservations de tables.', style: TextStyle(color: Colors.white70)),
                  activeThumbColor: _gold,
                  value: _reservationsEnabled,
                  onChanged: (value) => _change(() => _reservationsEnabled = value),
                ),
                _durationSettings(),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _goldButton('Réservations par date', Icons.event_seat,
                    () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => TableReservationPlanScreen(
                        businessId: widget.businessId,
                        sourceCollection: widget.sourceCollection,
                        professionalView: true,
                        initialRoomId: _selected >= 0 ? _room.roomId : null,
                      ))))),
                const Text('Le plan des réservations utilise les salles enregistrées. '
                  'Enregistrez vos modifications de salle pour les y retrouver.',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                if (_selected < 0) _roomPicker() else _editor()
              ])),
            Container(color: _bg, padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _goldButton(_saving ? 'Enregistrement...' : _dirty ? 'Enregistrer les modifications' : 'Plan enregistré',
                Icons.save_outlined, _saving ? () {} : () { _save(); })),
          ])),
    ),
  );
}


/// QR permanent: impression A5/PDF et partage/téléchargement PNG.
/// Le visuel utilise un logotype typographique provisoire :
/// le logo graphique officiel doit être fourni pour son intégration exacte.
class _EhQrPage extends StatefulWidget {
  const _EhQrPage({required this.businessName, required this.roomName,
    required this.tableNumber, required this.url});
  final String businessName, roomName, url;
  final int tableNumber;
  @override
  State<_EhQrPage> createState() => _EhQrPageState();
}

class _EhQrPageState extends State<_EhQrPage> {
  static const _bg = Color(0xFF061E12);
  static const _gold = Color(0xFFFFD700);
  final _captureKey = GlobalKey();
  bool _working = false;

  Future<Uint8List> _capture() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('Carte QR non disponible');
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('Impossible de créer le PNG');
    return bytes.buffer.asUint8List();
  }

  Future<void> _download() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final png = await _capture();
      final name = 'EuroHabesha_Table_T${widget.tableNumber}.png';
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png', name: name)],
        fileNameOverrides: [name],
        text: 'QR code ${widget.businessName} — ${widget.roomName} — Table T${widget.tableNumber}',
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Téléchargement/partage impossible : $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _print() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final png = await _capture();
      final document = pw.Document();
      final image = pw.MemoryImage(png);
      document.addPage(pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(18),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ));
      await Printing.layoutPdf(
        onLayout: (_) async => document.save(),
        name: 'EuroHabesha_Table_T${widget.tableNumber}.pdf',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impression impossible : $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(backgroundColor: _bg, foregroundColor: _gold,
      title: const Text('QR code de la table')),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        RepaintBoundary(key: _captureKey, child: Container(
          width: 365,
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF003C2C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _gold, width: 3),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.businessName.toUpperCase(), textAlign: TextAlign.center,
              style: const TextStyle(color: _gold, fontSize: 23,
                fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            const Text('SCANNEZ LE QR CODE',
              style: TextStyle(color: Colors.white, fontSize: 12,
                letterSpacing: 1.3, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _gold, width: 2)),
              child: QrImageView(data: widget.url, version: QrVersions.auto,
                size: 235, backgroundColor: Colors.white,
                errorStateBuilder: (_, error) => Text('Erreur QR : $error',
                  style: const TextStyle(color: Colors.red))),
            ),
            const SizedBox(height: 18),
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
              decoration: BoxDecoration(color: _gold,
                borderRadius: BorderRadius.circular(22)),
              child: Text(widget.roomName, textAlign: TextAlign.center,
                style: const TextStyle(color: _bg, fontSize: 19,
                  fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 9),
            Text('TABLE T${widget.tableNumber}',
              style: const TextStyle(color: Colors.white, fontSize: 28,
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.phone_android, color: _gold, size: 27),
              SizedBox(width: 10),
              Flexible(child: Text('Scannez pour consulter le menu et commander',
                style: TextStyle(color: Colors.white, fontSize: 14))),
            ]),
            const SizedBox(height: 25),
            Container(width: double.infinity, height: 1, color: _gold),
            const SizedBox(height: 14),
            const Icon(Icons.spa_outlined, color: _gold, size: 30),
            const SizedBox(height: 3),
            const Text('EURO HABESHA', textAlign: TextAlign.center,
              style: TextStyle(color: _gold, fontSize: 19,
                fontWeight: FontWeight.w900, letterSpacing: 1.6)),
            const SizedBox(height: 4),
            const Text('eurohabesha.eu',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        )),
        const SizedBox(height: 18),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 365),
          child: Row(children: [
            Expanded(child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.white,
                foregroundColor: _bg),
              onPressed: _working ? null : _download,
              icon: const Icon(Icons.download), label: const Text('Télécharger'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _gold,
                foregroundColor: _bg),
              onPressed: _working ? null : _print,
              icon: const Icon(Icons.print), label: const Text('Imprimer'))),
          ])),
        const SizedBox(height: 12),
        const Text('QR de test : la page de commande client reste à développer.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12)),
        TextButton(onPressed: () => Navigator.of(context).pop(),
          child: const Text('Retour aux tables', style: TextStyle(color: _gold))),
      ]),
    ))),
  );
}

class _WoodFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF5A4C39));
    final line = Paint()..color = const Color(0xFFBBA178).withValues(alpha: .22)..strokeWidth = 1;
    const h = 24.0;
    for (double y = 0; y < size.height; y += h) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      final row = (y / h).round();
      for (double x = row.isEven ? 0 : 35; x < size.width; x += 70) {
        canvas.drawLine(Offset(x, y), Offset(x, (y + h).clamp(0, size.height)), line);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
