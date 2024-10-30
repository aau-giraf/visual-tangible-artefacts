import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class ApiProvider {
  final String baseUrl;

  ApiProvider({required this.baseUrl});

  Future<Response?> fetchAsJson(String endPoint,
      {Map<String, String>? headers}) async {
    var uri = Uri.parse(baseUrl + endPoint);
    try {
      return await http.get(uri, headers: headers);
    } on Exception catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<Response?> postAsJson(String endPoint,
      {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    var uri = Uri.parse(baseUrl + endPoint);
    try {
      return await http.post(
        uri,
        headers: headers ?? {'Content-Type': 'application/json'},
        body: body != null ? json.encode(body) : null,
      );
    } on Exception catch (e) {
      print(e.toString());
      return null;
    }
  }
}
