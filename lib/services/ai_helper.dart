import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class AIHelper {
  static Future<String> getCategoryFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    // Using the default on-device model
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.6),
    );

    final List<ImageLabel> labels = await labeler.processImage(inputImage);
    await labeler.close();

    if (labels.isNotEmpty) {
      // Return the most confident label (e.g., "Vegetable", "Fruit", "Apple")
      return labels.first.label;
    }
    return "General";
  }
}
