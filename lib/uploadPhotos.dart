import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/home_page.dart';
import 'package:lottie/lottie.dart';

class UploadPhotos extends StatefulWidget {
  const UploadPhotos({super.key});

  @override
  State<UploadPhotos> createState() => _UploadPhotosState();
}

class _UploadPhotosState extends State<UploadPhotos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: MaterialButton(
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => Home()));
          },
          child: Row(
            children: const [
              Icon(Icons.arrow_circle_left_outlined,
                  color: Colors.white, size: 18),
              Text(
                " Back",
                style: TextStyle(
                  fontSize: 15,
                  color: Color.fromARGB(255, 251, 251, 251),
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 100,
        title: Image.asset("assets/gemini-icon-transparent.png",
            color: Colors.white, fit: BoxFit.contain, height: 50),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Lottie.network(
              'https://assets8.lottiefiles.com/packages/lf20_0zv8teye.json',
              height: 200,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Coming Soon...',
            style: TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
