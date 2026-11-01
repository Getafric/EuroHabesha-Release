import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfessionalHoursScreen extends StatefulWidget {
  final String businessId;
  final String sourceCollection;
  const ProfessionalHoursScreen({super.key, required this.businessId, required this.sourceCollection});
  @override
  State<ProfessionalHoursScreen> createState() => _ProfessionalHoursScreenState();
}

class _ProfessionalHoursScreenState extends State<ProfessionalHoursScreen> {
  static const dark = Color(0xFF061E12);
  static const gold = Color(0xFFFFD700);
  static const green = Color(0xFF0C3022);
  static const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  final List<bool> enabled = [true, true, true, true, true, false, false];
  final List<TimeOfDay> opens = List.generate(7, (_) => const TimeOfDay(hour: 9, minute: 0));
  final List<TimeOfDay> closes = List.generate(7, (_) => const TimeOfDay(hour: 18, minute: 0));
  final List<bool> pauses = List.filled(7, false);
  final List<TimeOfDay> pauseStarts = List.generate(7, (_) => const TimeOfDay(hour: 12, minute: 0));
  final List<TimeOfDay> pauseEnds = List.generate(7, (_) => const TimeOfDay(hour: 13, minute: 0));
  String confirmation = 'manual';
  bool loading = true;
  bool saving = false;

  DocumentReference<Map<String, dynamic>> get ref => FirebaseFirestore.instance
      .collection(widget.sourceCollection).doc(widget.businessId);

  @override
  void initState() { super.initState(); _load(); }

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;
  String _format(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  TimeOfDay _parse(dynamic raw, TimeOfDay fallback) {
    final p = raw?.toString().split(':');
    if (p == null || p.length != 2) return fallback;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return fallback;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _load() async {
    try {
      final doc = await ref.get();
      final data = doc.data() ?? <String, dynamic>{};
      final raw = data['appointmentWorkingHours'];
      if (raw is Map) {
        for (var i = 0; i < 7; i++) {
          final row = raw['${i + 1}'];
          if (row is! Map) continue;
          enabled[i] = row['enabled'] == true;
          opens[i] = _parse(row['open'], opens[i]);
          closes[i] = _parse(row['close'], closes[i]);
          pauses[i] = row['pauseEnabled'] == true;
          pauseStarts[i] = _parse(row['pauseStart'], pauseStarts[i]);
          pauseEnds[i] = _parse(row['pauseEnd'], pauseEnds[i]);
        }
      }
      confirmation = data['bookingConfirmationMode'] == 'automatic' ? 'automatic' : 'manual';
    } catch (e) {
      _message('Lecture impossible : $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  ThemeData _pickerTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: const ColorScheme.dark(primary: gold, onPrimary: dark,
          surface: green, onSurface: Colors.white),
      dialogTheme: const DialogThemeData(backgroundColor: green),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: gold),
      ),
    );
  }

  Future<void> _pick(int index, List<TimeOfDay> target) async {
    final result = await showTimePicker(
      context: context,
      initialTime: target[index],
      builder: (context, child) => Theme(
        data: _pickerTheme(context),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );
    if (result != null && mounted) setState(() => target[index] = result);
  }

  Future<void> _save() async {
    for (var i = 0; i < 7; i++) {
      if (!enabled[i]) continue;
      final start = _minutes(opens[i]);
      final end = _minutes(closes[i]);
      if (start >= end || (pauses[i] && !(_minutes(pauseStarts[i]) >= start &&
          _minutes(pauseStarts[i]) < _minutes(pauseEnds[i]) &&
          _minutes(pauseEnds[i]) <= end))) {
        _message('Horaires invalides : ${days[i]}');
        return;
      }
    }
    setState(() => saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Connexion requise');
      final snap = await ref.get();
      if (!snap.exists || snap.data()?['ownerId'] != user.uid) {
        throw Exception('Seul le propriétaire peut modifier ces horaires');
      }
      final schedule = <String, dynamic>{};
      for (var i = 0; i < 7; i++) {
        schedule['${i + 1}'] = {
          'enabled': enabled[i], 'open': _format(opens[i]), 'close': _format(closes[i]),
          'pauseEnabled': pauses[i], 'pauseStart': _format(pauseStarts[i]),
          'pauseEnd': _format(pauseEnds[i]),
        };
      }
      await ref.update({
        'appointmentWorkingHours': schedule,
        'bookingConfirmationMode': confirmation,
        'appointmentSettingsUpdatedAt': FieldValue.serverTimestamp(),
      });
      _message('Horaires enregistrés');
    } catch (e) {
      _message('Enregistrement impossible : $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _timeField(int index, List<TimeOfDay> times, String label) {
    return Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 7),
        OutlinedButton(
          onPressed: () => _pick(index, times),
          style: OutlinedButton.styleFrom(
            foregroundColor: gold,
            side: const BorderSide(color: gold),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(_format(times[index]), style: const TextStyle(
            color: gold, fontWeight: FontWeight.bold, fontSize: 18,
          )),
        ),
      ],
    ));
  }

  Widget _dayCard(int i) => Card(
    color: green,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(days[i], style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.bold, fontSize: 17)),
          value: enabled[i],
          activeThumbColor: gold,
          activeTrackColor: const Color(0xFF827316),
          onChanged: (v) => setState(() => enabled[i] = v),
        ),
        if (enabled[i]) ...[
          const SizedBox(height: 4),
          Row(children: [
            _timeField(i, opens, 'Ouverture'),
            const SizedBox(width: 12),
            _timeField(i, closes, 'Fermeture'),
          ]),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pause', style: TextStyle(color: Colors.white)),
            value: pauses[i],
            activeThumbColor: gold,
            activeTrackColor: const Color(0xFF827316),
            onChanged: (v) => setState(() => pauses[i] = v),
          ),
          if (pauses[i]) Row(children: [
            _timeField(i, pauseStarts, 'Début de pause'),
            const SizedBox(width: 12),
            _timeField(i, pauseEnds, 'Fin de pause'),
          ]),
        ],
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: dark,
    appBar: AppBar(
      title: const Text('Horaires et disponibilités',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      backgroundColor: dark,
      foregroundColor: gold,
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator(color: gold))
        : SafeArea(
            child: Column(children: [
              Expanded(child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                children: [
                  const Text('Définissez les horaires de votre établissement.',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  ...List.generate(7, _dayCard),
                  const SizedBox(height: 12),
                  const Text('Confirmation des rendez-vous', style: TextStyle(
                      color: gold, fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: confirmation,
                    onChanged: (value) {
                      if (value != null) setState(() => confirmation = value);
                    },
                    child: const Column(children: [
                      RadioListTile<String>(
                        title: Text('Manuelle', style: TextStyle(color: Colors.white)),
                        value: 'manual', activeColor: gold,
                      ),
                      RadioListTile<String>(
                        title: Text('Automatique', style: TextStyle(color: Colors.white)),
                        value: 'automatic', activeColor: gold,
                      ),
                    ]),
                  ),
                ],
              )),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    label: Text(saving ? 'Enregistrement...' : 'Enregistrer les horaires',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ]),
          ),
  );
}
