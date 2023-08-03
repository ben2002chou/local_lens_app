import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'nlp_detector_views/language_translator_view.dart';

import 'vision_detector_views/text_detector_view.dart';

import 'api/currency_conversion.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



Future<void> main() async {
  // print(await fetchExchangeRates());
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

var rate =
    1.0; // global rate variable. This is the rate that will be used to convert the prices
// Future<Map<String, dynamic>> getRates() async {
//   Map<String, dynamic> call = await loadExchangeRates();
//   return call['rates'];
// }

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? selectedSourceCurrency;
  String? selectedTargetCurrency;
  Map<String, double>? currencyRates;
  var sourceRate = 1.0;
  var targetRate = 1.0;
  Future<void> getRates() async {
    try {
      Map<String, dynamic> call = await loadExchangeRates();
      setState(() {
        currencyRates = Map<String, double>.from(call['rates'].map(
            (key, value) => MapEntry(key, double.parse(value.toString()))));
        selectedSourceCurrency = 'USD'; // default source currency
        selectedTargetCurrency =
            currencyRates?.keys.first; // default target currency
      });
    } catch (e) {
      print('Error in getRates: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getRates();
    fetchPlaceRatings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google ML Kit Demo App'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ExpansionTile(
                    title: const Text('Vision APIs'),
                    children: [
                      CustomCard('Text Recognition', TextRecognizerView()),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ExpansionTile(
                    title: const Text('Natural Language APIs'),
                    children: [
                      CustomCard(
                          'On-device Translation', LanguageTranslatorView()),
                    ],
                  ),
                  Text(
                    'Rates By Exchange Rate API',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  currencyRates == null
                      ? CircularProgressIndicator()
                      : Column(
                          children: [
                            DropdownButton<String>(
                              value: selectedSourceCurrency,
                              items: currencyRates?.keys.map((String key) {
                                return DropdownMenuItem<String>(
                                  value: key,
                                  child: Text(key),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSourceCurrency = value;
                                  sourceRate =
                                      currencyRates?[selectedSourceCurrency] ??
                                          1.0;
                                  // recalculate the rate
                                  rate = targetRate / sourceRate;
                                });
                              },
                            ),
                            DropdownButton<String>(
                              value: selectedTargetCurrency,
                              items: currencyRates?.keys.map((String key) {
                                return DropdownMenuItem<String>(
                                  value: key,
                                  child: Text(key),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedTargetCurrency = value;
                                  targetRate =
                                      currencyRates?[selectedTargetCurrency] ??
                                          1.0;
                                  // recalculate the rate
                                  rate = targetRate / sourceRate;
                                });
                              },
                            ),
                            Text(
                                // display the rate
                                'Rate: ${rate}'),
                          ],
                        ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


Future<void> requestLocationPermission() async {
  PermissionStatus status = await Permission.location.status;
  
  if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
    ].request();

    print(statuses[Permission.location]);
  }
}


Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
}
Future<dynamic> getPlaceDetails(
    {required LatLng pos, required int radius, required String apiKey}) async {
  double lat = pos.latitude;
  double lng = pos.longitude;

  final String url =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?&location=$lat,$lng&radius=$radius&key=$apiKey';

  var response = await http.get(Uri.parse(url));

  var json = convert.jsonDecode(response.body);

  return json;
}
void printPlaceRatings(dynamic json) {
    print(json['results']);
    var results = json['results'];
    for (var place in results) {
        print('Place: ${place['name']}, Rating: ${place['rating']}');
    }
}
Future<void> fetchPlaceRatings() async {
  // Request location permission
  await requestLocationPermission();
  
  // Get the current location
  Position position = await _getCurrentLocation();

  // Get place details using the current location
  String googleMapsApiKey = dotenv.env['GOOGLE_API_KEY']!;

  var details = await getPlaceDetails(
    pos: LatLng(position.latitude, position.longitude),
    radius: 10,
    apiKey: googleMapsApiKey,
  );

  // Get and print the place name and rating
  print(details['results']);
  for (var result in details['results']) {
    print('Name: ${result['name']}, Rating: ${result['rating']}');
  }
}



class CustomCard extends StatelessWidget {
  final String _label;
  final Widget _viewPage;
  final bool featureCompleted;

  const CustomCard(this._label, this._viewPage, {this.featureCompleted = true});
  // _viewpage is the widget that will be displayed when the card is tapped

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Theme.of(context).primaryColor,
        title: Text(
          _label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          if (!featureCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    const Text('This feature has not been implemented yet')));
          } else {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => _viewPage));
          }
        },
      ),
    );
  }
}
