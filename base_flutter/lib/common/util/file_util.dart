import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../index.dart';

class FileUtil {
  static String? defaultDir;

  static Future<XFile> convertToWebPAndResize({
    required File inputFile,
    int minWidth = 800,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(
      tempDir.path,
      '${path.basenameWithoutExtension(inputFile.path)}.webp',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      inputFile.absolute.path,
      targetPath,
      quality: 80,
      format: CompressFormat.webp,
      minWidth: minWidth,
    );

    if (result == null) throw Exception('Failed to compress image');
    return result;
  }

  static bool isExist(String filePath) {
    return File.fromUri(Uri.file(filePath)).existsSync();
  }

  static Future<File?> getImageFileFromUrl(String imageUrl) async {
    try {
      return DefaultCacheManager().getSingleFile(imageUrl);
    } catch (e) {
      Log.e('Error fetching image from URL: $e');

      return null;
    }
  }

  static String? lookupMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  static bool isFolder(String filePath) {
    return FileSystemEntity.isDirectorySync(filePath);
  }

  static Future<String> getUniqueFileName({
    required String directory,
    required String baseName,
    String extension = 'jpg',
  }) async {
    final timestamp = DateTimeUtil.now.toIso8601String().replaceAll(RegExp(r'[:.]'), '');
    String fileName = '${baseName}_$timestamp.$extension';
    String outputPath = path.join(directory, fileName);

    int counter = 1;
    while (await File(outputPath).exists()) {
      fileName = '${baseName}_${timestamp}_$counter.$extension';
      outputPath = path.join(directory, fileName);
      counter++;
    }

    return outputPath;
  }

  static bool deleteFile({
    required String filePath,
    bool recursive = false,
  }) {
    try {
      File(filePath).deleteSync(recursive: recursive);

      return true;
    } catch (e) {
      Log.e('Error deleting file: $e');
    }

    return false;
  }
}
