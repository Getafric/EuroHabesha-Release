import '../l10n/app_ui.dart';

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

import 'workspace_ui.dart';

class EhCommunityEntry extends StatelessWidget {
  const EhCommunityEntry({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Card(
        color: ehGold,
        child: ListTile(
          leading: const Icon(Icons.person_add_alt_1, color: Colors.black),
          title: const AppText(
            'Créer / modifier mon profil communautaire',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          subtitle: const AppText(
            'Votre compte Euro Habesha suffit. Présentez-vous pour échanger avec les membres.',
            style: TextStyle(color: Colors.black87),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.black),
          onTap: () => ehRun(context, () => ehEditMember(context)),
        ),
      ),
      ehTile(
        'Rencontrer la communauté',
        'Membres, centres d’intérêt et demandes de discussion',
        () => ehOpen<void>(context, const EhMembersPage()),
        icon: Icons.people_outline,
      ),
    ],
  );
}

Future<void> ehEditMember(BuildContext context) async {
  final d = await ehCall('profile.mine');
  final p = ehMap(d['profile']), private = ehMap(d['private']);
  if (!context.mounted) return;
  await ehOpen<bool>(
    context,
    EhForm(
      title: 'Mon profil communautaire',
      photoKey: 'photoUrl',
      note:
          'Ce profil est facultatif et réservé aux adultes. Votre date de naissance reste privée. '
          'Votre photo, votre ville et votre présentation seront visibles aux autres membres si vous activez la découverte. '
          'Désactivez-la à tout moment. Suivre un membre ne donne pas accès à sa discussion.',
      initial: {
        ...p,
        ...private,
        'interests': (p['interests'] as List? ?? []).join(', '),
        'languages': (p['languages'] as List? ?? []).join(', '),
      },
      fields: const [
        EhField('name', 'Nom affiché', max: 80),
        EhField('birthdate', 'Date de naissance privée', date: true),
        EhField('city', 'Ville', max: 120),
        EhField('bio', 'Ma présentation', lines: 3, required: false, max: 1000),
        EhField(
          'interests',
          'Centres d’intérêt séparés par des virgules',
          required: false,
        ),
        EhField(
          'languages',
          'Langues séparées par des virgules',
          required: false,
        ),
        EhField('showAge', 'Afficher mon âge', toggle: true),
        EhField(
          'discoverable',
          'Rendre mon profil visible aux membres',
          toggle: true,
        ),
      ],
      save: (v) async {
        await ehCall('profile.save', {
          ...v,
          'interests': ehSplit(v['interests']),
          'languages': ehSplit(v['languages']),
        });
      },
    ),
  );
}

class EhMembersPage extends StatefulWidget {
  const EhMembersPage({super.key});
  @override
  State<EhMembersPage> createState() => _EhMembersPageState();
}

class _EhMembersPageState extends State<EhMembersPage> {
  String _query = '';
  int _version = 0;
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Membres de la communauté',
    actions: [
      IconButton(
        tooltip: 'Mon profil communautaire',
        icon: const Icon(Icons.edit),
        onPressed: () => ehRun(context, () async {
          await ehEditMember(context);
          if (mounted) setState(() => _version++);
        }),
      ),
      IconButton(
        tooltip: 'Demandes de discussion',
        icon: const Icon(Icons.forum_outlined),
        onPressed: () => ehOpen<void>(context, const EhInboxPage()),
      ),
    ],
    body: EhLoad(
      key: ValueKey(_version),
      load: () async {
        final own = await ehCall('profile.mine');
        return ehMap(own['profile'])['discoverable'] == true
            ? await ehCall('members')
            : <String, dynamic>{'items': []};
      },
      builder: (d, refresh) {
        final members = ehRows(d['items'])
            .where(
              (p) => '${p['name']} ${p['city']} ${p['interests']}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
            )
            .toList();
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nom, ville ou centre d’intérêt',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            ehButton(
              'Créer / modifier mon profil communautaire',
              () => ehRun(context, () async {
                await ehEditMember(context);
                refresh();
              }),
              icon: Icons.person_outline,
            ),
            if (members.isEmpty)
              ehNote('Aucun membre à afficher pour le moment.'),
            for (final p in members)
              Card(
                color: ehCard,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ehPhoto(p['photoUrl']?.toString()),
                      AppText(
                        '${p['name']}${p['age'] != null ? ', ${p['age']} ans' : ''}',
                        style: const TextStyle(color: ehGold, fontSize: 20),
                      ),
                      ehNote(
                        '${p['city']} · ${(p['languages'] as List? ?? []).join(', ')}',
                      ),
                      ehNote('${p['bio']}'),
                      ehInterests(p['interests'] as List? ?? []),
                      if (p['followsYou'] == true)
                        ehNote('Ce membre vous suit'),
                      ehButton(
                        p['following'] == true
                            ? 'Ne plus suivre'
                            : p['followsYou'] == true
                            ? 'Suivre en retour'
                            : 'Suivre',
                        () => ehRun(context, () async {
                          await ehCall('follow', {
                            'to': p['uid'],
                            'follow': p['following'] != true,
                          });
                          refresh();
                        }),
                        icon: Icons.person_add_alt,
                      ),
                      ehButton('Demander une discussion', () async {
                        await ehOpen<void>(
                          context,
                          EhConversationPage(to: p['uid'], name: p['name']),
                        );
                        refresh();
                      }, icon: Icons.chat_bubble_outline),
                      TextButton(
                        onPressed: () =>
                            ehMemberMenu(context, p['uid'], refresh),
                        child: const AppText('Bloquer ou signaler'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

Future<void> ehMemberMenu(
  BuildContext context,
  String uid,
  VoidCallback refresh,
) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const AppText('Bloquer ce membre'),
            onTap: () => Navigator.pop(c, 'block'),
          ),
          ListTile(
            title: const AppText('Signaler ce membre'),
            onTap: () => Navigator.pop(c, 'report'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  await ehRun(context, () async {
    if (choice == 'block') {
      await ehCall('block', {'to': uid});
      refresh();
    } else {
      await ehOpen<bool>(
        context,
        EhForm(
          title: 'Signaler',
          fields: const [
            EhField('reason', 'Motif du signalement', lines: 4, max: 1000),
          ],
          save: (v) async {
            await ehCall('report', {...v, 'to': uid});
          },
        ),
      );
    }
  });
}

class EhInboxPage extends StatelessWidget {
  const EhInboxPage({super.key});
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Discussions communautaires',
    body: EhLoad(
      load: () => ehCall('inbox'),
      builder: (d, refresh) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final rows = ehRows(d['items']);
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            ehNote(
              'Les demandes autorisent trois messages texte avant acceptation. '
              'Actualisez pour recevoir les nouvelles réponses.',
            ),
            if (rows.isEmpty)
              ehNote('Vous n’avez pas encore de demande de discussion.'),
            for (final r in rows)
              ehTile(
                ehMap(r['names']).entries
                    .where((e) => e.key != uid)
                    .map((e) => e.value)
                    .join(),
                '${r['status'] == 'accepted'
                    ? 'Acceptée'
                    : r['status'] == 'declined'
                    ? 'Refusée'
                    : 'En attente'} · ${r['preview'] ?? ''}',
                () async {
                  await ehOpen<void>(
                    context,
                    EhConversationPage(conversationId: r['id']),
                  );
                  refresh();
                },
              ),
          ],
        );
      },
    ),
  );
}

class EhConversationPage extends StatefulWidget {
  const EhConversationPage({
    super.key,
    this.conversationId,
    this.to,
    this.name,
  });
  final String? conversationId, to, name;
  @override
  State<EhConversationPage> createState() => _EhConversationPageState();
}

class _EhConversationPageState extends State<EhConversationPage> {
  final _text = TextEditingController();
  final _audio = AudioPlayer();
  String? _id;
  String _intent = ehId();
  bool _busy = false;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _id = widget.conversationId;
  }

  @override
  void dispose() {
    _text.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _send(EhData? conversation, {EhData? attachment}) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ehRun(context, () async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final to =
          widget.to ??
          (conversation?['participants'] as List).firstWhere((v) => v != uid);
      final r = await ehCall('message.send', {
        'to': to,
        'intent': _intent,
        'text': _text.text,
        if (attachment != null) 'attachment': attachment,
      });
      if (!mounted) return;
      setState(() {
        _id = r['conversationId'];
        _text.clear();
        _intent = ehId();
        _revision++;
      });
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _attach(EhData d, bool camera, bool audio) async {
    if (_busy) return;
    await ehRun(context, () async {
      late List<int> bytes;
      String mime = 'image/jpeg';
      if (audio) {
        final f = await openFile(
          acceptedTypeGroups: [
            const XTypeGroup(
              label: 'Audio',
              extensions: ['mp3', 'm4a', 'wav', 'aac'],
              mimeTypes: ['audio/*'],
            ),
          ],
        );
        if (f == null) return;
        bytes = await f.readAsBytes();
        final ext = f.name.toLowerCase().split('.').last;
        mime =
            {
              'mp3': 'audio/mpeg',
              'm4a': 'audio/mp4',
              'wav': 'audio/wav',
              'aac': 'audio/aac',
            }[ext] ??
            '';
      } else {
        final f = await ImagePicker().pickImage(
          source: camera ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 640,
          imageQuality: 60,
        );
        if (f == null) return;
        bytes = await f.readAsBytes();
      }
      if (bytes.length > 250000)
        throw const FormatException(
          'Choisissez un fichier de moins de 250 Ko.',
        );
      await _send(d, attachment: {'mime': mime, 'base64': base64Encode(bytes)});
    });
  }

  @override
  Widget build(BuildContext context) => EhScaffold(
    title: widget.name ?? 'Discussion',
    body: EhLoad(
      key: ValueKey('$_id:$_revision'),
      load: () async {
        if (_id == null && widget.to != null) {
          _id = (await ehCall('conversation.open', {
            'to': widget.to,
          }))['id']?.toString();
        }
        return _id == null
            ? <String, dynamic>{'items': []}
            : await ehCall('messages', {'id': _id});
      },
      builder: (d, refresh) {
        final conversation = ehMap(d['conversation']),
            uid = FirebaseAuth.instance.currentUser?.uid;
        final accepted = conversation['status'] == 'accepted';
        final incoming =
            conversation.isNotEmpty &&
            conversation['requesterId'] != uid &&
            conversation['status'] == 'pending';
        final other =
            widget.to ??
            (conversation['participants'] as List? ?? [])
                .where((v) => v != uid)
                .firstOrNull;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            ehNote(
              accepted
                  ? 'Discussion acceptée. Photos et fichiers audio activés.'
                  : 'Trois messages texte maximum avant acceptation. Aucun appel vidéo n’est activé.',
            ),
            if (incoming) ...[
              ehButton(
                'Accepter la discussion',
                _busy
                    ? null
                    : () => ehRun(context, () async {
                        await ehCall('conversation.respond', {
                          'id': _id,
                          'choice': 'accepted',
                        });
                        refresh();
                      }),
              ),
              TextButton(
                onPressed: () => ehRun(context, () async {
                  await ehCall('conversation.respond', {
                    'id': _id,
                    'choice': 'declined',
                  });
                  refresh();
                }),
                child: const AppText('Refuser'),
              ),
            ],
            for (final m in ehRows(d['items']))
              Card(
                color: m['senderId'] == uid ? ehCard : const Color(0xFF183C2B),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText('${m['text'] ?? ''}'),
                      if (m['attachment'] != null)
                        TextButton.icon(
                          icon: Icon(
                            '${ehMap(m['attachment'])['mime']}'.startsWith(
                                  'image/',
                                )
                                ? Icons.photo
                                : Icons.play_arrow,
                          ),
                          label: const AppText('Ouvrir la pièce jointe'),
                          onPressed: () => ehRun(context, () async {
                            final a = await ehCall('message.attachment', {
                              'id': _id,
                              'messageId': m['id'],
                            });
                            if ('${a['mime']}'.startsWith('audio/')) {
                              await _audio.play(
                                BytesSource(
                                  base64Decode(a['base64']),
                                  mimeType: a['mime'],
                                ),
                              );
                            } else if (context.mounted) {
                              await ehOpen<void>(
                                context,
                                EhScaffold(
                                  title: 'Photo partagée',
                                  body: Center(child: ehAttachment(a)),
                                ),
                              );
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ),
            TextField(
              controller: _text,
              maxLength: 2000,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Votre message'),
            ),
            ehButton(
              _busy ? 'Envoi…' : 'Envoyer',
              _busy || incoming || conversation['status'] == 'declined'
                  ? null
                  : () => _send(conversation),
              icon: Icons.send,
            ),
            if (accepted)
              Wrap(
                children: [
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _attach(conversation, true, false),
                    icon: const Icon(Icons.camera_alt),
                    label: const AppText('Caméra'),
                  ),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _attach(conversation, false, false),
                    icon: const Icon(Icons.photo),
                    label: const AppText('Photo'),
                  ),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _attach(conversation, false, true),
                    icon: const Icon(Icons.audio_file),
                    label: const AppText('Fichier audio'),
                  ),
                ],
              ),
            if (other != null)
              TextButton(
                onPressed: () => ehMemberMenu(context, '$other', refresh),
                child: const AppText('Bloquer / signaler'),
              ),
            ehButton('Actualiser les messages', refresh, icon: Icons.refresh),
          ],
        );
      },
    ),
  );
}
