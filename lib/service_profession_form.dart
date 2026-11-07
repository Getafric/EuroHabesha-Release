import 'professional_activity_text.dart';

import 'package:flutter/material.dart';

import 'service_profession.dart';

class ServiceProfessionForm extends StatefulWidget {
  final ServiceDefinition definition;
  final Map<String, dynamic> initialValue;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const ServiceProfessionForm({
    super.key,
    required this.definition,
    required this.initialValue,
    required this.onChanged,
  });
  @override
  State<ServiceProfessionForm> createState() => _ServiceProfessionFormState();
}

class _ServiceProfessionFormState extends State<ServiceProfessionForm> {
  static const gold = Color(0xFFFFD700),
      green = Color(0xFF004D40),
      dark = Color(0xFF061E12);
  late Map<String, dynamic> values;
  @override
  void initState() {
    super.initState();
    values = {
      ...widget.initialValue,
      'extras': {...serviceMap(widget.initialValue['extras'])},
    };
  }

  void change(String key, dynamic value) {
    setState(() => values[key] = value);
    widget.onChanged({
      ...values,
      'extras': {...serviceMap(values['extras'])},
    });
  }

  InputDecoration decoration(String label, [String? hint]) => InputDecoration(
    labelText: activityText(context, label),
    hintText: hint == null ? null : activityText(context, hint),
    labelStyle: const TextStyle(color: Colors.white70),
    hintStyle: const TextStyle(color: Colors.white54),
    filled: true,
    fillColor: green,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
  Widget choices(String label, String key, List<String> options) =>
      FormField<List<String>>(
        key: ValueKey('${widget.definition.category}-$key'),
        initialValue: serviceChoices(values[key], options),
        validator: (v) => v == null || v.isEmpty
            ? activityText(context, "Choisissez au moins une option.")
            : null,
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activityText(context, label),
              style: const TextStyle(color: gold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: options
                  .map(
                    (v) => FilterChip(
                      label: Text(activityText(context, v)),
                      selected: (field.value ?? []).contains(v),
                      selectedColor: gold,
                      backgroundColor: green,
                      checkmarkColor: dark,
                      labelStyle: TextStyle(
                        color: (field.value ?? []).contains(v)
                            ? dark
                            : Colors.white,
                      ),
                      onSelected: (selected) {
                        final next = [...?field.value];
                        selected ? next.add(v) : next.remove(v);
                        field.didChange(next);
                        change(key, next);
                      },
                    ),
                  )
                  .toList(),
            ),
            if (field.hasError)
              Text(
                field.errorText!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            const SizedBox(height: 18),
          ],
        ),
      );
  @override
  Widget build(BuildContext context) {
    final p = widget.definition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p.offers.isNotEmpty)
          choices('Mes prestations *', 'offers', p.offers),
        choices('Lieu ou mode de prestation *', 'modes', p.modes),
        for (final f in p.fields) ...[
          TextFormField(
            key: ValueKey('${p.category}-${f.key}'),
            initialValue: serviceText(serviceMap(values['extras'])[f.key]),
            maxLines: 2,
            maxLength: 1200,
            style: const TextStyle(color: Colors.white),
            decoration: decoration(f.label, f.hint),
            validator: (v) =>
                f.key == 'languages' && (v?.trim().isEmpty ?? true)
                ? activityText(context, "Indiquez les langues proposées.")
                : null,
            onChanged: (v) =>
                change('extras', {...serviceMap(values['extras']), f.key: v}),
          ),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<String>(
          initialValue: serviceText(values['unit']),
          isExpanded: true,
          dropdownColor: green,
          style: const TextStyle(color: Colors.white),
          decoration: decoration('Base de tarif *'),
          items: p.units
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(activityText(context, v)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) change('unit', v);
          },
        ),
        if (values['unit'] != 'Sur devis') ...[
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('${p.category}-rate'),
            initialValue: serviceText(values['rate']),
            maxLength: 30,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: decoration('Tarif indicatif *', 'Ex. 45,00'),
            validator: (v) => serviceRate(v) == null
                ? activityText(context, "Indiquez un montant positif valide.")
                : null,
            onChanged: (v) => change('rate', v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: serviceText(values['currency']),
            isExpanded: true,
            dropdownColor: green,
            style: const TextStyle(color: Colors.white),
            decoration: decoration('Devise'),
            items: serviceCurrencies
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(activityText(context, v)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) change('currency', v);
            },
          ),
        ],
        const SizedBox(height: 12),
        Text(
          activityText(
            context,
            "Tarif de présentation. Le montant et les disponibilités sont à confirmer avec le client avant accord.",
          ),
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
