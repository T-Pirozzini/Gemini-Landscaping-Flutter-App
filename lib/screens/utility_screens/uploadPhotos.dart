import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UploadPhotos extends StatefulWidget {
  const UploadPhotos({super.key});

  @override
  State<UploadPhotos> createState() => _UploadPhotosState();
}

class _UploadPhotosState extends State<UploadPhotos> {
  List<Map<String, dynamic>> imageFolders = [];
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchFoldersFromFirestore();
  }

  Future<void> _uploadImage(String folderName, String documentId) async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final String imageName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Upload image to Firebase Storage
        final Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('images/$folderName/$imageName');

        final UploadTask uploadTask = storageReference.putFile(imageFile);
        await uploadTask.whenComplete(() async {
          final imageUrl = await storageReference.getDownloadURL();

          // Save image data to Firestore under the specific site document's images subcollection
          FirebaseFirestore.instance
              .collection('SiteList')
              .doc(documentId)
              .collection('images')
              .add({
            'url': imageUrl,
            'uploadDate': Timestamp.now(),
            'imageName': imageName,
          });

          print('Uploaded image URL: $imageUrl');

          // Refresh the displayed images
          fetchFoldersFromFirestore();
        });
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  void fetchFoldersFromFirestore() async {
    try {
      final folderSnapshot =
          await FirebaseFirestore.instance.collection('SiteList').get();

      List<Map<String, dynamic>> fetchedFolders = [];
      for (var folder in folderSnapshot.docs) {
        final folderData = folder.data();
        final imagesSnapshot =
            await folder.reference.collection('images').get();

        List<Map<String, dynamic>> images = [];
        for (var doc in imagesSnapshot.docs) {
          final imageData = doc.data();
          images.add(imageData);
        }

        // Sort images by uploadDate in descending order
        images.sort((a, b) => (b['uploadDate'] as Timestamp)
            .compareTo(a['uploadDate'] as Timestamp));

        fetchedFolders.add({
          'folderName': folderData["name"],
          'documentId': folder.id,
          'images': images,
        });
      }

      setState(() {
        imageFolders = fetchedFolders;
      });
    } catch (e) {
      print('Error fetching folders: $e');
    }
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      // Fetch the image bytes from the URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Get the external storage directory
        final directory = await getExternalStorageDirectory();
        final picturesDir = Directory('${directory!.path}/Pictures');
        if (!await picturesDir.exists()) {
          await picturesDir.create(recursive: true);
        }

        // Create a unique file name for the image
        final imageName =
            'downloaded_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${picturesDir.path}/$imageName';

        // Save the bytes to a file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Add to the gallery by saving to the "Pictures" directory
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to gallery: $filePath')),
        );
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      print('Error downloading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download image')),
      );
    }
  }

  void _showImageOptionsDialog(String folderName, String documentId) async {
    // Display a dialog to confirm upload location
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // title: Text('Upload an image to $folderName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Upload an image to $folderName'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadImage(folderName, documentId);
              },
              child: Text('Select Image'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text(
          "Upload Photos",
          style: GoogleFonts.montserrat(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        toolbarHeight: 25,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Text('Tap an image for enlarged view. Long press to download'),
          Expanded(
            child: ListView.builder(
              itemCount: imageFolders.length,
              itemBuilder: (context, folderIndex) {
                final folder = imageFolders[folderIndex];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    collapsedBackgroundColor: Colors.grey.shade300,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(folder['folderName']),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                          ),
                          onPressed: () => _showImageOptionsDialog(
                            folder['folderName'],
                            folder['documentId'],
                          ),
                          child: Icon(
                            Icons.add_a_photo,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      SingleChildScrollView(
                        child: Container(
                          height: 400,
                          child: GridView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                            itemCount: folder['images'].length,
                            itemBuilder: (context, imageIndex) {
                              final image = folder['images'][imageIndex];

                              // Format the uploadDate
                              final uploadDate =
                                  (image['uploadDate'] as Timestamp).toDate();
                              final formattedDate =
                                  DateFormat('dd MMM yyyy').format(uploadDate);

                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _showEnlargedImage(image['url']);
                                    },
                                    onLongPress: () {
                                      _downloadImage(image['url']);
                                    },
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      child: CachedNetworkImage(
                                        imageUrl: image['url'],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEnlargedImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }
}
