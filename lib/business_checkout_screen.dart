import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'order_receipt_screen.dart';

const _dark = Color(0xFF061E12);
const _green = Color(0xFF004D40);
const _gold = Color(0xFFFFD700);

String _euros(Object? value) => value is int
    ? '${(value / 100).toStringAsFixed(2).replaceAll('.', ',')} €'
    : 'Non renseigné';

Future<Map<String, dynamic>> _call(
  String name,
  Map<String, dynamic> data,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.isAnonymous) {
    throw StateError('Connectez-vous avec une adresse e-mail vérifiée.');
  }
  await user.reload();
  final refreshed = FirebaseAuth.instance.currentUser;
  if (refreshed == null ||
      refreshed.uid != user.uid ||
      refreshed.isAnonymous ||
      !refreshed.emailVerified) {
    throw StateError('Connectez-vous avec une adresse e-mail vérifiée.');
  }
  await refreshed.getIdToken(true);
  if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
    throw StateError('Le compte connecté a changé.');
  }
  final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable(
        name,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      )
      .call<Map<String, dynamic>>(data);
  if (FirebaseAuth.instance.currentUser?.uid != user.uid ||
      response.data['environment'] != 'live') {
    throw StateError('Le résultat du paiement n’a pas été confirmé.');
  }
  return Map<String, dynamic>.from(response.data);
}

String _message(Object error) {
  if (error is FirebaseFunctionsException) {
    return error.message ?? 'Opération non confirmée. Actualisez le paiement.';
  }
  if (error is StateError) return error.message.toString();
  return 'Opération non confirmée. Actualisez le statut avant de réessayer.';
}

Future<void> _openCheckout(Object? value) async {
  final uri = value is String ? Uri.tryParse(value) : null;
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'checkout.stripe.com' ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort) {
    throw StateError('Lien de paiement invalide.');
  }
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw StateError('Impossible d’ouvrir Stripe. Reprenez le paiement ici.');
  }
}

Future<bool> _confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _green,
        title: Text(title, style: const TextStyle(color: _gold)),
        content: Text(body, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _gold),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _dark,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ) ??
    false;

Future<void> requestBusinessOrderRefund(
  BuildContext context,
  String orderId,
) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (!await _confirm(
    context,
    'Annuler et rembourser cette commande ?',
    'Le remboursement intégral sera demandé à Stripe avant acceptation. '
        'Il peut rester en attente. Les frais de traitement Stripe ne sont '
        'pas présentés comme remboursés.',
  )) {
    return;
  }
  if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
  try {
    final result = await _call('refundBusinessOrder', {'orderId': orderId});
    if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }
    final order = result['order'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          order is Map && order['paymentStatus'] == 'refunded'
              ? 'Remboursement confirmé par Stripe.'
              : 'Remboursement demandé. Actualisez pour suivre sa confirmation.',
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_message(error))));
  }
}

abstract class _GuardedState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
  StreamSubscription<User?>? _auth;
  String? uid;
  int generation = 0;
  bool busy = false;
  String? error;

  bool current(int g) =>
      mounted &&
      generation == g &&
      FirebaseAuth.instance.currentUser?.uid == uid;
  void clearData();
  Future<void> refresh();

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    WidgetsBinding.instance.addObserver(this);
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == uid) return;
      setState(() {
        uid = user?.uid;
        generation++;
        busy = false;
        error = null;
        clearData();
      });
      unawaited(refresh());
    });
    unawaited(refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  Future<void> run(Future<void> Function(int g) action) async {
    if (busy) return;
    final g = generation;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action(g);
    } catch (failure) {
      if (current(g)) setState(() => error = _message(failure));
    } finally {
      if (current(g)) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_auth?.cancel());
    super.dispose();
  }

  Widget frame(String title, List<Widget> children) => Scaffold(
    backgroundColor: _dark,
    appBar: AppBar(
      backgroundColor: _dark,
      foregroundColor: _gold,
      title: Text(title),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (busy) const LinearProgressIndicator(color: _gold),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ...children,
        ],
      ),
    ),
  );

  Widget button(String label, VoidCallback? action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _gold,
        foregroundColor: _dark,
        padding: const EdgeInsets.all(16),
      ),
      onPressed: busy ? null : action,
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

class BusinessCheckoutScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final List<Map<String, dynamic>> items;
  const BusinessCheckoutScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.items,
  });
  @override
  State<BusinessCheckoutScreen> createState() => _BusinessCheckoutState();
}

class _BusinessCheckoutState extends _GuardedState<BusinessCheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  Map<String, dynamic>? quote;
  String? pendingId;
  String? attempt;

  @override
  void clearData() {
    quote = null;
    pendingId = null;
    attempt = null;
    _name.clear();
    _phone.clear();
    _address.clear();
    _notes.clear();
  }

  @override
  void didUpdateWidget(BusinessCheckoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessId != widget.businessId ||
        oldWidget.items != widget.items) {
      generation++;
      busy = false;
      clearData();
      unawaited(refresh());
    }
  }

  Future<void> findPending(int g) async {
    final result = await _call('getBusinessOrderPaymentStatus', {
      'businessId': widget.businessId,
      'orderId': null,
    });
    if (!current(g)) return;
    final o = result['order'];
    setState(() {
      pendingId =
          o is Map &&
              (o['status'] == 'pendingPayment' ||
                  o['status'] == 'refundPending' ||
                  o['orderId'] == pendingId)
          ? o['orderId'] as String?
          : null;
    });
  }

  @override
  Future<void> refresh() => run(findPending);

  Future<void> prepare() => run((g) async {
    final result = await _call('quoteBusinessOrder', {
      'businessId': widget.businessId,
      'items': widget.items,
      'buyerName': _name.text.trim(),
      'buyerPhone': _phone.text.trim(),
      'deliveryAddress': _address.text.trim(),
      'notes': _notes.text.trim(),
    });
    if (!current(g)) return;
    final random = Random.secure();
    setState(() {
      quote = result;
      attempt = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
    });
  });

  Future<void> pay() => run((g) async {
    final q = quote;
    if (q == null || attempt == null) return;
    try {
      final result = await _call('startBusinessOrderCheckout', {
        'quoteId': q['quoteId'],
        'attemptId': attempt,
      });
      if (!current(g)) return;
      setState(() => pendingId = result['orderId'] as String);
      await _openCheckout(result['url']);
    } finally {
      // A timeout may have created a session. Recover it before any new attempt.
      if (current(g)) await findPending(g);
    }
  });

  Widget field(
    String label,
    TextEditingController controller, {
    int max = 100,
    TextInputType? keyboard,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      controller: controller,
      enabled: !busy && pendingId == null,
      maxLength: max,
      maxLines: lines,
      keyboardType: keyboard,
      onChanged: (_) => setState(() {
        quote = null;
        attempt = null;
      }),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _gold),
        filled: true,
        fillColor: _green,
        border: const OutlineInputBorder(),
        counterStyle: const TextStyle(color: Colors.white70),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => frame('Votre commande', [
    Text(
      widget.businessName,
      style: const TextStyle(color: _gold, fontSize: 22),
    ),
    const SizedBox(height: 12),
    const Text(
      'Paiement réel des articles physiques du menu. Les prix et frais '
      'définitifs sont vérifiés sur le serveur avant de payer.',
      style: TextStyle(color: Colors.white70),
    ),
    if (pendingId != null) ...[
      const SizedBox(height: 16),
      const Text(
        'Une commande est en attente. Consultez-la avant de recommencer.',
        style: TextStyle(color: Colors.white),
      ),
      button('Ouvrir le suivi du paiement', () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => BusinessOrderPaymentStatusScreen(
              businessId: widget.businessId,
              orderId: pendingId!,
            ),
          ),
        );
        if (mounted) unawaited(refresh());
      }),
    ] else ...[
      field('Votre nom *', _name),
      field(
        'Téléphone de contact *',
        _phone,
        max: 40,
        keyboard: TextInputType.phone,
      ),
      const Text(
        'Ce numéro sert à la commande ; aucun SMS de vérification '
        'supplémentaire n’est demandé ici.',
        style: TextStyle(color: Colors.white60),
      ),
      field('Adresse ou lieu de rendez-vous', _address, max: 500, lines: 2),
      field('Notes', _notes, max: 1000, lines: 3),
      if (quote == null)
        button('Vérifier le total', prepare)
      else ...[
        for (final item in (quote!['items'] as List))
          _line(
            '${item['name']} × ${item['quantity']}',
            item['unitPriceCents'] is int && item['quantity'] is int
                ? item['unitPriceCents'] * item['quantity']
                : null,
          ),
        const Divider(color: Colors.white24),
        _line('Sous-total', quote!['subtotalCents']),
        _line('Frais Euro Habesha côté client', quote!['customerFeeCents']),
        _line('Total à payer', quote!['customerTotalCents']),
        const Text(
          'Stripe ouvrira sa page sécurisée. Le retour dans '
          'l’application ne vaut pas confirmation de paiement.',
          style: TextStyle(color: Colors.white70),
        ),
        button('Payer ${_euros(quote!['customerTotalCents'])} sur Stripe', pay),
      ],
    ],
    button('Actualiser le paiement', refresh),
  ]);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }
}

Widget _line(String label, Object? cents) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Row(
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
      Text(
        _euros(cents),
        style: const TextStyle(color: _gold, fontWeight: FontWeight.bold),
      ),
    ],
  ),
);

class BusinessOrderPaymentStatusScreen extends StatefulWidget {
  final String businessId;
  final String orderId;
  const BusinessOrderPaymentStatusScreen({
    super.key,
    required this.businessId,
    required this.orderId,
  });
  @override
  State<BusinessOrderPaymentStatusScreen> createState() => _OrderStatusState();
}

class _OrderStatusState
    extends _GuardedState<BusinessOrderPaymentStatusScreen> {
  Map<String, dynamic>? order;
  @override
  void clearData() {
    order = null;
  }

  @override
  void didUpdateWidget(BusinessOrderPaymentStatusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.businessId != widget.businessId) {
      generation++;
      busy = false;
      clearData();
      unawaited(refresh());
    }
  }

  @override
  Future<void> refresh() => run((g) async {
    final r = await _call('getBusinessOrderPaymentStatus', {
      'businessId': widget.businessId,
      'orderId': widget.orderId,
    });
    if (current(g)) {
      setState(
        () => order = r['order'] is Map
            ? Map<String, dynamic>.from(r['order'] as Map)
            : null,
      );
    }
  });
  Future<void> resume() => run((g) async {
    final r = await _call('resumeBusinessOrderCheckout', {
      'orderId': widget.orderId,
    });
    if (current(g)) await _openCheckout(r['url']);
  });
  Future<void> cancel() async {
    final g = generation;
    if (!await _confirm(
      context,
      'Fermer ce paiement ?',
      'Le serveur demandera à Stripe de fermer le lien. Un paiement déjà '
          'effectué devra être remboursé séparément.',
    )) {
      return;
    }
    if (!current(g)) return;
    await run((g) async {
      final r = await _call('cancelBusinessOrderCheckout', {
        'orderId': widget.orderId,
      });
      if (current(g)) {
        setState(() => order = Map<String, dynamic>.from(r['order'] as Map));
      }
    });
  }

  @override
  Widget build(BuildContext context) => frame('Suivi du paiement', [
    Text(switch (order?['paymentStatus']) {
      'paid' => 'Paiement confirmé par Stripe',
      'refunded' => 'Remboursement confirmé par Stripe',
      'partially_refunded' => 'Remboursement partiel confirmé',
      'disputed' => 'Paiement contesté : contrôle nécessaire dans Stripe',
      'expired' => 'Lien de paiement fermé ou expiré',
      _ =>
        order?['status'] == 'refundPending'
            ? 'Remboursement en attente'
            : 'Paiement non confirmé',
    }, style: const TextStyle(color: _gold, fontSize: 22)),
    const SizedBox(height: 16),
    if (order != null) ...[
      _line('Total enregistré', order!['customerTotalCents']),
      _line('Montant remboursé', order!['refundedAmountCents']),
      if (order!['canCancel'] == true) ...[
        button('Reprendre ce paiement sur Stripe', resume),
        button('Fermer le lien sans payer', cancel),
      ],
      if (order!['canRefund'] == true)
        button('Annuler et demander le remboursement', () async {
          await requestBusinessOrderRefund(context, widget.orderId);
          if (mounted) unawaited(refresh());
        }),
      button(
        'Voir le reçu et le statut enregistré',
        () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => OrderReceiptScreen(orderId: widget.orderId),
          ),
        ),
      ),
    ],
    button('Actualiser le paiement', refresh),
    const Text(
      'Le professionnel reçoit la commande après confirmation du '
      'paiement. Un paiement confirmé ne signifie pas que le virement bancaire '
      'a déjà été effectué.',
      style: TextStyle(color: Colors.white70),
    ),
  ]);
}

class OrderPaymentAdminScreen extends StatefulWidget {
  const OrderPaymentAdminScreen({super.key});
  @override
  State<OrderPaymentAdminScreen> createState() => _OrderPaymentAdminState();
}

class _OrderPaymentAdminState extends _GuardedState<OrderPaymentAdminScreen> {
  Map<String, dynamic>? config;
  bool enabled = false;
  bool fees = false;
  bool acknowledged = false;
  @override
  void clearData() {
    config = null;
    enabled = false;
    fees = false;
    acknowledged = false;
  }

  @override
  Future<void> refresh() => run((g) async {
    final r = await _call('getOrderPaymentAdminStatus', {});
    if (current(g)) {
      setState(() {
        config = r;
        enabled = r['enabled'] == true;
        fees = r['applyPlatformFees'] == true;
        acknowledged = false;
      });
    }
  });
  Future<void> save() async {
    final currentConfig = config;
    final g = generation;
    if (currentConfig == null || !acknowledged) return;
    final newEnabled = enabled;
    final newFees = fees;
    if (!await _confirm(
      context,
      'Enregistrer les réglages des commandes ?',
      '${newEnabled ? 'Les clients pourront payer de vraies commandes.' : 'Les nouvelles ouvertures de paiement seront fermées.'} '
          '${newFees ? 'Les frais clients et commissions du réglage Business seront appliqués aux nouveaux récapitulatifs.' : 'Les frais et commissions Euro Habesha seront à zéro.'} '
          'Les liens déjà émis et les paiements existants restent à suivre.',
    )) {
      return;
    }
    if (!current(g)) return;
    await run((g) async {
      await _call('setOrderPaymentSettings', {
        'enabled': newEnabled,
        'applyPlatformFees': newFees,
        'expectedRevision': currentConfig['revision'],
        'acknowledgeWebhook': true,
      });
    });
    if (current(g) && error == null) await refresh();
  }

  @override
  Widget build(BuildContext context) => frame('Paiements des commandes', [
    const Text(
      'Contrôle Super Admin',
      style: TextStyle(color: _gold, fontSize: 22),
    ),
    const SizedBox(height: 12),
    const Text(
      'Articles physiques du menu uniquement. Les tickets, devis, '
      'ebooks et abonnements utilisent des parcours séparés.',
      style: TextStyle(color: Colors.white70),
    ),
    if (config != null) ...[
      SwitchListTile(
        activeThumbColor: _gold,
        title: const Text(
          'Ouvrir les paiements réels',
          style: TextStyle(color: Colors.white),
        ),
        value: enabled,
        onChanged: busy || (config!['ready'] != true && !enabled)
            ? null
            : (v) => setState(() => enabled = v),
      ),
      SwitchListTile(
        activeThumbColor: _gold,
        title: const Text(
          'Appliquer les frais Euro Habesha',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          fees
              ? 'Réglages Business : Utilisateurs + Professionnels.'
              : 'Lancement : 0 € de frais et 0 € de commission Euro Habesha.',
          style: const TextStyle(color: Colors.white70),
        ),
        value: fees,
        onChanged: busy ? null : (v) => setState(() => fees = v),
      ),
      const Text(
        'Les frais de traitement Stripe restent distincts et sont '
        'prélevés sur le compte du professionnel. Les réductions Silver, Gold '
        'et VIP restent des offres prévues tant que les abonnements ne sont '
        'pas effectivement activés.',
        style: TextStyle(color: Colors.white70),
      ),
      CheckboxListTile(
        activeColor: _gold,
        checkColor: _dark,
        title: const Text(
          'J’ai configuré et vérifié la réception du webhook '
          'Stripe pour les comptes connectés.',
          style: TextStyle(color: Colors.white),
        ),
        value: acknowledged,
        onChanged: busy
            ? null
            : (v) => setState(() => acknowledged = v == true),
      ),
      if (config!['ready'] != true)
        const Text(
          'Connect et le secret de signature du webhook doivent être '
          'configurés avant ouverture.',
          style: TextStyle(color: Colors.orangeAccent),
        ),
      button('Enregistrer les réglages', acknowledged ? save : null),
    ],
    button('Actualiser les réglages', refresh),
  ]);
}
