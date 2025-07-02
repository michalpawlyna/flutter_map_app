import 'package:flutter/material.dart';
import '../screens/map_screen.dart';
import '../screens/profile_screen.dart';

/// Simple bottom navigation bar with three icons.
class NavbarWidget extends StatelessWidget {
  final int selectedIndex;
  
  const NavbarWidget({Key? key, this.selectedIndex = 0}) : super(key: key);
  
  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, Icons.home, 0),
            _navItem(context, Icons.search, 1),
            _navItem(context, Icons.person, 2),
          ],
        ),
      ),
    );
  }
  
  Widget _navItem(BuildContext context, IconData icon, int index) {
    final active = index == selectedIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: active
            ? BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Icon(
          icon,
          color: Colors.black,
          size: 24,
        ),
      ),
    );
  }
}