import 'dart:convert';
import 'dart:math';
import 'package:benzyn/main.dart';
import 'package:location/location.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'db.dart';

const String API_KEY = "767fd137-d94a-3d56-d1e0-ed76aa725201";
const int MAX_GAS_STATIONS = 10;

class GasStation {
  final String id;
  final String name;
  final String street;
  final String place;
  final double distance;
  final Price priceE5;
  final Price priceE10;
  final Price priceDiesel;
  final String houseNumber;
  final int postCode;
  final bool isOpen;
  bool isFail = false;
  String error = "";
  GasStation(
      this.id,
      this.name,
      this.street,
      this.place,
      this.distance,
      this.houseNumber,
      this.postCode,
      this.priceE5,
      this.priceE10,
      this.priceDiesel,
      this.isOpen);

  static GasStation fail(String errorMessage) {
    var g = GasStation("id", "name", "street", "place", 0, "", 0,
        Price.fromDouble(0), Price.fromDouble(0), Price.fromDouble(0), false);
    g.isFail = true;
    g.error = errorMessage;
    return g;
  }
}

class BestGasPrice extends StatelessWidget {
  const BestGasPrice({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return FutureBuilder(
        future: getNeareastAndCheapestGasStation(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Expanded(
                  child: Text(
                      "Something went wrong \u{1F62D} ${snapshot.error.toString()}"));
            } else if (snapshot.data![0].isFail) {
              return Expanded(child: Text(snapshot.data![0].error));
            }

            snapshot.data!.sort(
                (a, b) => a.priceE5.toDouble().compareTo(b.priceE5.toDouble()));

            return Expanded(
              child: Center(
                  child: ListView(
                children: [
                  for (int i = 0;
                      i < min(MAX_GAS_STATIONS, snapshot.data!.length);
                      i++)
                    Card(
                      child: ListTile(
                        onTap: () => appState.setPricePerLiter(snapshot.data![i].priceE5.toDouble()),
                        leading: Column(
                          children: [
                            ColoredBox(
                              color: Theme.of(context).colorScheme.primary,
                              child: Text(
                                snapshot.data![i].priceE5.format(),
                                style: TextStyle(
                                    fontFamily: "Montserrat",
                                    fontSize: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .background),
                              ),
                            ),
                            Text(
                              snapshot.data![i].priceE10.format(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              snapshot.data![i].priceDiesel.format(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        title: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  snapshot.data![i].name,
                                  overflow: TextOverflow.clip,
                                  style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                                "${snapshot.data![i].street} ${snapshot.data![i].houseNumber}"),
                            Text(
                              snapshot.data![i].isOpen
                                  ? "Geöffnet"
                                  : "Geschlossen",
                              style: TextStyle(
                                  color: snapshot.data![i].isOpen
                                      ? Colors.green
                                      : Colors.red),
                            )
                          ],
                        ),
                        trailing: Text("${snapshot.data![i].distance} km"),
                      ),
                    )
                ],
              )),
            );
          } else {
            return const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        });
  }
}

Price? _bestPrice;

Price getBestPrice() {
  _bestPrice ??= Price(cent: 69, euro: 2);
  return _bestPrice!;
}

Future<List<double>> getCurrentLocation() async {
  Location location = new Location();

  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData _locationData;

  _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return [];
    }
  }

  _permissionGranted = await location.hasPermission();
  if (_permissionGranted == PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != PermissionStatus.granted) {
      return [];
    }
  }

  _locationData = await location.getLocation();

  double lat = _locationData.latitude!;
  double long = _locationData.longitude!;
  if (kDebugMode) {
    print("Latitude: $lat and Longitude: $long");
  }
  return [lat, long];
}

Future<List<GasStation>> getNeareastAndCheapestGasStation(
    {double radius = 5, String petrolType = 'all'}) async {
  try {
    var pos = await getCurrentLocation();

    if (pos.isEmpty) {
      pos = [49.241758, 6.997667];
    }

    final response = await http.get(Uri.parse(
        'https://creativecommons.tankerkoenig.de/json/list.php?lat=${pos[0]}&lng=${pos[1]}&rad=${radius}&sort=dist&type=$petrolType&apikey=${API_KEY}'));

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);

      var stations = <GasStation>[];

      for (var station in json['stations']) {
        var priceE5 = petrolType == 'all'
            ? Price.fromDouble(station['e5'] ?? 0)
            : (petrolType == "e5"
                ? Price.fromDouble(station['price'] ?? 0)
                : Price.fromDouble(0));

        var priceE10 = petrolType == 'all'
            ? Price.fromDouble(station['e10'] ?? 0)
            : (petrolType == 'e10'
                ? Price.fromDouble(station['price'] ?? 0)
                : Price.fromDouble(0));

        var priceDiesel = petrolType == 'all'
            ? Price.fromDouble(station['diesel'] ?? 0)
            : (petrolType == 'diesel'
                ? Price.fromDouble(station['price'] ?? 0)
                : Price.fromDouble(0));

        stations.add(GasStation(
          station['id'],
          station['name'],
          station['street'],
          station['place'],
          double.parse(station['dist'].toString()),
          station['houseNumber'],
          station['postCode'],
          priceE5,
          priceE10,
          priceDiesel,
          station['isOpen'],
        ));
      }

      return stations;
    }
    return [];
  } catch (e) {
    return [GasStation.fail(e.toString())];
  }
}
