import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventTicketingManagementScreen extends StatefulWidget {
  const EventTicketingManagementScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final String eventId;
  final String eventTitle;

  @override
  State<EventTicketingManagementScreen> createState() =>
      _EventTicketingManagementScreenState();
}

class _EventTicketingManagementScreenState
    extends State<EventTicketingManagementScreen> {
  static const Color darkGreen = Color(0xFF062E25);
  static const Color cardGreen = Color(0xFF0F5257);
  static const Color gold = Color(0xFFFFB800);

  bool _loading = true;
  bool _saving = false;
  bool _ticketingEnabled = true;

  bool _nonRefundable = true;
  bool _nonTransferable = true;

  DateTime? _salesStart;
  DateTime? _salesEnd;

  final List<_TicketTypeEditor> _ticketTypes = [];

  DocumentReference<Map<String, dynamic>> get _eventRef =>
      FirebaseFirestore.instance.collection('events').doc(widget.eventId);

  @override
  void initState() {
    super.initState();
    _loadTicketing();
  }

  @override
  void dispose() {
    for (final ticket in _ticketTypes) {
      ticket.dispose();
    }
    super.dispose();
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().replaceAll(',', '.') ?? '',
        ) ??
        0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  Future<void> _loadTicketing() async {
    try {
      final snapshot = await _eventRef.get();

      if (!snapshot.exists) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Événement publié introuvable.',
            ),
          ),
        );
        return;
      }

      final data = snapshot.data() ?? <String, dynamic>{};

      final rawTicketTypes = data['ticketTypes'];

      final loadedTickets = <_TicketTypeEditor>[];

      if (rawTicketTypes is List) {
        for (final rawTicket in rawTicketTypes) {
          if (rawTicket is! Map) continue;

          final ticket = Map<String, dynamic>.from(rawTicket);

          loadedTickets.add(
            _TicketTypeEditor(
              id: ticket['id']?.toString() ?? '',
              name: ticket['name']?.toString() ?? '',
              price: _toDouble(ticket['price']),
              capacity: _toInt(ticket['capacity']),
              sold: _toInt(ticket['sold']),
              active: ticket['active'] != false,
            ),
          );
        }
      }

      if (loadedTickets.isEmpty) {
        loadedTickets.add(
          _TicketTypeEditor(
            id: 'general',
            name: 'Standard',
            price: 0,
            capacity: 100,
            sold: 0,
            active: true,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _ticketingEnabled = data['ticketingEnabled'] != false;

        _nonRefundable = data['nonRefundable'] != false;

        _nonTransferable = data['nonTransferable'] != false;

        _salesStart = _toDateTime(data['ticketSalesStart']);

        _salesEnd = _toDateTime(data['ticketSalesEnd']);

        _ticketTypes
          ..clear()
          ..addAll(loadedTickets);

        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de charger la billetterie : $error',
          ),
        ),
      );
    }
  }

  void _addTicketType() {
    setState(() {
      _ticketTypes.add(
        _TicketTypeEditor(
          id: '',
          name: '',
          price: 0,
          capacity: 100,
          sold: 0,
          active: true,
        ),
      );
    });
  }

  void _removeTicketType(int index) {
    final ticket = _ticketTypes[index];

    if (ticket.sold > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de supprimer un type de billet '
            'qui possède déjà des ventes.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _ticketTypes.removeAt(index);
    });

    ticket.dispose();
  }

  String _createTicketId(
    String name,
    int index,
  ) {
    final normalized = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return 'ticket_${index + 1}';
  }

  Future<void> _pickSalesDate({
    required bool isStart,
  }) async {
    final currentValue = isStart ? _salesStart : _salesEnd;

    final now = DateTime.now();

    final initialDate = currentValue ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        currentValue ?? now,
      ),
    );

    if (selectedTime == null || !mounted) return;

    final result = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      if (isStart) {
        _salesStart = result;
      } else {
        _salesEnd = result;
      }
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Non définie';
    }

    final day = value.day.toString().padLeft(2, '0');

    final month = value.month.toString().padLeft(2, '0');

    final hour = value.hour.toString().padLeft(2, '0');

    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} • $hour:$minute';
  }

  Future<void> _save() async {
    if (_saving) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous devez être connecté.',
          ),
        ),
      );
      return;
    }

    if (_ticketTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ajoutez au moins un type de billet.',
          ),
        ),
      );
      return;
    }

    if (_salesStart != null &&
        _salesEnd != null &&
        !_salesEnd!.isAfter(_salesStart!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fin des ventes doit être après '
            'le début des ventes.',
          ),
        ),
      );
      return;
    }

    final ticketData = <Map<String, dynamic>>[];
    final usedIds = <String>{};

    for (var index = 0; index < _ticketTypes.length; index++) {
      final ticket = _ticketTypes[index];

      final name = ticket.nameController.text.trim();

      final price = double.tryParse(
        ticket.priceController.text.trim().replaceAll(',', '.'),
      );

      final capacity = int.tryParse(
        ticket.capacityController.text.trim(),
      );

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Le billet ${index + 1} doit avoir un nom.',
            ),
          ),
        );
        return;
      }

      if (price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Prix incorrect pour "$name".',
            ),
          ),
        );
        return;
      }

      if (capacity == null || capacity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantité incorrecte pour "$name".',
            ),
          ),
        );
        return;
      }

      if (capacity < ticket.sold) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La capacité de "$name" ne peut pas être '
              'inférieure aux ${ticket.sold} billets '
              'déjà vendus.',
            ),
          ),
        );
        return;
      }

      var id = ticket.id.trim();

      if (id.isEmpty) {
        id = _createTicketId(
          name,
          index,
        );
      }

      var uniqueId = id;
      var suffix = 2;

      while (usedIds.contains(uniqueId)) {
        uniqueId = '${id}_$suffix';
        suffix++;
      }

      usedIds.add(uniqueId);

      ticketData.add({
        'id': uniqueId,
        'name': name,
        'price': price,
        'capacity': capacity,
        'sold': ticket.sold,
        'active': ticket.active,
      });
    }

    setState(() {
      _saving = true;
    });

    try {
      await _eventRef.update({
        'ticketingEnabled': _ticketingEnabled,
        'nonRefundable': _nonRefundable,
        'nonTransferable': _nonTransferable,
        'ticketTypes': ticketData,
        'ticketSalesStart':
            _salesStart == null ? null : Timestamp.fromDate(_salesStart!),
        'ticketSalesEnd':
            _salesEnd == null ? null : Timestamp.fromDate(_salesEnd!),
        'ticketingUpdatedAt': FieldValue.serverTimestamp(),
        'ticketingUpdatedBy': user.uid,
      });

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Billetterie enregistrée.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’enregistrer : $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Billetterie',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: gold,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.eventTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ID événement : ${widget.eventId}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: cardGreen,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SwitchListTile(
                    value: _ticketingEnabled,
                    activeThumbColor: gold,
                    title: const Text(
                      'Billetterie active',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Autoriser la vente des billets '
                      'pour cet événement.',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _ticketingEnabled = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: cardGreen,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _nonRefundable,
                        activeThumbColor: gold,
                        title: const Text(
                          'Billets non remboursables',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: const Text(
                          'Les billets achetés ne peuvent pas être remboursés.',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _nonRefundable = value;
                          });
                        },
                      ),
                      const Divider(
                        color: Colors.white24,
                        height: 1,
                      ),
                      SwitchListTile(
                        value: _nonTransferable,
                        activeThumbColor: gold,
                        title: const Text(
                          'Billets non transférables',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: const Text(
                          'Le billet reste associé à son acheteur.',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _nonTransferable = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  icon: Icons.calendar_month_outlined,
                  title: 'Période de vente',
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  icon: Icons.calendar_month_outlined,
                  title: 'Période de vente',
                ),
                const SizedBox(height: 10),
                _DateCard(
                  title: 'Début des ventes',
                  value: _formatDate(_salesStart),
                  onTap: () {
                    _pickSalesDate(
                      isStart: true,
                    );
                  },
                  onClear: _salesStart == null
                      ? null
                      : () {
                          setState(() {
                            _salesStart = null;
                          });
                        },
                ),
                const SizedBox(height: 10),
                _DateCard(
                  title: 'Fin des ventes',
                  value: _formatDate(_salesEnd),
                  onTap: () {
                    _pickSalesDate(
                      isStart: false,
                    );
                  },
                  onClear: _salesEnd == null
                      ? null
                      : () {
                          setState(() {
                            _salesEnd = null;
                          });
                        },
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Types de billets',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addTicketType,
                      icon: const Icon(
                        Icons.add,
                        color: gold,
                      ),
                      label: const Text(
                        'Ajouter',
                        style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _ticketTypes.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _TicketTypeCard(
                      ticket: _ticketTypes[index],
                      onDelete: () {
                        _removeTicketType(index);
                      },
                      onActiveChanged: (value) {
                        setState(() {
                          _ticketTypes[index].active = value;
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.security_outlined,
                        color: gold,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Le nombre de billets vendus '
                          'n’est pas modifiable ici. '
                          'Il sera mis à jour uniquement '
                          'après confirmation sécurisée '
                          'du paiement.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: darkGreen,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _saving
                        ? 'Enregistrement...'
                        : 'Enregistrer la billetterie',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}

class _TicketTypeEditor {
  _TicketTypeEditor({
    required this.id,
    required String name,
    required double price,
    required int capacity,
    required this.sold,
    required this.active,
  })  : nameController = TextEditingController(text: name),
        priceController = TextEditingController(
          text: price == price.roundToDouble()
              ? price.toInt().toString()
              : price.toStringAsFixed(2),
        ),
        capacityController = TextEditingController(
          text: capacity.toString(),
        );

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController capacityController;

  final int sold;
  bool active;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    capacityController.dispose();
  }
}

class _TicketTypeCard extends StatelessWidget {
  const _TicketTypeCard({
    required this.ticket,
    required this.onDelete,
    required this.onActiveChanged,
  });

  final _TicketTypeEditor ticket;
  final VoidCallback onDelete;
  final ValueChanged<bool> onActiveChanged;

  static const Color cardGreen = Color(0xFF0F5257);
  static const Color gold = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    final remaining = int.tryParse(
          ticket.capacityController.text.trim(),
        ) ??
        0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_activity_outlined,
                color: gold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ticket.nameController.text.trim().isEmpty
                      ? 'Nouveau billet'
                      : ticket.nameController.text.trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch(
                value: ticket.active,
                activeThumbColor: gold,
                onChanged: onActiveChanged,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ticket.nameController,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: _inputDecoration(
              'Nom du billet',
              'Ex. Standard, VIP',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ticket.priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: _inputDecoration(
                    'Prix (€)',
                    '25.00',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: ticket.capacityController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: _inputDecoration(
                    'Quantité',
                    '100',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Vendus',
                  value: '${ticket.sold}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'Restants',
                  value: '${(remaining - ticket.sold).clamp(0, 999999999)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    String hint,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: gold),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFFB800),
          size: 21,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.title,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String title;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F5257),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Color(0xFFFFB800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white60,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
