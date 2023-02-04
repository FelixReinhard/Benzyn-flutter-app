import 'package:benzyn/best_price.dart';
import 'package:benzyn/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'info_cart.dart';
import 'db.dart';
import 'best_price.dart';

class NewEntryPage extends StatefulWidget {
  const NewEntryPage({super.key});

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  Entry? currentEntry;
  final _key = GlobalKey<FormState>();
  var _selectedPriceMethode = [true, false];
  int currentMileage = 0;
  Price payedPrice = Price(euro: 0, cent: 0);
  double refuelAmount = 0;

  TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    appState.setPricePerLiter = (double value) {
      setState(() {
        payedPrice = Price.fromDouble(value);
        controller.value = controller.value
            .copyWith(text: "${value.toStringAsFixed(2).replaceAll('.', ',')} €/l");
        _selectedPriceMethode[0] = false;
        _selectedPriceMethode[1] = true;
      });
    };
    return Form(
      key: _key,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.add_road_rounded),
            title: TextFormField(
              validator: (value) {
                if (value != null) {
                  return int.tryParse(value.replaceAll(" km", "")) == null
                      ? "Bitte einen validen Kilometerstand angeben"
                      : null;
                } else {
                  return "Fehler";
                }
              },
              textInputAction: TextInputAction.next,
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: false),
              decoration: const InputDecoration(hintText: "Kilometerstand"),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]*')),
                formatWithSuffix('km')
              ],
              onChanged: (value) {
                if (value == "") {
                  currentMileage = 0;
                } else {
                  currentMileage = int.parse(value.replaceAll(' km', ''));
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.local_gas_station_rounded),
            title: TextFormField(
              validator: (value) {
                if (value != null) {
                  var x = double.tryParse(
                      value.replaceAll(" l", "").replaceAll(',', '.'));
                  return x == null ? "Bitte eine valide Zahl angeben." : null;
                } else {
                  return "Fehler";
                }
              },
              textInputAction: TextInputAction.next,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: "Getankt in Liter"),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^[1-9][0-9]*(\,?)[0-9]*')),
                formatWithSuffix('l')
              ],
              onChanged: (value) {
                if (value == "") {
                  refuelAmount = 0;
                } else {
                  refuelAmount = double.parse(
                      value.replaceAll(' l', '').replaceAll(',', '.'));
                }
              },
            ),
          ),
          ListTile(
            trailing: ToggleButtons(
              isSelected: _selectedPriceMethode,
              onPressed: (int index) {
                var prev = _selectedPriceMethode[0];
                setState(() {
                  for (int i = 0; i < _selectedPriceMethode.length; i++) {
                    _selectedPriceMethode[i] = i == index;
                  }
                  // if previously was € then change to €/l
                  if (prev) {
                    controller.value = controller.value.copyWith(
                        text: controller.value.text.replaceAll(' €', ' €/l'));
                    // Now it was €/l
                  } else {
                    controller.value = controller.value.copyWith(
                        text: controller.value.text.replaceAll(' €/l', ' €'));
                  }
                });
              },
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              children: const [
                Text(
                  '€',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '€/l',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
            leading: const Icon(Icons.euro_rounded),
            title: getPriceField(appState, context),
          ),
          const Padding(padding: EdgeInsets.all(20)),
          const Divider(
            height: 10,
            thickness: 2,
          ),
          ElevatedButton(
              onPressed: () async {
                if (_key.currentState!.validate()) {
                  //Confirm.
                  var newEntry = Entry(
                    bestPrice: getBestPrice(),
                    currentMileage: currentMileage,
                    date: DateTime.now(),
                    id: appState.nextId(),
                    payedPrice: _selectedPriceMethode[0]
                        ? payedPrice
                        : Price.fromDouble(
                            payedPrice.toDouble() * refuelAmount),
                    refuelAmount: refuelAmount,
                  );

                  await writeId();
                  await submit(newEntry, db);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Eintrag wurde eingetragen... duh.')));
                }
              },
              child: const Text("Fertig!")),
          const Padding(padding: EdgeInsets.all(10)),
          const BestGasPrice()
        ],
      ),
    );
  }

  TextFormField getPriceField(AppState appState, BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (value != null) {
          final doubleString = (_selectedPriceMethode[0]
                  ? value.replaceAll(' €', '')
                  : value.replaceAll(' €/l', ''))
              .replaceAll(",", ".");
          var x = double.tryParse(doubleString);
          return x == null ? "Bitte eine valide Zahl angeben." : null;
        } else {
          return "Fehler";
        }
      },
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (value) async {
        //Confirm.
        if (_key.currentState!.validate()) {
          var newEntry = Entry(
            bestPrice: getBestPrice(),
            currentMileage: currentMileage,
            date: DateTime.now(),
            id: appState.nextId(),
            payedPrice: _selectedPriceMethode[0]
                ? payedPrice
                : Price.fromDouble(payedPrice.toDouble() * refuelAmount),
            refuelAmount: refuelAmount,
          );
          await writeId();
          await submit(newEntry, db);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Eintrag wurde eingetragen... duh.')));
        }
      },
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
          hintText:
              _selectedPriceMethode[0] ? "Gesamtbetrag" : "Preis pro Liter"),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]*(\,?)[0-9]*')),
        _selectedPriceMethode[0]
            ? formatWithSuffix('€')
            : formatWithSuffix('€/l')
      ],
      onChanged: (value) {
        if (value == "") {
          payedPrice = Price.fromDouble(0);
        } else {
          var double_string = (_selectedPriceMethode[0]
                  ? value.replaceAll(' €', '')
                  : value.replaceAll(' €/l', ''))
              .replaceAll(",", ".");
          payedPrice = Price.fromDouble(double.parse(double_string));
        }
      },
    );
  }
}

Future<void> submit(Entry entry, DatabaseInterface db) async {
  await db.insertEntry(entry);
  if (kDebugMode) {
    print("Added to db");
  }
}

TextInputFormatter formatWithSuffix(String append) {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    var withoutKm = newValue.text.replaceAll(append, '');
    if (withoutKm.isEmpty) return newValue.copyWith(text: withoutKm);
    return newValue.copyWith(text: "$withoutKm $append");
  });
}

// ignore: camel_case_extensions
extension extString on String {}
