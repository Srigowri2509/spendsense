import 'package:flutter/material.dart';
import 'home_page.dart';
import 'insights_page.dart';
import 'profile_page.dart';

class RootNav extends StatefulWidget {
  const RootNav({super.key});
  
  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int idx = 0;
  
  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const InsightsPage(),
      const ProfilePage(),
    ];
    
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}