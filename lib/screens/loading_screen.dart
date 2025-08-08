import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
	const LoadingScreen({Key? key}) : super(key: key);

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
						const CircularProgressIndicator(),
					],
				),
			),
		);
	}
}


//TODO ALL