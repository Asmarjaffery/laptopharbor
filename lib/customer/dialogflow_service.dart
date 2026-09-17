import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class DialogflowService {
  DialogFlowtter? dialogFlowtter;

  // Initialize Dialogflow with credentials from assets
  Future<void> init() async {
    try {
      if (kIsWeb) {
        // Web platform - load credentials manually
        print('🌐 Initializing for Web platform...');
        final jsonString = await rootBundle.loadString('assets/dialogflow_key.json');
        final credentials = jsonDecode(jsonString);
        
        dialogFlowtter = await DialogFlowtter.fromJson(credentials);
      } else {
        // Mobile/Desktop - use file path
        print('📱 Initializing for Mobile/Desktop platform...');
        dialogFlowtter = await DialogFlowtter.fromFile(
          path: 'assets/dialogflow_key.json',
        );
      }
      print('✅ Dialogflow initialized successfully');
    } catch (e) {
      print('❌ Error initializing Dialogflow: $e');
      rethrow;
    }
  }

  // Send message to Dialogflow and get response
  Future<String> getResponse(String query) async {
    if (dialogFlowtter == null) {
      await init();
    }

    try {
      DetectIntentResponse response = await dialogFlowtter!.detectIntent(
        queryInput: QueryInput(
          text: TextInput(
            text: query,
            languageCode: 'en',
          ),
        ),
      );

      if (response.message == null || response.message!.text == null) {
        return 'Sorry, I could not understand that.';
      }

      return response.message!.text!.text![0];
    } catch (e) {
      print('Error getting response: $e');
      return 'Sorry, something went wrong. Please try again.';
    }
  }

  // Get response in different language
  Future<String> getResponseInLanguage(String query, String languageCode) async {
    if (dialogFlowtter == null) {
      await init();
    }

    try {
      DetectIntentResponse response = await dialogFlowtter!.detectIntent(
        queryInput: QueryInput(
          text: TextInput(
            text: query,
            languageCode: languageCode,
          ),
        ),
      );

      if (response.message == null || response.message!.text == null) {
        return 'Sorry, I could not understand that.';
      }

      return response.message!.text!.text![0];
    } catch (e) {
      print('Error getting response: $e');
      return 'Sorry, something went wrong. Please try again.';
    }
  }

  // Dispose resources
  void dispose() {
    dialogFlowtter?.dispose();
  }
}