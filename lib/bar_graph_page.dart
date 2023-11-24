import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class AreaData {
  final int index;
  final double area;

  AreaData(this.index, this.area);
}

class BarGraphPage extends StatelessWidget {
  final List<AreaData> data;

  BarGraphPage(this.data);

  @override
  Widget build(BuildContext context) {
    List<charts.Series<AreaData, String>> series = [
      charts.Series(
        id: 'Area',
        data: data,
        domainFn: (AreaData areaData, _) => 'Sector ${areaData.index}',
        measureFn: (AreaData areaData, _) => areaData.area,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Area Bar Graph'),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: charts.BarChart(
          series,
          animate: true,
          vertical: false,
        ),
      ),
    );
  }
}
