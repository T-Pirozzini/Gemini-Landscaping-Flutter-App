import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/viewReport.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: MaterialButton(
          onPressed: () {
            Navigator.pop(context);
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
      body: StreamBuilder<QuerySnapshot>(
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
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(
                    report['info']['siteName'],
                    style:
                        GoogleFonts.montserrat(fontSize: 20, letterSpacing: .5),
                  ),
                  subtitle: Text(
                    report['info']['address'],
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                  trailing: Text(
                    report['info']['date'],
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                  tileColor: Colors.white,
                  textColor: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey, width: 2),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewReport(docid: reports[index]),
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
  }
}
