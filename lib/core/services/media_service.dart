import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class MediaService {
  Future<String?> pickImageFromCamera();
  Future<String?> pickImageFromGallery();
  Future<List<String>> pickMultipleImages();
  Future<String> compressImage(String filePath, {int quality = 80, int maxDimension = 1600});
}

class MockMediaService implements MediaService {
  @override
  Future<String?> pickImageFromCamera() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'assets/mock/bus_sample_1.jpg';
  }

  @override
  Future<String?> pickImageFromGallery() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'assets/mock/bus_sample_2.jpg';
  }

  @override
  Future<List<String>> pickMultipleImages() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      'assets/mock/bus_sample_1.jpg',
      'assets/mock/bus_sample_2.jpg',
    ];
  }

  @override
  Future<String> compressImage(String filePath, {int quality = 80, int maxDimension = 1600}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return filePath;
  }
}

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MockMediaService();
});
