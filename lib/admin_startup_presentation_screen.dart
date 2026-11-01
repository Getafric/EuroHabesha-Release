import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';
import 'startup_presentation.dart';
import 'euro_habesha_video_intro.dart';

class AdminStartupPresentationScreen extends StatefulWidget {
  const AdminStartupPresentationScreen({super.key});
  @override
  State<AdminStartupPresentationScreen> createState() => _AdminStartupPresentationScreenState();
}

class _AdminStartupPresentationScreenState extends State<AdminStartupPresentationScreen> {
  static const _dark = Color(0xFF061E12), _card = Color(0xFF004D40), _gold = Color(0xFFFFD700);
  StartupPresentation _draft = const StartupPresentation();
  Uint8List? _imageBytes;
  String _fileLabel = 'Vidéo originale intégrée';
  String? _error;
  bool _loading = true;
  bool _busy = false;
  bool _dirty = false;
  double? _progress;
  UploadTask? _upload;
  StreamSubscription<TaskSnapshot>? _progressSubscription;
  Object? _loadedUpdatedAt;
  bool _loadedExists = false;

  @override
  void initState() { super.initState(); _load(); }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final doc = await StartupPresentationSettings.reference
        .get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 10));
      final settings = doc.exists ? StartupPresentation.fromMap(doc.data() ?? {}) : const StartupPresentation();
      if (settings == null) throw StateError('Paramètres existants invalides : rechargez ou contactez le support.');
      if (!mounted) return;
      setState(() {
        _loadedExists = doc.exists;
        _loadedUpdatedAt = doc.data()?['updatedAt'];
        _draft = settings; _dirty = false; _imageBytes = null;
        _fileLabel = settings.isLocal ? 'Vidéo originale intégrée' : settings.storagePath.split('/').last;
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() { _error = 'Chargement impossible : $error'; _loading = false; });
    }
  }

  void _change({bool? enabled, String? type, String? path, int? seconds}) {
    setState(() {
      _draft = StartupPresentation(enabled: enabled ?? _draft.enabled,
        mediaType: type ?? _draft.mediaType, storagePath: path ?? _draft.storagePath,
        durationSeconds: seconds ?? _draft.durationSeconds);
      _dirty = true;
    });
  }

  String? _mime(Uint8List bytes) {
    if (bytes.length >= 12 && String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') return 'video/mp4';
    if (bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) return 'image/jpeg';
    if (bytes.length >= 8 && bytes[0] == 137 && String.fromCharCodes(bytes.sublist(1, 4)) == 'PNG') return 'image/png';
    if (bytes.length >= 12 && String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') return 'image/webp';
    return null;
  }

  Future<void> _choose() async {
    if (!AppSession.isSuperAdmin || _busy) return;
    setState(() => _busy = true);
    try {
      final isImage = _draft.mediaType == 'image';
      final file = await openFile(acceptedTypeGroups: [isImage
        ? const XTypeGroup(label: 'Photos', extensions: ['jpg', 'jpeg', 'png', 'webp'],
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            uniformTypeIdentifiers: ['public.jpeg', 'public.png', 'org.webmproject.webp'])
        : const XTypeGroup(label: 'Vidéos MP4', extensions: ['mp4'],
            mimeTypes: ['video/mp4'], uniformTypeIdentifiers: ['public.mpeg-4'])]);
      if (file == null || !mounted) return;
      final size = await file.length();
      final maximum = (isImage ? 8 : 25) * 1024 * 1024;
      if (size <= 0 || size >= maximum) throw StateError(isImage ? 'Photo : moins de 8 Mo.' : 'Vidéo : moins de 25 Mo.');
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final mime = _mime(bytes);
      final extension = file.name.split('.').last.toLowerCase();
      if (mime == null || isImage && !mime.startsWith('image/') ||
          !isImage && (mime != 'video/mp4' || extension != 'mp4')) {
        throw StateError('Format non pris en charge. Utilisez JPEG, PNG, WebP ou une vidéo MP4 H.264.');
      }
      if (isImage) {
        final decoded = await decodeImageFromList(bytes);
        decoded.dispose();
      }
      final ext = {'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'video/mp4': 'mp4'}[mime]!;
      final unique = FirebaseFirestore.instance.collection('_startup_upload_ids').doc().id;
      final path = 'startup_media/$unique.$ext';
      final reference = FirebaseStorage.instance.ref(path);
      final task = reference.putData(bytes, SettableMetadata(contentType: mime,
        cacheControl: 'public,max-age=31536000,immutable'));
      _upload = task;
      _progressSubscription = task.snapshotEvents.listen((event) {
        if (mounted) setState(() => _progress = event.totalBytes == 0 ? null : event.bytesTransferred / event.totalBytes);
      }, onError: (Object _) {});
      await task;
      if (!mounted) return;
      setState(() {
        _draft = StartupPresentation(enabled: _draft.enabled, mediaType: isImage ? 'image' : 'video',
          storagePath: path, durationSeconds: _draft.durationSeconds);
        _imageBytes = isImage ? bytes : null;
        _fileLabel = file.name;
        _dirty = true;
      });
      _message('Fichier transféré. Prévisualisez puis publiez pour changer le démarrage.');
    } catch (error) {
      _message('Sélection ou transfert impossible : $error');
    } finally {
      await _progressSubscription?.cancel(); _progressSubscription = null;
      _upload = null;
      if (mounted) setState(() { _busy = false; _progress = null; });
    }
  }

  bool get _hasMedia => _draft.isLocal || StartupPresentation.pathPattern.hasMatch(_draft.storagePath);

  Future<void> _preview() async {
    if (_busy || !_hasMedia) return;
    // Preview ignores the enabled switch so disabled drafts can be checked.
    final draft = StartupPresentation(enabled: true, mediaType: _draft.mediaType,
      storagePath: _draft.storagePath, durationSeconds: _draft.durationSeconds);
    await Navigator.push<void>(context, MaterialPageRoute<void>(builder: (previewContext) =>
      StartupPresentationPlayer(settings: draft, allowLocalFallback: false,
        onFinished: () => Navigator.pop(previewContext))));
  }

  Future<void> _publish() async {
    if (!AppSession.isSuperAdmin || _busy || !_dirty || _draft.enabled && !_hasMedia) return;
    final confirm = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      backgroundColor: _card, title: const Text('Publier la présentation ?', style: TextStyle(color: _gold)),
      content: Text(_draft.enabled
        ? 'Les applications mises à jour afficheront cette présentation au prochain lancement avec Internet.'
        : 'La présentation sera désactivée pour les prochains lancements avec Internet.',
        style: const TextStyle(color: Colors.white)),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Publier', style: TextStyle(color: _gold)))],
    ));
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('Reconnectez-vous au compte Super Admin.');
      final map = _draft.toMap();
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final current = await transaction.get(StartupPresentationSettings.reference);
        if (current.exists != _loadedExists || current.data()?['updatedAt'] != _loadedUpdatedAt) {
          throw StateError('La présentation a changé ailleurs. Rechargez avant de publier.');
        }
        transaction.set(StartupPresentationSettings.reference, {...map,
          'updatedAt': FieldValue.serverTimestamp(), 'updatedBy': uid});
      });
      _message('Présentation publiée.');
      await _load();
    } catch (error) {
      _message('Publication impossible : $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    unawaited(_progressSubscription?.cancel());
    unawaited(_upload?.cancel().then<void>((_) {}).catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) return const Center(child: Text('Réservé au Super Admin', style: TextStyle(color: Colors.white)));
    if (_loading) return const Center(child: CircularProgressIndicator(color: _gold));
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(
      mainAxisSize: MainAxisSize.min, children: [Text(_error!, style: const TextStyle(color: Colors.white)),
        TextButton(onPressed: _load, child: const Text('Réessayer'))])));
    final valid = _hasMedia;
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Présentation au démarrage', style: TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Choisissez une vidéo ou une photo. La page de bienvenue reste indépendante.', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 18),
      Wrap(spacing: 12, children: [
        ChoiceChip(label: const Text('Vidéo'), selected: _draft.mediaType != 'image',
          onSelected: _busy ? null : (_) {
            if (_draft.mediaType == 'image') {
              _imageBytes = null; _fileLabel = 'Choisissez une vidéo MP4';
              _change(type: 'video', path: '');
            }
          }, selectedColor: _gold, labelStyle: TextStyle(color: _draft.mediaType != 'image' ? _dark : Colors.white)),
        ChoiceChip(label: const Text('Photo'), selected: _draft.mediaType == 'image',
          onSelected: _busy ? null : (_) {
            if (_draft.mediaType != 'image') {
              _imageBytes = null; _fileLabel = 'Choisissez une photo';
              _change(type: 'image', path: '');
            }
          }, selectedColor: _gold, labelStyle: TextStyle(color: _draft.mediaType == 'image' ? _dark : Colors.white)),
      ]),
      const SizedBox(height: 14),
      Container(height: 210, clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _gold)),
        child: _imageBytes != null ? Image.memory(_imageBytes!, fit: BoxFit.contain)
          : _draft.isLocal ? Padding(padding: const EdgeInsets.all(24), child: Image.asset('assets/images/euro_habesha_logo.png'))
          : Center(child: Icon(_draft.mediaType == 'image' ? Icons.image_outlined : Icons.play_circle_outline, color: _gold, size: 64))),
      const SizedBox(height: 10),
      Text(_fileLabel, style: const TextStyle(color: Colors.white70)),
      Text(_dirty ? 'Modifications non publiées' : 'Paramètres chargés', style: const TextStyle(color: _gold)),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _busy ? null : _choose, icon: const Icon(Icons.upload_file),
        label: const Text('Choisir un fichier'), style: OutlinedButton.styleFrom(foregroundColor: _gold, side: const BorderSide(color: _gold))),
      const Text('Le fichier choisi est transféré dans Storage pour l’aperçu. Le démarrage change uniquement après publication.',
        style: TextStyle(color: Colors.white70, fontSize: 12)),
      if (_busy) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator(value: _progress, color: _gold)),
      SwitchListTile(activeThumbColor: _gold, title: const Text('Activer la présentation', style: TextStyle(color: Colors.white)),
        value: _draft.enabled, onChanged: _busy ? null : (v) => _change(enabled: v)),
      const Text('Durée maximale', style: TextStyle(color: Colors.white)),
      DropdownButton<int>(value: _draft.durationSeconds, isExpanded: true, dropdownColor: _card,
        style: const TextStyle(color: _gold), items: [for (var i = 3; i <= 15; i++)
          DropdownMenuItem(value: i, child: Text('$i secondes'))],
        onChanged: _busy ? null : (v) { if (v != null) _change(seconds: v); }),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.volume_off, color: _gold),
        title: Text('Sans son · bouton Passer disponible', style: TextStyle(color: Colors.white70))),
      OutlinedButton.icon(onPressed: _busy || !valid ? null : _preview,
        icon: const Icon(Icons.play_arrow), label: const Text('Prévisualiser'),
        style: OutlinedButton.styleFrom(foregroundColor: _gold, side: const BorderSide(color: _gold))),
      const SizedBox(height: 10),
      FilledButton.icon(onPressed: _busy || !_dirty || _draft.enabled && !valid ? null : _publish,
        icon: const Icon(Icons.publish), label: const Text('Publier la présentation'),
        style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _dark)),
      TextButton(onPressed: _busy ? null : () {
        _imageBytes = null; _fileLabel = 'Vidéo originale intégrée';
        _change(type: 'local', path: '');
      }, child: const Text('Rétablir la vidéo originale', style: TextStyle(color: _gold))),
      TextButton(onPressed: _busy ? null : _load,
        child: const Text('Recharger / annuler les modifications', style: TextStyle(color: Colors.white70))),
      const SizedBox(height: 30),
    ]);
  }
}
