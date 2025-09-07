import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:yolo_test/detection/detection.dart';
import 'package:yolo_test/main.dart';
import 'package:yolo_test/timer.dart';

class RealTimeDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const RealTimeDetectionScreen({required this.cameras});

  @override
  _RealTimeDetectionScreenState createState() =>
      _RealTimeDetectionScreenState();
}

class _RealTimeDetectionScreenState extends State<RealTimeDetectionScreen> {
  late CameraController _cameraController;
  late YoloDetector _yoloDetector;
  bool _isDetecting = false;
  List<Detection> _detections = [];
  TimerUtil timerUtil = TimerUtil();
  @override
  void initState() {
    super.initState();

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    timerUtil.startTimer();
    await _initializeYolo();

    _cameraController = CameraController(
      widget.cameras[0], // Use the first camera
      ResolutionPreset.high,
    );

    await _cameraController.initialize();
    if (!mounted) return;

    setState(() {});

    _cameraController.startImageStream((CameraImage cameraImage) async {
      if (!_isDetecting) {
        _isDetecting = true;

        // Convert CameraImage to Float32List for YOLO input
        final input = _convertCameraImageToInput(cameraImage, 640, 640);

        // Run YOLO inference
        final output = await _yoloDetector.runVideoInferenceIsolate(input);

        // Decode YOLO output
        decodeYoloVideoOutput(
          context,
          output,
          0.5, // Confidence threshold
          0.8, // NMS threshold
        ).then((detections) {
          setState(() {
            if (detections != null) {
              _detections = detections;
            } else {
              print("Warning: detections is null");
            }
          });
          _isDetecting = false;
        });
      }
    });

    timerUtil.stopTimer("Initilaize Camera");
  }

  Future<void> _initializeYolo() async {
    timerUtil.startTimer();
    _yoloDetector = YoloDetector();
    await _yoloDetector.loadModel();
    timerUtil.stopTimer("Int Yolo");
  }

  Future<Float32List> convertCameraImageToInputIsolate(
      CameraImage image, int height, int width) async {
    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(
        _imageProcessingIsolate, [receivePort.sendPort, image, height, width]);

    return await receivePort.first; // Wait for result
  }

  void _imageProcessingIsolate(List<dynamic> args) {
    SendPort sendPort = args[0];
    CameraImage image = args[1];
    int height = args[2];
    int width = args[3];

    final inputBuffer = Float32List(1 * height * width * 3);
    int bufferIndex = 0;

    if (image.format.group == ImageFormatGroup.yuv420) {
      final yBuffer = image.planes[0].bytes;
      final uBuffer = image.planes[1].bytes;
      final vBuffer = image.planes[2].bytes;

      final yRowStride = image.planes[0].bytesPerRow;
      final uvRowStride = image.planes[1].bytesPerRow;
      final uvPixelStride = image.planes[1].bytesPerPixel!;

      for (int h = 0; h < height; h++) {
        final int yRow = h * yRowStride;
        final int uvRow = (h >> 1) * uvRowStride;
        for (int w = 0; w < width; w++) {
          final int yIndex = yRow + w;
          final int uvIndex = uvRow + ((w >> 1) * uvPixelStride);

          final y = yBuffer[yIndex];
          final u = uBuffer[uvIndex];
          final v = vBuffer[uvIndex];

          // Convert YUV to RGB
          final r = (y + 1.402 * (v - 128)).clamp(0, 255);
          final g =
              (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).clamp(0, 255);
          final b = (y + 1.772 * (u - 128)).clamp(0, 255);

          // Normalize to [0, 1]
          inputBuffer[bufferIndex++] = r / 255.0;
          inputBuffer[bufferIndex++] = g / 255.0;
          inputBuffer[bufferIndex++] = b / 255.0;
        }
      }
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      final buffer = image.planes[0].bytes;
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          final pixelOffset = h * height * 4 + w * 4;

          // Extract BGRA values
          final b = buffer[pixelOffset];
          final g = buffer[pixelOffset + 1];
          final r = buffer[pixelOffset + 2];

          // Normalize to [0, 1]
          inputBuffer[bufferIndex++] = r / 255.0;
          inputBuffer[bufferIndex++] = g / 255.0;
          inputBuffer[bufferIndex++] = b / 255.0;
        }
      }
    } else {
      throw UnsupportedError("Unsupported image format");
    }

    // Send processed data back to main thread
    sendPort.send(inputBuffer);
  }

  Float32List _convertCameraImageToInput(
      CameraImage image, int height, int width) {
    timerUtil.startTimer();
    final inputBuffer = Float32List(1 * height * width * 3);
    int bufferIndex = 0;

    if (image.format.group == ImageFormatGroup.yuv420) {
      final yBuffer = image.planes[0].bytes;
      final uBuffer = image.planes[1].bytes;
      final vBuffer = image.planes[2].bytes;

      final yRowStride = image.planes[0].bytesPerRow;
      final uvRowStride = image.planes[1].bytesPerRow;
      final uvPixelStride = image.planes[1].bytesPerPixel!;

      for (int h = 0; h < height; h++) {
        final int yRow = h * yRowStride;
        final int uvRow = (h >> 1) * uvRowStride;
        for (int w = 0; w < width; w++) {
          final int yIndex = yRow + w;
          final int uvIndex = uvRow + ((w >> 1) * uvPixelStride);
// This was done to work with values which are unsigned
          final y = yBuffer[yIndex] & 0xFF;
          final u = uBuffer[uvIndex] & 0xFF;
          final v = vBuffer[uvIndex] & 0xFF;

          // Convert YUV to RGB
          final r = (y + 1.402 * (v - 128)).clamp(0, 255);
          final g =
              (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).clamp(0, 255);
          final b = (y + 1.772 * (u - 128)).clamp(0, 255);

          // Normalize to [0, 1]
          inputBuffer[bufferIndex++] = r / 255.0;
          inputBuffer[bufferIndex++] = g / 255.0;
          inputBuffer[bufferIndex++] = b / 255.0;
        }
      }
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      final buffer = image.planes[0].bytes;
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          final pixelOffset = h * width * 4 + w * 4;

          // Extract BGRA values
          final b = buffer[pixelOffset];
          final g = buffer[pixelOffset + 1];
          final r = buffer[pixelOffset + 2];

          // Normalize to [0, 1]
          inputBuffer[bufferIndex++] = r / 255.0;
          inputBuffer[bufferIndex++] = g / 255.0;
          inputBuffer[bufferIndex++] = b / 255.0;
        }
      }
    } else {
      throw UnsupportedError("Unsupported image format");
    }
    timerUtil.stopTimer("_convertCameraImageToInput");
    return inputBuffer;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _yoloDetector.closeInterpreter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Container();
    }

    // Get actual camera preview size
    Size previewSize = _cameraController.value.previewSize!;
    double previewWidth = previewSize.height; // Flip width and height
    double previewHeight = previewSize.width;

    // Get screen dimensions
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Aspect ratio adjustments
    double scaleX = screenWidth / previewWidth;
    double scaleY = screenHeight / previewHeight;

    return Scaffold(
      appBar: AppBar(title: Text("Real-Time Object Detection")),
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          ..._detections.map((detection) {
            // Adjust bounding box from 640x640 to actual preview size
            double x = detection.box.left * scaleX;
            double y = detection.box.top * scaleY;
            double width = detection.box.width * scaleX;
            double height = detection.box.height * scaleY;

            return Positioned(
              left: x,
              top: y,
              width: width,
              height: height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 3),
                ),
                child: Align(
                  alignment: Alignment.topRight,
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
      ),
    );
  }
}
