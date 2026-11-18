import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart'
    if (dart.library.io) 'file_downloader_io.dart';

class FileDownloader {
  static Future<String?> saveAndDownload({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    return await downloadFile(bytes, filename, mimeType);
  }
}

