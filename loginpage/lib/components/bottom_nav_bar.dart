import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:loginpage/pages/home.dart';
import 'package:loginpage/pages/freunde_page.dart';
import 'package:loginpage/pages/alone_page.dart';
import 'package:loginpage/pages/search_page.dart';
import 'package:loginpage/pages/upload_page.dart';

class BottomNavigationBarWidget extends StatefulWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  State<BottomNavigationBarWidget> createState() => _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    MyFriends(),
    MyUpload(), // "Hochladen"-Seite ist aktuell leer
    MySearch(),
    MyProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      

     
     
      // bottomNavigationBar
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: GNav(
            backgroundColor: Theme.of(context).colorScheme.surface,
            gap: 8,
            padding: const EdgeInsets.all(16),
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            tabs: [
              GButton(
                icon: Icons.home,
                text: 'Home',
                iconColor: Theme.of(context).colorScheme.inversePrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              GButton(
                icon: Icons.group,
                text: 'Freunde',
                iconColor: Theme.of(context).colorScheme.inversePrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              GButton(
                icon: Icons.add,
                text: 'Hochladen',
                iconColor: Theme.of(context).colorScheme.inversePrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              GButton(
                icon: Icons.search,
                text: 'Finden',
                iconColor: Theme.of(context).colorScheme.inversePrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              GButton(
                icon: Icons.person,
                text: 'Alone',
                iconColor: Theme.of(context).colorScheme.inversePrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
