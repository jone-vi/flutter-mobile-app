import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future imgFromGallery() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    return await cropToSquare(image);
  }
}

Future imgFromCamera() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.camera);
  if (image != null) {
    return await cropToSquare(image);
  }
}

Future cropToSquare(XFile file) async {
  final imageBytes = await file.readAsBytes();
  img.Image originalImage = img.decodeImage(imageBytes)!;
  int size = min(originalImage.width, originalImage.height);
  img.Image croppedImage = img.copyCrop(originalImage,
      x: (originalImage.width - size) ~/ 2,
      y: (originalImage.height - size) ~/ 2,
      width: size,
      height: size);

  final directory = await getApplicationDocumentsDirectory();
  final String imageDirectoryPath = '${directory.path}/images';
  final Directory imageDirectory = Directory(imageDirectoryPath);

  if (!await imageDirectory.exists()) {
    await imageDirectory.create(recursive: true);
  }

  final String newPath =
      '$imageDirectoryPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(newPath).writeAsBytes(img.encodeJpg(croppedImage, quality: 70));

  return XFile(newPath);
}
