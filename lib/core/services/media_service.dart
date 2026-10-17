import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

abstract class MediaService {
  Future<String?> pickImageFromCamera();
  Future<String?> pickImageFromGallery();
  Future<List<String>> pickMultipleImages();
  Future<String> compressImage(String filePath,
      {int quality = 80, int maxDimension = 1600});
}

class ImagePickerMediaService implements MediaService {
  ImagePickerMediaService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pickImageFromCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    return image?.path;
  }

  @override
  Future<String?> pickImageFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  @override
  Future<List<String>> pickMultipleImages() async {
    final images = await _picker.pickMultiImage();
    return images.map((image) => image.path).toList(growable: false);
  }

  @override
  Future<String> compressImage(String filePath,
      {int quality = 80, int maxDimension = 1600}) async {
    final directory = await getTemporaryDirectory();
    final outputPath = p.join(
      directory.path,
      '${DateTime.now().microsecondsSinceEpoch}_${p.basenameWithoutExtension(filePath)}.jpg',
    );
    final compressed = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outputPath,
      quality: quality.clamp(1, 100),
      minWidth: maxDimension,
      minHeight: maxDimension,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) {
      throw FileSystemException('Could not compress selected image', filePath);
    }
    return compressed.path;
  }
}

final mediaServiceProvider = Provider<MediaService>((ref) {
  return ImagePickerMediaService();
});
