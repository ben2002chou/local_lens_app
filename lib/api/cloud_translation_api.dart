import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_cloud_translation/google_cloud_translation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// only use for static image translation !!! LIVE TRANSLATION will be too expensive. (around 2 requests per second with around 1000 characters is not economically viable (though possible)...)
class CloudTranslationApi {
  static Future<String?> translateText(String recognizedText) async {
    try {
      print("Translating Text: $recognizedText");
      String googleApiKey = dotenv.env['GOOGLE_API_KEY']!;
      final translation = Translation(apiKey: googleApiKey);
      
      final TranslationModel translationModel =
          await translation.translate(text: recognizedText, to: 'en');
      print("Translated Text: ${translationModel.translatedText}"); // Add this line
      return translationModel.translatedText;
    } catch (e) {
      return null;
    }
  }


  static Future<RecognizedText?> translateRecognizedText(
      RecognizedText recognizedText) async {
    List<TextBlock> translatedBlocks = [];

    for (TextBlock textBlock in recognizedText.blocks) {
      String? translatedText = await translateText(textBlock.text);
      if (translatedText != null) {
        TextBlock translatedBlock = TextBlock(
          text: translatedText,
          lines: textBlock.lines,
          boundingBox: textBlock.boundingBox,
          recognizedLanguages: textBlock.recognizedLanguages,
          cornerPoints: textBlock.cornerPoints,
        );
        translatedBlocks.add(translatedBlock);
      }
    }

    if (translatedBlocks.isNotEmpty) {
      RecognizedText translatedRecognizedText =
          RecognizedText(text: recognizedText.text, blocks: translatedBlocks);
      return translatedRecognizedText;
    }

    return null;
  }
}
