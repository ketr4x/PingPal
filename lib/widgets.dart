import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'screens/chats_screen.dart';
import 'screens/map_screen.dart';
import 'screens/pager_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';

Row buildLoginRow(String icon, double size) {
  return Row(
    children: [
      SvgPicture.asset('assets/logos/$icon.svg', height: size, width: size),
      SizedBox(width: 14),
      Text('Sign in ${icon == "google" ? 'with Google' : 'as a guest'}'),
    ],
  );
}

BottomNavigationBar bottomNavBar(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    items: [
      BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
      BottomNavigationBarItem(
        icon: Icon(Icons.notification_add),
        label: 'Pager',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Friends'),
      BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_circle),
        label: 'Profile',
      ),
    ],
    currentIndex: currentIndex,
    selectedItemColor: Theme.of(context).colorScheme.primary,
    unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    onTap: (index) {
      Widget page;
      switch (index) {
        case 0:
          page = ChatsScreen();
          break;
        case 1:
          page = PagerScreen();
          break;
        case 2:
          page = FriendsScreen();
          break;
        case 3:
          page = MapScreen();
          break;
        case 4:
          page = ProfileScreen();
          break;
        default:
          return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    },
  );
}
