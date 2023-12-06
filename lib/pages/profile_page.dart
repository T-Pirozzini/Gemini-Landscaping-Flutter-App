import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Profile",
            style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w500)),
        toolbarHeight: 25,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        centerTitle: true,
      ),
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
            style: GoogleFonts.montserrat(fontSize: 24),
          ),
          SizedBox(height: 10),
          Text(
            '${currentUser.email}',
            style: GoogleFonts.montserrat(fontSize: 18),
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
                    style: GoogleFonts.montserrat(
                        fontSize: 18, color: Colors.white),
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
