import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiHttpService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  
  final List<String> _categories = [
    'Food', 'Travel', 'Entertainment', 'Other', 'shopping', 'rent', 'bill', 'grocery', 'fuel'
  ];

  Future<Map<String, dynamic>?> processImage(String imagePath) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Gemini API Key is missing. Please check your .env file.');
    }

    final File imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // 1. Dynamically detect the correct MIME type based on file extension
    final extension = imagePath.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg'; // Default fallback
    
    if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'webp') {
      mimeType = 'image/webp';
    } else if (extension == 'heic' || extension == 'heif') {
      mimeType = 'image/heic';
    }

    // 2. Official Gemini 3.5-flash active free-tier REST endpoint
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$_apiKey',
    );

    debugPrint('Calling Gemini 3.5 API ($mimeType): $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': '''Analyze this bill or receipt image. Extract the total amount to be paid and the category.
                If the amount is in a foreign currency, convert it to INR (approximate rates: 1 USD=85, 1 EUR=92, 1 GBP=110).
                Return ONLY a JSON object with:
                - "amount": numeric value in INR
                - "category": one of ${_categories.join(', ')}
                '''
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'response_mime_type': 'application/json',
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      final String? responseText = data['candidates']?[0]['content']?[0]?['text'] ?? 
                                   data['candidates']?[0]['content']?['parts']?[0]?['text'];
      
      if (responseText != null && responseText.isNotEmpty) {
        // Handle potential code block wrapping in the response
        final jsonPattern = RegExp(r'\{.*\}', dotAll: true);
        final match = jsonPattern.firstMatch(responseText);
        final jsonStr = match != null ? match.group(0) : responseText;
        
        final parsed = jsonDecode(jsonStr!);

        double? amount = (parsed['amount'] as num?)?.toDouble();
        String category = parsed['category']?.toString() ?? 'Other';
        if (!_categories.contains(category)) category = 'Other';

        return {
          'amount': amount,
          'category': category,
        };
      }
    } else {
      debugPrint('Gemini Error Response: ${response.body}');
      throw Exception('Gemini API Error: ${response.statusCode}');
    }

    return null;
  }
}
