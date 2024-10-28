import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiProvider {
  final String baseUrl;

  ApiProvider({required this.baseUrl});

  Future<dynamic>? fetchAsJson(String endPoint,
      {Map<String, String>? headers}) async {
    var uri = Uri.parse(baseUrl + endPoint);
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.body}');
      }
    } on Exception catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<dynamic>? postAsJson(String endPoint,
      {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    var uri = Uri.parse(baseUrl + endPoint);
    try {
      final response = await http.post(
        uri,
        headers: headers ?? {'Content-Type': 'application/json'},
        body: body != null ? json.encode(body) : null,
      );

      // Process the response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.body}');
      }
    } on Exception catch (e) {
      print(e.toString());
      return null;
    }
  }
}
