import 'l10n/app_ui.dart';

import 'dart:async';

import 'business_checkout_screen.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _dark = Color(0xFF061E12);
const _green = Color(0xFF004D40);
const _gold = Color(0xFFFFD700);

Future<Map<String, dynamic>> _liveCall(
  String name,
  Map<String, dynamic> input,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.isAnonymous || !user.emailVerified) {
    throw StateError('Connexion et e-mail vérifié requis.');
  }
  await user.getIdToken(true);
  if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
    throw StateError('Le compte connecté a changé.');
  }
  final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable(
        name,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      )
      .call<Map<String, dynamic>>(input);
  if (FirebaseAuth.instance.currentUser?.uid != user.uid ||
      response.data['environment'] != 'live') {
    throw StateError('La connexion réelle n’a pas été confirmée.');
  }
  return Map<String, dynamic>.from(response.data);
}

String _error(Object error) {
  if (error is FirebaseFunctionsException) {
    if (error.code == 'not-found') {
      return 'Les fonctions de connexion réelle ne sont pas encore déployées.';
    }
    return error.message ?? 'Opération indisponible. Réessayez.';
  }
  return 'Opération indisponible. Vérifiez votre connexion et réessayez.';
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _green,
          title: AppText(title, style: const TextStyle(color: _gold)),
          content: AppText(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _gold),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const AppText('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _dark,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const AppText('Confirmer'),
            ),
          ],
        ),
      ) ??
      false;
}

abstract class _LiveState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
  StreamSubscription<User?>? _auth;
  String? _uid;
  int _generation = 0;
  bool busy = false;
  Map<String, dynamic>? data;
  String? error;

  String get statusEndpoint;
  Map<String, dynamic> get arguments;

  bool current(int generation) =>
      mounted &&
      generation == _generation &&
      FirebaseAuth.instance.currentUser?.uid == _uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _uid) {
        return;
      }
      setState(() {
        _uid = user?.uid;
        _generation++;
        busy = false;
        data = null;
        error = null;
      });
      unawaited(refresh());
    });
    unawaited(refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_auth?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
    }
  }

  Future<void> refresh() async {
    if (busy) {
      return;
    }
    final generation = _generation;
    setState(() {
      busy = true;
      error = null;
      data = null;
    });
    try {
      final result = await _liveCall(statusEndpoint, arguments);
      if (current(generation)) {
        setState(() => data = result);
      }
    } catch (failure) {
      if (current(generation)) {
        setState(() => error = _error(failure));
      }
    } finally {
      if (current(generation)) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> perform(Future<void> Function(int) action) async {
    if (busy) {
      return;
    }
    final generation = _generation;
    setState(() {
      busy = true;
      error = null;
    });
    String? actionError;
    try {
      await action(generation);
    } catch (failure) {
      actionError = _error(failure);
    } finally {
      if (current(generation)) {
        setState(() => busy = false);
        await refresh();
        if (current(generation) && actionError != null) {
          setState(() => error = actionError);
        }
      }
    }
  }
}

/// Separate LIVE connection; never reuses or converts the TEST account.
class StripeLiveConnectionCard extends StatefulWidget {
  const StripeLiveConnectionCard({
    super.key,
    required this.businessId,
    required this.sourceCollection,
  });
  final String businessId;
  final String sourceCollection;

  @override
  State<StripeLiveConnectionCard> createState() =>
      _StripeLiveConnectionCardState();
}

class _StripeLiveConnectionCardState
    extends _LiveState<StripeLiveConnectionCard> {
  @override
  String get statusEndpoint => 'getConnectLiveAccountStatus';
  @override
  Map<String, dynamic> get arguments => {
    'businessId': widget.businessId,
    'sourceCollection': widget.sourceCollection,
  };

  @override
  void didUpdateWidget(covariant StripeLiveConnectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessId != widget.businessId ||
        oldWidget.sourceCollection != widget.sourceCollection) {
      _generation++;
      busy = false;
      data = null;
      unawaited(refresh());
    }
  }

  Future<void> connect() async {
    if (busy ||
        data?['eligible'] != true ||
        data?['onboardingEnabled'] != true) {
      return;
    }
    final generation = _generation;
    if (!await _confirm(
      context,
      'Connecter mon activité réelle',
      'Ce parcours crée ou reprend un compte Stripe réel pour cet établissement. '
          'Renseignez les informations exactes de votre activité et votre compte bancaire. '
          'Le paiement des commandes est géré séparément dans le panier.',
    )) {
      return;
    }
    if (!current(generation)) {
      return;
    }
    await perform((generation) async {
      await _liveCall('createConnectLiveAccount', arguments);
      if (!current(generation)) {
        return;
      }
      final result = await _liveCall(
        'createConnectLiveOnboardingLink',
        arguments,
      );
      if (!current(generation)) {
        return;
      }
      final raw = result['url'];
      final uri = raw is String ? Uri.tryParse(raw) : null;
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'connect.stripe.com' ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort) {
        throw StateError('Lien invalide.');
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Ouverture impossible.');
      }
    });
  }

  @override
  Widget build(BuildContext context) => Card(
    color: _green,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Stripe Connect',
            style: TextStyle(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (busy) const LinearProgressIndicator(color: _gold),
          const SizedBox(height: 8),
          Text(
            data?['message']?.toString() ??
                error ??
                'Vérification de la connexion…',
            style: const TextStyle(color: Colors.white),
          ),
          if (error != null && data != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Colors.orangeAccent)),
          ],
          if (data?['hasAccount'] == true) ...[
            const SizedBox(height: 8),
            AppText(
              'Informations transmises : ${data?['detailsSubmitted'] == true ? 'Oui' : 'À compléter'}\n'
              'Paiements autorisés par Stripe : ${data?['chargesEnabled'] == true ? 'Oui' : 'En attente'}\n'
              'Versements autorisés par Stripe : ${data?['payoutsEnabled'] == true ? 'Oui' : 'En attente'}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 12),
          const AppText(
            'Connectez votre établissement, terminez les informations demandées par Stripe, puis actualisez. Activez ensuite le paiement en ligne si votre compte est prêt.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _dark,
                ),
                onPressed:
                    !busy &&
                        data?['eligible'] == true &&
                        data?['onboardingEnabled'] == true
                    ? connect
                    : null,
                icon: const Icon(Icons.account_balance_outlined),
                label: AppText(
                  data?['hasAccount'] == true
                      ? 'Continuer sur Stripe réel'
                      : 'Connecter mon compte Stripe réel',
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: _gold),
                onPressed: busy ? null : refresh,
                child: const AppText('Actualiser'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class StripeLiveAdminScreen extends StatefulWidget {
  const StripeLiveAdminScreen({super.key});
  @override
  State<StripeLiveAdminScreen> createState() => _StripeLiveAdminScreenState();
}

class _StripeLiveAdminScreenState extends _LiveState<StripeLiveAdminScreen> {
  @override
  String get statusEndpoint => 'getConnectLiveAdminStatus';
  @override
  Map<String, dynamic> get arguments => {};

  Future<void> changeEnabled() async {
    final config = data;
    if (busy || config == null) {
      return;
    }
    final enabled = config['enabled'] != true;
    final generation = _generation;
    if (!await _confirm(
      context,
      enabled
          ? 'Ouvrir les connexions réelles ?'
          : 'Fermer les nouvelles connexions ?',
      enabled
          ? 'Les professionnels avec un dossier approuvé pourront ouvrir un '
                'compte Stripe réel. Vérifiez le nom de votre plateforme. Aucun paiement de '
                'commande, abonnement ou commission n’est activé par ce bouton.'
          : 'Les nouvelles connexions et les liens de reprise seront fermés. '
                'Cela ne clôture pas les comptes Stripe déjà créés et n’annule aucun paiement.',
    )) {
      return;
    }
    if (!current(generation)) {
      return;
    }
    await perform((generation) async {
      final result = await _liveCall('setConnectLiveSettings', {
        'enabled': enabled,
        'expectedRevision': config['revision'],
        'acknowledgeLive': true,
      });
      if (current(generation)) {
        setState(() => data = result);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _dark,
    appBar: AppBar(
      backgroundColor: _dark,
      foregroundColor: _gold,
      title: const AppText('Connexions Stripe réelles'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const AppText(
            'Contrôle Super Admin',
            style: TextStyle(
              color: _gold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (busy) const LinearProgressIndicator(color: _gold),
          Text(
            data?['message']?.toString() ?? error ?? 'Chargement…',
            style: const TextStyle(color: Colors.white),
          ),
          if (error != null && data != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Colors.orangeAccent)),
          ],
          if (data?['platformName'] != null) ...[
            const SizedBox(height: 12),
            AppText(
              'Plateforme Stripe : ${data?['platformName']}',
              style: const TextStyle(color: _gold),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            data?['enabled'] == true
                ? 'Connexions réelles ouvertes'
                : 'Connexions réelles fermées',
            style: const TextStyle(color: _gold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _dark,
            ),
            onPressed:
                !busy &&
                    data != null &&
                    (data?['enabled'] == true || data?['ready'] == true)
                ? changeEnabled
                : null,
            child: Text(
              data?['enabled'] == true
                  ? 'Fermer les connexions'
                  : 'Ouvrir les connexions',
            ),
          ),
          TextButton(
            onPressed: busy ? null : refresh,
            child: const AppText('Vérifier à nouveau'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _dark,
            ),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const OrderPaymentAdminScreen(),
              ),
            ),
            child: const AppText('Paiements des commandes et commissions'),
          ),
          const SizedBox(height: 20),
          const AppText(
            'Les commandes, tickets et abonnements ne sont pas débités '
            'par cette étape. Les réglages de frais existants restent conservés. '
            'Le paiement des articles physiques du menu se règle dans '
            '« Paiements des commandes et commissions ». Les tickets et '
            'abonnements restent séparés.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}
