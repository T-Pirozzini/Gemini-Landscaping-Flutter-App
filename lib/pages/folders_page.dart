import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/files_page.dart';
import 'package:google_fonts/google_fonts.dart';

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
          siteList.sort(
              (a, b) => a['info']['siteName'].compareTo(b['info']['siteName']));

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
                            ? Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Image.network(
                                  siteList[index]['info']['imageURL'],
                                  fit: BoxFit.contain,
                                  height: 40,
                                  width: 40,
                                ),
                              )
                            : Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Icon(
                                  Icons.grass_outlined,
                                  color: Colors.green,
                                  size: 40,
                                ),
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
                        trailing: Text('$reportsCount reports'),
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
