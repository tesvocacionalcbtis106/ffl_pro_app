import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/app_colors.dart';
import 'screens/player_screen.dart';
import 'screens/team_screen.dart';
import 'screens/standings_screen.dart';
import 'screens/match_screen.dart';
import 'screens/referee_screen.dart';
import 'screens/ranking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int index = 0;

  final screens = [
    const PlayerScreen(),
    const TeamScreen(),
    const StandingsScreen(),
    const MatchScreen(),
    const RefereeScreen(),
    const RankingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.guinda,
        scaffoldBackgroundColor: AppColors.negroFondo,
      ),
      home: Scaffold(
        body: screens[index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Players",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: "Teams",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: "Tabla",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_football),
              label: "Match",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports),
              label: "Árbitro",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: "Ranking",
            ),
          ],
        ),
      ),
    );
  }
}