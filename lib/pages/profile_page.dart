import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth.dart';
import 'auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // get current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  // sign current user out
  Future<void> signOut() async {
    await Auth().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Profile Page'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: signOut,
                child: Text('Sign Out', style: TextStyle(color: Colors.black)),
              ),
              IconButton(
                onPressed: signOut,
                icon: Icon(Icons.logout_outlined, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
