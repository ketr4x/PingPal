import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/pager_screen.dart';
import 'screens/friends_screen.dart';

void printDebug(String text) {
  if (kDebugMode) {
    print(text);
  }
}

BottomNavigationBar bottomNavBar(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    items: [
      BottomNavigationBarItem(icon: Icon(Icons.notification_add), label: 'Pager'),
      BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Friends')
    ],
    currentIndex: currentIndex,
    onTap: (index) {
      Widget page;
      switch (index) {
        case 0:
          page = PagerScreen();
          break;
        case 1:
          page = FriendsScreen();
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