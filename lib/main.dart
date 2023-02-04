import 'dart:io';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'db.dart';
import 'main_page.dart';
import 'new_entry_page.dart';
import 'package:path_provider/path_provider.dart';
import 'stats_page.dart';

DatabaseInterface db = DatabaseInterface();
int currentIdCounter = 0;

void main() async {
  await db.databaseSetup();
  currentIdCounter = await readCounter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(db: db),
      child: MaterialApp(
        title: "Benzyn",
        theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey)),
        home: const ScaffoldMessenger(child: HomePage()),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var bottomNavIndex = 0;
  var newEntry = false;

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;
    switch (bottomNavIndex) {
      case 0:
        bodyWidget = const MainPage();
        break;
      case 1:
        bodyWidget = const StatsPage();
        break;
      default:
        throw UnimplementedError(
            "Bottomnavbar index out of bound : $bottomNavIndex");
    }

    if (newEntry) {
      bodyWidget = const NewEntryPage();
    }



    return Scaffold(
      appBar: AppBar(
        title: const Text('Benzyn'),
        leading: const Icon(Icons.cabin),
        backgroundColor: Theme.of(context).colorScheme.primary,
        shadowColor: Colors.black,
        
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: bodyWidget,
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: const [
          Icons.home,
          Icons.align_horizontal_left_rounded,
        ],
        activeIndex: bottomNavIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.smoothEdge,
        inactiveColor: Theme.of(context).focusColor,
        blurEffect: true,
        onTap: (index) {
          setState(() {
            bottomNavIndex = index;
            newEntry = false;
          });
        },
      ),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: !newEntry
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      onPressed: !newEntry
          ? () {
              setState(() {
                newEntry = true;
              });
            }
          : null,
      child: const Icon(Icons.add_rounded),
    );
  }
}

class AppState extends ChangeNotifier {
  AppState({required this.db});

  DatabaseInterface db;

  int nextId() {
    return ++currentIdCounter;
  }

  late Function setPricePerLiter;
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/id.txt');
}

Future<File> writeId() async {
  final file = await _localFile;
  // Write the file
  return file.writeAsString('$currentIdCounter');
}

Future<int> readCounter() async {
  try {
    final file = await _localFile;

    // Read the file
    final contents = await file.readAsString();

    return int.parse(contents);
  } catch (e) {
    // If encountering an error, return 0
    return 0;
  }
}

List<double> getEfficiencyAsList(Entry entryData, Entry prev) {
  var diff = entryData.currentMileage - prev.currentMileage;
  if (diff == 0) return [0, 0];
  if (kDebugMode) {
    print(diff);
  }
  var low = ((prev.refuelAmount * 0.8) / diff.toDouble() * 100.0).abs();
  var high = (prev.refuelAmount / diff.toDouble() * 100.0).abs();
  return [high, low];
}
