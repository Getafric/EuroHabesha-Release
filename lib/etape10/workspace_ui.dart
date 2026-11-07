import '../professional_photo_cropper.dart';
import '../l10n/app_ui.dart';
export 'workspace_values.dart';

import 'package:file_selector/file_selector.dart';

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const ehDark = Color(0xFF061E12);
const ehGold = Color(0xFFFFD700);
const ehCard = Color(0xFF004D40);
typedef EhData = Map<String, dynamic>;
String ehId() => FirebaseFirestore.instance.collection('_local_ids').doc().id;
EhData ehMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<EhData> ehRows(dynamic value) =>
    value is List ? value.map(ehMap).toList() : [];

String ehError(Object e) {
  if (e is FirebaseFunctionsException) {
    if (e.message == 'Action inconnue.')
      return 'Mettez à jour la fonction serveur ehWorkspace pour utiliser ce menu.';
    if (e.message != null && AppUi.known(e.message!)) return e.message!;
    return switch (e.code) {
      'unauthenticated' => 'Se connecter',
      'permission-denied' => 'Cette action n’est pas autorisée.',
      'invalid-argument' => 'Vérifiez les champs, puis réessayez.',
      'failed-precondition' =>
        'Actualisez et vérifiez les options disponibles.',
      'resource-exhausted' => 'Limite atteinte. Patientez avant de réessayer.',
      _ => 'Service indisponible.',
    };
  }
  return e is FormatException ? e.message : 'Service indisponible.';
}

Future<EhData> ehCall(String action, [EhData input = const {}]) async {
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable(
        'ehWorkspace',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 65)),
      )
      .call<dynamic>({...input, 'action': action});
  return ehMap(result.data);
}

Future<void> ehRun(BuildContext context, Future<void> Function() task) async {
  try {
    await task();
  } catch (e) {
    if (context.mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: AppText(ehError(e))));
  }
}

Future<T?> ehOpen<T>(BuildContext context, Widget page) =>
    Navigator.push<T>(context, MaterialPageRoute<T>(builder: (_) => page));
Widget ehButton(
  String label,
  VoidCallback? onPressed, {
  IconData icon = Icons.arrow_forward,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: ehGold,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.all(16),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: AppText(label),
    ),
  ),
);
Widget ehTile(
  String title,
  String subtitle,
  VoidCallback? onTap, {
  IconData icon = Icons.chevron_right,
}) => Card(
  color: ehCard,
  child: ListTile(
    title: AppText(
      title,
      style: const TextStyle(color: ehGold, fontWeight: FontWeight.bold),
    ),
    subtitle: subtitle.isEmpty
        ? null
        : AppText(subtitle, style: const TextStyle(color: Colors.white70)),
    trailing: Icon(icon, color: ehGold),
    onTap: onTap,
  ),
);
Widget ehNote(String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: AppText(
    value,
    style: const TextStyle(color: Colors.white70, height: 1.5),
  ),
);
Widget ehPhoto(String? value, {double height = 150}) =>
    value == null || value.isEmpty
    ? const SizedBox.shrink()
    : Image.network(
        value,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: ehGold),
      );

class EhScaffold extends StatelessWidget {
  const EhScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });
  final String title;
  final Widget body;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: ehDark,
      colorScheme: const ColorScheme.dark(
        primary: ehGold,
        secondary: ehGold,
        surface: ehCard,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: ehCard,
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(),
      ),
    ),
    child: Scaffold(
      backgroundColor: ehDark,
      appBar: AppBar(
        backgroundColor: ehDark,
        foregroundColor: ehGold,
        title: AppText(title),
        actions: actions,
      ),
      body: SafeArea(child: body),
    ),
  );
}

class EhLoad extends StatefulWidget {
  const EhLoad({super.key, required this.load, required this.builder});
  final Future<EhData> Function() load;
  final Widget Function(EhData value, VoidCallback refresh) builder;
  @override
  State<EhLoad> createState() => _EhLoadState();
}

class _EhLoadState extends State<EhLoad> {
  late Future<EhData> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void refresh() {
    if (mounted) setState(() => _future = widget.load());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<EhData>(
    future: _future,
    builder: (context, s) {
      if (s.hasError)
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ehNote(ehError(s.error!)),
                if (FirebaseAuth.instance.currentUser == null)
                  ehButton('Se connecter', () async {
                    await Navigator.pushNamed(context, '/login');
                    refresh();
                  }),
                ehButton('Actualiser', refresh, icon: Icons.refresh),
              ],
            ),
          ),
        );
      if (!s.hasData)
        return const Center(child: CircularProgressIndicator(color: ehGold));
      return RefreshIndicator(
        onRefresh: () async {
          refresh();
          await _future;
        },
        child: widget.builder(s.data!, refresh),
      );
    },
  );
}

class EhField {
  const EhField(
    this.keyName,
    this.label, {
    this.choices,
    this.lines = 1,
    this.toggle = false,
    this.date = false,
    this.required = true,
    this.number = false,
    this.helper,
    this.max = 3000,
  });
  final String keyName, label;
  final Map<String, String>? choices;
  final int lines, max;
  final bool toggle, date, required, number;
  final String? helper;
}

class EhForm extends StatefulWidget {
  const EhForm({
    super.key,
    required this.title,
    required this.fields,
    required this.save,
    this.initial = const {},
    this.note = '',
    this.photoKey,
    this.photoUse,
    this.pdfKey,
    this.submit = 'Enregistrer',
  });
  final String title, note, submit;
  final List<EhField> fields;
  final EhData initial;
  final String? photoKey, pdfKey;
  final ProfessionalPhotoUse? photoUse;
  final Future<void> Function(EhData value) save;
  @override
  State<EhForm> createState() => _EhFormState();
}

class _EhFormState extends State<EhForm> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  late EhData _values;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _values = {...widget.initial};
    for (final f in widget.fields) {
      if (!f.toggle && f.choices == null)
        _controllers[f.keyName] = TextEditingController(
          text: '${_values[f.keyName] ?? ''}',
        );
      if (f.choices != null) _values[f.keyName] ??= f.choices!.keys.first;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _photo() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 75,
      );
      if (picked != null) {
        final u = FirebaseAuth.instance.currentUser;
        if (u == null || !u.emailVerified)
          throw const FormatException(
            'Connectez-vous avec une adresse vérifiée.',
          );
        var bytes = await picked.readAsBytes();
        if (widget.photoUse != null) {
          if (!mounted) return;
          final framed = await frameProfessionalPhoto(
            context,
            bytes: bytes,
            use: widget.photoUse!,
          );
          if (framed == null) return;
          bytes = framed;
        }
        if (bytes.length > 4 * 1024 * 1024)
          throw const FormatException('Photo trop grande : 4 Mo maximum.');
        final r = FirebaseStorage.instance.ref(
          'businesses/${u.uid}/eh_${ehId()}.jpg',
        );
        await r.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        _values[widget.photoKey!] = await r.getDownloadURL();
      }
    } catch (e) {
      _error = ehError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pdf() async {
    setState(() => _busy = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'CV PDF',
            extensions: ['pdf'],
            mimeTypes: ['application/pdf'],
          ),
        ],
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 500000)
          throw const FormatException('Le CV doit faire moins de 500 Ko.');
        _values[widget.pdfKey!] = {
          'name': file.name,
          'base64': base64Encode(bytes),
        };
      }
    } catch (e) {
      _error = ehError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      for (final entry in _controllers.entries) {
        _values[entry.key] = entry.value.text.trim();
      }
      await widget.save({..._values});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = ehError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => EhScaffold(
    title: widget.title,
    body: Form(
      key: _form,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.note.isNotEmpty) ehNote(widget.note),
          if (widget.pdfKey != null)
            ehButton(
              _values[widget.pdfKey] == null
                  ? 'Joindre un CV PDF (facultatif)'
                  : 'CV joint : ${ehMap(_values[widget.pdfKey])['name']}',
              _busy ? null : _pdf,
              icon: Icons.attach_file,
            ),
          if (widget.photoKey != null) ...[
            ehPhoto(_values[widget.photoKey]?.toString()),
            ehButton(
              'Ajouter / changer la photo',
              _busy ? null : _photo,
              icon: Icons.add_a_photo,
            ),
          ],
          for (final f in widget.fields)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: f.toggle
                  ? SwitchListTile(
                      title: AppText(f.label),
                      value: _values[f.keyName] == true,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _values[f.keyName] = v),
                    )
                  : f.choices != null
                  ? DropdownButtonFormField<String>(
                      initialValue: _values[f.keyName]?.toString(),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: ui(context, f.label),
                      ),
                      items: f.choices!.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: AppText(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _values[f.keyName] = v),
                    )
                  : TextFormField(
                      controller: _controllers[f.keyName],
                      enabled: !_busy,
                      maxLines: f.lines,
                      maxLength: f.max,
                      keyboardType: f.number
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: ui(context, f.label),
                        helperText: f.helper == null
                            ? null
                            : ui(context, f.helper!),
                        counterText: '',
                        suffixIcon: f.date
                            ? IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(
                                      const Duration(days: 1),
                                    ),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 370),
                                    ),
                                  );
                                  if (d == null || !context.mounted) return;
                                  if (f.keyName == 'birthdate') {
                                    _controllers[f.keyName]!.text = d
                                        .toIso8601String()
                                        .substring(0, 10);
                                    return;
                                  }
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: const TimeOfDay(
                                      hour: 9,
                                      minute: 0,
                                    ),
                                  );
                                  if (t != null)
                                    _controllers[f.keyName]!.text = DateTime(
                                      d.year,
                                      d.month,
                                      d.day,
                                      t.hour,
                                      t.minute,
                                    ).toIso8601String();
                                },
                              )
                            : null,
                      ),
                      validator: (v) => f.required && (v ?? '').trim().isEmpty
                          ? ui(context, 'Ce champ est nécessaire.')
                          : null,
                    ),
            ),
          if (_error != null)
            AppText(_error!, style: const TextStyle(color: Colors.redAccent)),
          ehButton(_busy ? 'En cours…' : widget.submit, _busy ? null : _save),
        ],
      ),
    ),
  );
}

List<String> ehSplit(dynamic value) => value
    .toString()
    .split(',')
    .map((v) => v.trim())
    .where((v) => v.isNotEmpty)
    .toList();
Widget ehInterests(List<dynamic> values) => SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: values
        .map(
          (v) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Chip(label: AppText('$v')),
          ),
        )
        .toList(),
  ),
);
Widget ehAttachment(EhData a) {
  try {
    if ((a['mime'] ?? '').toString().startsWith('image/'))
      return Image.memory(base64Decode(a['base64']), height: 180);
  } catch (_) {
    return ehNote('Pièce jointe indisponible.');
  }
  return ehNote('Fichier audio');
}
