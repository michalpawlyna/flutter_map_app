import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  // kolor logo: #1B4369
  static const Color _logoColor = Color(0xFF1B4369);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_transparent.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 60,
              height: 24,
              child: LoadingIndicator(
                indicatorType: Indicator.ballPulse,
                colors: [_logoColor],
                // strokeWidth przy ballPulse nie ma dużego wpływu, ale zostawiam wartość domyślną 2
                strokeWidth: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
