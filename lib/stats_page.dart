import 'dart:ui';

import 'package:benzyn/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  var points = [1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    return Column(
      children: [
        const Padding(padding: EdgeInsets.all(10)),
        const Text('Verbrauch',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontFamily: "Montserrat")),
        const Padding(padding: EdgeInsets.all(10)),
        FutureBuilder(
            future: appState.db.getEfficiencyChartData(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final spots =
                    snapshot.data!.map((e) => FlSpot(e['x'], e['y'])).toList();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: LineChart(
                      LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                dotData: FlDotData(show: true),
                                barWidth: 5,
                                isStrokeCapRound: true,
                                belowBarData: BarAreaData(show: true)),
                          ],
                          lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((e) {
                                    return LineTooltipItem(
                                        e.y.toStringAsFixed(2),
                                        TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary));
                                  }).toList();
                                },
                              )),
                          gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                            verticalInterval: 1,
                            horizontalInterval: 5,
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: const Color(0xff37434d),
                                strokeWidth: 1,
                              );
                            },
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: const Color(0xff37434d),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(value.toString()));
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: const Color(0xff37434d)),
                          ),
                          minX: snapshot.data!.isNotEmpty
                              ? snapshot.data![0]['min'] - 1
                              : 1,
                          maxX: snapshot.data!.isNotEmpty
                              ? snapshot.data![0]['max'] + 1
                              : 3),
                      swapAnimationCurve: Curves.linear,
                      swapAnimationDuration: const Duration(milliseconds: 150),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [Icon(Icons.error), Text('Keine Einträge')],
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [Icon(Icons.error), Text('Laden')],
                      ),
                      const CircularProgressIndicator()
                    ],
                  ),
                );
              }
            }),
        const Padding(padding: EdgeInsets.all(100))
      ],
    );
  }
}
