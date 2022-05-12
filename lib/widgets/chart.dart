import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:intl/intl.dart';

class Chart extends StatefulWidget {
  Chart({Key? key}) : super(key: key);

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  late List<EmotionData> _chartData;
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _chartData = getChartData();
    _tooltipBehavior = TooltipBehavior(enable: true);
  }

  List<EmotionData> getChartData() {
    final List<EmotionData> chartData = [
      EmotionData('Happy', 100),
      EmotionData('Angry', 40),
      EmotionData('Sad', 10),
      EmotionData('Surprise', 80),
      EmotionData('Disgust', 80),
      EmotionData('Fear', 66),
      EmotionData('Neutral', 46),
    ];
    return chartData;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        child: SfCartesianChart(
          tooltipBehavior: _tooltipBehavior,
          series: <ChartSeries<EmotionData, String>>[
            BarSeries<EmotionData, String>(
                name: 'Emotion',
                dataSource: _chartData,
                xValueMapper: (EmotionData emotion, _) => emotion.emotion,
                yValueMapper: (EmotionData emotion, _) => emotion.value,
                dataLabelMapper: (EmotionData emotion, _) =>
                    emotion.value.toString(),
                dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.auto),
                enableTooltip: true)
          ],
          primaryXAxis: CategoryAxis(),
          primaryYAxis: NumericAxis(
            edgeLabelPlacement: EdgeLabelPlacement.shift,
          ),
          title: ChartTitle(text: '🙂😀😮😤😒😔😨😱'),

          // numberFormat: NumberFormat.percentPattern(),
        ),
      ),
      // child: SfCartesianChart(
      //   primaryXAxis: CategoryAxis(),
      //   series: [
      //     StackedColumnSeries(
      //       dataSource: chartData,
      //       xValueMapper: (ChartData ch, _) => ch.x,
      //       yValueMapper: (ChartData ch, _) => ch.y1,
      //     ),
      //   ],
      // ),
    );
  }
}

class EmotionData {
  EmotionData(this.emotion, this.value);
  final String emotion;
  final int value;
}
