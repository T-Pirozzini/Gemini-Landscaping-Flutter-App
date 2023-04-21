import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/view_report_page.dart';
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
          final reports = snapshot.data!.docs;
          reports
              .sort((a, b) => b['info']['date'].compareTo(a['info']['date']));
          final report = reports.isNotEmpty ? reports.first : null;
          final imageURL = (report?.data() as Map<String, dynamic>?)?['info']
              ?['imageURL'] as String?;

          return GridView.builder(
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: reports.length,
            itemBuilder: (BuildContext context, int index) {
              final report = reports[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewReport(docid: reports[index]),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    height: 500,
                    width: 500,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 2,
                      ),
                      color: Colors.white,
                    ),
                    child: GridTile(
                      header: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            report['info']['siteName'],
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                      ),
                      footer: Center(
                        child: Text(
                          report['info']['date'],
                          style: GoogleFonts.montserrat(fontSize: 12),
                        ),
                      ),
                      child: Center(
                        child: imageURL != null
                            ? Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Image.network(
                                  imageURL,
                                  fit: BoxFit.contain,
                                  height: 100,
                                ),
                              )
                            : Icon(
                                Icons.grass_outlined,
                                color: Colors.green,
                                size: 100,
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
