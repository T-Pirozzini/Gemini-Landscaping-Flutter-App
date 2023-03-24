import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth.dart';
import 'auth_page.dart';
import 'package:lottie/lottie.dart';

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
          Center(
            child: Lottie.network(
              'https://assets1.lottiefiles.com/packages/lf20_aL00NpAjvC.json',
              height: 200,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'You are signed in as:',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 10),
          Text(
            '${currentUser.email}',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 50),
          GestureDetector(
            onTap: signOut,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 10,
              ),
              margin: EdgeInsets.symmetric(horizontal: 80),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 31, 182, 77),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign Out ',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Icon(Icons.logout_outlined, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
