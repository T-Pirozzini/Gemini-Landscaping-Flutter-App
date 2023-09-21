import 'dart:typed_data';
import 'package:gemini_landscaping_app/pages/home_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class UploadPhotos extends StatefulWidget {
  const UploadPhotos({super.key});

  @override
  State<UploadPhotos> createState() => _UploadPhotosState();
}

class _UploadPhotosState extends State<UploadPhotos> {
  List<String> imageUrls = []; // List to store image URLs
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchImagesFromFirebaseStorage();
  }

  Future<void> _uploadImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Compress the image before uploading
        final Uint8List compressedImageData =
            await FlutterImageCompress.compressWithFile(
          imageFile.path,
          quality: 70, // Adjust the quality as needed (0 - 100)
        ) as Uint8List; // Explicitly cast it to Uint8List

        final Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('images/${DateTime.now()}.jpg');

        final UploadTask uploadTask =
            storageReference.putData(compressedImageData);

        await uploadTask.whenComplete(() {
          storageReference.getDownloadURL().then((imageUrl) {
            // Save the imageUrl to Firestore or use it as needed.
            print('Image URL: $imageUrl');
          });
        });

        setState(() {
          _image = imageFile; // Set the original image
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void fetchImagesFromFirebaseStorage() async {
    try {
      final ListResult result =
          await FirebaseStorage.instance.ref('images/').list();

//

      for (final Reference ref in result.items) {
        final imageUrl = await ref.getDownloadURL();
        print('Image URL: $imageUrl'); // Add this line to log the URL
        setState(() {
          imageUrls.add(imageUrl);
        });
      }
    } catch (e) {
      print('Error fetching images: $e'); // Print any errors
    }
  }

  void _showEnlargedImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context); // Close the dialog on tap
          },
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Uint8List uint8List = response.bodyBytes;
        final success = await ImageGallerySaver.saveImage(uint8List);

        if (success != null && success.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to gallery')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save image')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download image')),
        );
      }
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

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
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: _image != null
                    ? Image.file(_image!)
                    : Text('No image selected'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Upload Image'),
              ),
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
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Number of columns in the grid
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = imageUrls[index];
                return GestureDetector(
                  onTap: () {
                    _showEnlargedImage(
                        imageUrl); // Display enlarged image on tap
                  },
                  onLongPress: () {
                    _saveImage(imageUrl); // Save/download image on long press
                  },
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder: (context, url) => CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
