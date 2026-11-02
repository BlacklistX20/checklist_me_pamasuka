import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Klien HTTP tipis untuk Google Apps Script Web App.
/// - Semua request punya timeout (tidak menggantung selamanya).
/// - POST ke Apps Script dijawab dengan redirect 302/303; hasil JSON-nya
///   diambil dengan GET ke URL tujuan redirect (script hanya dieksekusi sekali).
class AppsScriptClient {
  AppsScriptClient._();

  static const Duration defaultTimeout = Duration(seconds: 25);
  static const int _maxRedirects = 3;

  static Future<http.Response> get(
    String url, {
    Duration timeout = defaultTimeout,
  }) {
    return http.get(Uri.parse(url)).timeout(timeout);
  }

  static Future<http.Response> postJson(
    String url,
    Map<String, dynamic> payload, {
    Duration timeout = defaultTimeout,
  }) async {
    final request = http.Request('POST', Uri.parse(url))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(payload)
      ..followRedirects = false;

    final streamed = await request.send().timeout(timeout);
    var response = await http.Response.fromStream(streamed).timeout(timeout);

    var hops = 0;
    while ((response.statusCode == 302 || response.statusCode == 303) && hops < _maxRedirects) {
      final location = response.headers['location'];
      if (location == null) break;
      response = await http.get(Uri.parse(location)).timeout(timeout);
      hops++;
    }
    return response;
  }
}
