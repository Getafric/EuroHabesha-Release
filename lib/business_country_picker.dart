import 'l10n/app_ui.dart';

import 'package:flutter/material.dart';

import 'business_countries.dart';

class BusinessCountryPicker extends StatefulWidget {
  const BusinessCountryPicker({super.key, this.selectedCode});
  final String? selectedCode;

  @override
  State<BusinessCountryPicker> createState() => _BusinessCountryPickerState();
}

class _BusinessCountryPickerState extends State<BusinessCountryPicker> {
  static const _dark = Color(0xFF061E12);
  static const _green = Color(0xFF0C3022);
  static const _gold = Color(0xFFFFD700);
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countries = BusinessCountries.search(_query);
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      duration: const Duration(milliseconds: 150),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Material(
          color: _green,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 6),
                  child: Row(
                    children: [
                      const Icon(Icons.public, color: _gold),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: AppText(
                          'Pays de l’établissement',
                          style: TextStyle(
                            color: _gold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fermer',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _search,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un pays ou un code',
                      hintStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.search, color: _gold),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Effacer la recherche',
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white,
                              ),
                            ),
                      filled: true,
                      fillColor: _dark,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _gold),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _gold, width: 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      '${countries.length} pays et territoires',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: countries.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: AppText(
                              'Aucun résultat. Essayez le nom du pays ou son code.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: countries.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: Colors.white12,
                            height: 1,
                            indent: 18,
                            endIndent: 18,
                          ),
                          itemBuilder: (context, index) {
                            final country = countries[index];
                            final selected =
                                country.code == widget.selectedCode;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 5,
                              ),
                              tileColor: selected
                                  ? const Color(0xFF174C38)
                                  : null,
                              leading: Text(
                                country.flag,
                                style: const TextStyle(fontSize: 26),
                              ),
                              title: Text(
                                country.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                country.code,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(Icons.check_circle, color: _gold)
                                  : null,
                              onTap: () => Navigator.of(context).pop(country),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
