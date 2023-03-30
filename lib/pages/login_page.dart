import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/components/my_button.dart';
import 'package:gemini_landscaping_app/components/my_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // sign user in method
  void signUserIn() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // try sign in
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // check if the widget is still mounted before updating the state
      if (mounted) {
        // pop the loading circle
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // show error message
      if (e.code == 'user-not-found') {
        showErrorMessage('Invalid email');
      }
      // incorrect password
      else if (e.code == "wrong-password") {
        showErrorMessage('Invalid password');
      } else {
        showErrorMessage('Enter your email and password');
      }
      // check if the widget is still mounted before updating the state
      if (mounted) {
        // pop the loading circle
        Navigator.pop(context);
      }
    }
  }

// error message popup
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 44, 179, 84),
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 50,
                  ),

                  // logo
                  Image.asset(
                    'assets/gemini-icon-transparent.png',
                    height: 150,
                  ),
                  const SizedBox(height: 50),

                  // welcome back
                  Text(
                    'Welcome back! Ready to start the day?',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // email and password textfields
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),

                  // sign in button
                  MyButton(
                    text: 'Sign In',
                    // onTap: signUserIn,
                    onTap: signUserIn,
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ));
  }
}
