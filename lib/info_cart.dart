import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'db.dart';
import 'main.dart';

class EntryCard extends StatelessWidget {
  EntryCard({super.key, required this.entryData, required this.prev}) {
    pricePerLiter = Price.fromDouble(
        entryData.payedPrice.toDouble() / entryData.refuelAmount);
  }

  static EntryCard fromEntry(Entry entry, Entry previous) {
    return EntryCard(
      entryData: entry,
      prev: previous,
    );
  }

  late Function removeFromList;
  final Entry entryData;
  final Entry prev;
  // Kilometerstand oder wieviele Kilometer gefahren wurden.
  late Price pricePerLiter;

  @override
  Widget build(BuildContext context) {
    var style = TextStyle(
        color: Theme.of(context).colorScheme.background,
        fontSize: 20,
        fontFamily: "Montserrat",
        fontWeight: FontWeight.bold);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      shadowColor: Theme.of(context).colorScheme.secondary,
      elevation: 2,
      margin: const EdgeInsets.all(10),
      child: ClipPath(
        clipper: ShapeBorderClipper(
            shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        )),
        child: Stack(children: [
          Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 80,
                  ),
                ),
              ),
              child: entryItems(context, style)),
          dateInfo(context, style),
        ]),
      ),
    );
  }

  Column dateInfo(BuildContext context, TextStyle style) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.only(bottom: 20)),
        SizedBox(
          width: 80,
          child: Center(
              child: Column(
            children: [
              Text(
                entryData.dayMonth(),
                style: style,
              ),
              Text(
                entryData.time(),
                style: style.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              )
            ],
          )),
        ),
      ],
    );
  }

  SizedBox entryItems(BuildContext context, TextStyle style) {
    var appState = context.watch<AppState>();
    return SizedBox(
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListTile(
                onLongPress: () async {
                  final res = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Löschen?'),
                      content: const Text("Diesen Eintrg löschen?"),
                      actions: [
                        IconButton(
                            onPressed: () async {
                              Navigator.pop(context, 'delete');
                              
                            },
                            icon: const Icon(Icons.check_outlined)),
                        IconButton(
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                            icon: const Icon(Icons.close))
                      ],
                    ),
                  );
                  if (res == "delete") {
                    await appState.db.delete(entryData);
                    // Somehow reload main_page ???
                    removeFromList(entryData);
                  }
                },
                isThreeLine: true,
                minLeadingWidth: 10,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                leading: const Icon(Icons.local_gas_station_rounded),
                title: Row(
                  children: [
                    Text(
                      "${entryData.refuelAmount}".replaceAll('.', ','),
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 22),
                    ),
                    const Text(
                      ' l getankt',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                subtitle: Text(
                    "für ${entryData.payedPrice.format()} \nmit ${entryData.getPricePerLiter()}/l"),
                trailing: Column(
                  children: [
                    Flexible(
                      child: Text(
                        getEfficiency(),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const Text(
                      "pro 100 km",
                      style: TextStyle(fontSize: 10),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      "${entryData.currentMileage} km",
                      style: const TextStyle(fontSize: 12),
                    )
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  String getEfficiency() {
    var hl = getEfficiencyAsList(entryData, prev);
    var low = hl[1];
    var high = hl[0];

    if (high == 0 && low == 0) return " \u{1F6AB}";
    if (high >= 100 || low >= 80) return "> $low l";
    if (high.toStringAsFixed(1) == low.toStringAsFixed(1))
      return "${low.toStringAsFixed(1)} l";
    return "${low.toStringAsFixed(1)} - ${high.toStringAsFixed(1)} l";
  }
}
