
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

const darkGreen = Color(0xFF061E12);
const gold = Color(0xFFFFD700);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

final firestore = FirebaseFirestore.instance;

firestore.useFirestoreEmulator('localhost', 8080);

firestore.settings = const Settings(
  persistenceEnabled: false,
);

  runApp(const RestaurantTestApp());
}

class RestaurantTestApp extends StatelessWidget {
  const RestaurantTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Euro Habesha Restaurant TEST',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        scaffoldBackgroundColor: darkGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
      ),
      home: const RestaurantTestScreen(),
    );
  }
}

class RestaurantTestScreen extends StatelessWidget {
  const RestaurantTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final restaurant = FirebaseFirestore.instance
        .collection('stripeTestBusinesses')
        .doc('restaurant_demo_001');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: gold,
        title: const Text('Euro Habesha • TEST'),
      ),
      body: FutureBuilder(
        future: restaurant.get(),
        builder: (context, restaurantSnapshot) {
          if (restaurantSnapshot.hasError) {
            return Center(
              child: Text(
                'Erreur Firestore TEST : ${restaurantSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!restaurantSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: gold),
            );
          }

          if (!restaurantSnapshot.data!.exists) {
            return const Center(
              child: Text('Restaurant TEST introuvable'),
            );
          }

          final restaurantName =
              restaurantSnapshot.data!.data()?['name'] ??
              'Restaurant TEST';

          return FutureBuilder(
            future: restaurant
                .collection('menuItems')
                .doc('repas_test_001')
                .get(),
            builder: (context, mealSnapshot) {
              if (mealSnapshot.hasError) {
                return Center(
                  child: Text('Erreur : ${mealSnapshot.error}'),
                );
              }

              if (!mealSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: gold),
                );
              }

              if (!mealSnapshot.data!.exists) {
                return const Center(
                  child: Text('Repas TEST introuvable'),
                );
              }

              final meal = mealSnapshot.data!.data()!;
              final price = (meal['price'] as num).toDouble();

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant,
                        size: 80,
                        color: gold,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        restaurantName.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: gold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Card(
                        color: const Color(0xFF123B28),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                meal['name'].toString(),
                                style: const TextStyle(
                                  fontSize: 21,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${price.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontSize: 26,
                                  color: gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: darkGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                        ),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Commande TEST'),
                              content: Text(
                                '1 × ${meal['name']}\n'
                                'Total : ${price.toStringAsFixed(2)} €\n\n'
                                'Simulation uniquement.\n'
                                'Aucun paiement effectué.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  child: const Text('Fermer'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Simuler la commande'),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'MODE TEST LOCAL • Aucun paiement réel',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
