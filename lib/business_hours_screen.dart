import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'professional_profile_sync_service.dart';

class BusinessHoursScreen extends StatefulWidget {
  final String businessId;
  final String sourceCollection;

  const BusinessHoursScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
  });

  @override
  State<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends State<BusinessHoursScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  static const List<Map<String, String>> _days = [
    {'key': 'monday', 'label': 'Lundi'},
    {'key': 'tuesday', 'label': 'Mardi'},
    {'key': 'wednesday', 'label': 'Mercredi'},
    {'key': 'thursday', 'label': 'Jeudi'},
    {'key': 'friday', 'label': 'Vendredi'},
    {'key': 'saturday', 'label': 'Samedi'},
    {'key': 'sunday', 'label': 'Dimanche'},
  ];

  final Map<String, bool> _openDays = {};
  final Map<String, TimeOfDay> _openingTimes = {};
  final Map<String, TimeOfDay> _closingTimes = {};

  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>> get _documentReference =>
      FirebaseFirestore.instance
          .collection(widget.sourceCollection)
          .doc(widget.businessId);

  @override
  void initState() {
    super.initState();

    for (final day in _days) {
      final key = day['key']!;

      _openDays[key] = false;
      _openingTimes[key] = const TimeOfDay(
        hour: 9,
        minute: 0,
      );
      _closingTimes[key] = const TimeOfDay(
        hour: 18,
        minute: 0,
      );
    }

    _loadHours();
  }

  TimeOfDay _parseTime(
    dynamic value,
    TimeOfDay fallback,
  ) {
    final text = value?.toString() ?? '';
    final parts = text.split(':');

    if (parts.length != 2) {
      return fallback;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return fallback;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  String _timeToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _loadHours() async {
    try {
      final snapshot = await _documentReference.get();
      final data = snapshot.data();

      final rawHours = data?['businessHours'];

      if (rawHours is Map) {
        for (final day in _days) {
          final key = day['key']!;
          final rawDay = rawHours[key];

          if (rawDay is Map) {
            _openDays[key] = rawDay['isOpen'] == true;

            _openingTimes[key] = _parseTime(
              rawDay['open'],
              const TimeOfDay(
                hour: 9,
                minute: 0,
              ),
            );

            _closingTimes[key] = _parseTime(
              rawDay['close'],
              const TimeOfDay(
                hour: 18,
                minute: 0,
              ),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de charger les horaires : $e',
          ),
        ),
      );
    }
  }

  Future<void> _selectTime({
    required String dayKey,
    required bool opening,
  }) async {
    final initialTime =
        opening ? _openingTimes[dayKey]! : _closingTimes[dayKey]!;

    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (opening) {
        _openingTimes[dayKey] = selected;
      } else {
        _closingTimes[dayKey] = selected;
      }
    });
  }

  Future<void> _saveHours() async {
    setState(() {
      _saving = true;
    });

    try {
      final Map<String, dynamic> hours = {};

      for (final day in _days) {
        final key = day['key']!;

        hours[key] = {
          'isOpen': _openDays[key] ?? false,
          'open': _timeToString(
            _openingTimes[key]!,
          ),
          'close': _timeToString(
            _closingTimes[key]!,
          ),
        };
      }

      await _documentReference.update({
        'businessHours': hours,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await ProfessionalProfileSyncService.syncPublishedProfile(
        sourceCollection: widget.sourceCollection,
        sourceId: widget.businessId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Horaires enregistrés.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’enregistrer les horaires : $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _timeButton({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF00382F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryGold.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                color: primaryGold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        title: const Text(
          'Horaires',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              children: [
                const Text(
                  'Horaires d’ouverture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choisissez les jours d’ouverture '
                  'et les horaires de votre activité.',
                  style: TextStyle(
                    color: Colors.white60,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ..._days.map((day) {
                  final key = day['key']!;
                  final label = day['label']!;
                  final isOpen = _openDays[key] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardGreen,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOpen
                            ? primaryGold.withValues(
                                alpha: 0.35,
                              )
                            : Colors.white10,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              isOpen ? 'Ouvert' : 'Fermé',
                              style: TextStyle(
                                color: isOpen ? primaryGold : Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: isOpen,
                              activeThumbColor: primaryGold,
                              onChanged: (value) {
                                setState(() {
                                  _openDays[key] = value;
                                });
                              },
                            ),
                          ],
                        ),
                        if (isOpen) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _timeButton(
                                  label: 'Ouverture',
                                  time: _openingTimes[key]!,
                                  onTap: () {
                                    _selectTime(
                                      dayKey: key,
                                      opening: true,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _timeButton(
                                  label: 'Fermeture',
                                  time: _closingTimes[key]!,
                                  onTap: () {
                                    _selectTime(
                                      dayKey: key,
                                      opening: false,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveHours,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: primaryDarkGreen,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryDarkGreen,
                            ),
                          )
                        : const Icon(
                            Icons.save_outlined,
                          ),
                    label: Text(
                      _saving
                          ? 'Enregistrement...'
                          : 'Enregistrer les horaires',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
