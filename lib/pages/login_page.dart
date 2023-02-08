import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/components/my_button.dart';
import 'package:gemini_landscaping_app/components/my_textfield.dart';
import 'package:gemini_landscaping_app/components/square_tile.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'auth.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  // text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // sign user in method
  void signUserIn() {}

// class _LoginState extends State<Login> {
//   String? errorMessage = '';
//   bool isLogin = true;

//   final TextEditingController _controllerEmail = TextEditingController();
//   final TextEditingController _controllerPassword = TextEditingController();

//   Future<void> signInWithEmailAndPassword() async {
//     try {
//       await Auth().signInWithEmailAndPassword(
//         email: _controllerEmail.text,
//         password: _controllerEmail.text,
//       );
//     } on FirebaseAuthException catch (e) {
//       setState(() {
//         errorMessage = e.message;
//       });
//     }
//   }

//   Future<void> createUserWithEmailAndPassword() async {
//     try {
//       await Auth().createUserWithEmailAndPassword(
//         email: _controllerEmail.text,
//         password: _controllerEmail.text,
//       );
//     } on FirebaseAuthException catch (e) {
//       setState(() {
//         errorMessage = e.message;
//       });
//     }
//   }

//   Widget _title() {
//     return const Text('Firebase Auth');
//   }

//   Widget _entryField(
//     String title,
//     TextEditingController controller,
//   ) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: title,
//       ),
//     );
//   }

//   Widget _errorMessage() {
//     return Text(errorMessage == '' ? '' : 'Hmmm ? $errorMessage');
//   }

//   Widget _submitButton() {
//     return ElevatedButton(
//       onPressed:
//           isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
//       child: Text(isLogin ? 'Login' : 'Register'),
//     );
//   }

//   Widget _loginOrRegisterButton() {
//     return TextButton(
//       onPressed: () {
//         setState(() {
//           isLogin = !isLogin;
//         });
//       },
//       child: Text(isLogin ? 'Register instead' : 'Login instead'),
//     );
//   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 50,
                ),

                // logo
                const Icon(
                  Icons.lock,
                  size: 100,
                ),
                const SizedBox(height: 50),

                // welcome back
                Text(
                  'Welcome back you\'ve been missed!',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),

                // username and password textfields
                MyTextField(
                  controller: usernameController,
                  hintText: 'Username',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                // forgot password?
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Forgot password?',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // sign in button
                MyButton(
                  onTap: signUserIn,
                ),
                const SizedBox(height: 50),

                // or continue with google or apple
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // google + apple sign in buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    // google
                    SquareTile(imagePath: 'assets/google.png'),
                    SizedBox(width: 10),
                    // apple
                    SquareTile(imagePath: 'assets/apple.png')
                  ],
                ),
                const SizedBox(height: 50),
                // not a member, register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Not a member?",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Register now",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
