import 'l10n/app_ui.dart';
import 'email_code_verification_panel.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_session.dart';

import 'notification_service.dart';

import 'country_phone_codes.dart';

enum _AuthView { welcome, login, register, verifyEmail, verifyPhone }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.resumeSession = false});

  // Only the launch page resumes an account, never an explicit login action.
  final bool resumeSession;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _googleWebClientId =
      '218564066910-ufqipbmm208mrm6sirk54d0ft8d9rabi.apps.googleusercontent.com';

  static const Color primaryDarkGreen = Color(0xFF061E12);

  static const Color primaryGold = Color(0xFFFFD700);

  static const Color cardGreen = Color(0xFF004D40);

  static const Color fieldGreen = Color(0xFF0C3022);

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _smsCodeController = TextEditingController();

  _AuthView _view = _AuthView.welcome;

  bool _isLoading = false;

  bool _isObscure = true;

  bool _smsCodeSent = false;

  bool _phoneVerified = false;

  String? _phoneVerificationId;

  String _selectedPhoneCountry = 'France';

  String get _selectedPhonePrefix =>
      countryPhoneCodes[_selectedPhoneCountry] ?? '+33';

  @override
  void initState() {
    super.initState();
    if (widget.resumeSession) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _resumeSession());
    }
  }

  bool get _canResume => mounted && ModalRoute.of(context)?.isCurrent == true;

  Future<void> _resumeSession() async {
    try {
      // A public event QR can be above this route: do not replace that event.
      if (!_canResume) return;
      AppSession.signOut();
      final auth = FirebaseAuth.instance;
      final savedUser = await auth.authStateChanges().first.timeout(
        const Duration(seconds: 8),
      );
      if (!_canResume || savedUser == null) return;
      await savedUser.reload().timeout(const Duration(seconds: 8));
      if (!_canResume) return;
      final user = auth.currentUser;
      if (user == null || user.uid != savedUser.uid) return;
      _emailController.text = user.email ?? '';
      if (!user.emailVerified) {
        _setView(_AuthView.verifyEmail);
        return;
      }
      if ((user.email ?? '').trim().toLowerCase() ==
          AppSession.superAdminEmail) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin-passcode');
        return;
      }
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 8));
      if (!_canResume || auth.currentUser?.uid != user.uid) return;
      if (profile.data()?['accountType'] == 'professional' &&
          (user.phoneNumber == null || user.phoneNumber!.isEmpty)) {
        setState(() {
          _phoneVerified = false;
          _view = _AuthView.verifyPhone;
        });
        return;
      }
      await _routeAfterVerifiedAuth(user);
    } catch (error) {
      // Keep all verification gates if the saved account cannot be checked.
      if (_canResume) {
        _setView(_AuthView.login);
        _showMessage(
          'Reprise de session impossible. Vérifiez votre connexion '
          'puis reconnectez-vous, ou choisissez le mode invité.',
        );
      }
      debugPrint('Reprise de session : $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    _emailController.dispose();

    _passwordController.dispose();

    _phoneController.dispose();

    _smsCodeController.dispose();

    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _setView(_AuthView view) {
    if (!mounted) return;

    setState(() => _view = view);
  }

  void _enterApp() {
    Navigator.pushReplacementNamed(context, '/app');
  }

  Future<void> _routeAfterVerifiedAuth(
    User user, {

    String? fallbackName,

    String? fallbackEmail,
  }) async {
    final email = (user.email ?? fallbackEmail ?? '').trim().toLowerCase();

    // Les notifications ne doivent jamais bloquer une connexion valide.
    try {
      await NotificationService.instance.registerCurrentToken().timeout(
        const Duration(seconds: 5),
      );
    } catch (error) {
      debugPrint('Notification token non enregistré : $error');
    }

    if (!_canResume || FirebaseAuth.instance.currentUser?.uid != user.uid)
      return;

    if (email == 'getafricshow1@gmail.com' && user.emailVerified) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin-passcode');

      return;
    }

    AppSession.signIn(
      name:
          user.displayName ??
          fallbackName ??
          user.email ??
          'Euro Habesha Member',

      emailAddress: user.email ?? fallbackEmail ?? '',

      verified: true,
    );

    _enterApp();
  }

  bool _validateEmailPassword({bool requireName = false}) {
    if (requireName && _nameController.text.trim().length < 2) {
      _showMessage('Veuillez entrer votre nom complet.');

      return false;
    }

    final email = _emailController.text.trim();

    final password = _passwordController.text;

    if (!email.contains('@') || password.length < 6) {
      _showMessage(
        'Entrez une adresse e-mail valide et un mot de passe de 6 caractères minimum.',
      );

      return false;
    }

    return true;
  }

  Future<void> _signInWithEmail() async {
    if (!_validateEmailPassword()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),

        password: _passwordController.text,
      );

      await credential.user?.reload();

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showMessage('Connexion impossible. Veuillez réessayer.');

        return;
      }

      final email = (user.email ?? '').trim().toLowerCase();

      if (email == 'getafricshow1@gmail.com' && user.emailVerified) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/admin-passcode');

        return;
      }

      if (!user.emailVerified) {
        _setView(_AuthView.verifyEmail);
        _showMessage('Confirmez votre adresse avec le code reçu par e-mail.');

        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data() ?? <String, dynamic>{};

      final accountType = (data['accountType'] ?? 'user').toString();

      final isProfessionalAccount = accountType == 'professional';

      final phoneVerified =
          user.phoneNumber != null && user.phoneNumber!.isNotEmpty;

      if (isProfessionalAccount && !phoneVerified) {
        if (!mounted) return;

        setState(() {
          _phoneVerified = false;

          _view = _AuthView.verifyPhone;
        });

        return;
      }

      await _routeAfterVerifiedAuth(
        user,

        fallbackEmail: _emailController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Échec de la connexion.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithEmail() async {
    if (!_validateEmailPassword(requireName: true)) return;
    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      final user = credential.user;
      if (user == null) {
        _showMessage('Impossible de créer le compte.');
        return;
      }

      // The code is explicitly requested on the verification screen.
      // Profile storage and e-mail delivery remain independent.
      // Enregistrer le profil séparément pour conserver le type de compte.
      String? profileError;
      try {
        await user.updateDisplayName(_nameController.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'emailVerified': false,
          'accountType': 'user',
          'phoneVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on FirebaseException catch (e) {
        profileError = '${e.code} : ${e.message ?? "Enregistrement refusé"}';
      } catch (e) {
        profileError = e.toString();
      }

      if (!mounted) return;
      setState(() => _view = _AuthView.verifyEmail);
      _showMessage(
        'Compte créé. Appuyez sur Recevoir un code par e-mail pour continuer.',
      );
      if (profileError != null) {
        _showMessage('Profil non enregistré : $profileError');
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(
        'Création impossible (${e.code}) : ${e.message ?? "Erreur Firebase"}',
      );
    } catch (e) {
      _showMessage('Erreur lors de la création du compte : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkEmailVerification() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Veuillez vous reconnecter.');
        _setView(_AuthView.login);
        return;
      }
      if (!user.emailVerified) {
        _showMessage(
          'Confirmez votre e-mail avec le code reçu avant de continuer.',
        );
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final isProfessionalAccount =
          doc.data()?['accountType'] == 'professional';
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'emailVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (isProfessionalAccount &&
          (user.phoneNumber == null || user.phoneNumber!.isEmpty)) {
        if (!mounted) return;
        setState(() {
          _view = _AuthView.verifyPhone;
        });
      } else {
        await _routeAfterVerifiedAuth(
          user,
          fallbackName: _nameController.text.trim(),
          fallbackEmail: _emailController.text.trim(),
        );
      }
    } on FirebaseException catch (e) {
      _showMessage(
        'Vérification impossible (${e.code}) : ${e.message ?? "Erreur Firebase"}',
      );
    } catch (e) {
      _showMessage('Erreur de vérification : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (!email.contains('@')) {
      _showMessage('Entrez d’abord votre adresse e-mail.');

      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _showMessage('Lien de réinitialisation envoyé par e-mail.');
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Impossible d’envoyer le lien.');
    }
  }

  String _buildInternationalPhone() {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (raw.startsWith('+')) return raw;
    final digits = raw.replaceFirst(RegExp(r'^00'), '');
    if (raw.startsWith('00')) return '+$digits';
    final prefixDigits = _selectedPhonePrefix.replaceFirst('+', '');
    if (digits.startsWith(prefixDigits) &&
        digits.length > prefixDigits.length + 6) {
      return '+$digits';
    }
    return '$_selectedPhonePrefix${digits.replaceFirst(RegExp(r'^0+'), '')}';
  }

  Future<void> _sendPhoneVerificationCode() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Veuillez vous reconnecter.');

      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Entrez votre numéro de téléphone.');

      return;
    }

    final phoneNumber = _buildInternationalPhone();
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phoneNumber)) {
      _showMessage('Numero invalide. Exemple : +33612345678.');
      return;
    }
    await user.reload();
    if (FirebaseAuth.instance.currentUser?.phoneNumber == phoneNumber) {
      await _finishProfessionalAccount();
      return;
    }

    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,

      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await user.linkWithCredential(credential);

          await _saveVerifiedPhone(user.uid, phoneNumber);

          if (!mounted) return;

          setState(() {
            _phoneVerified = true;

            _smsCodeSent = false;

            _isLoading = false;
          });

          await _finishProfessionalAccount();
        } on FirebaseAuthException catch (e) {
          if (!mounted) return;

          setState(() => _isLoading = false);

          _showMessage(e.message ?? 'Échec de la vérification du téléphone.');
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        _showMessage(e.message ?? 'Impossible d’envoyer le SMS.');
      },

      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;

        setState(() {
          _phoneVerificationId = verificationId;

          _smsCodeSent = true;

          _isLoading = false;
        });

        _showMessage('Code SMS envoyé.');
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _phoneVerificationId = verificationId;

        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  Future<void> _saveVerifiedPhone(String uid, String phoneNumber) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'phone': phoneNumber,

      'phoneCountry': _selectedPhoneCountry,

      'phoneDialCode': _selectedPhonePrefix,

      'phoneVerified': true,

      'phoneVerifiedAt': FieldValue.serverTimestamp(),

      'professionalVerificationStatus': 'contact_verified',
    }, SetOptions(merge: true));
  }

  Future<void> _verifySmsCode() async {
    final user = FirebaseAuth.instance.currentUser;

    final verificationId = _phoneVerificationId;

    final smsCode = _smsCodeController.text.trim();

    if (user == null || verificationId == null) {
      _showMessage('Envoyez d’abord le code SMS.');

      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(smsCode)) {
      _showMessage('Entrez le code SMS à 6 chiffres.');

      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,

        smsCode: smsCode,
      );

      await user.linkWithCredential(credential);
      await user.reload();
      final phoneNumber = _buildInternationalPhone();
      if (FirebaseAuth.instance.currentUser?.phoneNumber != phoneNumber) {
        throw FirebaseAuthException(
          code: 'phone-not-linked',
          message: 'Le numero verifie ne correspond pas au compte.',
        );
      }

      await _saveVerifiedPhone(user.uid, phoneNumber);

      if (!mounted) return;

      setState(() {
        _phoneVerified = true;

        _smsCodeSent = false;
      });

      await _finishProfessionalAccount();
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Code SMS incorrect.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finishProfessionalAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await user.reload();

    final refreshed = FirebaseAuth.instance.currentUser;

    if (refreshed == null) return;

    await _routeAfterVerifiedAuth(
      refreshed,

      fallbackName: _nameController.text.trim(),

      fallbackEmail: _emailController.text.trim(),
    );
  }

  Future<void> _continueAsGuest() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      // Do not let /app restore the account the user chose to leave.
      await FirebaseAuth.instance.signOut();
      AppSession.continueAsGuest();
      if (!mounted) return;
      _enterApp();
    } catch (error) {
      _showMessage('Impossible de passer en mode invité. Veuillez réessayer.');
      debugPrint('Déconnexion avant mode invité : $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      UserCredential result;
      String? fallbackName;
      String? fallbackEmail;
      if (kIsWeb) {
        // Sur Chrome, Firebase gère directement la fenêtre OAuth.
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        result = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn(serverClientId: _googleWebClientId);
        // Effacer le compte Google mémorisé localement pour permettre
        // de sélectionner une autre adresse à la prochaine connexion.
        await googleSignIn.signOut();
        final account = await googleSignIn.signIn();
        if (account == null) return;
        final googleAuth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        result = await FirebaseAuth.instance.signInWithCredential(credential);
        fallbackName = account.displayName;
        fallbackEmail = account.email;
      }
      final user = result.user;
      if (!mounted || user == null) return;
      // Un refus de lecture/écriture Firestore ne doit pas annuler Firebase Auth.
      try {
        await _saveSocialProfileWithoutChangingAccountType(
          user,
          fallbackName: fallbackName,
          fallbackEmail: fallbackEmail,
        );
      } catch (error) {
        debugPrint('Profil Google non synchronisé : $error');
      }
      await _routeAfterSocialAuth(
        user,
        fallbackName: fallbackName,
        fallbackEmail: fallbackEmail,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(
        'Connexion Google impossible (${e.code}) : ${e.message ?? "Erreur Firebase"}',
      );
    } catch (e) {
      _showMessage('Connexion Google impossible : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSocialProfileWithoutChangingAccountType(
    User user, {
    String? fallbackName,
    String? fallbackEmail,
  }) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final existing = await ref.get();
    final fields = <String, dynamic>{
      'name': user.displayName ?? fallbackName ?? 'Euro Habesha Member',
      'email': user.email ?? fallbackEmail ?? '',
      'emailVerified': user.emailVerified,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) fields['accountType'] = 'user';
    await ref.set(fields, SetOptions(merge: true));
  }

  // Google et Apple ne doivent pas contourner la verification du compte pro.
  Future<void> _routeAfterSocialAuth(
    User user, {
    String? fallbackName,
    String? fallbackEmail,
  }) async {
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed == null) return;
    if (!refreshed.emailVerified) {
      _setView(_AuthView.verifyEmail);
      _showMessage('Verifiez votre adresse e-mail pour continuer.');
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(refreshed.uid)
        .get();
    final data = doc.data() ?? <String, dynamic>{};
    if (data['accountType'] == 'professional' &&
        (refreshed.phoneNumber == null || refreshed.phoneNumber!.isEmpty)) {
      if (!mounted) return;
      setState(() {
        _phoneVerified = false;
        _view = _AuthView.verifyPhone;
      });
      return;
    }
    await _routeAfterVerifiedAuth(
      refreshed,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
    );
  }

  Future<void> _continueWithApple() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final provider = AppleAuthProvider();
      final result = kIsWeb
          ? await FirebaseAuth.instance.signInWithPopup(provider)
          : await FirebaseAuth.instance.signInWithProvider(provider);
      final user = result.user;
      if (!mounted || user == null) return;
      try {
        await _saveSocialProfileWithoutChangingAccountType(user);
      } catch (error) {
        debugPrint('Profil Apple non synchronisé : $error');
      }
      await _routeAfterSocialAuth(user);
    } on FirebaseAuthException catch (e) {
      _showMessage(
        'Connexion Apple impossible (${e.code}) : ${e.message ?? "Vérifiez la configuration Apple dans Firebase"}',
      );
    } catch (e) {
      _showMessage('Connexion Apple impossible : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,

      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _DarkGreenBackground()),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),

              child: _buildCurrentView(),
            ),

            if (_isLoading)
              Container(
                color: Colors.black38,

                alignment: Alignment.center,

                child: const CircularProgressIndicator(color: primaryGold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_view) {
      case _AuthView.welcome:
        return _buildWelcome();

      case _AuthView.login:
        return _buildLogin();

      case _AuthView.register:
        return _buildRegistration();

      case _AuthView.verifyEmail:
        return _buildEmailVerification();

      case _AuthView.verifyPhone:
        return _buildPhoneVerification();
    }
  }

  Widget _page({
    required Key key,

    required Widget child,

    bool showBack = true,
  }) {
    return SingleChildScrollView(
      key: key,

      padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,

              child: IconButton(
                onPressed: () {
                  if (_view == _AuthView.login) {
                    _setView(_AuthView.welcome);
                  } else if (_view == _AuthView.register) {
                    _setView(_AuthView.welcome);
                  } else {
                    _setView(_AuthView.login);
                  }
                },

                icon: const Icon(
                  Icons.arrow_back,
                  color: primaryGold,
                  size: 30,
                ),
              ),
            ),

          child,
        ],
      ),
    );
  }

  // L'image est gérée dans Firestore : app_settings / welcome.

  // Le logo officiel local reste prioritaire et ne change pas avec la bannière.

  Widget _welcomeBrand({String? logoUrl}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 82,
          height: 82,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryGold, width: 1.5),
            color: cardGreen.withValues(alpha: 0.86),
          ),
          child: ClipOval(
            child: (logoUrl != null && logoUrl.isNotEmpty)
                ? Image.network(
                    logoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _localWelcomeLogo(),
                  )
                : _localWelcomeLogo(),
          ),
        ),
        const SizedBox(height: 7),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Euro ',
                style: TextStyle(color: primaryGold),
              ),
              TextSpan(
                text: 'Habesha',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _localWelcomeLogo() {
    return Image.asset(
      'assets/images/euro_habesha_logo.png',

      fit: BoxFit.contain,

      errorBuilder: (_, __, ___) =>
          const Icon(Icons.public, color: primaryGold, size: 55),
    );
  }

  // Accueil compact : la photographie reste visible au-dessus du logo.
  // Les connexions Google, Apple et invité conservent leurs callbacks.
  Widget _welcomeAction(
    String label,
    IconData icon,
    VoidCallback onTap, {
    Color background = Colors.transparent,
    Color foreground = Colors.white,
    Color borderColor = primaryGold,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onTap,
        icon: Icon(icon, color: foreground, size: 21),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(color: borderColor, width: 1.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('app_settings')
          .doc('welcome')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Photo de bienvenue non chargée : ${snapshot.error}');
        }
        final settings = snapshot.data?.data() ?? <String, dynamic>{};
        final enabled = settings['enabled'] != false;
        final imageUrl = enabled
            ? (settings['imageUrl'] ?? '').toString().trim()
            : '';
        final logoUrl = (settings['logoUrl'] ?? '').toString().trim();

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height;
            // Sur les écrans plus hauts, garder une large zone photo.
            final photoSpace = (availableHeight * 0.35).clamp(125.0, 350.0);
            return Stack(
              key: const ValueKey('welcome'),
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                // Dégradé : haut clair pour voir la photo, bas foncé
                // pour que les boutons restent lisibles.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x14061E12),
                        Color(0x33061E12),
                        Color(0xCC061E12),
                        Color(0xFF061E12),
                      ],
                      stops: [0.0, 0.37, 0.73, 1.0],
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: photoSpace),
                      _welcomeBrand(logoUrl: logoUrl),
                      const SizedBox(height: 22),
                      _welcomeAction(
                        'Se connecter',
                        Icons.login,
                        () => _setView(_AuthView.login),
                        background: cardGreen.withValues(alpha: 0.75),
                      ),
                      const SizedBox(height: 9),
                      _welcomeAction(
                        'S’inscrire',
                        Icons.person_add_alt_1,
                        () => _setView(_AuthView.register),
                        background: primaryGold,
                        foreground: primaryDarkGreen,
                      ),
                      const SizedBox(height: 9),
                      _welcomeAction(
                        'Continuer avec Google',
                        Icons.g_mobiledata,
                        _continueWithGoogle,
                        background: Colors.white,
                        foreground: Colors.black,
                        borderColor: Colors.white,
                      ),
                      const SizedBox(height: 9),
                      _welcomeAction(
                        'Continuer avec Apple',
                        Icons.apple,
                        _continueWithApple,
                        background: Colors.black,
                        borderColor: Colors.white54,
                      ),
                      const SizedBox(height: 9),
                      _welcomeAction(
                        'Continuer en tant qu’invité',
                        Icons.person_outline,
                        _continueAsGuest,
                        background: primaryDarkGreen.withValues(alpha: 0.40),
                        borderColor: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLogin() {
    return _page(
      key: const ValueKey('login'),

      child: Column(
        children: [
          const SizedBox(height: 18),

          _title('Se connecter'),

          const SizedBox(height: 8),

          _subtitle('Accédez à votre compte Euro Habesha'),

          const SizedBox(height: 30),

          _textField(
            label: 'Adresse e-mail',

            icon: Icons.email_outlined,

            controller: _emailController,

            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          _textField(
            label: 'Mot de passe',

            icon: Icons.lock_outline,

            controller: _passwordController,

            isPassword: true,
          ),

          Align(
            alignment: Alignment.centerRight,

            child: TextButton(
              onPressed: _forgotPassword,

              child: const AppText(
                'Mot de passe oublié ?',

                style: TextStyle(color: primaryGold),
              ),
            ),
          ),

          const SizedBox(height: 10),

          _goldButton('Se connecter', Icons.login, _signInWithEmail),

          const SizedBox(height: 24),

          const AppText(
            'ou',

            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          _providerButton(
            'Continuer avec Google',

            Icons.g_mobiledata,

            _continueWithGoogle,
          ),

          const SizedBox(height: 12),

          _providerButton(
            'Continuer avec Apple',

            Icons.apple,

            _continueWithApple,
          ),

          const SizedBox(height: 18),

          TextButton(
            onPressed: () => _setView(_AuthView.register),

            child: const AppText(
              'Pas encore de compte ? Créer un compte',

              style: TextStyle(color: primaryGold, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistration() {
    return _page(
      key: const ValueKey('register'),

      child: Column(
        children: [
          const SizedBox(height: 12),

          _title('Créer un compte'),

          const SizedBox(height: 6),

          const AppText(
            'Compte membre',

            style: TextStyle(
              color: primaryGold,

              fontSize: 20,

              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 26),

          _textField(
            label: 'Nom complet',

            icon: Icons.person_outline,

            controller: _nameController,
          ),

          const SizedBox(height: 14),

          _textField(
            label: 'Adresse e-mail',

            icon: Icons.email_outlined,

            controller: _emailController,

            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 14),

          _textField(
            label: 'Mot de passe',

            icon: Icons.lock_outline,

            controller: _passwordController,

            isPassword: true,
          ),

          const SizedBox(height: 26),

          _goldButton(
            'Créer mon compte',

            Icons.person_add_alt_1,

            _registerWithEmail,
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => _setView(_AuthView.login),

            child: const AppText(
              'Déjà un compte ? Se connecter',

              style: TextStyle(color: primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerification() => _page(
    key: const ValueKey('verifyEmail'),
    child: EmailCodeVerificationPanel(onVerified: _checkEmailVerification),
  );

  Widget _buildPhoneVerification() {
    return _page(
      key: const ValueKey('verifyPhone'),

      child: Column(
        children: [
          const SizedBox(height: 16),

          const Icon(Icons.phone_iphone, color: primaryGold, size: 72),

          const SizedBox(height: 18),

          _title('Vérification du téléphone'),

          const SizedBox(height: 10),

          _subtitle('Obligatoire pour un compte professionnel'),

          const SizedBox(height: 26),

          DropdownButtonFormField<String>(
            initialValue: _selectedPhoneCountry,

            dropdownColor: cardGreen,

            style: const TextStyle(color: Colors.white),

            decoration: _inputDecoration('Pays du téléphone', Icons.public),

            items: countryPhoneCodes.keys.map((country) {
              return DropdownMenuItem<String>(
                value: country,

                child: AppText('$country  ${countryPhoneCodes[country]}'),
              );
            }).toList(),

            onChanged: (country) {
              if (country == null) return;

              setState(() => _selectedPhoneCountry = country);
            },
          ),

          const SizedBox(height: 14),

          _textField(
            label: 'Numéro de téléphone',

            icon: Icons.phone_outlined,

            controller: _phoneController,

            keyboardType: TextInputType.phone,

            prefixText: '$_selectedPhonePrefix ',
          ),

          const SizedBox(height: 18),

          if (!_smsCodeSent)
            _goldButton(
              'Envoyer le code SMS',

              Icons.sms_outlined,

              _sendPhoneVerificationCode,
            ),

          if (_smsCodeSent && !_phoneVerified) ...[
            _textField(
              label: 'Code SMS à 6 chiffres',

              icon: Icons.password_outlined,

              controller: _smsCodeController,

              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            _goldButton('Vérifier', Icons.verified_outlined, _verifySmsCode),

            const SizedBox(height: 10),

            TextButton(
              onPressed: _sendPhoneVerificationCode,

              child: const AppText(
                'Renvoyer le code',

                style: TextStyle(color: primaryGold),
              ),
            ),
          ],

          if (_phoneVerified)
            _infoBox(
              Icons.verified,

              'Téléphone vérifié',

              'Votre compte professionnel peut maintenant continuer vers la vérification de l’établissement.',
            ),
        ],
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,

      textAlign: TextAlign.center,

      style: const TextStyle(
        color: Colors.white,

        fontSize: 28,

        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _subtitle(String text) {
    return Text(
      text,

      textAlign: TextAlign.center,

      style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
    );
  }

  Widget _goldButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,

      height: 54,

      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,

        icon: Icon(icon),

        label: Text(
          text,

          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,

          foregroundColor: Colors.black,

          disabledBackgroundColor: primaryGold.withValues(alpha: 0.45),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _providerButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,

      height: 52,

      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,

        icon: Icon(icon, color: Colors.black, size: 28),

        label: Text(
          text,

          style: const TextStyle(
            color: Colors.black,

            fontWeight: FontWeight.w700,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,

          foregroundColor: Colors.black,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),

            side: const BorderSide(color: primaryGold, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,

    required IconData icon,

    required TextEditingController controller,

    bool isPassword = false,

    TextInputType? keyboardType,

    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,

      obscureText: isPassword ? _isObscure : false,

      keyboardType: keyboardType,

      style: const TextStyle(color: Colors.white, fontSize: 16),

      decoration: _inputDecoration(
        label,

        icon,

        prefixText: prefixText,

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,

                  color: Colors.white54,
                ),

                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,

    IconData icon, {

    Widget? suffixIcon,

    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,

      labelStyle: const TextStyle(color: Colors.white60),

      prefixIcon: Icon(icon, color: primaryGold),

      prefixText: prefixText,

      prefixStyle: const TextStyle(
        color: Colors.white,

        fontWeight: FontWeight.bold,
      ),

      suffixIcon: suffixIcon,

      filled: true,

      fillColor: fieldGreen,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide(color: primaryGold.withValues(alpha: 0.45)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: const BorderSide(color: primaryGold, width: 2),
      ),
    );
  }

  Widget _infoBox(IconData icon, String title, String description) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: cardGreen.withValues(alpha: 0.78),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: primaryGold.withValues(alpha: 0.55)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, color: primaryGold, size: 28),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    color: primaryGold,

                    fontWeight: FontWeight.w800,

                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,

                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkGreenBackground extends StatelessWidget {
  const _DarkGreenBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Container(color: _LoginScreenState.primaryDarkGreen),

          Positioned(
            top: -90,

            right: -80,

            child: Container(
              width: 250,

              height: 250,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: _LoginScreenState.cardGreen.withValues(alpha: 0.28),
              ),
            ),
          ),

          Positioned(
            bottom: -120,

            left: -100,

            child: Container(
              width: 300,

              height: 300,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: _LoginScreenState.cardGreen.withValues(alpha: 0.20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
