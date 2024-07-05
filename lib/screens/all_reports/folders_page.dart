import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/screens/all_reports/files_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SiteFolders extends StatefulWidget {
  const SiteFolders({super.key});

  @override
  State<SiteFolders> createState() => _SiteFoldersState();
}

class _SiteFoldersState extends State<SiteFolders> {
  final Stream<QuerySnapshot> _siteStream =
      FirebaseFirestore.instance.collectionGroup('SiteList').snapshots();

  Future<int> getSiteCount(String siteName) async {
    try {
      final QuerySnapshot siteCount = await FirebaseFirestore.instance
          .collectionGroup('SiteReports2023')
          .where('info.siteName', isEqualTo: siteName)
          .get();
      return siteCount.docs.length;
    } catch (e) {
      print("Error getting site count: $e");
      return 0;
    }
  }

  Future<String> getImageUrl(String management) async {
    final List<String> imageExtensions = ['png', 'jpg', 'jpeg'];
    String downloadUrl = '';

    for (String extension in imageExtensions) {
      try {
        downloadUrl = await FirebaseStorage.instance
            .ref('company_logos/$management.$extension')
            .getDownloadURL();
        break;
      } catch (e) {
        continue;
      }
    }

    return downloadUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("Site Reports",
            style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w500)),
        toolbarHeight: 25,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _siteStream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return const Text("something is wrong");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          List<QueryDocumentSnapshot> siteList = snapshot.data!.docs;
          siteList.sort((a, b) => a['name'].compareTo(b['name']));

          return Container(
            child: ListView.builder(
              itemCount: siteList.length,
              itemBuilder: (BuildContext context, int index) {
                final siteName = siteList[index]['name'];
                final management = siteList[index]['management'];
                final firstIndex =
                    siteList.indexWhere((doc) => doc['name'] == siteName);

                if (index != firstIndex) {
                  return SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: FutureBuilder<String>(
                      future: getImageUrl(management),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Icon(Icons.grass_outlined,
                              color: Colors.green, size: 40);
                        }
                        return Image.network(
                          snapshot.data!,
                          fit: BoxFit.contain,
                          height: 40,
                          width: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.grass_outlined,
                                color: Colors.green, size: 40);
                          },
                        );
                      },
                    ),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '$siteName',
                        style: GoogleFonts.montserrat(
                            fontSize: 20, letterSpacing: .5),
                      ),
                    ),
                    trailing: FutureBuilder<int>(
                      future: getSiteCount(siteName),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error');
                        }
                        return Text('${snapshot.data} reports');
                      },
                    ),
                    tileColor: Colors.grey[800],
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SiteFiles(
                            siteName: siteName,
                            management: management,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
