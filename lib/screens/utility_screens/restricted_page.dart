import 'package:flutter/material.dart';

class RestrictedPage extends StatelessWidget {
  const RestrictedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock, size: 100.0, color: Colors.grey[500]),
          Center(
            child: Text('You do not have permission to view this page.',
                style: TextStyle(fontSize: 14.0, color: Colors.grey[900])),
          )
        ],
      ),
    );
  }
}
