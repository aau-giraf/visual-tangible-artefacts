import 'dart:convert';
import 'dart:typed_data';
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
      headers?.addEntries([
        MapEntry('Content-Type', 'application/json'),
      ]);
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

  Future<Response?> postAsMultiPart(String endPoint,
      {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    var uri = Uri.parse(baseUrl + endPoint);
    try {
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers ?? {}); // Add custom headers
      _buildMultipartRequest(body, request);
      var streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } on Exception catch (e) {
      print(e.toString());
      return null;
    }
  }

  void _buildMultipartRequest(
      Map<String, dynamic>? body, http.MultipartRequest request) {
    body?.forEach((key, value) {
      if (value == null) return; // Skip null values

      if (value is String) {
        request.fields[key] = value; // Directly add strings
      } else if (value is int) {
        request.fields[key] = value.toString(); // Convert integers to strings
      } else if (value is double) {
        request.fields[key] = value.toString(); // Convert doubles to strings
      } else if (value is bool) {
        request.fields[key] = value.toString(); // Convert booleans to strings
      } else if (value is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes(key, value,
            filename: key)); // Add Uint8List directly
      } else if (value is List) {
        if (value is List<String>) {
          request.files.add(http.MultipartFile.fromBytes(
              key, utf8.encode(value.join(',')),
              filename: '$key.txt'));
        } else if (value is List<int>) {
          request.files.add(http.MultipartFile.fromBytes(key, value));
        } else if (value is List<double>) {
          request.files.add(http.MultipartFile.fromBytes(
              key, utf8.encode(value.join(',')),
              filename: '$key.txt'));
        } else if (value is List<bool>) {
          request.files.add(http.MultipartFile.fromBytes(
              key, utf8.encode(value.map((v) => v.toString()).join(',')),
              filename: '$key.txt'));
        } else {
          throw Exception(
              'Unsupported list type for key $key: ${value.runtimeType}');
        }
      } else if (value is Map) {
        if (value is Map<String, dynamic>) {
          request.files.add(http.MultipartFile.fromBytes(
              key, utf8.encode(json.encode(value)),
              filename: '$key.json'));
        } else {
          throw Exception(
              'Unsupported map type for key $key: ${value.runtimeType}');
        }
      } else {
        throw Exception(
            'Unsupported value type for key $key: ${value.runtimeType}');
      }
    });
  }
}
