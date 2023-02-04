import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db.dart';
import 'info_cart.dart';
import 'main.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return LayoutBuilder(builder: (context, boxConstraints) {
      return const EntriesList();
    });
  }
}

class EntriesList extends StatefulWidget {
  const EntriesList({super.key});

  @override
  State<EntriesList> createState() => _EntriesListState();
}

class _EntriesListState extends State<EntriesList> {
  
  @override
  Widget build(BuildContext context) {
    final _entries = db.entries(20);
    return Center(
        child: Column(
      children: [
        const Padding(padding: EdgeInsets.all(10)),
        FutureBuilder(
          future: _entries,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return Expanded(
                child: ListView(
                  children: [ 
                    for (var entry in getEntryCards(snapshot.data!)) entry
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return const Text('ERROR reading from db');
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              return Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.error),
                    Text('Keine Einträge vorhanden')
                  ],
                ),
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        )
      ],
    ));
  }

  List<EntryCard> getEntryCards(List<Entry> entries) {
    var ret = <EntryCard>[];

    for (int i = 0; i < entries.length; i++) {
      final e = EntryCard.fromEntry(
          entries[i], entries[min(entries.length - 1, i + 1)]);
      e.removeFromList = (Entry entry) {
        setState(() {
          entries.remove(entry);  
        });
      };
      ret.add(e);
    }
    return ret;
  }
}
