import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiError implements Exception {
  final String message;
  final int status;
  ApiError(this.message, this.status);
  @override
  String toString() => message;
}

class Api {
  final String? baseUrl;
  static String? _authToken;

  Api({this.baseUrl});

  Uri _resolveUrl(String path) {
    if (baseUrl != null && baseUrl!.trim().isNotEmpty) {
      final base = Uri.parse(baseUrl!.trim());
      return base.resolve(base.path.endsWith('/') ? 'api/$path' : '/api/$path');
    }
    const envUrl = String.fromEnvironment('LOADSECURE_API_URL');
    if (envUrl.isNotEmpty) {
      final base = Uri.parse(envUrl);
      return base.resolve(base.path.endsWith('/') ? 'api/$path' : '/api/$path');
    }
    // Quando executado localmente via flutter run (ex: localhost:60515)
    // direciona automaticamente para o servidor backend em localhost:8787
    if (Uri.base.scheme.startsWith('http') &&
        (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') &&
        Uri.base.port != 8787 &&
        Uri.base.port != 80 &&
        Uri.base.port != 443 &&
        Uri.base.port != 0) {
      return Uri.parse('http://localhost:8787/api/$path');
    }
    return Uri.base.resolve('/api/$path');
  }

  Future<Map<String, dynamic>> call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    final url = _resolveUrl(path);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    final response = method == 'GET'
        ? await http.get(url, headers: headers)
        : await http.post(
            url,
            headers: headers,
            body: jsonEncode(data ?? {}),
          );

    Map<String, dynamic> result;
    try {
      result = Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (_) {
      throw ApiError(
        'Não foi possível conectar ao servidor. Tente novamente.',
        503,
      );
    }
    if (response.statusCode >= 400) {
      throw ApiError(
        result['error']?.toString() ?? 'Não foi possível concluir a operação.',
        response.statusCode,
      );
    }
    if (result['token'] is String) {
      _authToken = result['token'] as String;
    }
    if (path == 'logout') {
      _authToken = null;
    }
    return result;
  }
}
