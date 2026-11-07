import 'l10n/app_ui.dart';
import 'advertisement_request_screen.dart'
    show AdvertisementRequestScreen, AdvertisementRequestHistoryScreen;
import 'professional_verification_screen.dart';
import 'app_session.dart';
import 'member_interface_text.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'business_dashboard_screen.dart';
import 'dynamic_submission_screen.dart';
import 'event_organizer_dashboard_screen.dart';

/// A single entry point. Opening it never changes the user's account type.
class ProfileTypeScreen extends StatefulWidget {
  const ProfileTypeScreen({super.key, this.initialType});

  final SubmissionType? initialType;

  @override
  State<ProfileTypeScreen> createState() => _ProfileTypeScreenState();
}

class _ProfileTypeScreenState extends State<ProfileTypeScreen> {
  static const _green = Color(0xFF061E12);
  static const _gold = Color(0xFFFFD700);
  static const _card = Color(0xFF004D40);

  bool _loading = true;
  bool _opening = false;
  String? _error;
  String? _loadedUid;
  List<OwnedProfessionalEntry> _entries = [];
  SubmissionType _selected = SubmissionType.business;

  static const _choices = <SubmissionType, String>{
    SubmissionType.business: 'Commerce / Restaurant',
    SubmissionType.professional: 'Professionnel / Profession libérale',
    SubmissionType.job: 'Services / Prestataire',
    SubmissionType.employer: 'Employeur',
    SubmissionType.event: 'Organisateur d’événements',
  };

  static const _englishChoices = <SubmissionType, String>{
    SubmissionType.business: 'Business / Restaurant',
    SubmissionType.professional: 'Professional / Liberal profession',
    SubmissionType.job: 'Services / Service provider',
    SubmissionType.employer: 'Employer',
    SubmissionType.event: 'Event organizer',
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.initialType;
    _selected = _choices.containsKey(initial)
        ? initial!
        : SubmissionType.business;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        setState(() {
          _entries = [];
          _loadedUid = null;
          _loading = false;
        });
      }
      return;
    }
    try {
      final entries = await ProfessionalProfileLookup.load(user.uid);
      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
        setState(() {
          _error = memberText(
            context,
            'Le compte a changé. Rechargez vos activités.',
            'The account changed. Reload your activities.',
          );
          _loading = false;
        });
        return;
      }
      setState(() {
        _entries = entries;
        _loadedUid = user.uid;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Chargement des activités : $error');
      if (!mounted) return;
      setState(() {
        _loadedUid = null;
        _error = memberText(
          context,
          'Impossible de vérifier vos activités existantes. Réessayez avant de créer un nouveau dossier.',
          'Unable to check existing activities. Try again before creating a new application.',
        );
        _loading = false;
      });
    }
  }

  Future<void> _signIn() async {
    await Navigator.pushNamed(context, '/login');
    if (mounted) await _load();
  }

  bool get _canAdminPreview {
    final user = FirebaseAuth.instance.currentUser;
    return user != null &&
        !user.isAnonymous &&
        user.emailVerified &&
        (user.email ?? '').trim().toLowerCase() ==
            AppSession.email.trim().toLowerCase() &&
        (AppSession.isSuperAdmin || AppSession.roles.isNotEmpty);
  }

  Future<void> _openAdminPreview() async {
    if (!_canAdminPreview || _opening) {
      return;
    }
    final type = await showModalBottomSheet<SubmissionType>(
      context: context,
      backgroundColor: _card,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  memberText(
                    context,
                    'Prévisualiser un formulaire',
                    'Preview a form',
                  ),
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final choice in _choices.entries)
                if (choice.key != SubmissionType.event)
                  ListTile(
                    title: Text(
                      memberText(
                        context,
                        choice.value,
                        _englishChoices[choice.key]!,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: _gold),
                    onTap: () => Navigator.pop(sheetContext, choice.key),
                  ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  memberText(
                    context,
                    'Aperçu uniquement : aucun dossier ne sera créé.',
                    'Preview only: no application will be created.',
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (type == null || !mounted || !_canAdminPreview) {
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicSubmissionScreen(type: type, previewOnly: true),
      ),
    );
  }

  bool get _accountMatches =>
      _loadedUid != null &&
      FirebaseAuth.instance.currentUser?.uid == _loadedUid &&
      FirebaseAuth.instance.currentUser?.isAnonymous == false &&
      FirebaseAuth.instance.currentUser?.emailVerified == true;

  Future<void> _openDashboard(bool events) async {
    if (_opening) return;
    if (!_accountMatches) {
      await _load();
      return;
    }
    setState(() => _opening = true);
    try {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => events
              ? const EventOrganizerDashboardScreen()
              : const BusinessDashboardScreen(),
        ),
      );
      if (mounted) await _load();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _create() async {
    if (_opening || _loading || _error != null) return;
    if (!_accountMatches) {
      await _load();
      return;
    }
    setState(() => _opening = true);
    try {
      // Recheck just before creation in case another screen created a dossier.
      final entries = await ProfessionalProfileLookup.load(_loadedUid!);
      if (!mounted || !_accountMatches) return;
      setState(() => _entries = entries);
      final sameKind = entries
          .where(
            (entry) =>
                entry.type == _selected ||
                (_selected == SubmissionType.job &&
                    entry.type == SubmissionType.professional),
          )
          .toList();
      if (sameKind.isNotEmpty) {
        final createAnother = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: _card,
            title: Text(
              memberText(
                context,
                'Une activité existe déjà',
                'An activity already exists',
              ),
              style: const TextStyle(color: _gold),
            ),
            content: Text(
              memberText(
                context,
                'Vous pouvez gérer le dossier existant depuis votre espace. Créez un autre dossier uniquement pour une autre activité ou un nouvel événement.',
                'Manage your existing application from your space. Create another application only for another activity or a new event.',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  memberText(
                    context,
                    'Revenir à mes activités',
                    'Back to my activities',
                  ),
                  style: const TextStyle(color: _gold),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  memberText(
                    context,
                    'Créer une autre activité',
                    'Create another activity',
                  ),
                  style: const TextStyle(color: _gold),
                ),
              ),
            ],
          ),
        );
        if (createAnother != true || !mounted || !_accountMatches) return;
      }
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => DynamicSubmissionScreen(type: _selected),
        ),
      );
      if (mounted) await _load();
    } catch (error) {
      debugPrint('Ouverture de création professionnelle : $error');
      if (mounted) {
        setState(
          () => _error = memberText(
            context,
            'Impossible de vérifier vos activités. Rechargez la liste avant de continuer.',
            'Unable to check your activities. Reload the list before continuing.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final signedIn = user != null && !user.isAnonymous && user.emailVerified;
    final hasBusiness = _entries.any(
      (entry) => entry.type != SubmissionType.event,
    );
    final hasEvents = _entries.any(
      (entry) => entry.type == SubmissionType.event,
    );
    return Scaffold(
      backgroundColor: _green,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: _gold,
        title: Text(
          memberText(
            context,
            'Mon espace professionnel',
            'My professional space',
          ),
        ),
        actions: [
          if (_canAdminPreview)
            IconButton(
              tooltip: memberText(
                context,
                'Aperçu administrateur',
                'Administrator preview',
              ),
              icon: const Icon(Icons.preview_outlined),
              onPressed: _opening ? null : _openAdminPreview,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  memberText(
                    context,
                    'Un compte, vos activités',
                    'One account, your activities',
                  ),
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (!signedIn) ...[
                  Text(
                    memberText(
                      context,
                      'Connectez-vous à votre compte membre pour retrouver ou créer votre activité. Votre adresse e-mail doit être vérifiée.',
                      'Sign in to your member account to find or create your activity. Your email must be verified.',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  _button(
                    memberText(context, 'Se connecter', 'Sign in'),
                    _signIn,
                  ),
                ] else if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  _button(memberText(context, 'Réessayer', 'Try again'), _load),
                ] else ...[
                  if (_entries.isNotEmpty) ...[
                    Text(
                      memberText(
                        context,
                        'Vos dossiers existants',
                        'Your existing applications',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final entry in _entries)
                      Card(
                        color: _card,
                        child: ListTile(
                          title: Text(
                            entry.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            entry.statusLabel(context),
                            style: const TextStyle(color: _gold),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: _gold,
                          ),
                          onTap: _opening
                              ? null
                              : () => _openDashboard(
                                  entry.type == SubmissionType.event,
                                ),
                        ),
                      ),
                    for (final entry in _entries)
                      if (entry.type == SubmissionType.business ||
                          entry.type == SubmissionType.professional)
                        TextButton.icon(
                          icon: const Icon(
                            Icons.verified_user_outlined,
                            color: _gold,
                          ),
                          label: AppText(
                            '${memberText(context, 'Dossier de vérification', 'Verification dossier')} — ${entry.title}',
                            style: const TextStyle(color: _gold),
                          ),
                          onPressed: _opening
                              ? null
                              : () async {
                                  await Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProfessionalVerificationScreen(
                                            businessId: entry.id,
                                            sourceCollection:
                                                entry.type ==
                                                    SubmissionType.business
                                                ? 'businessSubmissions'
                                                : 'jobSubmissions',
                                            currentStatus:
                                                entry.data['verificationStatus']
                                                    ?.toString() ??
                                                'draft',
                                            isVerified:
                                                entry.data['isVerified'] ==
                                                true,
                                          ),
                                    ),
                                  );
                                  if (mounted) {
                                    await _load();
                                  }
                                },
                        ),
                    if (hasBusiness)
                      _button(
                        memberText(
                          context,
                          'Gérer mes activités',
                          'Manage my activities',
                        ),
                        () => _openDashboard(false),
                      ),
                    if (hasEvents)
                      _button(
                        memberText(
                          context,
                          'Gérer mes événements',
                          'Manage my events',
                        ),
                        () => _openDashboard(true),
                      ),
                    const SizedBox(height: 16),
                    Card(
                      color: _gold,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.campaign_outlined,
                          color: Colors.black,
                          size: 32,
                        ),
                        title: Text(
                          memberText(
                            context,
                            'Promouvoir mon activité',
                            'Promote my activity',
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          memberText(
                            context,
                            'Demander une publicité sponsorisée',
                            'Request a sponsored advertisement',
                          ),
                          style: const TextStyle(color: Colors.black87),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.black,
                        ),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdvertisementRequestScreen(),
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.history, color: _gold),
                      label: Text(
                        memberText(
                          context,
                          'Mes demandes de publicité',
                          'My advertising requests',
                        ),
                        style: const TextStyle(color: _gold),
                      ),
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AdvertisementRequestHistoryScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  Text(
                    _entries.isEmpty
                        ? memberText(
                            context,
                            'Créer mon activité',
                            'Create my activity',
                          )
                        : memberText(
                            context,
                            'Ajouter une autre activité',
                            'Add another activity',
                          ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    memberText(
                      context,
                      'Choisissez votre activité. Les informations seront examinées avant publication. Ce choix ne modifie pas votre compte membre.',
                      'Choose your activity. The details will be reviewed before publication. This choice does not change your member account.',
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  for (final choice in _choices.entries)
                    Card(
                      color: _card,
                      child: ListTile(
                        leading: Icon(
                          _selected == choice.key
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _gold,
                        ),
                        title: Text(
                          memberText(
                            context,
                            choice.value,
                            _englishChoices[choice.key]!,
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: _opening
                            ? null
                            : () => setState(() => _selected = choice.key),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _button(
                    memberText(context, 'Continuer', 'Continue'),
                    _create,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    memberText(
                      context,
                      'Votre espace personnel reste accessible avec le bouton retour.',
                      'Your personal space remains accessible with the back button.',
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _button(String label, VoidCallback callback) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _gold,
        foregroundColor: _green,
        padding: const EdgeInsets.all(14),
      ),
      onPressed: _opening ? null : callback,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}

class OwnedProfessionalEntry {
  const OwnedProfessionalEntry(this.id, this.type, this.data);

  final String id;
  final SubmissionType type;
  final Map<String, dynamic> data;

  String get title {
    final fields = data['fields'];
    final value = fields is Map ? fields['title'] : null;
    return (value ?? data['title'] ?? 'Mon activité').toString();
  }

  String statusLabel(BuildContext context) {
    switch (data['status']?.toString()) {
      case 'approved':
      case 'published':
        return memberText(
          context,
          'Publication approuvée',
          'Publication approved',
        );
      case 'rejected':
        return memberText(
          context,
          'Demande refusée — consulter mon espace',
          'Application declined — see my space',
        );
      case 'draft':
        return memberText(context, 'Brouillon', 'Draft');
      default:
        return memberText(context, 'En cours d’examen', 'Under review');
    }
  }
}

class ProfessionalProfileLookup {
  static const _sources = <String, SubmissionType>{
    'businessSubmissions': SubmissionType.business,
    'jobSubmissions': SubmissionType.professional,
    'employerSubmissions': SubmissionType.employer,
    'eventSubmissions': SubmissionType.event,
  };

  static Future<List<OwnedProfessionalEntry>> load(String uid) async {
    final groups = await Future.wait(
      _sources.entries.map((source) async {
        final snapshot = await FirebaseFirestore.instance
            .collection(source.key)
            .where('ownerId', isEqualTo: uid)
            .get()
            .timeout(const Duration(seconds: 15));
        return snapshot.docs
            .map(
              (doc) => OwnedProfessionalEntry(doc.id, source.value, doc.data()),
            )
            .toList();
      }),
    );
    return groups.expand((group) => group).toList();
  }
}
