import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/viewReport.dart';

class SiteFiles extends StatefulWidget {
  const SiteFiles({super.key, required this.siteName});

  final String siteName;

  @override
  State<SiteFiles> createState() => _SiteFilesState(siteName: siteName);
}

class _SiteFilesState extends State<SiteFiles> {
  late final String siteName;

  _SiteFilesState({required this.siteName});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white38,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('SiteReports2023')
            .where('info.siteName', isEqualTo: siteName)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text("Something went wrong");
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          print('siteName: $siteName');
          final reports = snapshot.data!.docs;
          print(reports.length);
          print('reports: $reports');

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (BuildContext context, int index) {
              final report = reports[index];
              return ListTile(
                title: Text(report['info']['siteName']),
                subtitle: Text(report['info']['address']),
                leading: Text(report['info']['date']),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewReport(docid: reports[index]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
