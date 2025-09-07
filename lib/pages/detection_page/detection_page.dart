import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:yolo_test/detection/detection.dart';

class DetectionResultsScreen extends StatelessWidget {
  final List<Detection> detections;
  final ui.Image image;

  DetectionResultsScreen({required this.detections, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detection Results")),
      body: Center(
        child: CustomPaint(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          painter: DetectionPainter(detections: detections, image: image),
        ),
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final ui.Image image;

  DetectionPainter({required this.detections, required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image
    canvas.drawImage(image, Offset.zero, Paint());

    // Draw bounding boxes and labels
    for (var detection in detections) {
      final box = detection.box;
      final text =
          "${detection.className} (${(detection.confidence * 100).toStringAsFixed(2)}%)";

      // Draw bounding box
      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(box, paint);

      // Draw label background
      final textStyle = TextStyle(color: Colors.white, fontSize: 14);
      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final backgroundRect = Rect.fromLTWH(
        box.left,
        box.top - textPainter.height,
        textPainter.width,
        textPainter.height,
      );

      final backgroundPaint = Paint()..color = Colors.red;
      canvas.drawRect(backgroundRect, backgroundPaint);

      // Draw label text
      textPainter.paint(canvas, Offset(box.left, box.top - textPainter.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
