import 'dart:io';

Future<String?> downloadFile(List<int> bytes, String filename, String mimeType) async {
  final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
  final downloadsDir = Directory('$userProfile\\Downloads');
  final targetDir = downloadsDir.existsSync() ? downloadsDir : Directory.current;
  final file = File('${targetDir.path}\\$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}

