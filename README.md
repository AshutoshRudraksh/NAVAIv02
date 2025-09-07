# NavAI v02 - Real-Time Object Detection App

A Flutter application that performs real-time object detection using YOLO (You Only Look Once) models. The app supports both image-based detection and live camera feed detection with TensorFlow Lite integration.

## 🚀 Features

- **Real-time Object Detection**: Live camera feed with instant object detection
- **Image Detection**: Capture or select images for object detection
- **Multiple YOLO Models**: Support for various YOLO model variants (YOLOv8, YOLOv10)
- **80 COCO Classes**: Detects 80 different object classes including people, vehicles, animals, and everyday objects
- **Cross-platform**: Works on Android, iOS, and other Flutter-supported platforms
- **Performance Optimized**: Uses isolates for background processing to maintain smooth UI

## 📱 Screenshots

The app provides a clean interface with:
- Main page with camera and image detection options
- Real-time detection overlay on camera feed
- Detailed detection results with confidence scores
- Bounding boxes with class labels

## 🛠️ Technical Stack

- **Framework**: Flutter 3.5.4+
- **ML Framework**: TensorFlow Lite
- **Models**: YOLO (YOLOv8, YOLOv10) variants
- **Camera**: Flutter Camera plugin
- **Image Processing**: Custom YUV to RGB conversion
- **Performance**: Dart Isolates for background processing

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  tflite_flutter: ^0.11.0
  permission_handler: ^11.3.1
  path_provider: ^2.1.5
  image_picker: ^1.1.2
  image: ^4.5.2
  camera: ^0.11.0+2
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # Main application entry point
├── detection/
│   └── detection.dart        # Detection logic and UI components
├── video_detection/
│   └── video_detection.dart  # Real-time camera detection
├── pages/
│   └── detection_page/
│       └── detection_page.dart
└── timer.dart               # Performance timing utilities

assets/
├── metadata.yaml            # Model metadata
├── yolov10n_float32.tflite  # YOLOv10 nano model
├── yolov8m_float16.tflite   # YOLOv8 medium (float16)
├── yolov8m_float32.tflite   # YOLOv8 medium (float32)
├── yolov8n_float16.tflite   # YOLOv8 nano (float16)
├── yolov8n_float32.tflite   # YOLOv8 nano (float32)
└── ssd_mobilenet.tflite     # SSD MobileNet model
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.5.4 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Camera permissions on target device

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd NavAiv02
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Platform-specific Setup

#### Android
- Ensure camera permissions are granted
- Minimum SDK version: 21
- Target SDK version: 34

#### iOS
- Add camera usage description in `Info.plist`
- Minimum iOS version: 11.0

## 🎯 Usage

### Image Detection
1. Tap the camera icon on the main screen
2. Take a photo or select from gallery
3. View detection results with bounding boxes and labels

### Real-time Detection
1. Tap the video icon on the main screen
2. Grant camera permissions
3. Point camera at objects to see real-time detection
4. Detection results appear as colored bounding boxes with labels

## 🔧 Model Configuration

The app uses YOLOv10n by default, but you can switch models by modifying the model path in `main.dart`:

```dart
interpreter = await Interpreter.fromAsset(
  'assets/yolov10n_float32.tflite', // Change this path
);
```

Available models:
- `yolov10n_float32.tflite` - YOLOv10 nano (recommended for mobile)
- `yolov8n_float32.tflite` - YOLOv8 nano
- `yolov8m_float32.tflite` - YOLOv8 medium (higher accuracy, slower)

## 🎨 Detection Classes

The app can detect 80 different object classes from the COCO dataset:

**People & Animals**: person, bird, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe

**Vehicles**: bicycle, car, motorcycle, airplane, bus, train, truck, boat

**Furniture**: chair, couch, bed, dining table, toilet

**Electronics**: tv, laptop, mouse, remote, keyboard, cell phone, microwave, oven, toaster

**Food**: banana, apple, sandwich, orange, broccoli, carrot, hot dog, pizza, donut, cake

**And many more...**

## ⚡ Performance Features

- **Isolate Processing**: Heavy computations run in background isolates
- **Non-Maximum Suppression**: Removes overlapping detections
- **Confidence Filtering**: Configurable confidence thresholds
- **Optimized Image Processing**: Efficient YUV to RGB conversion
- **Memory Management**: Proper cleanup of TensorFlow Lite interpreters

## 🔧 Configuration

### Detection Parameters

You can adjust detection sensitivity by modifying these parameters:

```dart
// In detection.dart
decodeYoloOutput(
  context,
  output,
  0.75, // Confidence threshold (0.0 - 1.0)
  0.8,  // NMS threshold (0.0 - 1.0)
  imageFile,
);
```

- **Confidence Threshold**: Higher values = fewer, more confident detections
- **NMS Threshold**: Higher values = more aggressive overlap removal

## 🐛 Troubleshooting

### Common Issues

1. **Camera not working**
   - Check camera permissions
   - Ensure device has a working camera
   - Try restarting the app

2. **Slow performance**
   - Use smaller model (yolov8n instead of yolov8m)
   - Reduce camera resolution
   - Close other apps

3. **No detections**
   - Check lighting conditions
   - Ensure objects are clearly visible
   - Lower confidence threshold

4. **App crashes**
   - Check device memory
   - Ensure sufficient storage space
   - Update Flutter and dependencies

## 📊 Performance Metrics

The app includes built-in timing utilities to monitor performance:

- Model loading time
- Inference time
- Image processing time
- Total detection time

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ultralytics](https://ultralytics.com/) for YOLO models
- [TensorFlow Lite](https://www.tensorflow.org/lite) for mobile ML inference
- [Flutter](https://flutter.dev/) for the cross-platform framework
- [COCO Dataset](https://cocodataset.org/) for object detection classes

## 📞 Support

For support, please open an issue in the repository or contact the development team.

---

**Note**: This app requires camera permissions and works best on devices with sufficient processing power for real-time inference.
