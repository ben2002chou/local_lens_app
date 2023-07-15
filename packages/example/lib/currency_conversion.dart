import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// This method currently works!
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
