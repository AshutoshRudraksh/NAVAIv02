import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:yolo_test/timer.dart';

class Detection {
  final Rect box;
  final double confidence;
  final int classId;
  final String className;

  Detection(this.box, this.confidence, this.classId, this.className);
}

Future<List<Detection>> decodeYoloVideoOutput(
  BuildContext context,
  List<List<List<double>>> output,
  double confidenceThreshold,
  double nmsThreshold,
) async {
  TimerUtil timerUtil = TimerUtil();
  timerUtil.startTimer();
  print("Calling Decode Output");

  List<Detection> detections = [];

  // Get screen dimensions once
  double screenHeight = MediaQuery.of(context).size.height;
  double screenWidth = MediaQuery.of(context).size.width;

  List<String> classNames = [
    "person",
    "bicycle",
    "car",
    "motorcycle",
    "airplane",
    "bus",
    "train",
    "truck",
    "boat",
    "traffic light",
    "fire hydrant",
    "stop sign",
    "parking meter",
    "bench",
    "bird",
    "cat",
    "dog",
    "horse",
    "sheep",
    "cow",
    "elephant",
    "bear",
    "zebra",
    "giraffe",
    "backpack",
    "umbrella",
    "handbag",
    "tie",
    "suitcase",
    "frisbee",
    "skis",
    "snowboard",
    "sports ball",
    "kite",
    "baseball bat",
    "baseball glove",
    "skateboard",
    "surfboard",
    "tennis racket",
    "bottle",
    "wine glass",
    "cup",
    "fork",
    "knife",
    "spoon",
    "bowl",
    "banana",
    "apple",
    "sandwich",
    "orange",
    "broccoli",
    "carrot",
    "hot dog",
    "pizza",
    "donut",
    "cake",
    "chair",
    "couch",
    "potted plant",
    "bed",
    "dining table",
    "toilet",
    "tv",
    "laptop",
    "mouse",
    "remote",
    "keyboard",
    "cell phone",
    "microwave",
    "oven",
    "toaster",
    "sink",
    "refrigerator",
    "book",
    "clock",
    "vase",
    "scissors",
    "teddy bear",
    "hair drier",
    "toothbrush"
  ];

  // Pre-filter low-confidence detections
  List<List<double>> filteredPredictions =
      output[0].where((p) => p[4] >= confidenceThreshold).toList();

  // Process detections
  List<Detection> processedDetections = filteredPredictions
      .map((prediction) {
        double objectness = prediction[4];
        double inputSize = 640.0; // YOLO input size

// Scale factors based on the actual video frame size
        double scaleX = screenWidth / inputSize; // 384 / 640
        double scaleY = screenHeight / inputSize; // 784 / 640

// Convert normalized YOLO coordinates back to the original 640x640 space
        double x = prediction[0] * inputSize;
        double y = prediction[1] * inputSize;
        double width = prediction[2] * inputSize;
        double height = prediction[3] * inputSize;

// Adjust for the actual video frame size
        x *= scaleX;
        y *= scaleY;
        width *= scaleX;
        height *= scaleY;
        int classId = prediction[5].toInt();
        print("Class Id: $classId");
        print("Class Name: ${classNames[classId]}");
        print("Confidence: ${prediction[4]}");
        print("x:$x,y:$y,height:$height,width:$width");

        if (classId < 0 || classId >= classNames.length) {
          return null; // Skip invalid classId
        }

        return Detection(Rect.fromLTWH(x, y, width, height), objectness,
            classId, classNames[classId]);
      })
      .whereType<Detection>() // This ensures we only get non-null values
      .toList();

  // Apply Non-Maximum Suppression (NMS)
  detections = nonMaxSuppression(processedDetections, nmsThreshold);

  timerUtil.stopTimer("Decode Video Output");
  return detections;
}

Future<List<Detection>> decodeYoloOutput(
  BuildContext context,
  List<List<List<double>>> output,
  double confidenceThreshold,
  double nmsThreshold,
  File imageFile,
) async {
  print("Calling Decode Output");
  List<Detection> detections = [];

  // COCO class names (80 classes)
  List<String> classNames = [
    "person",
    "bicycle",
    "car",
    "motorcycle",
    "airplane",
    "bus",
    "train",
    "truck",
    "boat",
    "traffic light",
    "fire hydrant",
    "stop sign",
    "parking meter",
    "bench",
    "bird",
    "cat",
    "dog",
    "horse",
    "sheep",
    "cow",
    "elephant",
    "bear",
    "zebra",
    "giraffe",
    "backpack",
    "umbrella",
    "handbag",
    "tie",
    "suitcase",
    "frisbee",
    "skis",
    "snowboard",
    "sports ball",
    "kite",
    "baseball bat",
    "baseball glove",
    "skateboard",
    "surfboard",
    "tennis racket",
    "bottle",
    "wine glass",
    "cup",
    "fork",
    "knife",
    "spoon",
    "bowl",
    "banana",
    "apple",
    "sandwich",
    "orange",
    "broccoli",
    "carrot",
    "hot dog",
    "pizza",
    "donut",
    "cake",
    "chair",
    "couch",
    "potted plant",
    "bed",
    "dining table",
    "toilet",
    "tv",
    "laptop",
    "mouse",
    "remote",
    "keyboard",
    "cell phone",
    "microwave",
    "oven",
    "toaster",
    "sink",
    "refrigerator",
    "book",
    "clock",
    "vase",
    "scissors",
    "teddy bear",
    "hair drier",
    "toothbrush"
  ];

  // Iterate over all predictions
  for (var prediction in output[0]) {
    // Extract objectness score
    double objectness = prediction[4];

    // Skip if objectness score is below the threshold
    if (objectness < confidenceThreshold) continue;

    // Extract bounding box coordinates (x, y, width, height)
    // Get the image size dynamically
    final image = await decodeImageFromList(imageFile.readAsBytesSync());
    double imageWidth = image.width.toDouble();
    double imageHeight = image.height.toDouble();
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    // double imageWidth = 640;
    // double imageHeight = 640;

    // Extract bounding box coordinates (center_x, center_y, width, height)
    print("Screen Height: ${MediaQuery.of(context).size.height}");
    print("Screen Width: ${MediaQuery.of(context).size.width}");
    print("Image Height: ${imageHeight}");
    print("Imag Width: ${imageWidth}");
    print("Prediction[0]: ${prediction[0]}");
    print("Prediction[1]: ${prediction[1]}");
    print("Prediction[2]: ${prediction[2]}");
    print("Prediction[3]: ${prediction[3]}");
    double centerX = prediction[0] * screenWidth; // Center X
    double centerY = prediction[1] * screenHeight; // Center Y
    double width = prediction[2] * screenWidth; // Width of the box
    double height = prediction[3] * screenHeight; // Height of the box

    // Convert center coordinates to top-left coordinates
    double x = centerX - width / 2;
    double y = centerY - height / 2;

    // Clamp coordinates to ensure they stay within image bounds
    // x = x.clamp(0, imageWidth - width);
    // y = y.clamp(0, imageHeight - height);
    // width = width.clamp(0, imageWidth - x);
    // height = height.clamp(0, imageHeight - y);

// Clamp width and height to stay within image bounds
//     width = min(width, imageWidth - x);
//     height = min(height, imageHeight - y);

// Ensure x, y are not negative
//     x = max(0, x);
//     y = max(0, y);

    print("Predictions: $prediction");
    print("X: $x, Y: $y, Width: $width, Height: $height");

    // Convert normalized coordinates to absolute coordinates
    Rect box = Rect.fromLTWH(x, y, width, height);
    print("Box: $box");

    // Extract class probabilities
    double classProbs = prediction[5];
    print("Class Id: ${prediction[5]}");

    // Ensure that the class ID is an integer
    int classId = classProbs.toInt();

    double confidence = objectness; // Final confidence score

    // Ensure classId is within the valid range (0-79)
    if (classId < 0 || classId >= classNames.length) {
      print("⚠️ Invalid classId: $classId. Skipping this detection.");
      continue;
    }

    // Add detection to the list
    print(
        "Class ID: $classId, Class Name: ${classNames[classId]}, Confidence: $confidence");
    detections.add(Detection(box, confidence, classId, classNames[classId]));
  }

  // Apply Non-Maximum Suppression (NMS) to remove overlapping boxes
  detections = nonMaxSuppression(detections, nmsThreshold);
  print("Detections: $detections");

  // Navigate only if there are detections
  // if (detections.isNotEmpty) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DetectionScreen(detections, imageFile),
    ),
  );
  return detections;
}

List<Detection> nonMaxSuppression(
    List<Detection> detections, double threshold) {
  detections.sort((a, b) => b.confidence.compareTo(a.confidence));
  List<Detection> filteredDetections = [];

  while (detections.isNotEmpty) {
    Detection bestDetection = detections.removeAt(0);
    filteredDetections.add(bestDetection);

    detections.removeWhere((detection) {
      double iou = calculateIoU(bestDetection.box, detection.box);
      return iou > threshold;
    });
  }

  return filteredDetections;
}

double calculateIoU(Rect box1, Rect box2) {
  double x1 = max(box1.left, box2.left);
  double y1 = max(box1.top, box2.top);
  double x2 = min(box1.right, box2.right);
  double y2 = min(box1.bottom, box2.bottom);

  double intersectionArea = max(0, x2 - x1) * max(0, y2 - y1);
  double box1Area = box1.width * box1.height;
  double box2Area = box2.width * box2.height;

  double unionArea = box1Area + box2Area - intersectionArea;
  return intersectionArea / unionArea;
}

// Screen to display detections
class DetectionScreen extends StatelessWidget {
  final List<Detection> detections;
  final File imageFile;

  DetectionScreen(this.detections, this.imageFile);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detections")),
      body: Center(
        child: FutureBuilder<Size>(
          future: _getImageSize(imageFile), // Get image size
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();

            Size imageSize = snapshot.data!;

            return Stack(
              children: [
                Image.file(imageFile),
                ...detections.map((detection) {
                  print("Detection ");

                  print("Screen Height: ${MediaQuery.of(context).size.height}");
                  print("Screen Width: ${MediaQuery.of(context).size.width}");
                  print(detection.box.left);
                  print(detection.box.top);
                  print(detection.box.width);
                  print(detection.box.height);
                  // Generate a random color
                  final random = Random();
                  Color randomColor = Color.fromARGB(
                    255,
                    random.nextInt(256), // Red value
                    random.nextInt(256), // Green value
                    random.nextInt(256), // Blue value
                  );

                  return Positioned(
                    left: detection.box.left + 192,
                    top: detection.box.top,
                    width: detection.box.width,
                    height: detection.box.height,
                    // bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: randomColor, width: 3),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          color: Colors.red,
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            "${detection.className} ${(detection.confidence * 100).toStringAsFixed(2)}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Get the size of the image for proper bounding box scaling
  Future<Size> _getImageSize(File imageFile) async {
    final image = await decodeImageFromList(imageFile.readAsBytesSync());
    return Size(image.width.toDouble(), image.height.toDouble());
  }
}
