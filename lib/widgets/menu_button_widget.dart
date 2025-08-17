import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const MenuButton({Key? key, required this.scaffoldKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu,
              color: Colors.black,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}