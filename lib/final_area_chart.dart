import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class FinalAreaChart extends StatelessWidget {
  final List<double> areas;

  FinalAreaChart({required this.areas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Final Area Chart'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Final Area Chart',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Expanded(
              child: charts.LineChart(
                _createSeriesData(),
                animate: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<charts.Series<AreaData, int>> _createSeriesData() {
    final data = areas.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value;
      return AreaData(index, value);
    }).toList();

    return [
      charts.Series<AreaData, int>(
        id: 'Area',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (AreaData area, _) => area.index,
        measureFn: (AreaData area, _) => area.value,
        data: data,
      ),
    ];
  }
}

class AreaData {
  final int index;
  final double value;

  AreaData(this.index, this.value);
}
