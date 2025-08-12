import 'package:flutter/material.dart';

/// Simple bottom navigation bar with three icons.
/// Keeps the same API: selectedIndex + onTabSelected.
class NavbarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const NavbarWidget({Key? key, required this.selectedIndex, required this.onTabSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _navItem(Icons.home, 0),
          _navItem(Icons.search, 1),
          _navItem(Icons.person, 2),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final active = index == selectedIndex;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.all(8),
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
