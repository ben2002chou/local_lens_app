import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';


Future<Map<String, dynamic>> fetchExchangeRates() async {
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
  final nextUpdateTimestamp = prefs.getInt('nextUpdate') ?? 0;

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
    print('Less than 24 hours have passed since the last update, using cached rates');
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
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('exchangeRates', json.encode(rates));
  prefs.setInt('nextUpdate', rates['time_next_update_unix'] * 1000);  // Convert from seconds to milliseconds
}




Future<String> getMatches(String text) async {
  RegExp regExp  = RegExp(r'\b\d{1,3}(?:(?:[.,]\d{3})*(?:[.,]\d{2})?)?\b');
  return regExp.allMatches(text).map((match) => text.substring(match.start, match.end)).join('\n');
}

Future<double?> convertPrice(String priceString, double multiplier) async {
  print("convertPrice received: $priceString");
  priceString = priceString.replaceAll(',', '');
  double price = double.parse(priceString);
  return price * multiplier;
}

Future<String> replaceInText(String text, String oldString, String newString) async {
  return text.replaceAll(oldString, newString);
}

Future<String> processText(String text, double multiplier) async {
  RegExp regExp  = RegExp(r'\b\d{1,3}(?:(?:[.,]\d{3})*(?:[.,]\d{2})?)?\b');
  // Keep track of the offsets of the replacements to avoid overlapping
  int offset = 0;

  // Use a StringBuffer for efficiency
  StringBuffer buffer = StringBuffer();

  for (RegExpMatch match in regExp.allMatches(text)) {
    String priceString = text.substring(match.start, match.end);
    if (isNumeric(priceString)) {
      double? newPrice = await convertPrice(priceString, multiplier);
      // If convertPrice returned null, skip this price
    if (newPrice != null) {
      // Add the text before the match, and the replacement text
      buffer
        ..write(text.substring(offset, match.start))
        ..write(newPrice.toStringAsFixed(2));  // Keep the decimal points
      offset = match.end;
    }

    }
    
    
  }

  // Add the remaining text after the last match
  buffer.write(text.substring(offset));

  return buffer.toString();
}


bool isNumeric(String s) {
  return double.tryParse(s) != null;
}
