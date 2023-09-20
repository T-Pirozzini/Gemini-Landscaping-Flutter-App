// import 'package:flutter/material.dart';
// import 'package:gemini_landscaping_app/pages/home_page.dart';
// import 'package:lottie/lottie.dart';
// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';

// class UploadPhotos extends StatefulWidget {
//   const UploadPhotos({super.key});

//   @override
//   State<UploadPhotos> createState() => _UploadPhotosState();
// }

// class _UploadPhotosState extends State<UploadPhotos> {
//   File? _image;
//   final picker = ImagePicker();

//   Future<void> _uploadImage() async {
//     try {
//       final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//       if (pickedFile != null) {
//         final imageFile = File(pickedFile.path);

//         final Reference storageReference = FirebaseStorage.instance
//             .ref()
//             .child('images/${DateTime.now()}.jpg');

//         final UploadTask uploadTask = storageReference.putFile(imageFile);

//         await uploadTask.whenComplete(() {
//           // Handle the image upload completion.
//           // You can get the download URL here:
//           storageReference.getDownloadURL().then((imageUrl) {
//             // Save the imageUrl to Firestore or use it as needed.
//             print('Image URL: $imageUrl');
//           });
//         });

//         setState(() {
//           _image = imageFile;
//         });
//       }
//     } catch (e) {
//       print(e.toString());
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(255, 31, 182, 77),
//         leading: MaterialButton(
//           onPressed: () {
//             Navigator.pushReplacement(
//                 context, MaterialPageRoute(builder: (_) => Home()));
//           },
//           child: Row(
//             children: const [
//               Icon(Icons.arrow_circle_left_outlined,
//                   color: Colors.white, size: 18),
//               Text(
//                 " Back",
//                 style: TextStyle(
//                   fontSize: 15,
//                   color: Color.fromARGB(255, 251, 251, 251),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         leadingWidth: 100,
//         title: Image.asset("assets/gemini-icon-transparent.png",
//             color: Colors.white, fit: BoxFit.contain, height: 50),
//         centerTitle: true,
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Center(
//             child: _image != null
//                 ? Image.file(_image!)
//                 : Text('No image selected'),
//           ),
//           SizedBox(height: 10),
//           ElevatedButton(
//             onPressed: _uploadImage,
//             child: Text('Upload Image'),
//           ),
//           Center(
//             child: Lottie.network(
//               'https://assets8.lottiefiles.com/packages/lf20_0zv8teye.json',
//               height: 200,
//             ),
//           ),
//           SizedBox(height: 10),
//           Text(
//             'Coming Soon...',
//             style: TextStyle(fontSize: 24),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/home_page.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UploadPhotos extends StatefulWidget {
  const UploadPhotos({super.key});

  @override
  State<UploadPhotos> createState() => _UploadPhotosState();
}

class _UploadPhotosState extends State<UploadPhotos> {
  File? _image;
  final picker = ImagePicker();

  Future<void> _uploadImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);

        final Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('images/${DateTime.now()}.jpg');

        final UploadTask uploadTask = storageReference.putFile(imageFile);

        await uploadTask.whenComplete(() {
          // Handle the image upload completion.
          // You can get the download URL here:
          storageReference.getDownloadURL().then((imageUrl) {
            // Save the imageUrl to Firestore or use it as needed.
            print('Image URL: $imageUrl');
          });
        });

        setState(() {
          _image = imageFile;
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _showSavedImagesDialog(BuildContext context) async {
    try {
      final List<String> savedImageUrls = await _getSavedImageUrls();

      if (savedImageUrls.isNotEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Saved Images'),
              content: Container(
                width: double.maxFinite,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Adjust the number of columns as needed
                  ),
                  itemCount: savedImageUrls.length,
                  itemBuilder: (BuildContext context, int index) {
                    final imageUrl = savedImageUrls[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(imageUrl),
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('No Saved Images'),
              content: Text('There are no saved images to display.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error fetching saved images: $e');
    }
  }

  Future<List<String>> _getSavedImageUrls() async {
    final List<String> savedImageUrls = [];

    try {
      // Replace 'images/' with the actual path to your images in Firebase Storage.
      final ListResult result =
          await FirebaseStorage.instance.ref('images/').listAll();

      for (final Reference ref in result.items) {
        final String downloadUrl = await ref.getDownloadURL();
        savedImageUrls.add(downloadUrl);
      }
    } catch (e) {
      print('Error fetching image URLs: $e');
    }

    return savedImageUrls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... (rest of your widget code)
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ... (your existing UI elements)

          ElevatedButton(
            onPressed: _uploadImage,
            child: Text('Upload Image'),
          ),

          // Button to show the saved images dialog
          TextButton(
            onPressed: () {
              _showSavedImagesDialog(context);
            },
            child: Text('Show Saved Images'),
          ),

          // ... (your remaining UI elements)
        ],
      ),
    );
  }
}
