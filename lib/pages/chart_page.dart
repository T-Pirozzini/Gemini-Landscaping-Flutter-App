import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';

class Chart extends StatefulWidget {
  const Chart({super.key});

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 550,
      child: SfCartesianChart(
        title: ChartTitle(
          text: "Car Sales",
        ),
        primaryXAxis: CategoryAxis(
          title: AxisTitle(
            text: "Car Names",
          ),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(
            text: "Sales in Millions",
          ),
        ),
        legend: Legend(
          isVisible: true,
        ),
        series: <ChartSeries>[
          ColumnSeries<SalesData, String>(
            name: "Cars",
            dataSource: getColumnData(),
            xValueMapper: (SalesData sales, _) => sales.x,
            yValueMapper: (SalesData sales, _) => sales.y,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
            ),
          )
        ],
      ),
    );
  }
}

class SalesData {
  String x;
  double y;

  SalesData(this.x, this.y);
}

dynamic getColumnData() {
  List<SalesData> ColumnData = <SalesData>[
    SalesData("BMW", 20),
    SalesData("Subaru", 30),
    SalesData("Honda", 10),
    SalesData("Tesla", 60),
    SalesData("Toyota", 20),
    SalesData("Mazda", 50),
    SalesData("Hyundai", 10),
    SalesData("Mitsubishi", 60),
    SalesData("Ford", 20),
    SalesData("Chevrolet", 30),
    SalesData("GMC", 10),
    SalesData("Volvo", 60),
  ];
  return ColumnData;
}
