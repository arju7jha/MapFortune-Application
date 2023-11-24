import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'dart:math';

class FinalPage extends StatelessWidget {
  final List<double> areas;

  FinalPage({required this.areas});

  @override
  Widget build(BuildContext context) {
    final mean = calculateMean(areas);
    final standardDeviation = calculateStandardDeviation(areas);

    final seriesData = [
      charts.Series<ChartData, String>(
        id: 'Area',
        domainFn: (ChartData data, _) => data.index.toString(),
        measureFn: (ChartData data, _) => data.value,
        data: areas.asMap().entries.map((entry) {
          return ChartData(entry.key, entry.value);
        }).toList(),
      ),
      charts.Series<ChartData, String>(
        id: 'Mean',
        domainFn: (ChartData data, _) => data.index.toString(),
        measureFn: (ChartData data, _) => mean,
        data: areas.asMap().entries.map((entry) {
          return ChartData(entry.key, mean);
        }).toList(),
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
      ),
      charts.Series<ChartData, String>(
        id: 'Standard Deviation',
        domainFn: (ChartData data, _) => data.index.toString(),
        measureFn: (ChartData data, _) => standardDeviation,
        data: areas.asMap().entries.map((entry) {
          return ChartData(entry.key, standardDeviation);
        }).toList(),
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      ),
    ];

    final chart = charts.BarChart(
      seriesData,
      animate: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Final Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 400,
              child: chart,
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Mean: $mean'),
            ),
            ListTile(
              title: Text('Standard Deviation: $standardDeviation'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: areas.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Area ${index + 1}: ${areas[index]}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = calculateMean(values);
    final variance = values.map((value) => pow(value - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }
}

class ChartData {
  final int index;
  final double value;

  ChartData(this.index, this.value);
}
