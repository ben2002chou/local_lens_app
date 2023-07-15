import 'package:flutter/material.dart';

import 'nlp_detector_views/language_translator_view.dart';

import 'vision_detector_views/text_detector_view.dart';

import 'currency_conversion.dart';
Future<void> main() async {
  print(await fetchExchangeRates());
  WidgetsFlutterBinding.ensureInitialized();

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

void testFunction() async {
  Map<String, dynamic> call = await loadExchangeRates();
  // Now you can use the rates
  const value = 1.0;
  print(value * call['rates']['EUR']);
}

class Home extends StatelessWidget {
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
                      color: Colors
                          .blue, // Making the text color similar to a hyperlink
                      decoration: TextDecoration
                          .underline, // Underlining the text similar to a hyperlink
                    ),
                  ),
                  ElevatedButton(
                      onPressed: testFunction,
                      child: Text('Get USD to EUR Rate')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
