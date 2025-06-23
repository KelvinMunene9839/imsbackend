import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiClient({required this.baseUrl})
      : defaultHeaders = {
          'Content-Type': 'application/json',
        };

  Future<http.Response> get(String endpoint) {
    final url = Uri.parse('$baseUrl$endpoint');
    return http.get(url, headers: defaultHeaders);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) {
    final url = Uri.parse('$baseUrl$endpoint');
    return http.post(url, headers: defaultHeaders, body: jsonEncode(body));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) {
    final url = Uri.parse('$baseUrl$endpoint');
    return http.put(url, headers: defaultHeaders, body: jsonEncode(body));
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) {
    final url = Uri.parse('$baseUrl$endpoint');
    return http.patch(url, headers: defaultHeaders, body: jsonEncode(body));
  }
}
