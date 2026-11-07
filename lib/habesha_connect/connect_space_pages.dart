import '../l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'connect_space_form.dart';
import 'connect_space_model.dart';
import 'connect_space_service.dart';

const connectDark = Color(0xFF061E12),
    connectGreen = Color(0xFF004D40),
    connectGold = Color(0xFFFFD700);
void connectMessage(BuildContext context, Object value) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(
          value is StateError ? value.message.toString() : value.toString(),
        ),
      ),
    );
Widget connectNotice(String value) => Padding(
  padding: const EdgeInsets.all(16),
  child: AppText(value, style: const TextStyle(color: Colors.white70)),
);
Widget connectSpaceTile(
  BuildContext context,
  String id,
  Map<String, dynamic> data,
) => Card(
  color: connectGreen,
  child: ListTile(
    leading: (data['logoUrl'] ?? '').toString().isEmpty
        ? Icon(
            data['kind'] == 'association'
                ? Icons.handshake_outlined
                : Icons.groups_outlined,
            color: connectGold,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              data['logoUrl'].toString(),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.groups_outlined, color: connectGold),
            ),
          ),
    title: Text(
      (data['title'] ?? 'Espace communautaire').toString(),
      style: const TextStyle(color: Colors.white),
    ),
    subtitle: AppText(
      '${ui(context, connectSpaceLabel((data['kind'] ?? '').toString()))} · ${data['city'] ?? ''}',
      style: const TextStyle(color: Colors.white70),
    ),
    trailing: const Icon(Icons.chevron_right, color: connectGold),
    onTap: () => Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ConnectSpaceDetail(id: id)),
    ),
  ),
);

class ConnectSpaceDirectory extends StatelessWidget {
  const ConnectSpaceDirectory({super.key, required this.kind});
  final String kind;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: connectDark,
    appBar: AppBar(
      backgroundColor: connectDark,
      foregroundColor: connectGold,
      title: AppText(kind == 'association' ? 'Associations' : 'Groupes'),
      actions: [
        IconButton(
          tooltip: ui(context, 'Mes demandes'),
          icon: const Icon(Icons.assignment_outlined),
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const ConnectMyRequests()),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: connectGold,
              foregroundColor: connectDark,
            ),
            icon: const Icon(Icons.add),
            label: AppText(
              kind == 'association'
                  ? 'Présenter une association'
                  : 'Proposer un groupe',
            ),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => ConnectSpaceForm(kind: kind)),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ConnectSpaceService.spaces
                .where('status', isEqualTo: 'published')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return connectNotice('Lecture impossible : ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: connectGold),
                );
              }
              final docs = snapshot.data!.docs
                  .where((doc) => doc.data()['kind'] == kind)
                  .toList();
              if (docs.isEmpty) {
                return connectNotice(
                  'Aucun espace publié dans cette rubrique pour le moment.',
                );
              }
              return ListView(
                children: docs
                    .map((doc) => connectSpaceTile(context, doc.id, doc.data()))
                    .toList(),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class ConnectMyRequests extends StatelessWidget {
  const ConnectMyRequests({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: connectDark,
      appBar: AppBar(
        backgroundColor: connectDark,
        foregroundColor: connectGold,
        title: const AppText('Mes demandes communautaires'),
      ),
      body: user == null || user.isAnonymous
          ? connectNotice('Connectez-vous pour retrouver vos demandes.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ConnectSpaceService.requests
                  .where('ownerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return connectNotice(
                    'Lecture impossible : ${snapshot.error}',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: connectGold),
                  );
                }
                if (snapshot.data!.docs.isEmpty) {
                  return connectNotice(
                    'Aucune demande. Vos futurs groupes et associations apparaîtront ici.',
                  );
                }
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data(), status = doc.data()['status'];
                    return Card(
                      color: connectGreen,
                      child: ListTile(
                        title: Text(
                          (data['title'] ?? '').toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: AppText(
                          status == 'approved'
                              ? 'Approuvé — ouvrir mon espace'
                              : status == 'rejected'
                              ? 'Refusé : ${data['reviewNote'] ?? ''}'
                              : 'En attente de validation administrative',
                          style: const TextStyle(color: connectGold),
                        ),
                        onTap: status != 'approved'
                            ? null
                            : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ConnectSpaceDetail(id: doc.id),
                                ),
                              ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}

class ConnectSpaceDetail extends StatefulWidget {
  const ConnectSpaceDetail({super.key, required this.id});
  final String id;
  @override
  State<ConnectSpaceDetail> createState() => _ConnectSpaceDetailState();
}

class _ConnectSpaceDetailState extends State<ConnectSpaceDetail> {
  bool _busy = false;
  DocumentReference<Map<String, dynamic>> get _space =>
      ConnectSpaceService.spaces.doc(widget.id);
  Future<void> _join() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ConnectSpaceService.askToJoin(widget.id);
    } catch (error) {
      if (mounted) {
        connectMessage(context, 'Demande impossible : $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: connectDark,
    appBar: AppBar(
      backgroundColor: connectDark,
      foregroundColor: connectGold,
      title: const AppText('Espace communautaire'),
    ),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _space.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return connectNotice(
            'Cet espace n’est pas accessible : ${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: connectGold),
          );
        }
        final data = snapshot.data!.data();
        if (data == null || data['status'] != 'published') {
          return connectNotice('Cet espace n’est pas publié.');
        }
        final user = FirebaseAuth.instance.currentUser;
        final owner = user != null && data['ownerId'] == user.uid;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if ((data['logoUrl'] ?? '').toString().isNotEmpty)
              SizedBox(
                height: 160,
                child: Image.network(
                  data['logoUrl'].toString(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.groups_outlined, color: connectGold),
                ),
              ),
            Text(
              (data['title'] ?? '').toString(),
              style: const TextStyle(
                color: connectGold,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            connectNotice(
              '${ui(context, connectSpaceLabel(data['kind'].toString()))} · ${data['city']} · ${data['country']}',
            ),
            Text(
              (data['description'] ?? '').toString(),
              style: const TextStyle(color: Colors.white),
            ),
            if ((data['topic'] ?? '').toString().isNotEmpty)
              connectNotice('Thème : ${data['topic']}'),
            if ((data['audience'] ?? '').toString().isNotEmpty)
              connectNotice('Pour : ${data['audience']}'),
            const SizedBox(height: 16),
            if (owner) ...[
              FilledButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConnectMemberRequests(spaceId: widget.id),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: connectGold,
                  foregroundColor: connectDark,
                ),
                child: const AppText('Gérer les demandes d’adhésion'),
              ),
              _discussionButton(manager: true),
            ] else if (user == null || user.isAnonymous)
              connectNotice(
                'Connectez-vous à votre compte Euro Habesha pour demander à rejoindre.',
              )
            else
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _space.collection('members').doc(user.uid).snapshots(),
                builder: (context, member) {
                  if (member.hasError) {
                    return connectNotice(
                      'Lecture de votre adhésion impossible : ${member.error}',
                    );
                  }
                  if (!member.hasData) {
                    return const LinearProgressIndicator(color: connectGold);
                  }
                  if (connectMayReadDiscussion(
                    published: true,
                    owner: false,
                    member: member.data!.exists,
                  )) {
                    return _discussionButton();
                  }
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _space
                        .collection('membershipRequests')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, request) {
                      if (request.hasError) {
                        return connectNotice(
                          'Lecture de votre demande impossible : ${request.error}',
                        );
                      }
                      if (!request.hasData) {
                        return const LinearProgressIndicator(
                          color: connectGold,
                        );
                      }
                      if (request.data!.exists) {
                        final status = request.data!.data()?['status'];
                        return connectNotice(
                          status == 'pending'
                              ? 'Votre demande d’adhésion est en attente du responsable.'
                              : status == 'rejected'
                              ? 'Votre demande d’adhésion a été refusée.'
                              : 'Votre adhésion a été traitée.',
                        );
                      }
                      return FilledButton(
                        onPressed: _busy ? null : _join,
                        style: FilledButton.styleFrom(
                          backgroundColor: connectGold,
                          foregroundColor: connectDark,
                        ),
                        child: AppText(
                          _busy ? 'Envoi…' : 'Demander à rejoindre',
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    ),
  );
  Widget _discussionButton({bool manager = false}) => OutlinedButton.icon(
    onPressed: () => Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ConnectSpaceDiscussion(spaceId: widget.id, isManager: manager),
      ),
    ),
    style: OutlinedButton.styleFrom(foregroundColor: connectGold),
    icon: const Icon(Icons.forum_outlined),
    label: const AppText('Discussion des membres'),
  );
}

class ConnectMemberRequests extends StatefulWidget {
  const ConnectMemberRequests({super.key, required this.spaceId});
  final String spaceId;
  @override
  State<ConnectMemberRequests> createState() => _ConnectMemberRequestsState();
}

class _ConnectMemberRequestsState extends State<ConnectMemberRequests> {
  String? _busy;
  Future<void> _review(String uid, bool approve) async {
    if (_busy != null) {
      return;
    }
    setState(() => _busy = uid);
    try {
      await ConnectSpaceService.reviewMember(
        widget.spaceId,
        uid,
        approve: approve,
      );
    } catch (error) {
      if (mounted) {
        connectMessage(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: connectDark,
    appBar: AppBar(
      backgroundColor: connectDark,
      foregroundColor: connectGold,
      title: const AppText('Adhésions et membres'),
    ),
    body: Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ConnectSpaceService.spaces
                .doc(widget.spaceId)
                .collection('membershipRequests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return connectNotice('Accès impossible : ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: connectGold),
                );
              }
              if (snapshot.data!.docs.isEmpty) {
                return connectNotice('Aucune demande en attente.');
              }
              return ListView(
                children: snapshot.data!.docs
                    .map(
                      (doc) => Card(
                        color: connectGreen,
                        child: ListTile(
                          title: Text(
                            (doc.data()['displayName'] ?? 'Membre').toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Wrap(
                            children: [
                              TextButton(
                                onPressed: _busy != null
                                    ? null
                                    : () => _review(doc.id, true),
                                child: const AppText(
                                  'Accepter',
                                  style: TextStyle(color: connectGold),
                                ),
                              ),
                              TextButton(
                                onPressed: _busy != null
                                    ? null
                                    : () => _review(doc.id, false),
                                child: const AppText(
                                  'Refuser',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: AppText(
            'Membres acceptés',
            style: TextStyle(color: connectGold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ConnectSpaceService.spaces
                .doc(widget.spaceId)
                .collection('members')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return connectNotice(
                  'Membres indisponibles : ${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: connectGold),
                );
              }
              if (snapshot.data!.docs.isEmpty) {
                return connectNotice('Aucun membre accepté.');
              }
              return ListView(
                children: snapshot.data!.docs
                    .map(
                      (doc) => ListTile(
                        title: Text(
                          (doc.data()['displayName'] ?? 'Membre').toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          tooltip: ui(context, 'Retirer ce membre'),
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: connectGold,
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const AppText('Retirer ce membre ?'),
                                content: const AppText(
                                  'Son accès à la discussion sera retiré. Il ne pourra pas refaire de demande dans cette version.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const AppText('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const AppText('Retirer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) {
                              return;
                            }
                            try {
                              await doc.reference.delete();
                            } catch (error) {
                              if (context.mounted) {
                                connectMessage(context, error);
                              }
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class ConnectSpaceDiscussion extends StatefulWidget {
  const ConnectSpaceDiscussion({
    super.key,
    required this.spaceId,
    this.isManager = false,
  });
  final String spaceId;
  final bool isManager;
  @override
  State<ConnectSpaceDiscussion> createState() => _ConnectSpaceDiscussionState();
}

class _ConnectSpaceDiscussionState extends State<ConnectSpaceDiscussion> {
  final _message = TextEditingController();
  bool _sending = false;
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _message.text.trim();
    if (_sending || user == null || text.isEmpty) {
      return;
    }
    if (text.length > 3000) {
      connectMessage(context, 'Message trop long.');
      return;
    }
    setState(() => _sending = true);
    try {
      await ConnectSpaceService.spaces
          .doc(widget.spaceId)
          .collection('messages')
          .add({
            'authorId': user.uid,
            'displayName': user.displayName ?? 'Membre',
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });
      if (mounted && _message.text.trim() == text) {
        _message.clear();
      }
    } catch (error) {
      if (mounted) {
        connectMessage(context, 'Message non envoyé : $error');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: connectDark,
    appBar: AppBar(
      backgroundColor: connectDark,
      foregroundColor: connectGold,
      title: const AppText('Discussion des membres'),
    ),
    body: Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ConnectSpaceService.spaces
                .doc(widget.spaceId)
                .collection('messages')
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return connectNotice(
                  'Discussion inaccessible : ${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: connectGold),
                );
              }
              if (snapshot.data!.docs.isEmpty) {
                return connectNotice('Aucun message. Lancez la discussion.');
              }
              return ListView(
                reverse: true,
                children: snapshot.data!.docs
                    .map(
                      (doc) => Card(
                        color: connectGreen,
                        child: ListTile(
                          title: Text(
                            (doc.data()['displayName'] ?? '').toString(),
                            style: const TextStyle(color: connectGold),
                          ),
                          trailing:
                              widget.isManager ||
                                  doc.data()['authorId'] ==
                                      FirebaseAuth.instance.currentUser?.uid
                              ? IconButton(
                                  tooltip: ui(context, 'Supprimer ce message'),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: connectGold,
                                  ),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const AppText(
                                          'Supprimer ce message ?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            child: const AppText('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            child: const AppText('Supprimer'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true) {
                                      return;
                                    }
                                    try {
                                      await doc.reference.delete();
                                    } catch (error) {
                                      if (context.mounted) {
                                        connectMessage(context, error);
                                      }
                                    }
                                  },
                                )
                              : null,
                          subtitle: Text(
                            (doc.data()['text'] ?? '').toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                    enabled: !_sending,
                    maxLength: 3000,
                    style: const TextStyle(color: Colors.white),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: ui(context, 'Écrire au groupe…'),
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: connectGreen,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send, color: connectGold),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
