import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/providers/user_provider.dart';
import '../../auth.dart';
import '../auth/auth_page.dart';
import 'package:lottie/lottie.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final _usernameController = TextEditingController();
  bool _isEditing = false;

  Future<void> signOut() async {
    await Auth().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
    );
  }

  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.uid)
        .set({'username': newUsername}, SetOptions(merge: true));

    setState(() => _isEditing = false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);

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
            style: GoogleFonts.montserrat(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          // Username display/edit
          appUserAsync.when(
            data: (appUser) {
              final username = appUser?.username ??
                  currentUser.email!.split('@')[0];
              if (!_isEditing) {
                _usernameController.text = username;
              }
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: _isEditing
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _usernameController,
                              style: GoogleFonts.montserrat(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.green),
                            onPressed: _saveUsername,
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey),
                            onPressed: () =>
                                setState(() => _isEditing = false),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            username,
                            style: GoogleFonts.montserrat(
                                fontSize: 22, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.grey, size: 20),
                            onPressed: () =>
                                setState(() => _isEditing = true),
                          ),
                        ],
                      ),
              );
            },
            loading: () => CircularProgressIndicator(),
            error: (e, _) => Text('Error loading profile'),
          ),
          SizedBox(height: 40),
          GestureDetector(
            onTap: signOut,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10),
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
