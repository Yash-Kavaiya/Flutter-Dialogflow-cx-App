import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/dialogflow/v3.dart' as df;

class AuthClient {
  static const _scopes = [df.DialogflowApi.cloudPlatformScope];

  static Future<df.DialogflowApi> getDialogflowApi() async {
    // Load the service account JSON file from assets
    final serviceAccountJson = await rootBundle.loadString('assets/key.json');
    final credentials = ServiceAccountCredentials.fromJson(json.decode(serviceAccountJson));
    final client = await clientViaServiceAccount(credentials, _scopes);

    // Specify the base URL for the correct region (assuming us-central1)
    final endpoint = 'https://us-central1-dialogflow.googleapis.com/';

    return df.DialogflowApi(client, rootUrl: endpoint);
  }
}

class ChatbotClient {
  final String projectId;
  final String agentId;
  final String location;

  ChatbotClient({
    required this.projectId,
    required this.agentId,
    required this.location,
  });

  Future<String> sendMessage(String sessionId, String message) async {
    try {
      final dialogflow = await AuthClient.getDialogflowApi();
      final sessionPath = 'projects/$projectId/locations/$location/agents/$agentId/sessions/$sessionId';
      
      final queryInput = df.GoogleCloudDialogflowCxV3QueryInput(
        languageCode: 'en',
        text: df.GoogleCloudDialogflowCxV3TextInput(text: message),
      );

      final response = await dialogflow.projects.locations.agents.sessions.detectIntent(
        df.GoogleCloudDialogflowCxV3DetectIntentRequest(queryInput: queryInput),
        sessionPath,
      );

      final queryResult = response.queryResult;
      if (queryResult != null && 
          queryResult.responseMessages != null && 
          queryResult.responseMessages!.isNotEmpty) {
        
        // Extract text from the first response message
        final firstMessage = queryResult.responseMessages!.first;
        if (firstMessage.text != null && 
            firstMessage.text!.text != null && 
            firstMessage.text!.text!.isNotEmpty) {
          return firstMessage.text!.text!.first;
        }
      }
      
      return 'No response from chatbot';
    } catch (e) {
      print('Error sending message: $e');
      return 'Error: Unable to get response from chatbot';
    }
  }
}