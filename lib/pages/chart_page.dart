import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({Key? key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final Stream<QuerySnapshot> _siteStream =
      FirebaseFirestore.instance.collectionGroup('SiteReports2023').snapshots();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 8, 8, 40),
      color: Colors.grey.shade200,
      child: StreamBuilder<QuerySnapshot>(
        stream: _siteStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            final data = getColumnData(snapshot.data!);
            return SfCartesianChart(
              title: ChartTitle(
                text: "April 2023",
              ),
              primaryXAxis: CategoryAxis(
                title: AxisTitle(
                  text: "Sites",
                ),
                labelRotation: 90,
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(
                  text: "Time (hours)",
                ),
              ),
              legend: Legend(
                isVisible: true,
              ),
              series: <ChartSeries>[
                ColumnSeries<SiteData, String>(
                  name: "Site Time",
                  dataSource: data,
                  xValueMapper: (SiteData data, _) => data.x,
                  yValueMapper: (SiteData data, _) => data.y,
                  dataLabelSettings: DataLabelSettings(
                    // isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class SiteData {
  String x;
  double y;

  SiteData(this.x, this.y);
}

List<SiteData> getColumnData(QuerySnapshot snapshot) {
  final List<SiteData> ColumnData = <SiteData>[];
  for (var doc in snapshot.docs) {
    ColumnData.add(SiteData(doc['info']['siteName'], 20));
  }
  return ColumnData;
}
