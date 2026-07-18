import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'access_control.dart';

class ProviderChatThreadScreen extends StatefulWidget {
  const ProviderChatThreadScreen({
    super.key,
    required this.providerUid,
    required this.providerName,
    this.postId,
    this.postType,
    this.postTitle,
    this.postCategory,
    this.providerPhone,
    this.providerEmail,
  });

  final String providerUid;
  final String providerName;
  final String? postId;
  final String? postType;
  final String? postTitle;
  final String? postCategory;
  final String? providerPhone;
  final String? providerEmail;

  @override
  State<ProviderChatThreadScreen> createState() => _ProviderChatThreadScreenState();
}

class _ProviderChatThreadScreenState extends State<ProviderChatThreadScreen> with WidgetsBindingObserver {
  static const int _freeMessageLimit = 10;
  static const int _creditsPerPurchase = 10;
  static const String _messagePackProductId = 'direct_message_pack_10_eur';

  final TextEditingController _messageController = TextEditingController();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  String _chatId = '';
  bool _initializing = true;
  bool _isPurchasingCredits = false;
  bool _isSendingMessage = false;
  bool _quotaLoaded = false;
  bool _messageBypassEnabled = false;
  String _purchaseStatus = '';
  int _freeUsed = 0;
  int _purchasedCredits = 0;
  ProductDetails? _messagePackProduct;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  String _sanitizeKeyPart(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    return normalized.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureThread();
    _loadQuota();
    _loadMessageBypassAccess();
    _initBilling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadQuota();
      if (_isPurchasingCredits && mounted) {
        setState(() {
          _purchaseStatus = 'Waiting for Google Play confirmation...';
        });
      }
    }
  }

  int get _remainingFree => (_freeMessageLimit - _freeUsed).clamp(0, _freeMessageLimit);
  int get _remainingTotal => _remainingFree + _purchasedCredits;

  Future<void> _loadMessageBypassAccess() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return;

    var adminAccess = false;
    try {
      adminAccess = await AccessControl.hasCurrentUserAdminAccess();
    } catch (_) {
      adminAccess = false;
    }

    var userBypass = false;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
      final userData = userDoc.data() ?? const <String, dynamic>{};
      userBypass = userData['messageCreditBypass'] == true
          || userData['billingBypass'] == true
          || userData['iapBypass'] == true
          || userData['isBillingTester'] == true;
    } catch (_) {
      userBypass = false;
    }

    if (!mounted) return;
    final bypass = adminAccess || userBypass;
    setState(() {
      _messageBypassEnabled = bypass;
      if (bypass) {
        _purchaseStatus = 'Test/admin bypass enabled. Message credits are temporarily unlimited.';
      }
    });
  }

  Future<void> _loadQuota() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _quotaLoaded = true;
        _purchaseStatus = '';
      });
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('message_quota').doc(currentUid).get();
    final data = doc.data() ?? const <String, dynamic>{};
    final freeUsed = (data['freeUsed'] is num) ? (data['freeUsed'] as num).toInt() : 0;
    final purchased = (data['purchasedCredits'] is num) ? (data['purchasedCredits'] as num).toInt() : 0;

    if (!mounted) return;
    setState(() {
      _freeUsed = freeUsed < 0 ? 0 : freeUsed;
      _purchasedCredits = purchased < 0 ? 0 : purchased;
      _quotaLoaded = true;
      if (_purchasedCredits > 0) {
        _purchaseStatus = '10 message credits confirmed and ready to use.';
      }
    });
  }

  Future<void> _initBilling() async {
    if (!Platform.isAndroid) return;

    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _purchaseStatus = 'Google Play billing is unavailable on this device.';
      });
      return;
    }

    final response = await _inAppPurchase.queryProductDetails({_messagePackProductId});
    if (response.productDetails.isNotEmpty) {
      if (mounted) {
        setState(() {
          _messagePackProduct = response.productDetails.first;
        });
      } else {
        _messagePackProduct = response.productDetails.first;
      }
    } else if (mounted) {
      final notFound = response.notFoundIDs.isNotEmpty ? response.notFoundIDs.join(', ') : _messagePackProductId;
      setState(() {
        _purchaseStatus = 'Google Play product not found: $notFound';
      });
    }

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen((purchaseDetailsList) async {
      for (final purchase in purchaseDetailsList) {
        if (purchase.productID != _messagePackProductId) {
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }
          continue;
        }

        if (purchase.status == PurchaseStatus.pending) {
          if (mounted) {
            setState(() {
              _isPurchasingCredits = true;
              _purchaseStatus = 'Payment pending in Google Play...';
            });
          }
          continue;
        }

        if (purchase.status == PurchaseStatus.error) {
          if (mounted) {
            setState(() {
              _isPurchasingCredits = false;
              _purchaseStatus = 'Payment failed. No credits were added.';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment failed: ${purchase.error?.message ?? 'Unknown error'}')),
            );
          }
        }

        if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
          await _grantPurchasedCredits(purchase);
        }

        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      }
    });
  }

  Future<void> _grantPurchasedCredits(PurchaseDetails purchase) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return;

    final purchaseKey = (purchase.purchaseID ?? '${purchase.productID}_${purchase.transactionDate ?? DateTime.now().millisecondsSinceEpoch}').trim();
    final quotaRef = FirebaseFirestore.instance.collection('message_quota').doc(currentUid);
    final purchaseRef = FirebaseFirestore.instance.collection('message_credit_purchases').doc(purchaseKey);

    var granted = false;
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final already = await tx.get(purchaseRef);
      if (already.exists) {
        return;
      }

      tx.set(purchaseRef, {
        'uid': currentUid,
        'productId': purchase.productID,
        'purchaseId': purchase.purchaseID,
        'transactionDate': purchase.transactionDate,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(quotaRef, {
        'purchasedCredits': FieldValue.increment(_creditsPerPurchase),
        'lastPurchaseId': purchaseKey,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      granted = true;
    });

    if (!mounted) return;
    setState(() {
      _isPurchasingCredits = false;
      _purchaseStatus = granted
          ? 'Payment confirmed. 10 message credits added.'
          : 'Payment record received, but confirmation is still pending.';
    });
    await _loadQuota();
    if (!mounted) return;
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful. 10 message credits added.')),
      );
    }
  }

  Future<void> _buyMessageCredits() async {
    if (!Platform.isAndroid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Play billing is available on Android only.')),
      );
      return;
    }

    if (_messagePackProduct == null) {
      if (!mounted) return;
      setState(() {
        _purchaseStatus = 'Configure Play product ID: $_messagePackProductId';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message credit product is not configured yet. ID: $_messagePackProductId')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isPurchasingCredits = true;
      _purchaseStatus = 'Opening Google Play purchase flow...';
    });

    final param = PurchaseParam(productDetails: _messagePackProduct!);
    _inAppPurchase.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  Future<void> _ensureThread() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
      });
      return;
    }

    try {
      final ids = [currentUid, widget.providerUid]..sort();
      final postId = _sanitizeKeyPart(widget.postId ?? '');
      final postType = _sanitizeKeyPart(widget.postType ?? 'post');
      _chatId = postId.isEmpty
          ? '${ids.first}_${ids.last}'
          : '${ids.first}_${ids.last}_${postType}_$postId';

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
      final existing = await chatRef.get().timeout(const Duration(seconds: 8));
      if (!existing.exists) {
        final now = FieldValue.serverTimestamp();
        await chatRef.set({
          'participantIds': ids,
          'participantNameMap': {
            currentUid: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
            widget.providerUid: widget.providerName,
          },
          'createdAt': now,
          'updatedAt': now,
          'lastMsg': '',
          'postId': widget.postId ?? '',
          'postType': widget.postType ?? '',
          'postTitle': widget.postTitle ?? '',
          'postCategory': widget.postCategory ?? '',
          'providerUid': widget.providerUid,
          'providerName': widget.providerName,
          'providerPhone': widget.providerPhone ?? '',
          'providerEmail': widget.providerEmail ?? '',
          'threadType': (widget.postId ?? '').trim().isEmpty ? 'direct' : 'post',
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
      } else {
        await chatRef.set({
          'participantIds': ids,
          'participantNameMap': {
            currentUid: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
            widget.providerUid: widget.providerName,
          },
          'updatedAt': FieldValue.serverTimestamp(),
          'postId': widget.postId ?? '',
          'postType': widget.postType ?? '',
          'postTitle': widget.postTitle ?? '',
          'postCategory': widget.postCategory ?? '',
          'providerUid': widget.providerUid,
          'providerName': widget.providerName,
          'providerPhone': widget.providerPhone ?? '',
          'providerEmail': widget.providerEmail ?? '',
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
      }
    } on TimeoutException {
      debugPrint('Chat thread setup timed out. Opening composer anyway.');
    } on FirebaseException catch (error) {
      debugPrint('Chat thread setup skipped: $error');
    } catch (error) {
      debugPrint('Chat thread setup failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (_isSendingMessage || text.isEmpty) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return;

    if (_chatId.isEmpty) {
      await _ensureThread();
      if (_chatId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat is still loading. Please try sending again.')),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isSendingMessage = true;
    });

    if (_messageBypassEnabled) {
      final msgRef = FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').doc();
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
      try {
        await FirebaseFirestore.instance.runTransaction((tx) async {
          tx.set(msgRef, {
            'senderId': currentUid,
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
            'chatId': _chatId,
            'postId': widget.postId ?? '',
            'postType': widget.postType ?? '',
          });
          tx.set(chatRef, {
            'lastMsg': text,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
      } on FirebaseException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to send message: ${error.code}')),
        );
        return;
      } finally {
        if (mounted) {
          setState(() {
            _isSendingMessage = false;
          });
        }
      }
      if (!mounted) return;
      _messageController.clear();
      return;
    }

    final msgRef = FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').doc();
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
    final quotaRef = FirebaseFirestore.instance.collection('message_quota').doc(currentUid);

    var allowed = false;
    var nextFreeUsed = _freeUsed;
    var nextPurchasedCredits = _purchasedCredits;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final quotaSnap = await tx.get(quotaRef);
        final data = quotaSnap.data() ?? const <String, dynamic>{};
        final freeUsed = (data['freeUsed'] is num) ? (data['freeUsed'] as num).toInt() : 0;
        final purchasedCredits = (data['purchasedCredits'] is num) ? (data['purchasedCredits'] as num).toInt() : 0;

        if (purchasedCredits > 0) {
          nextFreeUsed = freeUsed;
          nextPurchasedCredits = purchasedCredits - 1;
        } else if (freeUsed < _freeMessageLimit) {
          nextFreeUsed = freeUsed + 1;
          nextPurchasedCredits = purchasedCredits;
        } else {
          return;
        }

        tx.set(quotaRef, {
          'freeUsed': nextFreeUsed,
          'purchasedCredits': nextPurchasedCredits,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(msgRef, {
          'senderId': currentUid,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
          'chatId': _chatId,
          'postId': widget.postId ?? '',
          'postType': widget.postType ?? '',
        });

        tx.set(chatRef, {
          'lastMsg': text,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        allowed = true;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      final message = error.code == 'permission-denied'
          ? 'Send blocked by security rules. Enable message bypass for your user in Admin Panel.'
          : 'Unable to send message: ${error.code}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }

    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You used 10 free messages. Buy 10 more for EUR 1 to continue.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _freeUsed = nextFreeUsed;
      _purchasedCredits = nextPurchasedCredits;
      _quotaLoaded = true;
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final systemBottomInset = mediaQuery.padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2E1E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.providerName, style: const TextStyle(fontWeight: FontWeight.w700)),
            if ((widget.postTitle ?? '').trim().isNotEmpty)
              Text(
                widget.postTitle!.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
      ),
      body: Column(
              children: [
                if (_initializing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: const Color(0xFF0B281A),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Opening chat...',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                if ((widget.postCategory ?? '').trim().isNotEmpty
                    || (widget.providerPhone ?? '').trim().isNotEmpty
                    || (widget.providerEmail ?? '').trim().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: const Color(0xFF0B281A),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if ((widget.postCategory ?? '').trim().isNotEmpty)
                          _metaChip(widget.postCategory!.trim()),
                        if ((widget.providerPhone ?? '').trim().isNotEmpty)
                          _metaChip(widget.providerPhone!.trim()),
                        if ((widget.providerEmail ?? '').trim().isNotEmpty)
                          _metaChip(widget.providerEmail!.trim()),
                      ],
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(_chatId)
                        .collection('messages')
                        .orderBy('createdAt', descending: true)
                        .limit(80)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No messages yet. Start the conversation.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final senderId = (data['senderId'] ?? '').toString();
                          final text = (data['text'] ?? '').toString();
                          final mine = senderId == currentUid;

                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: mine ? const Color(0xFFF59E0B) : const Color(0xFF0E2E1E),
                                borderRadius: BorderRadius.circular(12),
                                border: mine ? null : Border.all(color: Colors.white10),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: mine ? const Color(0xFF061E12) : Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.fromLTRB(
                    8,
                    8,
                    8,
                    8 + (keyboardInset > 0 ? 0 : systemBottomInset),
                  ),
                  color: const Color(0xFF0E2E1E),
                  child: SafeArea(
                    top: false,
                    maintainBottomViewPadding: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      if (_purchaseStatus.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF123222),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            _purchaseStatus,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF123222),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _messageBypassEnabled
                                    ? 'Message credits: unlimited (test/admin bypass)'
                                    : _quotaLoaded
                                    ? 'Message credits left: $_remainingTotal (free left: $_remainingFree)'
                                    : 'Loading message credits...',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: (_isPurchasingCredits || _messagePackProduct == null || _messageBypassEnabled)
                                  ? null
                                  : _buyMessageCredits,
                              child: Text(
                                _messageBypassEnabled
                                    ? 'Bypass Active'
                                    : _isPurchasingCredits
                                    ? 'Processing...'
                                    : (_messagePackProduct == null ? 'Not Configured' : 'Buy 10 / ${_messagePackProduct!.price}'),
                                style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Type a message',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF061E12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _isSendingMessage ? null : _sendMessage,
                            icon: const Icon(Icons.send_outlined, color: Color(0xFFF59E0B)),
                          ),
                        ],
                      ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF123222),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
