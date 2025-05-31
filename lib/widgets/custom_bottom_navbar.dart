import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/home_screen.dart';
import '../screens/post_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == currentIndex) return; // Don't navigate if already on that tab
            
            // Always call onTap to allow parent screen to update its state
            onTap(index);
            
            // Only handle navigation if we're not already in a screen of the same type
            switch (index) {
              case 0: // Home
                if (currentIndex != 0) {
                  _navigateWithSlideTransition(context, const HomeScreen());
                }
                break;
              case 1: // Calendar
                if (currentIndex != 1) {
                  _navigateWithSlideTransition(context, const PostScreen());
                }
                break;
              case 2: // Search (center button)
                // Navigate to search screen
                if (currentIndex != 2) {
                  _navigateWithSlideTransition(context, const SearchScreen());
                }
                break;
              case 3: // Detail
                // Navigate to the DetailScreen without a specific postId
                if (currentIndex != 3) {
                  _navigateWithSlideTransition(context, const DetailScreen());
                }
                break;
              case 4: // Profile
                // Navigate to the ProfileScreen
                if (currentIndex != 4) {
                  _navigateWithSlideTransition(context, const ProfileScreen());
                }
                break;
            }
          },
          selectedItemColor: Colors.blue,
          unselectedItemColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          backgroundColor: backgroundColor,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 30),
              activeIcon: Icon(Icons.search, size: 30),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: 'Detail',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _navigateWithSlideTransition(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Coming from right
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
} 