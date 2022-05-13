import 'package:flutter/material.dart';
import 'package:my_feelings/controllers/emotionController.dart';
import 'package:my_feelings/models/emotion.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Chart extends ConsumerStatefulWidget {
  const Chart({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChartState();
}

class _ChartState extends ConsumerState<Chart> {
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
  }

  @override
  Widget build(BuildContext context) {
    final emotions = ref.watch(emotionController);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.only(left: 20, right: 10),
          child: Text(
            '🙂😀😮😤😒😔😱',
            style: TextStyle(fontSize: 22),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 22,
              top: 22,
            ),
            child: SfCartesianChart(
              tooltipBehavior: _tooltipBehavior,
              series: <ChartSeries<Emotion, String>>[
                BarSeries<Emotion, String>(
                    name: 'Emotion',
                    dataSource: emotions,
                    xValueMapper: (Emotion emotion, _) => emotion.emotion,
                    yValueMapper: (Emotion emotion, _) => emotion.value,
                    dataLabelMapper: (Emotion emotion, _) =>
                        emotion.value.toString(),
                    dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelAlignment: ChartDataLabelAlignment.auto),
                    enableTooltip: true)
              ],
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(
                edgeLabelPlacement: EdgeLabelPlacement.shift,
                visibleMaximum: 100,
                maximum: 100,
              ),

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
        ),
      ],
    );
  }
}
