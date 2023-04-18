import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/files_page.dart';
import 'package:gemini_landscaping_app/pages/viewReport.dart';

class SiteFolders extends StatefulWidget {
  const SiteFolders({super.key});

  @override
  State<SiteFolders> createState() => _SiteFoldersState();
}

class _SiteFoldersState extends State<SiteFolders> {
  final Stream<QuerySnapshot> _siteStream =
      FirebaseFirestore.instance.collectionGroup('siteList').snapshots();  

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
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
        List<QueryDocumentSnapshot> sites = snapshot.data!.docs;

        return Container(
          child: ListView.builder(
            itemCount: sites.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text('${sites[index]['name']}'),
                trailing: Text('${sites[index]['quantity']} reports'),
                onTap: () {                  
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SiteFiles(siteName: sites[index]['name']),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
