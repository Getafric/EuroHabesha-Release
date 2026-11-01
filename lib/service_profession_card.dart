import 'package:flutter/material.dart';
import 'service_profession.dart';

class ServiceProfessionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const ServiceProfessionCard({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final v = publicServiceDetails(data);
    if (v.isEmpty) return const SizedBox.shrink();
    final p = serviceDefinition(serviceText(v['category']));
    final f = serviceMap(data['fields']), extras = serviceMap(v['extras']);
    String field(String key) => serviceText(f[key] ?? data[key]);
    final rows = <MapEntry<String, String>>[
      MapEntry('Tarif indicatif', servicePrice(v)),
      if (field('serviceArea').isNotEmpty)
        MapEntry('Zone de déplacement', field('serviceArea')),
      if (field('availability').isNotEmpty)
        MapEntry('Disponibilités', field('availability')),
      for (final x in p.fields)
        if (serviceText(extras[x.key]).isNotEmpty)
          MapEntry(x.label.replaceAll(' *', ''), serviceText(extras[x.key])),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            p.label,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                [
                      ...serviceChoices(v['offers'], p.offers),
                      ...serviceChoices(v['modes'], p.modes),
                    ]
                    .map(
                      (s) => Chip(
                        label: Text(s),
                        backgroundColor: const Color(0xFF061E12),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    )
                    .toList(),
          ),
          for (final row in rows.take(3)) _row(row),
          if (rows.length > 3)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Détails des prestations',
                style: TextStyle(color: Color(0xFFFFD700)),
              ),
              iconColor: const Color(0xFFFFD700),
              collapsedIconColor: const Color(0xFFFFD700),
              children: rows.skip(3).map(_row).toList(),
            ),
          const SizedBox(height: 8),
          const Text(
            'Le professionnel confirme le tarif et sa disponibilité avant accord.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _row(MapEntry<String, String> r) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.key,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(r.value, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}
