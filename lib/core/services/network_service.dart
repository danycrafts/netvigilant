import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';

class NetworkService {
  final http.Client _client;

  NetworkService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(String url, {Map<String, String>? headers}) async {
    log('GET Request to: $url');
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      log('Network Client Exception: $e');
      throw ServerFailure('Network error: ${e.message}');
    } catch (e) {
      log('Unexpected GET error: $e');
      throw ServerFailure('Unexpected error during GET request');
    }
  }

  Future<Map<String, dynamic>> post(String url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    log('POST Request to: $url with body: $body');
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: body,
        encoding: encoding,
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      log('Network Client Exception: $e');
      throw ServerFailure('Network error: ${e.message}');
    } catch (e) {
      log('Unexpected POST error: $e');
      throw ServerFailure('Unexpected error during POST request');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      log('Response Status: ${response.statusCode}, Body: ${response.body}');
      return json.decode(response.body);
    } else {
      log('HTTP Error: ${response.statusCode} - ${response.body}');
      throw ServerFailure(
          'Request failed with status ${response.statusCode}: ${response.body}');
    }
  }

  void dispose() {
    _client.close();
  }
}
