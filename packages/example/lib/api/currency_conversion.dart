import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

Future<Map<String, dynamic>> fetchExchangeRates() async {
  // TODO: Add error handling
  final response =
      await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load exchange rates');
  }
}

Future<Map<String, dynamic>> loadExchangeRates() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('exchangeRates');
  final nextUpdateTimestamp = prefs.getInt('nextUpdate') ??
      0; // nextUpdateTimestamp is used to determine if cached rates are too old

  // Get the current time in milliseconds since epoch
  final currentTime = DateTime.now().millisecondsSinceEpoch;

  // Check if more than 24 hours have passed since the last update
  if (currentTime >= nextUpdateTimestamp) {
    print('More than 24 hours have passed since the last update');
    // More than 24 hours have passed, or it's time for the next update
    // Fetch the new rates and save them
    var newRates = await fetchExchangeRates();
    saveExchangeRates(newRates);
    return newRates;
  } else {
    print(
        'Less than 24 hours have passed since the last update, using cached rates');
    // Less than 24 hours have passed, return the cached rates
    if (jsonString != null) {
      return json.decode(jsonString);
    } else {
      // Fetch from API if not available in SharedPreferences
      print('No cached rates found, fetching from API');
      var rates = await fetchExchangeRates();
      saveExchangeRates(rates);
      return rates;
    }
  }
}

void saveExchangeRates(Map<String, dynamic> rates) async {
  // Save the rates and the next update timestamp to cache
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('exchangeRates', json.encode(rates));
  prefs.setInt(
      'nextUpdate',
      rates['time_next_update_unix'] *
          1000); // Convert from seconds to milliseconds
}

Future<String> processText(String text, double multiplier) async {
  /* 
  This regular expression (RegExp regExp = RegExp(r'\b\d+((\.|,)\d{3})*((\.|,)\d{1,2})?');) is used to match numeric values in a given string. These numeric values can represent various types of formatted numbers, such as integers, decimal numbers, and numbers with thousand separators.

  The components of the regular expression perform the following functions:

  - \b: Matches a word boundary. This prevents the regular expression from matching numbers that are part of larger words.

  - \d+: Matches one or more digits. This will match any sequence of digits at the start of a word.

  - ((\.|,)\d{3})*: Matches any number of groups of three digits preceded by a period or comma. This allows the regular expression to match numbers with thousand separators, like "1,000" or "1.000".

  - ((\.|,)\d{1,2})?: Matches an optional group of one or two digits preceded by a period or comma. This allows the regular expression to match decimal numbers, like "1.23" or "1,23".

  Examples of use cases:
  - "The price is 1,000.23": Matches "1,000.23"
  - "I have 1.000,23 in my bank account": Matches "1.000,23"
  - "The population is 12345": Matches "12345"
  - "The number 7890.12 is a decimal number": Matches "7890.12"
  */

  RegExp regExp = RegExp(r'\b\d+((\.|,)\d{3})*((\.|,)\d{1,2})?');

  // Keep track of the offsets of the replacements to avoid overlapping
  int offset = 0;

  // Use a StringBuffer for efficiency
  StringBuffer buffer = StringBuffer();

  for (RegExpMatch match in regExp.allMatches(text)) {
    String priceString =
        text.substring(match.start, match.end); // Get the matched text
    priceString =
        priceString.replaceAll(RegExp(r'\D*$'), ''); // Remove non-digits
    priceString = priceString.replaceAll(',', ''); // Remove commas
    // TODO handle decimals and non comma seperated numbers. It currently works but further testing is needed.
    // Check if the string is a valid number that can be parsed to double
    if (double.tryParse(priceString) != null) {
      double price = double.parse(priceString);
      // Multiply the price by the rate
      double newPrice = price * multiplier;

      // Add the text before the match, and the replacement text
      buffer
        ..write(text.substring(offset, match.start))
        ..write(newPrice.toStringAsFixed(2)); // Keep the decimal points
      offset = match.end;
    }
  }

  // Add the remaining text after the last match
  buffer.write(text.substring(offset));

  return buffer.toString();
}
