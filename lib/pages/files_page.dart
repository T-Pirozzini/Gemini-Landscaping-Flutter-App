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
                      child: Stack(
                        children: [
                          Center(
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
                          Align(
                            alignment: Alignment.bottomRight,
                            child: IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                // Call your edit function here
                                _editReport(context, report, imageURL);
                              },
                            ),
                          ),
                        ],
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

void _editReport(
    BuildContext context, DocumentSnapshot report, String? imageURL) {
  List<String> iconUrls = [
    // Add your list of network URLs here
    'https://www.northpointnanaimo.ca/theme/orca/images/logos/Logo-Skyline-Living.png',
    'https://www.lifetimenetworks.org/wp-content/uploads/2016/02/Country-Grocer-logo.png',
    'https://colyvanpacific.com/wp-content/uploads/2021/02/cropped-cp-web-logo-500px-200x200-1.png',
    'https://shared-s3.property.ca/public/images/managements/pacific-quorum-properties-inc/pacific-quorum-properties-inc-original-1.jpg'
    // ...
  ];
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Report'),
        content: Container(
          width: 300, // Adjust the width as needed
          height: 300, // Adjust the height as needed
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: iconUrls.length,
            itemBuilder: (BuildContext context, int index) {
              String iconUrl = iconUrls[index];
              return GestureDetector(
                onTap: () async {
                  // Update the imageURL in the database
                  await report.reference.update({
                    'info.imageURL': iconUrl,
                  });

                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.network(
                    iconUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}
