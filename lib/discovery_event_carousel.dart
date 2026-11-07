import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'discovery_catalog.dart';
import 'discovery_photo.dart';
import 'home_event_selection.dart';
import 'home_admin_menu.dart';
import 'l10n/app_ui.dart';

class DiscoveryEventCarousel extends StatefulWidget {
  const DiscoveryEventCarousel({
    super.key,
    required this.onOpen,
    this.onViewAll,
  });
  final Future<void> Function(Map<String, dynamic>) onOpen;
  final VoidCallback? onViewAll;
  @override
  State<DiscoveryEventCarousel> createState() => _DiscoveryEventCarouselState();
}

class _DiscoveryEventCarouselState extends State<DiscoveryEventCarousel>
    with WidgetsBindingObserver {
  final _scroll = ScrollController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  Timer? _timer;
  bool _active = true, _touching = false, _opening = false;
  int _count = 0, _index = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stream = FirebaseFirestore.instance.collection('events').snapshots();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          !_active ||
          _touching ||
          _opening ||
          _count < 2 ||
          !_scroll.hasClients ||
          ModalRoute.of(context)?.isCurrent != true ||
          MediaQuery.of(context).disableAnimations)
        return;
      _index = (_index + 1) % _count;
      _scroll.animateTo(
        (_index * 220.0)
            .clamp(0.0, _scroll.position.maxScrollExtent)
            .toDouble(),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(DiscoveryEntry entry) async {
    if (_opening) return;
    _opening = true;
    try {
      await widget.onOpen(entry.navigationData);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return const Padding(
          padding: EdgeInsets.all(16),
          child: AppText('Service indisponible.'),
        );
      if (!snapshot.hasData)
        return const SizedBox(
          height: 90,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          ),
        );
      final published = snapshot.data!.docs
          .where(
            (d) =>
                discoveryPublished(d.data(), 'events') &&
                d.data()['homeHidden'] != true,
          )
          .map((d) => DiscoveryEntry('events', d.id, d.data()))
          .toList();
      final selected = selectHomeEvents(
        published,
        (DiscoveryEntry entry) => discoveryEventDate(entry.data),
      );
      final visible = selected.items;
      _count = visible.length;
      if (_index >= _count) _index = 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 10, 8),
            child: Row(
              children: [
                const Icon(Icons.event, color: Color(0xFFFFD700)),
                const SizedBox(width: 9),
                Expanded(
                  child: AppText(
                    selected.upcoming
                        ? 'Événements à venir'
                        : 'Événements à découvrir',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onViewAll,
                  child: const AppText('Voir tout'),
                ),
              ],
            ),
          ),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: AppText('Aucun événement publié pour le moment.'),
            ),
          if (visible.isNotEmpty)
            Listener(
              onPointerDown: (_) => _touching = true,
              onPointerUp: (_) => _touching = false,
              onPointerCancel: (_) => _touching = false,
              child: SizedBox(
                height: 180,
                child: ListView.separated(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final entry = visible[i],
                        date = discoveryEventDate(entry.data);
                    final d = date?.toLocal();
                    final today = DateTime.now();
                    final past =
                        d != null &&
                        DateTime(d.year, d.month, d.day).isBefore(
                          DateTime(today.year, today.month, today.day),
                        );
                    return SizedBox(
                      width: 210,
                      child: InkWell(
                        onTap: () => _open(entry),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(
                                color: const Color(0xFF004D40),
                                child: DiscoveryPhoto(
                                  urls: discoveryImages(entry.data),
                                  fallback: const Center(
                                    child: Icon(
                                      Icons.event,
                                      color: Color(0xFFFFD700),
                                      size: 44,
                                    ),
                                  ),
                                ),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black87,
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                right: 10,
                                bottom: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      entry.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (d != null)
                                      Text(
                                        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
                                        style: const TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 12,
                                        ),
                                      )
                                    else
                                      const AppText(
                                        'Date à confirmer',
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (past)
                                      const AppText(
                                        'Événement passé',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: HomeAdminMenu(
                                  collection: 'events',
                                  id: entry.id,
                                  title: entry.title,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      );
    },
  );
}
