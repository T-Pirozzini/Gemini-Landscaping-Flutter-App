import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';

class UploadPhotos extends StatefulWidget {
  const UploadPhotos({super.key});

  @override
  State<UploadPhotos> createState() => _UploadPhotosState();
}

class _UploadPhotosState extends State<UploadPhotos> {
  List<String> imageUrls = []; // List to store image URLs
  File? image;
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
        // final Uint8List compressedImageData =
        //     await FlutterImageCompress.compressWithFile(
        //   imageFile.path,
        //   quality: 70,
        // ) as Uint8List;

        final Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('images/${DateTime.now()}.jpg');

        // final UploadTask uploadTask =
        //     storageReference.putData(compressedImageData);

        // await uploadTask.whenComplete(() async {
        //   final imageUrl = await storageReference.getDownloadURL();
        //   // Save the imageUrl to Firestore or use it as needed.
        //   print('Image URL: $imageUrl');

        //   // Update the imageUrls list with the new image URL
        //   setState(() {
        //     imageUrls.add(imageUrl);
        //   });
        // });

        setState(() {
          image = imageFile;
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

      for (final Reference ref in result.items) {
        final imageUrl = await ref.getDownloadURL();
        print('Image URL: $imageUrl');
        setState(() {
          imageUrls.add(imageUrl);
        });
      }
    } catch (e) {
      print('Error fetching images: $e');
    }
  }

  void _showEnlargedImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  // Future<void> _saveImage(String imageUrl) async {
  //   try {
  //     final response = await http.get(Uri.parse(imageUrl));
  //     if (response.statusCode == 200) {
  //       final Uint8List uint8List = response.bodyBytes;
  //       // final success = await ImageGallerySaver.saveImage(uint8List);

  //       if (success != null && success.isNotEmpty) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Image saved to gallery')),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Failed to save image')),
  //         );
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to download image')),
  //       );
  //     }
  //   } catch (e) {
  //     print(e.toString());
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("Upload Photos",
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
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Upload Image'),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromARGB(255, 31, 182, 77)),
                ),
              ),
              SizedBox(height: 10),
              Text('Hint: long press to save image',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            ],
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = imageUrls[index];
                return Container(
                  padding: EdgeInsets.all(2.0),
                  margin: EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      _showEnlargedImage(imageUrl);
                    },
                    onLongPress: () {
                      // _saveImage(imageUrl);
                    },
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                    ),
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
