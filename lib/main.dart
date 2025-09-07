import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:yolo_test/detection/detection.dart';
import 'package:yolo_test/video_detection/video_detection.dart';

class YoloDetector {
  late Interpreter interpreter;

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset(
      'assets/yolov10n_float32.tflite',
    );
    print(interpreter.getInputTensors());
    print(interpreter.getOutputTensors());

    print("✅ YOLO model loaded successfully.");
  }

  Float32List preprocessImage(Uint8List imageBytes) {
    img.Image image = img.decodeImage(imageBytes)!;
    img.Image resized = img.copyResize(image, width: 640, height: 640);

    // Ensure shape matches (1, 640, 640, 3)
    var inputBuffer = Float32List(1 * 640 * 640 * 3);
    var bufferIndex = 0;

    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        var pixel = resized.getPixel(x, y);
        inputBuffer[bufferIndex++] = pixel.r / 255;
        inputBuffer[bufferIndex++] = pixel.g / 255.0;
        inputBuffer[bufferIndex++] = pixel.b / 255.0;
      }
    }

    return inputBuffer;
  }

  Future<void> runInference(
      {required File imageFile, required BuildContext context}) async {
    if (interpreter == null) {
      print("⚠️ Interpreter not initialized.");
      return;
    }
    var output = List.generate(
      1,
      (_) => List.generate(
        300,
        (_) => List<double>.filled(6, 0),
      ),
    );
    var input = preprocessImage(imageFile.readAsBytesSync());
    final bytes = await imageFile.readAsBytes();

    // Decode the image
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage != null) {
      final width = decodedImage.width;
      final height = decodedImage.height;

      print('Image Dimensions: Width = $width, Height = $height');
    } else {
      print('Failed to decode the image.');
    }
    // print(interpreter.getOutputTensor(0).shape);
    // Run inference
    // print("Output: ${output}");
    var reshapedInput = input.reshape([1, 640, 640, 3]);
    print("Model Input Shape: ${interpreter.getInputTensors()}");
    print("Model Output Shape: ${interpreter.getOutputTensors()}");
    print("Input Shape Before Running: ${reshapedInput.shape}");
    print("Output Shape Before Running: ${output.shape}");

    // interpreter.allocateTensors();

    interpreter.run(reshapedInput, output);
    img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;
    img.Image resized = img.copyResize(image, width: 640, height: 640);

    decodeYoloOutput(context, output, 0.75, 0.8, imageFile);
  }

  Future<List<List<List<double>>>> runVideoInferenceIsolate(
      Float32List input) async {
    final ReceivePort receivePort = ReceivePort();

    await Isolate.spawn(_yoloInferenceIsolate, [receivePort.sendPort, input]);

    return await receivePort.first; // Wait for the result
  }

  void _yoloInferenceIsolate(List<dynamic> args) {
    SendPort sendPort = args[0];
    Float32List input = args[1];

    // YOLO inference
    var output = List.generate(
        1,
        (_) => List.generate(
              300,
              (_) => List<double>.filled(6, 0),
            ));

    var reshapedInput = input.reshape([1, 640, 640, 3]);
    interpreter.run(reshapedInput, output);

    // Send result back to main thread
    sendPort.send(output);
  }

  void closeInterpreter() {
    interpreter.close();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // yolo.closeInterpreter();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: MainPage());
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Main Page"),
      ),
      body: Container(
        child: Center(
            child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        final yolo = YoloDetector();
                        await yolo.loadModel();

                        final picker = ImagePicker();
                        final pickedFile =
                            await picker.pickImage(source: ImageSource.camera);

                        if (pickedFile != null) {
                          final imageFile = File(pickedFile.path);
                          await yolo.runInference(
                              imageFile: imageFile, context: context);
                        } else {
                          print("⚠️ No image selected.");
                        }
                      },
                      child: Icon(
                        Icons.camera,
                        size: 50,
                      ),
                    ),
                    Text("Image")
                  ],
                ),
                Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        final yolo = YoloDetector();
                        await yolo.loadModel();
                        final cameras = await availableCameras();

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RealTimeDetectionScreen(cameras: cameras),
                            ));
                      },
                      child: Icon(
                        Icons.video_call,
                        size: 50,
                      ),
                    ),
                    Text("Video")
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 25,
            ),
            Text("This is the main page"),
          ],
        )),
      ),
    );
  }
}
