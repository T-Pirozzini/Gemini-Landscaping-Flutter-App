import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({Key? key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<String> timesList = [];

  @override
  void initState() {
    super.initState();
    fetchSiteReports();
  }

  Future<void> fetchSiteReports() async {
    DateTime currentDate = DateTime.now();
    DateTime startDate = DateTime(currentDate.year, currentDate.month, 1);
    DateTime endDate = DateTime(currentDate.year, currentDate.month + 1, 1)
        .subtract(Duration(days: 1));

    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('SiteReports2023')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate)
        .get();

    final List<DocumentSnapshot> documents = snapshot.docs;
    print(documents.length);

    for (var document in documents) {
      Map<String, dynamic> times = document['times'];
      times.forEach((key, value) {
        timesList.add(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Column(
        children: [
          Container(
            height: 50,
            child: Text('Placeholder'),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: timesList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(timesList[index]),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
