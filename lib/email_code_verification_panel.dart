import 'l10n/app_ui.dart';

import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Verifies the current Firebase Auth e-mail once; never an arbitrary recipient.
class EmailCodeVerificationPanel extends StatefulWidget {
  const EmailCodeVerificationPanel({super.key, required this.onVerified});
  final Future<void> Function() onVerified;
  @override
  State<EmailCodeVerificationPanel> createState() =>
      _EmailCodeVerificationPanelState();
}

class _EmailCodeVerificationPanelState
    extends State<EmailCodeVerificationPanel> {
  static const _gold = Color(0xFFFFD700),
      _green = Color(0xFF004D40),
      _dark = Color(0xFF061E12);
  final _code = TextEditingController();
  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  Timer? _timer;
  String? _intent;
  bool _busy = false;
  int _lastRemaining = 0;
  bool _lastExpired = false;
  String _message = 'Demandez votre code pour confirmer votre adresse e-mail.';
  DateTime? _resendAt;
  DateTime? _expiresAt;
  int get _remaining => _resendAt == null
      ? 0
      : max(
          0,
          (_resendAt!.difference(DateTime.now()).inMilliseconds / 1000).ceil(),
        );
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      final remaining = _remaining;
      final expired =
          _expiresAt != null && !_expiresAt!.isAfter(DateTime.now());
      if (remaining != _lastRemaining || expired != _lastExpired) {
        setState(() {
          _lastRemaining = remaining;
          _lastExpired = expired;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  String _newIntent() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  void _handleError(Object error) {
    if (!mounted) {
      return;
    }
    var message = 'La vérification est indisponible. Réessayez plus tard.';
    if (error is FirebaseFunctionsException) {
      message = error.message ?? message;
      final details = error.details;
      final delay = details is Map ? details['retryAfterSeconds'] : null;
      if (delay is num && delay > 0) {
        _resendAt = DateTime.now().add(Duration(seconds: delay.ceil()));
      }
    } else if (error is FirebaseAuthException) {
      message = error.message ?? 'Session expirée. Reconnectez-vous.';
    }
    setState(() => _message = message);
  }

  Future<void> _finish() async {
    final before = FirebaseAuth.instance.currentUser;
    if (before == null || before.isAnonymous) {
      throw StateError('Session absente.');
    }
    final expectedEmail = before.email;
    await before.reload();
    final current = FirebaseAuth.instance.currentUser;
    if (current == null ||
        current.uid != before.uid ||
        current.email != expectedEmail ||
        !current.emailVerified) {
      throw StateError('Vérification non confirmée par Firebase.');
    }
    await current.getIdToken(true);
    if (mounted) {
      await widget.onVerified();
    }
  }

  Future<void> _send() async {
    if (_busy || _remaining > 0) {
      return;
    }
    setState(() => _busy = true);
    final before = FirebaseAuth.instance.currentUser;
    try {
      if (before == null || before.isAnonymous) {
        throw StateError('Session absente.');
      }
      await before.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != before.uid) {
        throw StateError('Session modifiée.');
      }
      if (user.emailVerified) {
        await _finish();
        return;
      }
      await user.getIdToken(true);
      _intent ??= _newIntent();
      final result = await _functions
          .httpsCallable(
            'requestEmailVerificationCode',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
          )
          .call(<String, dynamic>{'requestId': _intent});
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != before.uid) {
        return;
      }
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['verified'] == true) {
        await _finish();
        return;
      }
      final wait = (data['retryAfterSeconds'] as num?)?.ceil() ?? 60;
      setState(() {
        _resendAt = DateTime.now().add(Duration(seconds: wait));
        _expiresAt = DateTime.fromMillisecondsSinceEpoch(
          (data['expiresAtMs'] as num).toInt(),
        );
        _message =
            'Code demandé pour ${user.email}. Vérifiez votre boîte et les spams. '
            'La réception peut prendre un moment.';
        _intent = null;
        _code.clear();
      });
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _verify() async {
    if (_busy) {
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _message = 'Saisissez les six chiffres reçus par e-mail.');
      return;
    }
    setState(() => _busy = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      final result = await _functions
          .httpsCallable(
            'verifyEmailVerificationCode',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
          )
          .call(<String, dynamic>{'code': _code.text.trim()});
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['verified'] == true) {
        await _finish();
      }
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 30),
      const Icon(Icons.mark_email_read_outlined, color: _gold, size: 72),
      const SizedBox(height: 22),
      const AppText(
        'Vérifier mon e-mail',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _gold,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        FirebaseAuth.instance.currentUser?.email ?? '',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      const SizedBox(height: 16),
      Text(_message, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 18),
      TextField(
        controller: _code,
        enabled: !_busy,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          letterSpacing: 8,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: const InputDecoration(
          labelText: 'Code reçu par e-mail',
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: _green,
        ),
        onSubmitted: (_) => _verify(),
      ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: _busy ? null : _verify,
        style: FilledButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _dark,
          minimumSize: const Size.fromHeight(52),
        ),
        child: const AppText('Vérifier et continuer'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _busy || _remaining > 0 ? null : _send,
        style: OutlinedButton.styleFrom(
          foregroundColor: _gold,
          minimumSize: const Size.fromHeight(48),
        ),
        child: Text(
          _remaining > 0
              ? 'Renvoyer dans $_remaining s'
              : 'Recevoir un code par e-mail',
        ),
      ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.all(14),
          child: Center(child: CircularProgressIndicator(color: _gold)),
        ),
      if (_expiresAt != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            DateTime.now().isAfter(_expiresAt!)
                ? 'Le code a expiré. Demandez-en un nouveau.'
                : 'Code valable 10 minutes. Un nouveau code remplace le précédent.',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      const SizedBox(height: 14),
      const AppText(
        'Cette confirmation est liée à votre compte. Elle ne sera pas redemandée '
        'lors de la création de votre activité si votre adresse reste vérifiée.',
        style: TextStyle(color: Colors.white70),
      ),
    ],
  );
}
