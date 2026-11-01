// Euro Habesha: photos et publicites v1
import 'about_euro_habesha_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

import 'package:geolocator/geolocator.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'notifications_screen.dart';

import 'business_screen.dart';

import 'events_screen.dart';

import 'jobs_screen.dart';

import 'marketplace_screen.dart';

import 'professionals_screen.dart';

import 'admin_panel_screen.dart';

import 'app_session.dart';

import 'admin_updates_feed.dart';

import 'nearby_screen.dart';

import 'habesha_connect/habesha_connect_screen.dart';

import 'sponsored_banner_section.dart';

import 'sponsored_interstitial_ad.dart';

import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override

  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {

  static const Color primaryDarkGreen = Color(0xFF061E12);

  static const Color primaryGold = Color(0xFFFFD700);

  static const Color cardGreen = Color(0xFF004D40);

  String userLocation = 'Localisation GPS en cours...';

  late final PageController _pageController;

  Timer? _sliderTimer;

  Timer? _interstitialTimer;
  final ScrollController _quickSuggestionsController = ScrollController();
  Timer? _quickSuggestionsTimer;
  bool _quickSuggestionsPaused = false;
  double _quickSuggestionsDirection = 1;


  final Map<String, Map<String, String>> texts = const {

    'Categories': {

      'English': 'Categories',

      'French': 'Catégories',

      'Amharic': 'ምድቦች',

      'Tigrinya': 'ምድባት',

    },

    'Recent Updates': {

      'English': 'Featured Updates',

      'French': 'Nouveautés près de vous',

      'Amharic': 'ዋና ዋና መረጃዎች',

      'Tigrinya': 'ፍሉያት ሓበሬታታት',

    },

    'Jobs': {

      'English': 'Jobs',

      'French': 'Emplois',

      'Amharic': 'ስራ',

      'Tigrinya': 'ስራሕ',

    },

    'Businesses': {

      'English': 'Businesses',

      'French': 'Commerces',

      'Amharic': 'ንግድ',

      'Tigrinya': 'ንግዲ',

    },

    'Market': {

      'English': 'Market',

      'French': 'Marché',

      'Amharic': 'ገበያ',

      'Tigrinya': 'ዕዳጋ',

    },

    'Pros': {

      'English': 'Professionals',

      'French': 'Professionnels',

      'Amharic': 'ባለሙያዎች',

      'Tigrinya': 'ሰብ ሞያ',

    },

    'Events': {

      'English': 'Events',

      'French': 'Événements',

      'Amharic': 'ክስተት',

      'Tigrinya': 'ፍጻመታት',

    },

    'Habesha Connect': {

      'English': 'Habesha Connect',

      'French': 'Habesha Connect',

      'Amharic': 'Habesha Connect',

      'Tigrinya': 'Habesha Connect',

    },

    'Nearby': {

      'English': 'Nearby',

      'French': 'À proximité',

      'Amharic': 'በአቅራቢያ',

      'Tigrinya': 'ኣብ ቀረባ',

    },

  };

  String getTxt(String key) {

    final language = switch (context.locale.languageCode) {

      'fr' => 'French',

      'am' => 'Amharic',

      'ti' => 'Tigrinya',

      _ => 'English',

    };

    return texts[key]?[language] ?? texts[key]?['English'] ?? key;

  }

  @override

  void initState() {

    super.initState();

    _quickSuggestionsTimer = Timer.periodic(
      const Duration(milliseconds: 35),
      (_) => _advanceQuickSuggestions(),
    );
    _pageController = PageController(

      initialPage: 0,

      viewportFraction: 0.82,

    );

    WidgetsBinding.instance.addPostFrameCallback((_) {

      _checkLocationPermission();

      _interstitialTimer = Timer(

        const Duration(seconds: 12),

        () {

          if (!mounted) return;

          SponsoredInterstitialAd.showIfAvailable(context);

        },

      );

    });

  }

  @override

  void dispose() {

    _sliderTimer?.cancel();

    _interstitialTimer?.cancel();
    _quickSuggestionsTimer?.cancel();
    _quickSuggestionsController.dispose();

    _pageController.dispose();

    super.dispose();

  }

  Future<void> _checkLocationPermission() async {

    bool serviceEnabled;

    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {

      if (mounted) {

        setState(() {

          userLocation = 'Les services de localisation sont désactivés.';

        });

      }

      return;

    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {

      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {

        if (mounted) {

          setState(() {

            userLocation = 'Autorisation de localisation refusée.';

          });

        }

        return;

      }

    }

    if (permission == LocationPermission.deniedForever) {

      if (mounted) {

        setState(() {

          userLocation = 'Autorisation de localisation refusée définitivement.';

        });

      }

      return;

    }

    try {

      final Position position = await Geolocator.getCurrentPosition(

        locationSettings: const LocationSettings(

          accuracy: LocationAccuracy.high,

        ),

      );

      String locationName = 'GPS actif';

      try {

        final geocoding = Geocoding();

        final placemarks = await geocoding.placemarkFromCoordinates(

          position.latitude,

          position.longitude,

        );

        if (placemarks.isNotEmpty) {

          final place = placemarks.first;

          final locality = place.locality?.trim() ?? '';

          final subLocality = place.subLocality?.trim() ?? '';

          final administrativeArea = place.administrativeArea?.trim() ?? '';

          if (subLocality.isNotEmpty &&

              subLocality.toLowerCase() != locality.toLowerCase()) {

            locationName = subLocality;

          } else if (locality.isNotEmpty) {

            locationName = locality;

          } else if (administrativeArea.isNotEmpty) {

            locationName = administrativeArea;

          }

        }

      } catch (_) {

        locationName = 'GPS actif';

      }

      if (mounted) {

        setState(() {

          userLocation = locationName;

        });

      }

    } catch (e) {

      if (mounted) {

        setState(() {

          userLocation = 'GPS actif';

        });

      }

    }

  }

  Future<void> _handleRefresh() async {

    await _checkLocationPermission();

    if (mounted) {

      setState(() {});

    }

  }

  // Transforme les documents Firestore (avec ou sans `fields`) en fiche lisible.
  Map<String, dynamic> _detailFromSubmission(Map<String, dynamic> source) {
    final rawFields = source['fields'];
    final fields = rawFields is Map ? Map<String, dynamic>.from(rawFields) : <String, dynamic>{};
    String first(List<dynamic> values) {
      for (final value in values) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty && text != 'null') return text;
      }
      return '';
    }
    final phone = first([fields['phoneNumber'], fields['phone'], source['phone']]);
    final title = first([fields['title'], fields['jobTitle'], source['name'], source['title']]);
    final category = first([fields['jobCategory'], fields['professionalCategory'], fields['category'], source['category'], source['title']]);
    final location = first([fields['cityAddress'], fields['city'], source['location'], fields['country'], source['country']]);
    final description = first([fields['description'], fields['requirements'], source['description']]);
    final normalized = <String, dynamic>{
      ...source,
      'name': title,
      'title': title,
      'category': category,
      'location': location,
      'description': description,
      'phone': phone.isEmpty ? '' : (phone.startsWith('tel:') ? phone : 'tel:$phone'),
      'email': first([fields['emailAddress'], fields['email'], source['email'], source['submitterEmail']]),
      'website': first([fields['websiteUrl'], source['website']]),
      'whatsapp': first([source['whatsapp'], fields['whatsapp']]),
      'logoUrl': first([fields['logoUrl'], fields['imageUrl'], source['logoUrl'], source['imageUrl']]),
      'coverUrl': first([fields['coverUrl'], source['coverUrl']]),
      'serviceType': first([source['serviceType'], fields['serviceType'], fields['jobCategory']]).toLowerCase(),
      'menuItems': source['menuItems'] is List ? source['menuItems'] : <dynamic>[],
      'depositPercentage': source['depositPercentage'] ?? (source['orderingModel'] is Map ? source['orderingModel']['depositPercentage'] : null) ?? 0,
      'icon': source['icon'] is IconData ? source['icon'] : Icons.work_outline,
      'gallery': source['gallery'] is List ? (source['gallery'] as List).map((e) => e.toString()).toList() : <dynamic>[],
      'reviews': source['reviews'] is List ? (source['reviews'] as List).map((r) => r is Map ? {...Map<String, dynamic>.from(r), 'rating': r['rating']?.toString() ?? '', 'user': r['user']?.toString() ?? '', 'comment': r['comment']?.toString() ?? ''} : r).toList() : <dynamic>[],
      'rating': source['rating']?.toString() ?? '',
    };
    return normalized;
  }

  // Ouvre la fiche originale, pas une version reduite du publicFeed.
  Future<void> _handleUpdateTap(Map<String, dynamic> data) async {
    String value(Map<String, dynamic> m, String key) =>
        (m[key] ?? '').toString().trim();
    var collection = value(data, 'sourceCollection');
    var id = value(data, 'sourceId');
    Map<String, dynamic>? original;

    if (collection.isNotEmpty && id.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection(collection).doc(id).get();
        if (doc.exists && doc.data() != null) {
          original = {...doc.data()!, 'id': doc.id};
        }
      } catch (_) { /* Acces refuse ou document indisponible. */ }
    }

    // Certains anciens posts du flux ne contiennent pas sourceId.
    // Rechercher une correspondance EXACTE et UNIQUE, jamais un nom approximatif.
    if (original == null) {
      final name = value(data, 'name').isNotEmpty ? value(data, 'name') : value(data, 'title');
      final kind = '${value(data, 'category')} ${value(data, 'type')}'.toLowerCase();
      final candidates = <String>[];
      if (collection.isNotEmpty) candidates.add(collection);
      if (kind.contains('business') || kind.contains('restaurant') || kind.contains('commerce')) {
        candidates.add('businesses');
      } else if (kind.contains('event')) {
        candidates.add('events');
      } else if (kind.contains('market')) {
        candidates.add('marketplace');
      } else if (kind.contains('professional') || kind.contains('pro')) {
        candidates.add('professionals');
      } else if (kind.contains('job') || kind.contains('service') || kind.contains('catering')) {
        candidates.add('jobs');
      }
      if (name.isNotEmpty) {
        final matches = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        for (final c in candidates.toSet()) {
          for (final field in const ['name', 'title']) {
            try {
              final result = await FirebaseFirestore.instance.collection(c)
                  .where(field, isEqualTo: name).limit(2).get();
              for (final doc in result.docs) {
                if (!matches.any((x) => x.reference.path == doc.reference.path)) {
                  matches.add(doc);
                }
              }
            } catch (_) { /* Ne pas inventer de fiche en cas d'erreur. */ }
          }
        }
        if (matches.length == 1) {
          final doc = matches.single;
          original = {...doc.data(), 'id': doc.id};
          collection = doc.reference.parent.id;
          id = doc.id;
        }
      }
    }

    if (!mounted) return;
    if (original == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fiche complète introuvable. Vérifiez les références de cette annonce.'),
      ));
      return;
    }

    final fields = original['fields'] is Map
        ? Map<String, dynamic>.from(original['fields'] as Map)
        : <String, dynamic>{};
    final kind = [
      value(data, 'category'), value(data, 'type'),
      value(original, 'category'), value(original, 'type'),
      value(original, 'submissionType'), value(fields, 'jobCategory'),
      value(fields, 'professionalCategory'),
    ].join(' ').toLowerCase();
    final source = collection.toLowerCase();
    final detail = {...data, ...original, 'id': id};

    if (source.contains('event') || kind.contains('event')) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventData: detail),
      ));
    } else if (source.contains('market') || kind.contains('market')) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: detail),
      ));
    } else if (source == 'businesses' || kind.contains('business') ||
        kind.contains('restaurant') || kind.contains('commerce')) {
      // Use exactly the same mapper as the Commerces directory.
      // It restores address, opening hours, registration and docRef for orders.
      // Some legacy publicFeed entries point to a publication instead of
      // the actual businesses document. Resolve the real business by its
      // displayed name (including the nested fields.title schema).
      DocumentSnapshot<Map<String, dynamic>>? businessDoc;
      if (source == 'businesses' && id.isNotEmpty) {
        try {
          final direct = await FirebaseFirestore.instance
              .collection('businesses').doc(id).get();
          if (direct.exists) businessDoc = direct;
        } catch (_) {}
      }
      if (businessDoc == null) {
        final names = <String>{};
        for (final record in [data, original]) {
          for (final key in ['name', 'title', 'businessName']) {
            final text = value(record, key);
            if (text.isNotEmpty) names.add(text.toLowerCase());
          }
          final nested = record['fields'];
          if (nested is Map) {
            for (final key in ['title', 'name', 'businessName']) {
              final text = (nested[key] ?? '').toString().trim();
              if (text.isNotEmpty) names.add(text.toLowerCase());
            }
          }
        }
        try {
          final all = await FirebaseFirestore.instance
              .collection('businesses').get();
          final matches = all.docs.where((doc) {
            final record = doc.data();
            final nested = record['fields'];
            final possible = <String>[
              value(record, 'name'), value(record, 'title'),
              value(record, 'businessName'),
              if (nested is Map) ...[
                (nested['title'] ?? '').toString(),
                (nested['name'] ?? '').toString(),
                (nested['businessName'] ?? '').toString(),
              ],
            ];
            return possible.any((n) => names.contains(n.trim().toLowerCase()));
          }).toList();
          if (matches.length == 1) businessDoc = matches.single;
        } catch (_) {}
      }
      if (!mounted) return;
      if (businessDoc == null) {
        final name = value(data, 'name').isNotEmpty
            ? value(data, 'name') : value(data, 'title');
        if (name.isNotEmpty) {
          _openDiscoverHome(search: name, openBusinessName: name);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Référence du commerce introuvable.'),
          ));
        }
        return;
      }
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => BusinessDetailScreen(
         businessData: normalizeBusinessForDetail(businessDoc!),
        ),
      ));
    } else if (source == 'jobs' || source.contains('job') ||
        kind.contains('job') || kind.contains('emploi') ||
        kind.contains('catering') || kind.contains('traiteur') ||
        kind.contains('service') || kind.contains('dj')) {
      // JobsScreen ouvre JobDetailScreen pour les emplois ET les services.
      // Cette page contient notamment le menu et la commande des traiteurs.
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => JobDetailScreen(jobData: _detailFromSubmission(detail)),
      ));
    } else if (source.contains('professional') || kind.contains('professional')) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProDetailScreen(proData: _detailFromSubmission(detail)),
      ));
    } else if (source.contains('habeshaconnect') || kind.contains('habesha connect')) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const HabeshaConnectScreen(),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Catégorie non reconnue pour cette fiche.'),
      ));
    }
  }

  void _openDiscoverHome({
    String? category,
    String? search,
    String? quickFilter,
    String? openBusinessName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessDirectoryScreen(
          initialCategory: category,
          initialSearch: search,
          quickFilter: quickFilter,
          openBusinessName: openBusinessName,
        ),
      ),
    );
  }

  Widget _homeSearch() => Padding(

    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),

    child: InkWell(

      onTap: _openDiscoverHome,

      borderRadius: BorderRadius.circular(13),

      child: Container(

        height: 40,

        padding: const EdgeInsets.symmetric(horizontal: 12),

        decoration: BoxDecoration(

          color: cardGreen,

          borderRadius: BorderRadius.circular(13),

          border: Border.all(color: primaryGold.withValues(alpha: .45)),

        ),

        child: Row(children: [

          const Icon(Icons.search, color: primaryGold, size: 21),

          const SizedBox(width: 10),

          const Expanded(child: Text(

            'Que cherchez-vous ?',

            style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),

          )),

          Container(width: 1, height: 19, color: Colors.white24),

          const SizedBox(width: 9),

          const Icon(Icons.tune, color: primaryGold),

        ]),

      ),

    ),

  );

  void _advanceQuickSuggestions() {
    if (!mounted || _quickSuggestionsPaused ||
        !_quickSuggestionsController.hasClients) {
      return;
    }
    final position = _quickSuggestionsController.position;
    if (position.maxScrollExtent <= 0) return;
    final next = position.pixels + (0.45 * _quickSuggestionsDirection);
    if (next >= position.maxScrollExtent) {
      _quickSuggestionsDirection = -1;
      _quickSuggestionsController.jumpTo(position.maxScrollExtent);
    } else if (next <= position.minScrollExtent) {
      _quickSuggestionsDirection = 1;
      _quickSuggestionsController.jumpTo(position.minScrollExtent);
    } else {
      _quickSuggestionsController.jumpTo(next);
    }
  }

  Widget _quickSuggestions() {
    final items = <(IconData, String, String, String?)>[
      (Icons.restaurant, 'Habesha food', 'habesha_food', 'Restaurants'),
      (Icons.content_cut, 'Coiffure', 'coiffure', 'Services'),
      (Icons.photo_camera_outlined, 'Photographie', 'photographie', 'Services'),
      (Icons.translate, 'Traduction', 'traduction', 'Services'),
      (Icons.event, 'Événements', 'evenements', 'Événements'),
      (Icons.shopping_bag_outlined, 'Marketplace', 'marketplace', null),
      (Icons.work_outline, 'Emplois', 'emplois', null),
      (Icons.content_cut, 'Barbershop', 'barbershop', 'Services'),
      (Icons.shopping_basket_outlined, 'Épicerie', 'epicerie', 'Commerces'),
      (Icons.restaurant_menu, 'Restaurants', 'restaurants', 'Restaurants'),
      (Icons.local_cafe_outlined, 'Cafés', 'cafes', 'Restaurants'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 10, 0),
        child: Row(children: [
          const Expanded(child: Text('Suggestions rapides', style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.w800))),
          TextButton(onPressed: () => _openDiscoverHome(), child: const Text('Voir tout ›', style: TextStyle(color: Colors.white70, fontSize: 11))),
        ]),
      ),
      Listener(
        onPointerDown: (_) => _quickSuggestionsPaused = true,
        onPointerUp: (_) => _quickSuggestionsPaused = false,
        onPointerCancel: (_) => _quickSuggestionsPaused = false,
        child: SizedBox(
        height: 32,
        child: ListView.separated(
          controller: _quickSuggestionsController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 5),
          itemBuilder: (_, i) => InkWell(
            onTap: () {
              final filter = items[i].$3;
              if (filter == 'marketplace') {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const MarketplaceScreen(),
                ));
              } else if (filter == 'emplois') {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const JobsScreen(),
                ));
              } else {
                _openDiscoverHome(
                  category: items[i].$4,
                  quickFilter: filter == 'evenements' ? null : filter,
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: cardGreen.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryGold.withValues(alpha: .35)),
              ),
              child: Row(children: [
                Icon(items[i].$1, color: primaryGold, size: 15),
                const SizedBox(width: 5),
                Text(items[i].$2, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
        ),
      ),
    ]);
  }

  Widget _homeSectionTitle(IconData icon,String title,String subtitle,{VoidCallback? onTap}) => Padding(

    padding:const EdgeInsets.fromLTRB(16,10,12,5),

    child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[

      Icon(icon,color:primaryGold,size:20),

      const SizedBox(width:8),

      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[

        Text(title,style:const TextStyle(color:primaryGold,fontSize:17,fontWeight:FontWeight.w800)),

        const SizedBox(height:1),

        Text(subtitle,style:const TextStyle(color:Colors.white54,fontSize:10)),

      ])),

      TextButton(onPressed:onTap??_openDiscoverHome,child:const Text('Voir tout ›',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w600))),

    ]),

  );

  Widget _eventPreviewSection() => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[

    _homeSectionTitle(Icons.event,'Événements à venir','Concerts, fêtes, soirées et rencontres près de vous.',

      onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const EventsScreen()))),

    SizedBox(

      height:96,

      child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(

        stream:FirebaseFirestore.instance.collection('events').limit(8).snapshots(),

        builder:(context,snapshot){

          final docs=(snapshot.data?.docs??[]).where((d){

            final x=d.data();

            final st=(x['status']??'').toString().toLowerCase();

            return st.isEmpty||st=='published'||st=='approved';

          }).take(5).toList();

          if(docs.isEmpty){

            return InkWell(

              onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const EventsScreen())),

              child:Container(

                margin:const EdgeInsets.symmetric(horizontal:16),

                padding:const EdgeInsets.all(16),

                decoration:BoxDecoration(color:cardGreen,borderRadius:BorderRadius.circular(15),border:Border.all(color:primaryGold.withValues(alpha:.25))),

                child:const Row(children:[Icon(Icons.event,color:primaryGold),SizedBox(width:10),Expanded(child:Text('Découvrez les prochains événements Euro Habesha',style:TextStyle(color:Colors.white70)))]),

              ),

            );

          }

          return ListView.separated(

            padding:const EdgeInsets.symmetric(horizontal:16),

            scrollDirection:Axis.horizontal,

            itemCount:docs.length,

            separatorBuilder:(_,__)=>const SizedBox(width:10),

            itemBuilder:(_,i){

              final d=docs[i].data();

              final title=(d['title']??d['name']??'Événement').toString();

              final city=(d['city']??d['location']??'').toString();

              final img=(d['imageUrl']??d['coverImageUrl']??'').toString();

              return InkWell(

                onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const EventsScreen())),

                child:Container(

                  width:210,clipBehavior:Clip.antiAlias,

                  decoration:BoxDecoration(color:cardGreen,borderRadius:BorderRadius.circular(15),border:Border.all(color:primaryGold.withValues(alpha:.25))),

                  child:Stack(fit:StackFit.expand,children:[

                    if(img.isNotEmpty) Image.network(img,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox()),

                    Container(decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Colors.black87]))),

                    Positioned(left:10,right:8,bottom:8,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[

                      Text(title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),

                      if(city.isNotEmpty) Text(city,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white70,fontSize:10)),

                    ])),

                  ]),

                ),

              );

            },

          );

        },

      ),

    ),

  ]);

  Widget _offersSection() => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[

    _homeSectionTitle(Icons.local_offer,'Offres & Promotions','Découvrez les offres de nos professionnels.'),

    SizedBox(

      height:72,

      child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(

        stream:FirebaseFirestore.instance.collection('publicFeed').limit(30).snapshots(),

        builder:(context,snapshot){

          final docs=(snapshot.data?.docs??[]).where((d){

            final x=d.data();

            final text='${x['category']??''} ${x['type']??''} ${x['title']??''}'.toLowerCase();

            return (x['status']??'').toString().toLowerCase()=='published' &&

              (text.contains('promo')||text.contains('offer')||text.contains('offre')||text.contains('discount'));

          }).take(5).toList();

          if(docs.isEmpty){

            return InkWell(

              onTap:_openDiscoverHome,

              child:Container(

                margin:const EdgeInsets.symmetric(horizontal:16),

                padding:const EdgeInsets.symmetric(horizontal:15),

                decoration:BoxDecoration(color:cardGreen,borderRadius:BorderRadius.circular(14),border:Border.all(color:primaryGold.withValues(alpha:.25))),

                child:const Row(children:[Icon(Icons.local_offer,color:primaryGold),SizedBox(width:10),Expanded(child:Text('Les nouvelles offres apparaîtront ici automatiquement.',style:TextStyle(color:Colors.white70,fontSize:12))),Icon(Icons.chevron_right,color:primaryGold)]),

              ),

            );

          }

          return ListView.separated(

            padding:const EdgeInsets.symmetric(horizontal:16),

            scrollDirection:Axis.horizontal,

            itemCount:docs.length,

            separatorBuilder:(_,__)=>const SizedBox(width:9),

            itemBuilder:(_,i){

              final d=docs[i].data();

              return InkWell(

                onTap:()=>_handleUpdateTap(d),

                child:Container(

                  width:205,padding:const EdgeInsets.all(11),

                  decoration:BoxDecoration(color:cardGreen,borderRadius:BorderRadius.circular(14),border:Border.all(color:primaryGold.withValues(alpha:.28))),

                  child:Row(children:[

                    const Icon(Icons.local_offer,color:primaryGold),

                    const SizedBox(width:9),

                    Expanded(child:Text((d['title']??'Offre').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold))),

                    const Icon(Icons.chevron_right,color:primaryGold),

                  ]),

                ),

              );

            },

          );

        },

      ),

    ),

  ]);

@override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: primaryDarkGreen,

      drawer: _buildSideDrawer(

        context,

        primaryDarkGreen,

        primaryGold,

      ),

      appBar: AppBar(

        toolbarHeight: 78,

        title: SizedBox(

          height: 60,

          child: FittedBox(

            fit: BoxFit.scaleDown,

            child: Row(

              mainAxisSize: MainAxisSize.min,

              children: [

                Image.asset(

                  'assets/images/euro_habesha_logo.png',

                  height: 54,

                  errorBuilder: (c, e, s) => const Icon(

                    Icons.public,

                    color: primaryGold,

                    size: 48,

                  ),

                ),

                const SizedBox(width: 8),

                RichText(

                  maxLines: 1,

                  text: const TextSpan(

                    style: TextStyle(

                      fontSize: 18,

                      fontWeight: FontWeight.bold,

                      letterSpacing: 1.2,

                    ),

                    children: [

                      TextSpan(

                        text: 'EURO ',

                        style: TextStyle(

                          color: primaryGold,

                        ),

                      ),

                      TextSpan(

                        text: 'HABESHA',

                        style: TextStyle(

                          color: Colors.white,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

          ),

        ),

        backgroundColor: primaryDarkGreen,

        elevation: 0,

        centerTitle: true,

        iconTheme: const IconThemeData(

          color: primaryGold,

        ),

        actions: [

          Builder(

            builder: (context) {

              final user = FirebaseAuth.instance.currentUser;

              if (user == null) {

                return const SizedBox(width: 48);

              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

                stream: FirebaseFirestore.instance

                    .collection('notifications')

                    .where(

                      'recipientId',

                      isEqualTo: user.uid,

                    )

                    .snapshots(),

                builder: (context, snapshot) {

                  final unreadCount = snapshot.hasData

                      ? snapshot.data!.docs.where((document) {

                          final data = document.data();

                          final isUnread = data['read'] != true;

                          final type = data['type']?.toString() ?? '';

                          return isUnread && type != 'message';

                        }).length

                      : 0;

                  return Padding(

                    padding: const EdgeInsets.only(right: 8),

                    child: Stack(

                      clipBehavior: Clip.none,

                      children: [

                        IconButton(

                          tooltip: 'Notifications',

                          icon: const Icon(

                            Icons.notifications_outlined,

                            color: primaryGold,

                            size: 28,

                          ),

                          onPressed: () {

                            Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (_) => const NotificationScreen(),

                              ),

                            );

                          },

                        ),

                        if (unreadCount > 0)

                          Positioned(

                            right: 2,

                            top: 6,

                            child: Container(

                              constraints: const BoxConstraints(

                                minWidth: 18,

                                minHeight: 18,

                              ),

                              padding: const EdgeInsets.symmetric(

                                horizontal: 4,

                              ),

                              decoration: BoxDecoration(

                                color: Colors.red,

                                borderRadius: BorderRadius.circular(10),

                              ),

                              alignment: Alignment.center,

                              child: Text(

                                unreadCount > 99 ? '99+' : '$unreadCount',

                                style: const TextStyle(

                                  color: Colors.white,

                                  fontSize: 9.5,

                                  fontWeight: FontWeight.bold,

                                ),

                              ),

                            ),

                          ),

                      ],

                    ),

                  );

                },

              );

            },

          ),

        ],

      ),

      body: SafeArea(

        child: Column(

          children: [

            // Bannière et contenu partagent une seule zone défilante.
            // Cela évite le débordement vertical en mode paysage.
            Expanded(

              child: RefreshIndicator(

                color: primaryDarkGreen,

                backgroundColor: primaryGold,

                onRefresh: _handleRefresh,

                child: SingleChildScrollView(

                  physics: const AlwaysScrollableScrollPhysics(),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

  const TopSponsoredBanner(),
  const SizedBox(height: 4),

            // -------------------------------------------------

            // NEARBY / RADAR

            // -------------------------------------------------

            InkWell(

              onTap: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (context) => const NearbyScreen(),

                  ),

                );

              },

              child: Container(

                width: double.infinity,

                padding: const EdgeInsets.symmetric(

                  horizontal: 16,

                  vertical: 10,

                ),

                color: cardGreen,

                child: Row(

                  children: [

                    const Icon(

                      Icons.near_me,

                      color: primaryGold,

                      size: 18,

                    ),

                    const SizedBox(width: 8),

                    Expanded(

                      child: Text(

                        '${getTxt('Nearby')} • $userLocation',

                        style: const TextStyle(

                          color: Colors.white70,

                          fontSize: 12,

                        ),

                        overflow: TextOverflow.ellipsis,

                      ),

                    ),

                    Container(

                      padding: const EdgeInsets.symmetric(

                        horizontal: 8,

                        vertical: 2,

                      ),

                      decoration: BoxDecoration(

                        color: primaryGold,

                        borderRadius: BorderRadius.circular(6),

                      ),

                      child: const Text(

                        'Radar 📍',

                        style: TextStyle(

                          color: primaryDarkGreen,

                          fontWeight: FontWeight.bold,

                          fontSize: 10,

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ),

            const SizedBox(height: 4),

                      _homeSearch(),

                      _quickSuggestions(),

// -------------------------------------------------

// SPONSORED BANNER

// -------------------------------------------------

                      // -------------------------------------------------

// OFFICIAL UPDATES

// -------------------------------------------------

                      const AdminUpdatesFeed(),

                      const SizedBox(height: 4),

                      // -------------------------------------------------

                      // CATEGORIES

                      // -------------------------------------------------



                      // -------------------------------------------------

                      _homeSectionTitle(

                          Icons.star_rounded,

                          'Nouveautés près de vous',

                          'Découvrez les dernières publications sur Euro Habesha.',

                          onTap: _openDiscoverHome,

                        ),

                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(

                        stream: FirebaseFirestore.instance

                            .collection('publicFeed')

                            .limit(30)

                            .snapshots(),

                        builder: (context, snapshot) {

                          if (snapshot.connectionState ==

                              ConnectionState.waiting) {

                            return const SizedBox(

                              height: 110,

                              child: Center(

                                child: CircularProgressIndicator(

                                  color: primaryGold,

                                ),

                              ),

                            );

                          }

                          if (snapshot.hasError) {

                            return const SizedBox(

                              height: 55,

                              child: Center(

                                child: Text(

                                  'Unable to load updates.',

                                  style: TextStyle(color: Colors.white70),

                                ),

                              ),

                            );

                          }

                          final updates =

                              (snapshot.data?.docs ?? []).where((doc) {

                            final data = doc.data();

                            return (data['status'] ?? '')

                                    .toString()

                                    .toLowerCase() ==

                                'published';

                          }).toList();

                          updates.sort((a, b) {

                            int score(Map<String, dynamic> data) {

                              final badgeData = data['verificationBadge'];

                              final badge = badgeData is Map

                                  ? Map<String, dynamic>.from(badgeData)

                                  : <String, dynamic>{};

                              final badgeTitle = (badge['title'] ?? '')

                                  .toString()

                                  .toLowerCase();

                              final tier = (data['subscriptionTier'] ?? '')

                                  .toString()

                                  .toLowerCase();

                              final publishedAt =

                                  data['publishedAt'] ?? data['createdAt'];

                              final timestamp = publishedAt is Timestamp

                                  ? publishedAt.millisecondsSinceEpoch ~/ 100000

                                  : 0;

                              final rating =

                                  (data['rating'] as num?)?.toDouble() ?? 0;

                              final reviewCount =

                                  (data['reviewCount'] as num?)?.toInt() ?? 0;

                              final isVip = badgeTitle.contains('vip') ||

                                  tier.contains('vip');

                              final isPro = badgeTitle.contains('pro') ||

                                  tier.contains('pro');

                              final isSilver = badgeTitle.contains('silver') ||

                                  tier.contains('silver');

                              final isVerified = data['isVerified'] == true ||

                                  data['verificationStatus'] == 'approved' ||

                                  badgeTitle.isNotEmpty;

                              return (data['isDemo'] == true ? -20000000 : 0) +

                                  (isVip ? 12000000 : 0) +

                                  (isPro ? 8000000 : 0) +

                                  (isSilver ? 6000000 : 0) +

                                  (isVerified ? 5000000 : 0) +

                                  (rating * 1000).round() +

                                  reviewCount +

                                  timestamp;

                            }

                            return score(b.data()).compareTo(score(a.data()));

                          });

                          if (updates.isEmpty) {

                            return const SizedBox(

                              height: 58,

                              child: Center(

                                child: Text(

                                  'Aucune mise à jour disponible.',

                                  style: TextStyle(color: Colors.white54),

                                ),

                              ),

                            );

                          }

                          return _HomeDiscoveryCarousels(
                            items: updates.map((doc) => doc.data()).toList(),
                            onOpen: _handleUpdateTap,
                          );

                        },

                      ),

                      _eventPreviewSection(),

                      _offersSection(),

                      const SizedBox(height: 18),

                      const SizedBox(height: 18),

                    ],

                  ),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

  Widget _buildSideDrawer(

    BuildContext context,

    Color bgColor,

    Color goldColor,

  ) {

    return Drawer(

      backgroundColor: bgColor,

      child: ListView(

        padding: EdgeInsets.zero,

        children: [

          DrawerHeader(

            decoration: const BoxDecoration(

              color: Color(0xFF004D40),

            ),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisAlignment: MainAxisAlignment.end,

              children: [

                Image.asset(

                  'assets/images/euro_habesha_logo.png',

                  height: 60,

                  errorBuilder: (c, e, s) => Icon(

                    Icons.public,

                    size: 60,

                    color: goldColor,

                  ),

                ),

                const SizedBox(height: 4),

                Text(

                  'Euro Habesha',

                  style: TextStyle(

                    color: goldColor,

                    fontSize: 18,

                    fontWeight: FontWeight.bold,

                  ),

                ),

                const Text(

                  'Connect. Discover. Grow.',

                  style: TextStyle(

                    color: Colors.white70,

                    fontSize: 12,

                  ),

                ),

              ],

            ),

          ),

          _buildDrawerItem(

            const Icon(

              Icons.near_me,

              color: primaryGold,

            ),

            getTxt('Nearby'),

            () {

              Navigator.pop(context);

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => const NearbyScreen(),

                ),

              );

            },

            goldColor,

          ),

          _buildDrawerItem(

            const Icon(

              Icons.work,

              color: primaryGold,

            ),

            getTxt('Jobs'),

            () {

              Navigator.pop(context);

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => const JobsScreen(),

                ),

              );

            },

            goldColor,

          ),

          _buildDrawerItem(

            const Icon(

              Icons.storefront,

              color: primaryGold,

            ),

            getTxt('Businesses'),

            () {

              Navigator.pop(context);

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => const BusinessDirectoryScreen(),

                ),

              );

            },

            goldColor,

          ),

          _buildDrawerItem(

            const Icon(

              Icons.shopping_cart,

              color: primaryGold,

            ),

            getTxt('Market'),

            () {

              Navigator.pop(context);

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => const MarketplaceScreen(),

                ),

              );

            },

            goldColor,

          ),

          _buildDrawerItem(

            const Icon(

              Icons.verified_user,

              color: primaryGold,

            ),

            getTxt('Pros'),

            () {

              Navigator.pop(context);

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => const ProfessionalsScreen(),

                ),

              );

            },

            goldColor,

          ),

          _buildDrawerItem(

            const Icon(

              Icons.event,

              color: primaryGold,

            ),

            getTxt('Events'),

            () {

              Navigator.pop(context);

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => const EventsScreen(),

                ),

              );

            },

            goldColor,

          ),

          _buildDrawerItem(

            const Icon(

              Icons.groups,

              color: primaryGold,

            ),

            getTxt('Habesha Connect'),

            () {

              Navigator.pop(context);

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => const HabeshaConnectScreen(),

                ),

              );

            },

            goldColor,

          ),

          const Divider(color: Colors.white24),

          if (AppSession.isSuperAdmin || AppSession.roles.isNotEmpty)

            _buildDrawerItem(

              Icon(

                Icons.admin_panel_settings,

                color: goldColor,

              ),

              AppSession.isSuperAdmin

                  ? getTxt('Admin Control Panel')

                  : getTxt('My Admin Panel'),

              () {

                Navigator.pop(context);

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (context) => const AdminPanelScreen(),

                  ),

                );

              },

              goldColor,

            ),

          _buildDrawerItem(

            const Icon(

              Icons.info_outline,

              color: primaryGold,

            ),

            getTxt('About Euro Habesha'),

            () {

              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutEuroHabeshaScreen(),
                ),
              );

            },

            goldColor,

          ),

        ],

      ),

    );

  }

  // =============================================================

  // DRAWER ITEM

  // =============================================================

  Widget _buildDrawerItem(

    Widget iconWidget,

    String title,

    VoidCallback onTap,

    Color goldColor,

  ) {

    return ListTile(

      leading: iconWidget,

      title: Text(

        title,

        style: const TextStyle(

          color: Colors.white,

          fontWeight: FontWeight.w500,

        ),

      ),

      onTap: onTap,

    );

  }


}


// Deux carrousels de découvertes. Utilise exclusivement les documents publiés
// déjà chargés par HomeScreen, sans nouvelle collection ni données fictives.
class _HomeDiscoveryCarousels extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Future<void> Function(Map<String, dynamic>) onOpen;

  const _HomeDiscoveryCarousels({required this.items, required this.onOpen});

  @override
  State<_HomeDiscoveryCarousels> createState() => _HomeDiscoveryCarouselsState();
}

class _HomeDiscoveryCarouselsState extends State<_HomeDiscoveryCarousels> {
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF004D40);
  final ScrollController _top = ScrollController();
  final ScrollController _bottom = ScrollController();
  Timer? _ticker;
  bool _paused = false;
  final Map<String, Map<String, dynamic>> _mediaProfiles = {};
  final Map<String,
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _mediaSubscriptions = {};

  // Partage une seule lecture par fiche entre toutes les cartes du carrousel.
  // Le publicFeed reste la source des annonces et de leur navigation.
  String? _mediaPath(dynamic collection, dynamic id) {
    const allowed = {
      'businessSubmissions', 'jobSubmissions', 'businesses', 'jobs',
    };
    if (collection is! String || !allowed.contains(collection) ||
        id is! String || id.trim().isEmpty || id.contains('/')) {
      return null;
    }
    return '$collection/${id.trim()}';
  }

  String? _feedProfilePath(Map<String, dynamic> item) =>
      _mediaPath(item['sourceCollection'], item['sourceId']);

  String? _originalProfilePath(Map<String, dynamic> data) {
    for (final pair in const [
      ['bookingSourceCollection', 'bookingBusinessId'],
      ['sourceCollection', 'sourceId'],
      ['roomLayoutSourceCollection', 'roomLayoutBusinessId'],
      ['sourceCollection', 'sourceBusinessId'],
      ['sourceCollection', 'sourceSubmissionId'],
    ]) {
      final collection = data[pair[0]];
      if (collection != 'businessSubmissions' &&
          collection != 'jobSubmissions') {
        continue;
      }
      final path = _mediaPath(collection, data[pair[1]]);
      if (path != null) return path;
    }
    return null;
  }

  void _syncMediaSubscriptions() {
    final wanted = <String>{};
    for (final item in widget.items) {
      final primary = _feedProfilePath(item);
      final directOriginal = _originalProfilePath(item);
      if (primary != null) {
        wanted.add(primary);
        final profile = _mediaProfiles[primary];
        if (profile != null) {
          final original = _originalProfilePath(profile);
          if (original != null) wanted.add(original);
        }
      }
      if (directOriginal != null) wanted.add(directOriginal);
    }
    for (final path in _mediaSubscriptions.keys.toList()) {
      if (!wanted.contains(path)) {
        unawaited(_mediaSubscriptions.remove(path)!.cancel());
        _mediaProfiles.remove(path);
      }
    }
    for (final path in wanted) {
      if (_mediaSubscriptions.containsKey(path)) continue;
      _mediaSubscriptions[path] = FirebaseFirestore.instance
          .doc(path).snapshots().listen((snapshot) {
        if (!mounted || !_mediaSubscriptions.containsKey(path)) return;
        setState(() {
          final data = snapshot.data();
          if (data == null) {
            _mediaProfiles.remove(path);
          } else {
            _mediaProfiles[path] = data;
          }
        });
        _syncMediaSubscriptions();
      }, onError: (Object error) {
        // Conserve les images du flux si la fiche est inaccessible.
        if (!mounted || !_mediaSubscriptions.containsKey(path)) return;
        setState(() => _mediaProfiles.remove(path));
        _syncMediaSubscriptions();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _HomeDiscoveryCarousels oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMediaSubscriptions();
  }

  @override
  void initState() {
    super.initState();
    _syncMediaSubscriptions();
    _ticker = Timer.periodic(const Duration(milliseconds: 35), (_) {
      if (!mounted || _paused) return;
      _advance(_top, 0.55);
      _advance(_bottom, 0.30);
    });
  }

  void _advance(ScrollController controller, double pixels) {
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.maxScrollExtent <= 0) return;
    final next = position.pixels + pixels;
    controller.jumpTo(next >= position.maxScrollExtent ? 0 : next);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final subscription in _mediaSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    _mediaSubscriptions.clear();
    _mediaProfiles.clear();
    _top.dispose();
    _bottom.dispose();
    super.dispose();
  }

  String _text(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  List<String> _imageCandidates(Map<String, dynamic> item,
      {required bool preferLogo}) {
    final urls = <String>{};
    void addUrl(dynamic value) {
      if (value is! String) return;
      final text = value.trim();
      final uri = Uri.tryParse(text);
      if (uri != null && uri.host.isNotEmpty &&
          (uri.scheme == 'https' || uri.scheme == 'http')) {
        urls.add(text);
      }
    }

    void addMedia(dynamic value) {
      if (value is Map) {
        for (final key in const [
          'url', 'downloadUrl', 'imageUrl', 'photoUrl', 'src',
        ]) {
          addUrl(value[key]);
        }
      } else {
        addUrl(value);
      }
    }

    void addRecord(Map<dynamic, dynamic> record) {
      final keys = preferLogo
          ? const [
              'logoUrl', 'businessLogoUrl', 'imageUrl', 'photoUrl', 'image',
              'coverUrl', 'coverImageUrl',
            ]
          : const [
              'coverUrl', 'coverImageUrl', 'imageUrl', 'photoUrl', 'image',
              'logoUrl', 'businessLogoUrl',
            ];
      for (final key in keys) {
        addMedia(record[key]);
      }
      for (final key in const [
        'gallery', 'imageUrls', 'photoUrls', 'photos', 'mediaUrls',
      ]) {
        final values = record[key];
        if (values is List) {
          for (final value in values) {
            addMedia(value);
          }
        }
      }
    }

    final paths = <String>{};
    final primary = _feedProfilePath(item);
    final profile = primary == null ? null : _mediaProfiles[primary];
    final linked = profile == null ? null : _originalProfilePath(profile);
    final original = _originalProfilePath(item);
    if (linked != null) paths.add(linked);
    if (original != null) paths.add(original);
    if (primary != null) paths.add(primary);
    for (final path in paths) {
      final record = _mediaProfiles[path];
      if (record == null) continue;
      addRecord(record);
      final fields = record['fields'];
      if (fields is Map) addRecord(fields);
    }
    addRecord(item);
    final fields = item['fields'];
    if (fields is Map) addRecord(fields);
    return urls.take(16).toList();
  }

  Widget _networkPhoto(List<String> urls, Widget fallback, [int index = 0]) {
    if (index >= urls.length) return fallback;
    return Image.network(
      urls[index],
      key: ValueKey(urls[index]),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _networkPhoto(urls, fallback, index + 1),
    );
  }

  String _category(Map<String, dynamic> item) =>
      _text(item, const ['category', 'type', 'sourceCollection']).toUpperCase();

  IconData _icon(Map<String, dynamic> item) {
    final category = _category(item).toLowerCase();
    if (category.contains('job') || category.contains('emploi')) return Icons.work_outline;
    if (category.contains('event') || category.contains('événement')) return Icons.event_outlined;
    if (category.contains('market') || category.contains('marché')) return Icons.shopping_bag_outlined;
    if (category.contains('restaurant') || category.contains('food')) return Icons.restaurant_outlined;
    if (category.contains('business') || category.contains('commerce')) return Icons.storefront_outlined;
    if (category.contains('pro')) return Icons.badge_outlined;
    if (category.contains('habesha') || category.contains('connect')) return Icons.groups_outlined;
    return Icons.public;
  }

  Widget _photo(Map<String, dynamic> item) {
    return _networkPhoto(
      _imageCandidates(item, preferLogo: false),
      Center(child: Icon(_icon(item), color: _gold, size: 44)),
    );
  }

  Widget _rectangular(Map<String, dynamic> item) {
    final title = _text(item, const ['title', 'name']);
    final city = _text(item, const ['city', 'location', 'subtitle']);
    return InkWell(
      onTap: () => widget.onOpen(item),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _green, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold.withValues(alpha: .45)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 90, width: double.infinity, child: _photo(item)),
          Padding(
            padding: const EdgeInsets.all(7),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title.isEmpty ? 'Euro Habesha' : title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 3),
              Text(_category(item), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
              if (city.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(city, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  // Palette douce réservée aux icônes rondes « À découvrir aussi ».
  static const Color _discoverIcon = Color(0xFFD5BD8A);
  static const Color _discoverBorder = Color(0xFFC5AA72);
  static const Color _discoverBackground = Color(0xFF103F35);

  Widget _circularPhoto(Map<String, dynamic> item) {
    return _networkPhoto(
      _imageCandidates(item, preferLogo: true),
      Center(child: Icon(_icon(item), color: _discoverIcon, size: 35)),
    );
  }

  Widget _circular(Map<String, dynamic> item) {
    final title = _text(item, const ['title', 'name']);
    final city = _text(item, const ['city', 'location']);
    return InkWell(
      onTap: () => widget.onOpen(item),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 87,
        child: Column(children: [
          Container(
            width: 71,
            height: 71,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _discoverBackground,
              border: Border.all(color: _discoverBorder, width: 1.5),
            ),
            child: _circularPhoto(item),
          ),
          const SizedBox(height: 4),
          Text(title.isEmpty ? 'Euro Habesha' : title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _discoverIcon, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(_category(item), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 9)),
          if (city.isNotEmpty)
            Text(city, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    // Les mêmes annonces réelles sont réparties entre les deux lignes.
    // Une annonce unique reste visible dans les deux styles pour éviter un carrousel vide.
    final topItems = widget.items.length == 1 ? widget.items : widget.items.asMap().entries
        .where((entry) => entry.key.isEven).map((entry) => entry.value).toList();
    final bottomItems = widget.items.length == 1 ? widget.items : widget.items.asMap().entries
        .where((entry) => entry.key.isOdd).map((entry) => entry.value).toList();
    return Listener(
      onPointerDown: (_) => _paused = true,
      onPointerUp: (_) => _paused = false,
      onPointerCancel: (_) => _paused = false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 12, 6),
          child: Text('Annonces récentes', style: TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 169,
          child: ListView.builder(
            controller: _top, scrollDirection: Axis.horizontal,
            itemCount: topItems.length > 1 ? topItems.length * 20 : topItems.length,
            itemBuilder: (_, index) => _rectangular(topItems[index % topItems.length]),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 12, 12),
          child: Text('À découvrir aussi', style: TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 84 + MediaQuery.textScalerOf(context).scale(10) * 1.6 +
              MediaQuery.textScalerOf(context).scale(9) * 3.2,
          child: ListView.builder(controller: _bottom, scrollDirection: Axis.horizontal, reverse: true,
            itemCount: bottomItems.length > 1 ? bottomItems.length * 20 : bottomItems.length,
            itemBuilder: (_, index) => _circular(bottomItems[index % bottomItems.length]),
          ),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }
}
