import '../l10n/app_ui.dart';

import 'package:file_selector/file_selector.dart';

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../business_countries.dart';
import '../business_country_picker.dart';
import '../professional_photo_cropper.dart';
import 'connect_space_model.dart';
import 'connect_space_service.dart';

class ConnectSpaceForm extends StatefulWidget {
  const ConnectSpaceForm({super.key, required this.kind});
  final String kind;
  @override
  State<ConnectSpaceForm> createState() => _ConnectSpaceFormState();
}

class _ConnectSpaceFormState extends State<ConnectSpaceForm> {
  static const dark = Color(0xFF061E12),
      green = Color(0xFF004D40),
      gold = Color(0xFFFFD700);
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  BusinessCountry? _country = BusinessCountries.byCode('FR');
  Uint8List? _logo;
  Uint8List? _evidence;
  String _evidenceExtension = 'pdf';
  String _evidenceName = '';

  String? _requestId;
  bool _sending = false;
  TextEditingController _field(String key) =>
      _fields.putIfAbsent(key, () => TextEditingController());
  bool get _association => widget.kind == 'association';
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _field('contactName').text = user?.displayName ?? '';
    _field('contactEmail').text = user?.email ?? '';
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  void _message(Object value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AppText(ui(context, value.toString()))));
    }
  }

  Widget _input(
    String key,
    String label, {
    int lines = 1,
    bool mandatory = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _field(key),
      enabled: !_sending,
      maxLines: lines,
      maxLength: lines > 1
          ? 3000
          : key == 'title'
          ? 120
          : 200,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: ui(context, label),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: green,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => mandatory && (value?.trim().isEmpty ?? true)
          ? ui(context, 'Champ requis')
          : null,
    ),
  );

  Future<void> _pickLogo() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null || !mounted) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      final result = await frameProfessionalPhoto(
        context,
        bytes: bytes,
        use: ProfessionalPhotoUse.logo,
      );
      if (mounted && result != null) {
        setState(() => _logo = result);
      }
    } catch (_) {
      _message('Impossible de lire cette image. Essayez un JPEG, PNG ou WebP.');
    }
  }

  Future<void> _pickEvidence() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Justificatif officiel',
            extensions: ['pdf', 'jpg', 'png'],
            mimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
          ),
        ],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
        _message('Le justificatif doit faire moins de 8 Mo.');
        return;
      }
      if (mounted)
        setState(() {
          _evidence = bytes;
          _evidenceExtension = file.name.toLowerCase().split('.').last;
          _evidenceName = file.name;
        });
    } catch (_) {
      _message('Impossible de lire ce justificatif.');
    }
  }

  Future<void> _submit() async {
    if (_sending || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _message('Connectez-vous avant d’envoyer la demande.');
      return;
    }
    final values = {
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
      'kind': widget.kind,
      'country': _country?.name ?? '',
    };
    final error = connectSpaceValidation(values, hasLogo: _logo != null);
    if (error != null) {
      _message(error);
      return;
    }
    if (_association && _evidence == null) {
      _message('Ajoutez le justificatif officiel d’enregistrement.');
      return;
    }
    setState(() => _sending = true);
    try {
      await user.reload();
      final active = FirebaseAuth.instance.currentUser;
      if (active == null || active.uid != user.uid || !active.emailVerified) {
        throw StateError(
          'Vérifiez votre e-mail et votre session avant l’envoi.',
        );
      }
      await active.getIdToken(true);
      _requestId ??= ConnectSpaceService.requests.doc().id;
      final reference = ConnectSpaceService.requests.doc(_requestId!);
      {
        var logoUrl = '';
        if (_logo != null) {
          final storage = FirebaseStorage.instance.ref(
            'businesses/${active.uid}/connect_${reference.id}.png',
          );
          await storage.putData(
            _logo!,
            SettableMetadata(contentType: 'image/png'),
          );
          logoUrl = await storage.getDownloadURL();
        }
        var evidencePath = '';
        if (_association && _evidence != null) {
          evidencePath =
              'professional_verification/${active.uid}/connect_${reference.id}/registration.$_evidenceExtension';
          await FirebaseStorage.instance
              .ref(evidencePath)
              .putData(
                _evidence!,
                SettableMetadata(
                  contentType: _evidenceExtension == 'pdf'
                      ? 'application/pdf'
                      : _evidenceExtension == 'png'
                      ? 'image/png'
                      : 'image/jpeg',
                ),
              );
        }
        await reference.set({
          'ownerId': active.uid,
          'kind': widget.kind,
          'status': 'pendingApproval',
          'title': values['title'],
          'description': values['description'],
          'city': values['city'],
          'country': _country!.name,
          'countryCode': _country!.code,
          'topic': values['topic'] ?? '',
          'audience': values['audience'] ?? '',
          'logoUrl': logoUrl,
          'contactName': values['contactName'],
          'contactPhone': values['contactPhone'],
          'contactEmail': values['contactEmail'],
          'legalName': _association ? values['legalName'] : '',
          'registrationNumber': _association
              ? values['registrationNumber']
              : '',
          'evidencePath': evidencePath,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) {
        return;
      }
      _message('Demande enregistrée. Retrouvez son suivi dans Mes demandes.');
      Navigator.pop(context);
    } catch (error) {
      _message('Envoi impossible : $error');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: dark,
    appBar: AppBar(
      backgroundColor: dark,
      foregroundColor: gold,
      title: AppText(
        _association ? 'Présenter une association' : 'Proposer un groupe',
      ),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.paddingOf(context).bottom + 32,
        ),
        children: [
          AppText(
            _association ? 'Association déclarée' : 'Groupe communautaire',
            style: const TextStyle(
              color: gold,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_logo != null)
            SizedBox(
              height: 130,
              child: Image.memory(_logo!, fit: BoxFit.contain),
            ),
          if (_logo != null)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: gold),
              onPressed: _sending ? null : () => setState(() => _logo = null),
              icon: const Icon(Icons.delete_outline),
              label: const AppText('Retirer la photo'),
            ),
          OutlinedButton.icon(
            onPressed: _sending ? null : _pickLogo,
            style: OutlinedButton.styleFrom(foregroundColor: gold),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: AppText(
              _association
                  ? 'Ajouter le logo obligatoire'
                  : 'Photo du groupe (facultatif)',
            ),
          ),
          const SizedBox(height: 12),
          _input(
            'title',
            _association ? 'Nom de l’association *' : 'Nom du groupe *',
          ),
          _input(
            'description',
            _association
                ? 'Mission et actions de l’association *'
                : 'Pourquoi créer ce groupe ? *',
            lines: 4,
          ),
          _input(
            'topic',
            'Thème : sport, familles, formation…',
            mandatory: false,
          ),
          _input(
            'audience',
            'À qui s’adresse cet espace ?',
            lines: 2,
            mandatory: false,
          ),
          _input('city', 'Ville ou zone d’activité *'),
          ListTile(
            tileColor: green,
            title: const AppText(
              'Pays',
              style: TextStyle(color: Colors.white70),
            ),
            subtitle: Text(
              _country?.name ?? 'Choisir un pays',
              style: const TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.expand_more, color: gold),
            onTap: _sending
                ? null
                : () async {
                    final selected =
                        await showModalBottomSheet<BusinessCountry>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => BusinessCountryPicker(
                            selectedCode: _country?.code,
                          ),
                        );
                    if (selected != null && mounted) {
                      setState(() => _country = selected);
                    }
                  },
          ),
          const SizedBox(height: 18),
          if (_association) ...[
            OutlinedButton.icon(
              onPressed: _sending ? null : _pickEvidence,
              icon: const Icon(Icons.attach_file),
              label: AppText(
                _evidence == null
                    ? 'Ajouter le justificatif officiel *'
                    : 'Justificatif ajouté : $_evidenceName',
              ),
            ),
            const AppText(
              'PDF, JPG ou PNG · 8 Mo maximum · document privé, visible uniquement par vous et les administrateurs.',
              style: TextStyle(color: Colors.white70),
            ),
            _input('legalName', 'Nom officiel de l’association *'),
            _input(
              'registrationNumber',
              _country?.code == 'FR'
                  ? 'RNA, SIREN ou SIRET déclaré *'
                  : 'Numéro officiel selon le pays *',
            ),
            const AppText(
              'Le numéro et les contacts sont transmis à l’administration, pas à la page publique. '
              'La publication ne constitue pas une certification du numéro.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),
          ],
          const AppText(
            'Responsable et contact privé',
            style: TextStyle(
              color: gold,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _input('contactName', 'Personne responsable *'),
          _input('contactPhone', 'Téléphone de contact privé *'),
          _input('contactEmail', 'E-mail de contact privé *'),
          const AppText(
            'La demande sera examinée avant publication. Les membres demanderont ensuite à rejoindre '
            'l’espace et le responsable décidera de leur admission.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sending ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: dark,
            ),
            child: AppText(
              _sending ? 'Envoi…' : 'Envoyer pour examen administratif',
            ),
          ),
        ],
      ),
    ),
  );
}
