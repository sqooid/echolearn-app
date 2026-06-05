import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  final http.Client _client;
  String apiKey;

  ApiService({http.Client? client, this.apiKey = ''})
      : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (apiKey.isNotEmpty) h['x-api-key'] = apiKey;
    return h;
  }

  Future<TranslationResult> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConfig.translateUrl),
      headers: _headers,
      body: jsonEncode({'text': text, 'from': from, 'to': to}),
    );

    if (response.statusCode != 200) {
      throw ApiException('Translation failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return TranslationResult(text: data['text'] as String);
  }

  Future<List<int>> textToSpeech({
    required String text,
    required String language,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConfig.ttsUrl),
      headers: _headers,
      body: jsonEncode({'text': text, 'language': language}),
    );

    if (response.statusCode != 200) {
      throw ApiException('TTS failed: ${response.statusCode}');
    }

    return response.bodyBytes.toList();
  }
}

class TranslationResult {
  final String text;
  const TranslationResult({required this.text});
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}
