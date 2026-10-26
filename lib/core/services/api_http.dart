import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Session tokens stay in memory, matching the app's existing login lifecycle.
String? accessToken;
String? actorIdentity;
http.Client client = http.Client();
final Map<String, Future<http.Response>> _inFlight = {};

Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
    client.get(url, headers: _headers(headers));

Map<String, String> _headers(Map<String, String>? headers) => {
  'Accept': 'application/json',
  ...?headers,
  if (accessToken != null) 'Authorization': 'Bearer $accessToken',
};

Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _mutate('POST', url, headers, body, encoding);
Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _mutate('PUT', url, headers, body, encoding);
Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _mutate('DELETE', url, headers, body, encoding);

Future<http.Response> _mutate(String method, Uri url, Map<String, String>? headers, Object? body, Encoding? encoding) {
  final fingerprint = sha256.convert(utf8.encode('$actorIdentity|$method|$url|$body')).toString();
  return _inFlight.putIfAbsent(fingerprint, () =>
    _send(method, url, headers, body, encoding, fingerprint)
      .whenComplete(() { _inFlight.remove(fingerprint); }));
}

Future<http.Response> _send(String method, Uri url, Map<String, String>? headers, Object? body, Encoding? encoding, String fingerprint) async {
  final prefs = await SharedPreferences.getInstance();
  final storageKey = 'pending_operation_$fingerprint';
  var key = prefs.getString(storageKey);
  if (key == null) {
    final random = Random.secure();
    key = List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString(storageKey, key);
  }
  final requestHeaders = {..._headers(headers), 'Idempotency-Key': key};
  final future = switch (method) {
    'PUT' => client.put(url, headers: requestHeaders, body: body, encoding: encoding),
    'DELETE' => client.delete(url, headers: requestHeaders, body: body, encoding: encoding),
    _ => client.post(url, headers: requestHeaders, body: body, encoding: encoding),
  };
  // Earlier than the service/UI timeout: a late response must not erase a retry key.
  final response = await future.timeout(const Duration(seconds: 7));
  if (response.statusCode < 500) await prefs.remove(storageKey);
  return response;
}
