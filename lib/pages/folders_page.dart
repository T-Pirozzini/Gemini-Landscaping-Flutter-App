import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/files_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

class SiteFolders extends StatefulWidget {
  const SiteFolders({super.key});

  @override
  State<SiteFolders> createState() => _SiteFoldersState();
}

class _SiteFoldersState extends State<SiteFolders> {
  final Stream<QuerySnapshot> _siteStream =
      FirebaseFirestore.instance.collectionGroup('SiteReports2023').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
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

          return Container(
            child: ListView.builder(
              itemCount: siteList.length,
              itemBuilder: (BuildContext context, int index) {
                final siteName = siteList[index]['info']['siteName'];
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('SiteReports2023')
                      .where('info.siteName', isEqualTo: siteName)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    final reportsCount = snapshot.data!.size;

                    // Check if current index matches the index of first occurrence of site name in the list
                    final firstIndex = siteList.indexWhere(
                        (doc) => doc['info']['siteName'] == siteName);
                    if (index != firstIndex) {
                      return SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: siteList[index]['info']['imageURL'] != null
                            ? Image.network(siteList[index]['info']['imageURL'],
                                fit: BoxFit.cover, height: 40, width: 40)
                            : Icon(Icons.grass_outlined, color: Colors.green),
                        title: Text(
                          '$siteName',
                          style: GoogleFonts.montserrat(
                              fontSize: 20, letterSpacing: .5),
                        ),
                        trailing: Text('$reportsCount reports'),
                        tileColor: Colors.grey[850],
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
                                siteName: siteList[index]['info']['siteName'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
