import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'currency_conversion.dart';
import 'package:google_cloud_translation/google_cloud_translation.dart';
import '../main.dart';


class TranslationApi {
  static Future<String?> translateText(String recognizedText, String lc) async {
    try {
      final languageCode = lc;
      final translator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.values
              .firstWhere((element) => element.bcpCode == languageCode),
          targetLanguage: TranslateLanguage.english);
      final translatedText = await translator.translateText(recognizedText);
      translator.close();
      print("Translated Text: $translatedText"); // Add this line
      return translatedText;
    } catch (e) {
      print("Error while translating: $e"); // Add this line
      return null;
    }
  }
  



  static Future<RecognizedText?> translateRecognizedText(
      RecognizedText recognizedText) async {
    List<String> texts = [];
    List<TextBlock> blocks = [];

    int i = 1;
    for (TextBlock textBlock in recognizedText.blocks) {
      var temp = await processText(textBlock.text, rate);
      texts.add(temp);
      texts.add('=00' + i.toString() + '=');
      i++;
      blocks.add(textBlock);
    }

    String combinedText = texts.join('');
    String? translatedText = await translateText(combinedText, 'zh');
    translatedText = translatedText! + ' ';
    if (translatedText.isNotEmpty) {
      List<TextBlock> translatedBlocks = [];
      int missedMarkers = 0;
      for (int i = 1; i <= blocks.length; i++) {
        String marker = '= 00' + i.toString() + ' =';
        TextBlock block = blocks[i - 1];
        if (translatedText != null && (translatedText.contains(marker) || i == blocks.length)) {
          String translatedSentence = i != blocks.length
              ? translatedText.split(marker)[0].trim()
              : translatedText.replaceAll(marker, '').trim(); // remove marker if it's the last block
          translatedText = i != blocks.length
              ? translatedText.split(marker).length > 1
                  ? translatedText.split(marker).last
                  : ""
              : "";

          TextBlock translatedBlock = TextBlock(
            text: translatedSentence,
            lines: block.lines,
            boundingBox: block.boundingBox,
            recognizedLanguages: block.recognizedLanguages,
            cornerPoints: block.cornerPoints,
          );
          translatedBlocks.add(translatedBlock);
        } else {
          print("Warning: Marker $marker not found in translated text. Replacing with '!!!!'");
          missedMarkers += 1;
          if (missedMarkers > 2) {
            print("Warning: More than 2 markers missed. Returning null.");
            return null;
          }
          TextBlock translatedBlock = TextBlock(
            text: '!!!!',
            lines: block.lines,
            boundingBox: block.boundingBox,
            recognizedLanguages: block.recognizedLanguages,
            cornerPoints: block.cornerPoints,
          );
          translatedBlocks.add(translatedBlock);
        }
      }

      RecognizedText translatedRecognizedText = RecognizedText(
          text: recognizedText.text, blocks: translatedBlocks);
      if (recognizedText.blocks.length != translatedBlocks.length) {
        print("Warning: Number of blocks before and after translation don't match");
      }
      return translatedRecognizedText;
    }
    return null;
  }
}